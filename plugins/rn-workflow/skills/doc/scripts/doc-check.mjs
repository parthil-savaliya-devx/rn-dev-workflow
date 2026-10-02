#!/usr/bin/env node
// doc-check — verifies docs/modules/<module>/<feature>/{spec,build}.md follow the doc skill's format.
// Usage: node doc-check.mjs [project-root]      exit 0 = clean (or no docs/modules), 1 = problems
// Plain Node, no dependencies, so it runs in any project. Used by /doc:check and the Stop hook.
import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(process.argv[2] ?? '.');
const modulesDir = path.join(root, 'docs', 'modules');
const problems = [];
const rel = p => path.relative(root, p);
const add = (file, line, msg) => problems.push(`${rel(file)}${line ? `:${line}` : ''} — ${msg}`);

if (!fs.existsSync(modulesDir)) {
  console.log('doc-check: no docs/modules — nothing to check');
  process.exit(0);
}

const STATUSES = ['Draft', 'Approved', 'Building', 'Shipped', 'Retired'];
const APPROVED_OR_LATER = ['Approved', 'Building', 'Shipped', 'Retired'];
const norm = s => s.toLowerCase().replace(/[’`]/g, "'").replace(/\s+/g, ' ').trim();
const isBlank = v =>
  v === '' || /^(—|–|-|tbd|todo|\?|n\/a|none)$/i.test(v) || /^<.*>$/.test(v) || /YYYY-MM-DD/.test(v);
const isDate = v => /^\d{4}-\d{2}-\d{2}$/.test(v) && !Number.isNaN(Date.parse(v));
const linkText = v => v.replace(/^\[([^\]]*)\]\([^)]*\)$/, '$1').replace(/`/g, '').trim();
const cells = line => line.trim().replace(/^\|/, '').replace(/\|$/, '').split(/(?<!\\)\|/).map(c => c.trim());
const dirs = d => fs.readdirSync(d, { withFileTypes: true }).filter(e => e.isDirectory() && !e.name.startsWith('.') && !e.name.startsWith('_')).map(e => e.name);

function readLines(file) {
  return fs.readFileSync(file, 'utf8').split('\n');
}

// Returns { header, rows: [{ cells, line }] } for the first table between [from, to).
function tableIn(lines, from, to) {
  let i = from;
  while (i < to && !lines[i].trim().startsWith('|')) i++;
  if (i >= to) return null;
  const header = cells(lines[i]);
  const rows = [];
  let j = i + 2; // skip the separator row
  while (j < to && lines[j].trim().startsWith('|')) {
    rows.push({ cells: cells(lines[j]), line: j + 1 });
    j++;
  }
  return { header, headerLine: i + 1, rows };
}

function checkHeader(file, table, expected, label) {
  if (!table) return add(file, 0, `${label}: table missing`), false;
  if (table.header.length !== expected.length || table.header.some((h, k) => norm(h) !== norm(expected[k]))) {
    add(file, table.headerLine, `${label}: columns must be | ${expected.join(' | ')} |`);
    return false;
  }
  for (const r of table.rows) {
    if (r.cells.length !== expected.length) add(file, r.line, `${label}: row has ${r.cells.length} cells, expected ${expected.length}`);
  }
  return true;
}

function sections(file, lines, expected) {
  const found = {};
  let last = -1;
  for (const title of expected) {
    const idx = lines.findIndex(l => norm(l).startsWith(norm(`## ${title}`)));
    if (idx === -1) add(file, 0, `missing section "## ${title}"`);
    else {
      if (idx < last) add(file, idx + 1, `section "## ${title}" is out of order`);
      last = Math.max(last, idx);
      found[title] = idx;
    }
  }
  const starts = Object.values(found).sort((a, b) => a - b);
  const end = title => {
    const s = found[title];
    const next = starts.find(x => x > s);
    return next ?? lines.length;
  };
  return { found, end };
}

function checkIds(file, rows, prefix, label) {
  const seen = new Set();
  for (const r of rows) {
    const id = r.cells[0];
    if (!new RegExp(`^${prefix}\\d+$`).test(id)) add(file, r.line, `${label}: id "${id}" must look like ${prefix}1, ${prefix}2…`);
    else if (seen.has(id)) add(file, r.line, `${label}: id ${id} is used twice`);
    seen.add(id);
  }
  return seen;
}

function checkRefs(file, row, value, known, label) {
  for (const token of value.split(/[,\s]+/)) {
    if (/^[QDREB]\d+$/.test(token) && !known.has(token)) add(file, row.line, `${label}: "From" points at ${token}, which doesn't exist`);
  }
}

function need(file, row, value, what, label) {
  if (isBlank(value)) add(file, row.line, `${label}: ${what} is empty`);
}

function checkSpec(file) {
  const lines = readLines(file);
  if (!/^# .+ — Spec\s*$/.test(lines[0] ?? '')) add(file, 1, 'first line must be "# <Feature name> — Spec"');

  const head = tableIn(lines, 0, lines.findIndex(l => l.startsWith('## ')) === -1 ? lines.length : lines.findIndex(l => l.startsWith('## ')));
  let status = null;
  let approvedBy = '';
  if (checkHeader(file, head, ['Status', 'Owner', 'Approved by', 'Created', 'Updated'], 'header')) {
    const row = head.rows[0];
    if (!row) add(file, head.headerLine, 'header: row missing');
    else {
      [status, , approvedBy] = row.cells;
      const [, owner, , created, updated] = row.cells;
      if (!STATUSES.includes(status)) add(file, row.line, `header: status "${status}" must be one of ${STATUSES.join(' / ')}`);
      need(file, row, owner, 'Owner', 'header');
      if (!isDate(created)) add(file, row.line, 'header: Created must be a date (YYYY-MM-DD)');
      if (!isDate(updated)) add(file, row.line, 'header: Updated must be a date (YYYY-MM-DD)');
      if (APPROVED_OR_LATER.includes(status) && isBlank(approvedBy)) add(file, row.line, `header: status is ${status} but "Approved by" is empty`);
    }
  }

  const titles = ['1. Summary', '2. Questions & answers', '3. Decisions', '4. Requirements', '5. Edge cases', '6. Bugs fixed', '7. Changelog'];
  const { found, end } = sections(file, lines, titles);

  if (found['1. Summary'] !== undefined) {
    const body = lines.slice(found['1. Summary'] + 1, end('1. Summary')).join('\n');
    for (const field of ['Goal', 'In scope', 'Out of scope']) {
      const m = body.match(new RegExp(`^${field}:\\s*(.*)$`, 'm'));
      if (!m || isBlank(m[1].trim())) add(file, found['1. Summary'] + 1, `Summary: "${field}:" is missing or empty`);
    }
  }

  const tbl = (title, expected, label) => {
    if (found[title] === undefined) return null;
    const t = tableIn(lines, found[title] + 1, end(title));
    return checkHeader(file, t, expected, label) ? t : null;
  };

  const q = tbl('2. Questions & answers', ['#', 'Question', 'Options given', "Answer (dev's words)", 'By', 'Date'], 'Questions');
  const d = tbl('3. Decisions', ['#', 'Decision', 'Why', 'Decided by', 'Approved by', 'Date', 'From'], 'Decisions');
  const r = tbl('4. Requirements', ['#', 'Requirement', 'Proof (test / screenshot)'], 'Requirements');
  const e = tbl('5. Edge cases', ['#', 'Situation', 'What should happen', 'Proof', 'From'], 'Edge cases');
  const b = tbl('6. Bugs fixed', ['#', 'What broke', 'Root cause', 'Fix', 'Decided by', 'Approved by', 'Date', 'PR'], 'Bugs fixed');
  const c = tbl('7. Changelog', ['Date', 'Change', 'By', 'Ref'], 'Changelog');

  const known = new Set([
    ...(q ? checkIds(file, q.rows, 'Q', 'Questions') : []),
    ...(d ? checkIds(file, d.rows, 'D', 'Decisions') : []),
    ...(r ? checkIds(file, r.rows, 'R', 'Requirements') : []),
    ...(e ? checkIds(file, e.rows, 'E', 'Edge cases') : []),
    ...(b ? checkIds(file, b.rows, 'B', 'Bugs fixed') : []),
  ]);

  for (const row of q?.rows ?? []) {
    const [, question, options, answer, by, date] = row.cells;
    need(file, row, question, 'Question', 'Questions');
    need(file, row, options, 'Options given', 'Questions');
    need(file, row, answer, 'Answer', 'Questions');
    need(file, row, by, 'By', 'Questions');
    if (!isDate(date ?? '')) add(file, row.line, 'Questions: Date must be YYYY-MM-DD');
  }
  for (const row of d?.rows ?? []) {
    const [, decision, why, decidedBy, approved, date, from] = row.cells;
    need(file, row, decision, 'Decision', 'Decisions');
    need(file, row, why, 'Why', 'Decisions');
    need(file, row, decidedBy, 'Decided by', 'Decisions');
    need(file, row, approved, 'Approved by', 'Decisions');
    if (!isDate(date ?? '')) add(file, row.line, 'Decisions: Date must be YYYY-MM-DD');
    checkRefs(file, row, from ?? '', known, 'Decisions');
  }
  for (const row of r?.rows ?? []) {
    const [, requirement, proof] = row.cells;
    need(file, row, requirement, 'Requirement', 'Requirements');
    if (status === 'Shipped' && isBlank(proof ?? '')) add(file, row.line, 'Requirements: status is Shipped but Proof is empty');
  }
  for (const row of e?.rows ?? []) {
    const [, situation, expected, proof, from] = row.cells;
    need(file, row, situation, 'Situation', 'Edge cases');
    need(file, row, expected, 'What should happen', 'Edge cases');
    if (status === 'Shipped' && isBlank(proof ?? '')) add(file, row.line, 'Edge cases: status is Shipped but Proof is empty');
    checkRefs(file, row, from ?? '', known, 'Edge cases');
  }
  for (const row of b?.rows ?? []) {
    const [, broke, cause, fix, decidedBy, approved, date] = row.cells;
    need(file, row, broke, 'What broke', 'Bugs fixed');
    need(file, row, cause, 'Root cause', 'Bugs fixed');
    need(file, row, fix, 'Fix', 'Bugs fixed');
    need(file, row, decidedBy, 'Decided by', 'Bugs fixed');
    need(file, row, approved, 'Approved by', 'Bugs fixed');
    if (!isDate(date ?? '')) add(file, row.line, 'Bugs fixed: Date must be YYYY-MM-DD');
  }
  for (const row of c?.rows ?? []) {
    const [date, change, by] = row.cells;
    if (!isDate(date ?? '')) add(file, row.line, 'Changelog: Date must be YYYY-MM-DD');
    need(file, row, change, 'Change', 'Changelog');
    need(file, row, by, 'By', 'Changelog');
  }
  if (APPROVED_OR_LATER.includes(status) && r && r.rows.length === 0) add(file, found['4. Requirements'] + 1, `status is ${status} but there are no requirements`);
  return status;
}

function checkBuild(file) {
  const lines = readLines(file);
  if (!/^# .+ — Build\s*$/.test(lines[0] ?? '')) add(file, 1, 'first line must be "# <Feature name> — Build"');
  if (!lines.some(l => l.trim() === 'Spec: ./spec.md')) add(file, 0, 'missing the line "Spec: ./spec.md"');
  const titles = ['1. Design values', '2. Files', '3. testIDs', '4. Plan', '5. Verification'];
  const { found, end } = sections(file, lines, titles);
  const tables = {
    '1. Design values': ['Element', 'Font', 'Colour → token', 'Spacing', 'Figma node'],
    '2. Files': ['File', 'What it does'],
    '3. testIDs': ['Element', 'testID'],
    '5. Verification': ['Check', 'Result', 'Evidence'],
  };
  for (const [title, expected] of Object.entries(tables)) {
    if (found[title] !== undefined) checkHeader(file, tableIn(lines, found[title] + 1, end(title)), expected, title);
  }
}

function indexRows(file, expected, label) {
  const lines = readLines(file);
  const t = tableIn(lines, 0, lines.length);
  return checkHeader(file, t, expected, label) ? t.rows : [];
}

// ---- walk ----
const indexFile = path.join(modulesDir, 'README.md');
const indexed = new Map(); // "module/feature" -> { status, line }
if (!fs.existsSync(indexFile)) add(indexFile, 0, 'missing — the index of every feature');
else {
  for (const row of indexRows(indexFile, ['Module', 'Feature', 'Status', 'Owner', 'Updated'], 'index')) {
    const key = `${linkText(row.cells[0])}/${linkText(row.cells[1])}`;
    if (indexed.has(key)) add(indexFile, row.line, `index: ${key} is listed twice`);
    indexed.set(key, { status: row.cells[2], line: row.line });
  }
}

const actual = new Map(); // "module/feature" -> status
for (const mod of dirs(modulesDir)) {
  const modDir = path.join(modulesDir, mod);
  const modReadme = path.join(modDir, 'README.md');
  const listed = new Map();
  if (!fs.existsSync(modReadme)) add(modReadme, 0, 'missing — every module needs a README with its feature list');
  else {
    for (const row of indexRows(modReadme, ['Feature', 'Status', 'Owner', 'Updated'], 'module features')) {
      listed.set(linkText(row.cells[0]), { status: row.cells[1], line: row.line });
    }
  }
  for (const feat of dirs(modDir)) {
    const featDir = path.join(modDir, feat);
    const spec = path.join(featDir, 'spec.md');
    const build = path.join(featDir, 'build.md');
    let status = null;
    if (!fs.existsSync(spec)) add(spec, 0, 'missing — every feature needs spec.md');
    else status = checkSpec(spec);
    if (!fs.existsSync(build)) add(build, 0, 'missing — every feature needs build.md');
    else checkBuild(build);
    for (const extra of fs.readdirSync(featDir).filter(f => !['spec.md', 'build.md'].includes(f) && !f.startsWith('.'))) {
      add(path.join(featDir, extra), 0, 'only spec.md and build.md belong in a feature folder');
    }
    const key = `${mod}/${feat}`;
    actual.set(key, status);
    const inModule = listed.get(feat);
    if (fs.existsSync(modReadme) && !inModule) add(modReadme, 0, `feature "${feat}" is not in this module's feature list`);
    else if (inModule && status && inModule.status !== status) add(modReadme, inModule.line, `${feat}: status says ${inModule.status}, spec says ${status}`);
    listed.delete(feat);
  }
  for (const [feat, { line }] of listed) add(modReadme, line, `lists "${feat}", but docs/modules/${mod}/${feat}/ doesn't exist`);
}
for (const [key, status] of actual) {
  const row = indexed.get(key);
  if (fs.existsSync(indexFile) && !row) add(indexFile, 0, `${key} is not in the index`);
  else if (row && status && row.status !== status) add(indexFile, row.line, `${key}: status says ${row.status}, spec says ${status}`);
}
for (const [key, { line }] of indexed) if (!actual.has(key)) add(indexFile, line, `lists ${key}, but that folder doesn't exist`);

// ---- local links ----
function walkMd(d) {
  for (const e of fs.readdirSync(d, { withFileTypes: true })) {
    const p = path.join(d, e.name);
    if (e.isDirectory()) walkMd(p);
    else if (e.name.endsWith('.md')) {
      readLines(p).forEach((line, i) => {
        for (const m of line.matchAll(/\]\(([^)\s]+)\)/g)) {
          const target = m[1];
          if (/^(https?:|mailto:|tel:|#)/.test(target)) continue;
          const file = target.split('#')[0];
          if (file && !fs.existsSync(path.resolve(path.dirname(p), file))) add(p, i + 1, `broken link → ${target}`);
        }
      });
    }
  }
}
walkMd(modulesDir);

if (problems.length) {
  console.error(`doc-check: ${problems.length} problem(s) in docs/modules\n`);
  for (const p of problems) console.error(`  • ${p}`);
  process.exit(1);
}
console.log(`doc-check: docs/modules is clean (${actual.size} feature${actual.size === 1 ? '' : 's'})`);
