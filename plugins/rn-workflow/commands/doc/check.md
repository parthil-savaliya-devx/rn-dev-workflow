---
description: 'Check that all feature docs in docs/modules follow the format — sections, IDs, who/when on decisions, index in sync, links. Reports problems; fixes only after you confirm.'
---

Use the **`doc` skill** and follow its **/doc:check** flow.

1. Run the mechanical check and show its output:

   ```bash
   node "${CLAUDE_PLUGIN_ROOT}/skills/doc/scripts/doc-check.mjs" .
   ```

2. Then review what the script can't check: decisions with no real "why", Shipped requirements with no proof, answers that contradict each other, specs that no longer match the code.
3. **Report every problem, then ask before fixing anything** — one question at a time. Never change a recorded answer or decision without the developer's confirmation.
