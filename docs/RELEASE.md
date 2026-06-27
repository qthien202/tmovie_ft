# Release & OTA (Android)

Mobile and TV update over-the-air by reading this repo's **latest GitHub Release**
and downloading the APK whose name matches the app (`mobile` / `tv`). One release
serves both apps.

## Cut a release

Either:

- **Tag push** — `git tag v1.2.3 && git push origin v1.2.3`
- **Manual** — Actions tab → *Release APK (OTA)* → Run workflow → type `1.2.3`

The `.github/workflows/release.yml` workflow then:
1. builds `apps/mobile` + `apps/tv` release APKs (versionName forced to the tag),
2. attaches `tmovie-tv-v1.2.3.apk` and `tmovie-mobile-v1.2.3.apk`,
3. publishes a Release marked *latest* with **auto-generated release notes**
   (commits/PRs since the previous tag).

An installed app shows the update dialog when its version < the release tag.

## Signing (required for real OTA update-installs)

Android only allows an update-install when the new APK is signed with the **same
key** as the installed one. Generate one release keystore and add it as repo
secrets, otherwise the workflow falls back to the debug key (fresh installs work,
updates over an existing install fail with a signature error).

```bash
keytool -genkey -v -keystore release.keystore -alias tmovie \
  -keyalg RSA -keysize 2048 -validity 10000
base64 -i release.keystore | pbcopy   # copy for the secret below
```

Repo → Settings → Secrets and variables → Actions:

| Secret | Value |
|---|---|
| `KEYSTORE_BASE64` | base64 of `release.keystore` |
| `KEYSTORE_PASSWORD` | store password |
| `KEY_ALIAS` | `tmovie` |
| `KEY_PASSWORD` | key password |

Locally, the same signing kicks in if you create `apps/<app>/android/key.properties`
(gitignored) with `storeFile/storePassword/keyAlias/keyPassword`.

## Notes
- Release notes come from the GitHub Release body; the workflow generates them
  automatically. Edit the release afterwards to customize.
- iOS does not use this flow — it updates via Shorebird (`shorebird patch ios`).
