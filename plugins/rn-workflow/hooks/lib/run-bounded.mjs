#!/usr/bin/env node
// run-bounded — runs a heavy hook command (jest, eslint) so it can never take over the machine:
//   • one at a time per project (--name lock; waits up to --wait seconds, else skips)
//   • a Node heap cap for the command and its workers (--max-mb → NODE_OPTIONS)
//   • its own time limit (--timeout), set below the hook's, so it never relies on being cancelled
//   • kills the WHOLE process tree on timeout, on SIGTERM/SIGINT/SIGHUP, or when its parent dies —
//     a cancelled hook can no longer leave jest / eslint workers running in the background.
//
// Usage: node run-bounded.mjs --name <lock> --timeout <s> [--wait <s>] [--max-mb <MB>] -- <cmd> [args…]
// Exit:  the command's own code · 124 timed out (killed) · 75 skipped (another run held the lock)
import { spawn } from 'node:child_process';
import { createHash } from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const argv = process.argv.slice(2);

// ---- watchdog mode: lives INSIDE the command's process group ----
// If the runner disappears for any reason — even SIGKILL, which it can't trap — the watchdog takes the
// whole group (the command and every worker it started) down within a second.
if (argv[0] === '--watchdog') {
  const runnerPid = Number(argv[1]);
  const [wcmd, ...wargs] = argv.slice(3);
  const isAlive = pid => {
    try {
      process.kill(pid, 0);
      return true;
    } catch (e) {
      return e.code === 'EPERM';
    }
  };
  const c = spawn(wcmd, wargs, { stdio: 'inherit' }); // same group as the watchdog
  setInterval(() => {
    if (!isAlive(runnerPid)) {
      try { process.kill(-process.pid, 'SIGTERM'); } catch {}
      setTimeout(() => { try { process.kill(-process.pid, 'SIGKILL'); } catch {} }, 2000);
    }
  }, 1000).unref();
  c.on('error', err => { console.log(`run-bounded: could not start "${wcmd}": ${err.message}`); process.exit(127); });
  c.on('exit', (code, signal) => process.exit(code ?? (signal ? 1 : 0)));
} else {
await main();
}

