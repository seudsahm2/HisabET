import { spawnSync } from 'node:child_process';
import { describe, expect, it } from 'vitest';

/**
 * Netlify loads firebase-admin with classic `require()`, on a Node version
 * that cannot `require()` an ES module. firebase-admin 14 pulls in
 * `jwks-rsa` 4 → `jose` 6 (ESM-only) and crashed every function with
 * ERR_REQUIRE_ESM in production while passing locally on Node 22.12+.
 *
 * `--no-experimental-require-module` gives this machine the same limitation,
 * so an upgrade that breaks the production runtime fails here first.
 */
describe('production runtime compatibility', () => {
  it.each(['firebase-admin/app', 'firebase-admin/auth', 'firebase-admin/firestore'])(
    '%s loads with classic require()',
    (moduleName) => {
      const result = spawnSync(
        process.execPath,
        ['--no-experimental-require-module', '-e', `require(${JSON.stringify(moduleName)})`],
        { cwd: process.cwd(), encoding: 'utf8' },
      );
      expect(result.stderr).not.toContain('ERR_REQUIRE_ESM');
      expect(result.status).toBe(0);
    },
  );
});
