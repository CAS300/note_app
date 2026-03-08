# Packaging and Release Guide

This document outlines how to package and release the Note App for our supported desktop platforms. It covers the release process, required placeholders, and data safety instructions.

## A) Overview

The Note App currently supports two primary platforms for packaging:

1. **Windows**: Packaged as an `MSIX` installer file. This provides clean installation, updates, and uninstallation.
2. **CachyOS / Arch Linux**: Packaged as a standard `.pkg.tar.zst` file via a `PKGBUILD` script, suitable for pacman/makepkg.

Artifacts produced:

- `build/windows/x64/runner/Release/NoteApp.msix`
- `build/note-app-[version]-[pkgrel]-x86_64.pkg.tar.zst`

## B) Windows (MSIX) Packaging

### Prerequisites

- Install the Flutter SDK and Windows desktop build tools (Visual Studio C++ Workload).
- Verify the project has `msix: ^3.7.1` in `dev_dependencies` inside `pubspec.yaml`.

### Build Commands

We provide a PowerShell script to automate the build:

```powershell
.\scripts\build_windows_package.ps1
```

If running manually:

1. `flutter clean`
2. `flutter pub get`
3. `flutter build windows`
4. `dart run msix:create`

### Configuration and Placeholders

MSIX settings live inside `pubspec.yaml` under the `msix_config` block.
When building a production release, you must maintain **stable identity variables** so Windows sees it as the same application (allowing seamless upgrades):

- `identity_name`: Example `YourPublisher.NoteApp`
- `publisher_display_name`: Example `MyPublisher`

These are currently **PLACEHOLDERS**. Change them to your real publisher identity for production. Do NOT change them once distributed, otherwise updates will fail.

### Handling Certificates (Signing)

To distribute outside the Microsoft Store without warnings, the `.msix` must be signed with a trusted certificate (e.g. `certificate.pfx`).
**DO NOT commit this file or its password to Git.**

- Store the certificate locally securely outside the repo.
- Pass the password via an environment variable or typed manually during the CI/build step using:
  ```bash
  dart run msix:create --certificate-path C:\path\to\cert.pfx --certificate-password YOUR_PASSWORD
  ```

### Troubleshooting: 0x800B010A (Untrusted Certificate)

Since this is a local build, the `.msix` is signed with a temporary self-signed certificate. Windows doesn't trust it by default. To install anyway:

1. **Right-click** the `note_app.msix` file -> **Properties**.
2. Go to the **Digital Signatures** tab.
3. Select the signature in the list and click **Details**.
4. Click **View Certificate**.
5. Click **Install Certificate...**
6. Select **Local Machine** and click Next.
7. Select **Place all certificates in the following store** and click **Browse**.
8. Select **Trusted Root Certification Authorities** and click OK -> Next -> Finish.
9. You can now run the `.msix` file to install the app.

## C) CachyOS / Arch Linux Packaging

### Prerequisites

- `makepkg` toolchain installed (base-devel).
- Flutter SDK installed and in your `$PATH`.

### Build Commands

Run the provided Bash helper script from the root of the project:

```bash
./scripts/build_linux_package.sh
```

### Usage

This script copies the project into a temporary build folder, calls `makepkg`, and places the final `.pkg.tar.zst` inside the `/build` directory.

- **Desktop Entry**: Included via `packaging/linux/note-app.desktop`.
- **Icon**: Automatically copies the generated `app_icon.png` into `/usr/share/pixmaps`.

To install:

```bash
sudo pacman -U build/note-app*.pkg.tar.zst
```

## D) Release Checklist

Before issuing a new release, follow these steps:

1. **Version Bump**: Update `version: X.Y.Z+N` inside `pubspec.yaml`.
2. **Rebuild Icons**: If you changed `assets/icons/app_icon.png`, run:
   - `flutter pub run flutter_launcher_icons:main`
3. **Verify Export**: Launch the app in debug and ensure the local drive export path works correctly.
4. **Build Windows Release**: Execute `.\scripts\build_windows_package.ps1`
5. **Build Linux Release**: Execute `./scripts/build_linux_package.sh`
6. **Test Clean Install**: Ensure a fresh Windows/Linux install works correctly.
7. **Test Upgrade Install**: Install the new version over the old version to ensure settings and UI load properly.
8. **Verify Data Safety**: Ensure user records remain intact (see below).

## E) Data Safety Notes

- **User Data Location**: The user's active databases and `.notes_workspace.json` manifest are kept in a separate, user-selected folder outside the application's installation directory.
- **Upgrades**: Updating via MSIX or pacman will **not** overwrite the user data directory. However, bugs in schema migrations or path resolutions can cause access issues.
- **Recommendation**: It is highly recommended to advise users to utilize the in-app "Yedeği Dışa Aktar" (Export Backup) feature before executing major version upgrades, to prevent data loss in extreme scenarios.

## F) Secrets, Keys, and Signing Placeholders

- **Never** place real signing keys or passwords directly inside this repository.
- Placeholders in `pubspec.yaml` (e.g. `# PLACEHOLDER`) indicate values that must be replaced locally.
- When utilizing CI/CD (GitHub Actions, GitLab CI), utilize secret environment variables to inject the password and inject the `.pfx` file dynamically into the runner environment.

## G) Current Limitations

- **No Auto-Update**: The application currently has no daemon to auto-update itself; upgrades are done manually via MSIX installer launches or system package managers.
- **Local Export Only**: The "Yedeği Dışa Aktar" function only copies local files to another folder, without network-level syncing, parsing, merging, or remote cloud functionality.
- **Offline-First**: The application interacts strictly with local SQLite files without hitting backend APIs. This makes the UI rapid but limits cross-device real-time sync capabilities.
