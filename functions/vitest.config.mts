import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    // Emulator suites share one Firestore instance; run files serially.
    fileParallelism: false,
    testTimeout: 20000,
  },
});
