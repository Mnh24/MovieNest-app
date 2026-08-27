# Auto-deploy to TestFlight from GitHub Actions

The `Deploy iOS to TestFlight` workflow (`.github/workflows/deploy-ios.yml`)
builds a signed release IPA and uploads it to App Store Connect on every push
to `main`. Once the build finishes processing, it appears in **TestFlight**.

You set this up **once** by adding the secrets below. Apple's code signing is
the fiddly part — take it slowly and it's a one-time cost.

> Requires a paid **Apple Developer Program** membership and the app record
> already created in App Store Connect for bundle id **`com.m.mvieApp`**
> (team `WAC85HB79P`).

---

## Required GitHub secrets

Add these under **GitHub repo → Settings → Secrets and variables → Actions →
New repository secret**.

| Secret | What it is |
| --- | --- |
| `IOS_DIST_CERT_P12_BASE64` | Your **Apple Distribution** certificate + private key, exported as `.p12`, base64-encoded. |
| `IOS_DIST_CERT_PASSWORD` | The password you set when exporting the `.p12`. |
| `IOS_KEYCHAIN_PASSWORD` | Any random string — used to create a temporary keychain on the runner. |
| `IOS_PROVISION_PROFILE_BASE64` | An **App Store** provisioning profile for `com.m.mvieApp`, base64-encoded. |
| `APPSTORE_API_KEY_ID` | App Store Connect API key **Key ID**. |
| `APPSTORE_API_ISSUER_ID` | App Store Connect API **Issuer ID**. |
| `APPSTORE_API_PRIVATE_KEY` | Contents of the API key `.p8` file (paste the whole file). |
| `TMDB_PROXY_URL` | Your deployed Cloud Functions proxy URL (see SETUP_FIREBASE.md). |

---

## How to get each one

### 1. Distribution certificate (`IOS_DIST_CERT_P12_BASE64` + password)

Easiest from a Mac with Xcode:

1. Xcode → **Settings → Accounts → Manage Certificates → +
   → Apple Distribution**. (Or create one at
   <https://developer.apple.com/account/resources/certificates>.)
2. Open **Keychain Access**, find the *Apple Distribution* certificate, expand
   it so its private key shows, select **both**, right-click → **Export 2 items**
   → save as `.p12` and set a password → that password is
   `IOS_DIST_CERT_PASSWORD`.
3. Base64-encode it:
   ```bash
   base64 -i dist.p12 | pbcopy   # macOS – now paste as IOS_DIST_CERT_P12_BASE64
   ```

### 2. Provisioning profile (`IOS_PROVISION_PROFILE_BASE64`)

1. At <https://developer.apple.com/account/resources/profiles> → **+** →
   **App Store** distribution → pick App ID `com.m.mvieApp` → pick the
   distribution certificate above → download the `.mobileprovision`.
2. Base64-encode it:
   ```bash
   base64 -i movienest.mobileprovision | pbcopy
   ```
   (The workflow reads the profile's name and UUID out of the file itself, so
   you don't need to store those separately.)

### 3. App Store Connect API key (`APPSTORE_API_*`)

1. <https://appstoreconnect.apple.com> → **Users and Access → Integrations →
   App Store Connect API → +**. Give it the **App Manager** role.
2. Copy the **Issuer ID** (`APPSTORE_API_ISSUER_ID`) and the **Key ID**
   (`APPSTORE_API_KEY_ID`).
3. Download the `AuthKey_XXXX.p8` **once** (Apple only lets you download it
   one time). Paste its full contents as `APPSTORE_API_PRIVATE_KEY`.

### 4. Proxy URL (`TMDB_PROXY_URL`)

The Cloud Functions URL from `SETUP_FIREBASE.md` step 4, e.g.
`https://us-central1-<project>.cloudfunctions.net/tmdb`.

---

## How it works

- Trigger: push to `main` (or run manually via **Actions → Deploy iOS to
  TestFlight → Run workflow**).
- The build number is set to the GitHub run number
  (`--build-number=${{ github.run_number }}`) so every upload is unique —
  TestFlight rejects duplicate build numbers.
- The **version name** (`1.0.0`) comes from `pubspec.yaml`. Bump it there when
  you want a new version rather than just a new build.
- `--dart-define=TMDB_PROXY_URL=...` means the shipped app talks to your proxy,
  so **no TMDB key is in the binary**.

## Notes & tuning

- **Deploy on tags instead of every push:** change the `on:` trigger to
  ```yaml
  on:
    push:
      tags: ["v*"]
  ```
  and push a tag (`git tag v1.0.1 && git push --tags`) to release.
- **Processing time:** after upload, App Store Connect takes a few minutes to
  process the build before it shows in TestFlight. You may also need to answer
  the export-compliance question once (set `ITSAppUsesNonExemptEncryption` in
  `ios/Runner/Info.plist` to `false` to skip it if you use no custom crypto).
- **First upload** sometimes must be done from Xcode/Transporter to initialise
  the app record; subsequent CI uploads then work.
- Signing errors almost always mean the certificate, provisioning profile, and
  App ID don't all match `com.m.mvieApp` + team `WAC85HB79P`.
