/**
 * Stops Firebase emulator processes left behind by a previous run.
 *
 * On Windows, `firebase emulators:exec` sometimes exits without killing the
 * Firestore emulator's Java process, so the next run fails with "port taken".
 * This runs before the emulator tests (npm `pretest:emulator`).
 *
 * Only processes whose command line is a Firebase emulator jar are touched —
 * never anything else that happens to use the same port.
 */
import { execFileSync } from 'node:child_process';

const MARKER = /cloud-firestore-emulator|firebase[\/]emulators/i;

function run(cmd, args) {
  try {
    return execFileSync(cmd, args, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] });
  } catch {
    return '';
  }
}

let stopped = 0;

if (process.platform === 'win32') {
  const out = run('powershell.exe', [
    '-NoProfile',
    '-Command',
    "Get-CimInstance Win32_Process -Filter \"Name='java.exe'\" | ForEach-Object { \"$($_.ProcessId)`t$($_.CommandLine)\" }",
  ]);
  for (const line of out.split(/\r?\n/)) {
    const [pid, cmdline = ''] = line.split('\t');
    if (pid && MARKER.test(cmdline)) {
      run('taskkill', ['/PID', pid.trim(), '/F']);
      stopped++;
    }
  }
} else {
  const out = run('ps', ['-eo', 'pid=,args=']);
  for (const line of out.split('\n')) {
    const match = line.trim().match(/^(\d+)\s+(.*)$/);
    if (match && /java/.test(match[2]) && MARKER.test(match[2])) {
      try {
        process.kill(Number(match[1]));
        stopped++;
      } catch {
        /* already gone */
      }
    }
  }
}

if (stopped > 0) console.log(`Stopped ${stopped} stale emulator process(es).`);
