import { cert, getApps, initializeApp, type App } from 'firebase-admin/app';

/**
 * Initialises firebase-admin once per process, on any host.
 *
 * - On Cloud Functions, Google provides credentials automatically.
 * - Anywhere else (Netlify, a VPS, …) set `FIREBASE_SERVICE_ACCOUNT` to the
 *   service-account JSON from Firebase Console → Project settings →
 *   Service accounts → Generate new private key. That key is full admin
 *   access to the project: keep it only in the host's secret settings.
 *
 * firebase-admin works on the free Spark plan; only Cloud Functions need Blaze.
 */
export function adminApp(): App {
  const existing = getApps()[0];
  if (existing) return existing;

  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!raw) return initializeApp();

  let parsed: { project_id?: string; client_email?: string; private_key?: string };
  try {
    parsed = JSON.parse(raw);
  } catch {
    // Never echo the value: it is a private key.
    throw new Error('FIREBASE_SERVICE_ACCOUNT is not valid JSON.');
  }
  if (!parsed.project_id || !parsed.client_email || !parsed.private_key) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT is missing project_id, client_email or private_key.');
  }
  return initializeApp({
    credential: cert({
      projectId: parsed.project_id,
      clientEmail: parsed.client_email,
      // Some dashboards store the key with literal "\n" sequences.
      privateKey: parsed.private_key.replace(/\\n/g, '\n'),
    }),
    projectId: parsed.project_id,
  });
}

/** Reads a required setting, failing loudly at startup rather than mid-request. */
export function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required environment variable ${name}.`);
  return value;
}
