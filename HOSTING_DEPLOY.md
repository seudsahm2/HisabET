# Deploy Legal Pages to Firebase Hosting

This project already includes:

- `public/index.html`
- `public/privacy.html`
- `public/terms.html`
- `firebase.json`
- `.firebaserc` (default project: `hisabet`)

## 1. Install Firebase CLI (one time)

```powershell
npm install -g firebase-tools
```

## 2. Login to Firebase

```powershell
firebase login
```

## 3. Verify selected project

```powershell
firebase use
```

Expected output should include `hisabet` as default.

## 4. Deploy hosting

```powershell
firebase deploy --only hosting
```

## 5. Verify URLs

- Home: `https://hisabet.firebaseapp.com/`
- Privacy: `https://hisabet.firebaseapp.com/privacy`
- Terms: `https://hisabet.firebaseapp.com/terms`

## 6. Paste these into OAuth consent screen

- Application home page: `https://hisabet.firebaseapp.com/`
- Application privacy policy link: `https://hisabet.firebaseapp.com/privacy`
- Application Terms of Service link: `https://hisabet.firebaseapp.com/terms`

## Troubleshooting

- If project mismatch occurs:

```powershell
firebase use hisabet
firebase deploy --only hosting
```

- If command not found, restart terminal after npm install.
- If deployment permission error appears, ensure you are logged into the same Google account that owns the Firebase project.
