/**
 * Every message the bot sends, in one place so wording can be reviewed and
 * translated without touching logic.
 */
export const Messages = {
  help:
    'This bot verifies phone numbers for HisabET.\n\n' +
    'Open the HisabET app and tap "Verify with Telegram" to start.',

  invalidLink:
    'This verification link is not valid any more.\n\n' +
    'Go back to HisabET and tap "Verify with Telegram" again.',

  expired:
    'This verification link has expired (links last 10 minutes).\n\n' +
    'Go back to HisabET and tap "Verify with Telegram" again.',

  otherAccount:
    'This link was already opened from a different Telegram account, so it cannot be used here.\n\n' +
    'Start again from the HisabET app on your own phone.',

  askForContact: (accountLabel: string) =>
    'HisabET phone verification\n\n' +
    `Account: ${accountLabel}\n\n` +
    'Tap "Share my phone number" below to confirm the number on this Telegram account.\n\n' +
    'If you did not just start this in the HisabET app, ignore this message.',

  notOwnContact:
    'For security, only your own number can be used.\n\n' +
    'Tap the "Share my phone number" button instead of sending a contact.',

  noActiveSession:
    'There is no verification waiting for this Telegram account.\n\n' +
    'Open HisabET and tap "Verify with Telegram" to start.',

  anonymousNumber:
    'Anonymous +888 numbers cannot be used to verify a HisabET account.\n\n' +
    'Use a Telegram account registered with your SIM number.',

  invalidNumber:
    'Telegram did not send a usable phone number. Please try again.',

  verified: (phone: string) =>
    `✅ ${phone} is verified.\n\nGo back to HisabET — it has already updated.`,

  phoneInUse:
    'This number is already linked to another HisabET account.\n\n' +
    'If it is yours, sign in to that account instead.',
} as const;
