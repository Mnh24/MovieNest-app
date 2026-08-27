# Protecting the TMDB key with a Firebase proxy

The TMDB API key must **not** ship inside the app binary — anything embedded in
an IPA/APK (including `--dart-define`) can be extracted. The professional fix is
a backend proxy: the app calls a Cloud Function, and the function holds the key
and forwards the request to TMDB. The key never leaves Google's servers.

```
App ──────────────► Cloud Function (holds TMDB key) ──► api.themoviedb.org
      App Check                Secret Manager
```

This repo ships the proxy in `functions/` and the app is already wired to use it
via `--dart-define=TMDB_PROXY_URL=...`. Follow the steps below once.

---

## 1. Create a Firebase project

1. Go to <https://console.firebase.google.com> and create a project (or reuse
   one). Note its **Project ID**.
2. Cloud Functions requires the **Blaze (pay-as-you-go)** plan. TMDB traffic is
   tiny and cache-friendly, so this stays within the free monthly allowance for
   a portfolio/TestFlight app — but a billing account must be attached.

Put your project id in `.firebaserc` (replace `your-firebase-project-id`).

## 2. Install tooling and dependencies

```bash
npm install -g firebase-tools
firebase login
cd functions && npm install && cd ..
```

## 3. Store the TMDB key as a secret

```bash
firebase functions:secrets:set TMDB_API_KEY
# paste your TMDB v3 API key when prompted
```

The key now lives in Google Secret Manager. It is never committed and never sent
to the app.

## 4. Deploy the proxy

```bash
firebase deploy --only functions
```

The deploy output prints the function URL, e.g.:

```
https://us-central1-<project-id>.cloudfunctions.net/tmdb
```

## 5. Point the app at the proxy

Copy `dart_defines.example.json` to `dart_defines.json` and set `TMDB_PROXY_URL`
to that function URL (leave `TMDB_API_KEY` empty). Then build:

```bash
flutter build ipa --release --dart-define-from-file=dart_defines.json
```

`dart_defines.json` is git-ignored. The proxy URL is not a secret, so you can
also just pass `--dart-define=TMDB_PROXY_URL=https://...` directly, or bake it
into your CI. Upload the resulting build to TestFlight as usual — the "TMDB not
configured" screen will be gone and no key ships in the binary.

---

## 6. (Recommended) Lock the proxy down with App Check

Steps 1–5 already achieve the goal: **the TMDB key is no longer in the app.**
App Check is the next hardening layer — it stops *other* apps/scripts from using
your proxy as a free TMDB relay by attesting that each request comes from a
genuine build of *this* app.

Enabling it is a two-part switch (do both, or neither):

**a) In the app**

1. Register the iOS/Android app in the Firebase console and run
   `flutterfire configure` (adds `firebase_options.dart`, `GoogleService-Info.plist`,
   `google-services.json`).
2. Add the packages:
   ```bash
   flutter pub add firebase_core firebase_app_check
   ```
3. In `lib/main.dart`, initialise Firebase + App Check and register the token
   provider the network layer already exposes:
   ```dart
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   await FirebaseAppCheck.instance.activate(
     appleProvider: AppleProvider.appAttest,      // DeviceCheck for older iOS
     androidProvider: AndroidProvider.playIntegrity,
   );
   DioClient.setAppCheckTokenProvider(
     () => FirebaseAppCheck.instance.getToken(),
   );
   ```
   `DioClient` already attaches the returned token as the `X-Firebase-AppCheck`
   header on every proxied request — no other client change is needed.

**b) In the function**

Set `ENFORCE_APP_CHECK = true` in `functions/index.js`, then
`firebase deploy --only functions`. The proxy now rejects any request without a
valid App Check token.

> Enable both sides together. Turning on enforcement in the function before the
> app sends tokens will reject every request.

For local development, use an App Check **debug token** so simulator/emulator
builds keep working — see
<https://firebase.google.com/docs/app-check/flutter/debug-provider>.

---

## Local development without a backend

You don't have to deploy anything to run the app locally. Pass a TMDB key
directly (this path talks to TMDB without the proxy and is fine for dev only):

```bash
flutter run --dart-define=TMDB_API_KEY=your_key
```

## How the app chooses

`lib/core/constants/app_config.dart`:

- `TMDB_PROXY_URL` set → all TMDB calls go through the proxy (no key in app).
- else `TMDB_API_KEY` set → app talks to TMDB directly (dev only).
- neither → the "TMDB not configured" screen explains what to pass.