async function main() {
const sep = argv.indexOf('--');
if (sep === -1 || sep === argv.length - 1) {
  console.error('run-bounded: usage: --name <lock> --timeout <s> [--wait <s>] [--max-mb <MB>] -- <cmd> [args…]');
  process.exit(2);
}
const opt = {};
for (let i = 0; i < sep; i += 2) opt[argv[i].replace(/^--/, '')] = argv[i + 1];
const [cmd, ...args] = argv.slice(sep + 1);
const timeoutMs = Number(opt.timeout ?? 120) * 1000;
const waitMs = Number(opt.wait ?? 0) * 1000;
const maxMb = Number(opt['max-mb'] ?? 0);

// ---- lock: one run per (project, name) ----
const project = process.env.CLAUDE_PROJECT_DIR || process.cwd();
const lockRoot = path.join(os.tmpdir(), 'rn-workflow-locks');
fs.mkdirSync(lockRoot, { recursive: true });
const lockPath = path.join(lockRoot, `${createHash('sha1').update(project).digest('hex').slice(0, 12)}-${opt.name ?? 'run'}.lock`);
const alive = pid => {
  try {
    process.kill(pid, 0);
    return true;
  } catch (e) {
    return e.code === 'EPERM';
  }
};
// The lock is a symlink whose target is the owner's pid: creating it is one atomic step, so there is
// never a moment where the lock exists without its owner (a mkdir-then-write lock has that gap, and
// parallel edits hit it). 0 = no lock · -1 = something unreadable sits there (treated as stale).
const holderOf = p => {
  try {
    const pid = Number(fs.readlinkSync(p));
    return Number.isInteger(pid) && pid > 0 ? pid : -1;
  } catch (e) {
    return e.code === 'ENOENT' ? 0 : -1;
  }
};
// Remove the lock itself — fs.rmSync would follow the link to its (non-existent) target and quietly do nothing.
const removeLock = p => {
  try {
    if (fs.lstatSync(p).isDirectory()) fs.rmSync(p, { recursive: true, force: true }); // old-style folder lock
    else fs.unlinkSync(p);
  } catch {}
};
function tryLock() {
  try {
    fs.symlinkSync(String(process.pid), lockPath);
    return true;
  } catch (e) {
    if (e.code !== 'EEXIST') throw e;
  }
  const holder = holderOf(lockPath);
  if (holder === 0) return tryLock(); // released just now
  if (holder > 0 && alive(holder)) return false;
  // Stale lock from a run that was SIGKILLed. Move it aside first (atomic, so only one waiter wins),
  // then delete it only if it is still that dead run's lock — never a live run's.
  const aside = `${lockPath}.${process.pid}`;
  try {
    fs.renameSync(lockPath, aside);
  } catch {
    return false;
  }
  const moved = holderOf(aside);
  if (moved !== holder) {
    try {
      fs.symlinkSync(String(moved), lockPath); // a live run's lock — put it back
    } catch {}
  }
  removeLock(aside);
  return moved === holder ? tryLock() : false;
}
const release = () => {
  if (holderOf(lockPath) === process.pid) removeLock(lockPath);
};

const sleep = ms => new Promise(r => setTimeout(r, ms));
let locked = tryLock();
for (const start = Date.now(); !locked && Date.now() - start < waitMs; ) {
  await sleep(500);
  locked = tryLock();
}
if (!locked) process.exit(75);

// ---- run in its own process group ----
const env = { ...process.env };
if (maxMb > 0) env.NODE_OPTIONS = `${env.NODE_OPTIONS ?? ''} --max-old-space-size=${maxMb}`.trim();
const self = fileURLToPath(import.meta.url);
const child = spawn(process.execPath, [self, '--watchdog', String(process.pid), '--', cmd, ...args], {
  cwd: project,
  env,
  detached: true, // its own process group, so the whole tree can be killed at once
  stdio: ['ignore', 'pipe', 'pipe'],
});

const tail = [];
const keep = chunk => {
  tail.push(...chunk.toString().split('\n'));
  if (tail.length > 400) tail.splice(0, tail.length - 400);
};
child.stdout.on('data', keep);
child.stderr.on('data', keep);

let done = false;
const killTree = signal => {
  try {
    process.kill(-child.pid, signal);
  } catch {}
};
const stopAll = code => {
  if (done) return;
  done = true;
  killTree('SIGTERM');
  setTimeout(() => {
    killTree('SIGKILL');
    release();
    process.exit(code);
  }, 2000).unref();
};

const timer = setTimeout(() => {
  tail.push(`run-bounded: "${cmd}" ran longer than ${timeoutMs / 1000}s — stopped it and all its processes.`);
  process.stdout.write(tail.join('\n') + '\n');
  stopAll(124);
}, timeoutMs);

for (const sig of ['SIGTERM', 'SIGINT', 'SIGHUP']) process.on(sig, () => stopAll(143));

// If the hook that started us is killed, we are re-parented — take the tree down with us.
const parent = process.ppid;
const orphanCheck = setInterval(() => {
  if (process.ppid !== parent || !alive(parent)) stopAll(143);
}, 1000);

child.on('error', err => {
  clearTimeout(timer);
  clearInterval(orphanCheck);
  release();
  console.log(`run-bounded: could not start "${cmd}": ${err.message}`);
  process.exit(127);
});
child.on('exit', (code, signal) => {
  if (done) return;
  done = true;
  clearTimeout(timer);
  clearInterval(orphanCheck);
  killTree('SIGKILL'); // workers that outlived their parent
  release();
  process.stdout.write(tail.join('\n'));
  process.exit(code ?? (signal ? 1 : 0));
});
}
