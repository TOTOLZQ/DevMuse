# DevMuse

English | [简体中文](README.md)

![Build unsigned IPA](https://github.com/TOTOLZQ/DevMuse/actions/workflows/build-ipa.yml/badge.svg)

A local-first iOS development assistant. Notes, snippets, prompts, conversations and sandbox files all stay on the device. No accounts, no network calls.

- Minimum OS: iOS 16
- Architecture: arm64 (iPhone / iPad)
- Interface language: Simplified Chinese

## Features

| Module | Details |
| --- | --- |
| Agent | Chat-style development copilot with streaming typewriter animation, quick prompts and a local response engine covering reviews, refactors, tests, commit messages, release checklists and explanations |
| Canvas | Infinite note canvas with drag, zoom, inertia panning and inline editing |
| Sandbox | In-app Linux-style virtual terminal backed by its own virtual file system and a dozen common commands |
| Vault | Code snippet library with language and tag filtering, plus one-tap copy |
| Prompts | Prompt lab grouped by category, with create, edit, copy and delete |
| Settings | Appearance (warm paper / ink / follow system), library stats and starter-content reset |

## Linux sandbox

The sandbox is a virtual terminal that runs in app memory. It does not load a real kernel or execute system binaries, and it never touches real files. It ships with its own directory tree (`/home/muse`, `/etc`, `/var/log`, `/usr/bin`). Every command only mutates this virtual file system, which resets when the app relaunches.

Supported commands:

| Command | Description |
| --- | --- |
| `ls [-l|-a] <path>` | List directory contents |
| `cd <path>` | Change directory, supports `~`, `..` and absolute paths |
| `pwd` | Print the working directory |
| `cat <file>` | Print file contents |
| `echo <text>` | Print text, supports `>` and `>>` redirection |
| `mkdir [-p] <dir>` | Create a directory |
| `touch <file>` | Create an empty file |
| `rm [-r] <path>` | Remove a file or directory |
| `tree [path]` | Render the directory tree |
| `grep [-i] <pattern> <file>` | Search text with line numbers |
| `wc <file>` | Count lines, words and characters |
| `whoami` / `uname` / `date` | Show user, kernel info and time |
| `uptime` / `env` / `history` | Show uptime, environment variables and command history |
| `clear` / `help` | Clear the terminal / show help |

The session survives tab switches while the app is running.

## Download and install

Unsigned arm64 IPA (iOS 16+):

<https://github.com/TOTOLZQ/DevMuse/releases/latest/download/MuseDev-unsigned.ipa>

The package is unsigned and must be re-signed before installing:

1. Download `MuseDev-unsigned.ipa`
2. Re-sign it with your own certificate and provisioning profile (Sideloadly, AltStore, TrollStore or a custom p12 workflow)
3. Install on device and trust the certificate under Settings → General → VPN & Device Management

## Build

### CI (recommended)

Pushing to `main` or a `v*` tag runs an unsigned build on a `macos-15` runner:

- Workflow: [Build unsigned IPA](.github/workflows/build-ipa.yml)
- Artifact: `muse-dev-unsigned-ipa`, retained for 30 days
- Release: published automatically, tagged `latest` (tag name is used when pushing a tag)

You can also trigger `workflow_dispatch` manually from the Actions tab.

### Local build

Requires macOS and Xcode 15:

```bash
xcodebuild \
  -project DevMuse.xcodeproj \
  -target DevMuse \
  -configuration Release \
  -sdk iphoneos \
  -arch arm64 \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  CONFIGURATION_BUILD_DIR="$PWD/build/Release"

mkdir -p build/Payload
cp -R build/Release/DevMuse.app build/Payload/
cd build && zip -qry MuseDev-unsigned.ipa Payload
```

## Project layout

```text
DevMuse/
├── .github/workflows/build-ipa.yml     # unsigned IPA build and release
├── DevMuse.xcodeproj                   # Xcode project
└── DevMuse/
    ├── DevMuseApp.swift                # app entry
    ├── RootView.swift                  # custom tab bar and routing
    ├── Theme.swift                     # colors, fonts, motion, shared components
    ├── Models.swift                    # data models and seed content
    ├── MuseStore.swift                 # local persistence and response engine
    ├── AgentView.swift                 # agent chat
    ├── CanvasBoardView.swift           # infinite canvas
    ├── CardEditorSheet.swift           # card editor
    ├── SnippetListView.swift           # snippet list
    ├── SnippetDetailView.swift         # snippet detail and editor
    ├── PromptLabView.swift             # prompt lab
    ├── SandboxShell.swift              # virtual file system and command interpreter
    ├── SandboxView.swift               # sandbox terminal UI
    ├── SettingsView.swift              # settings
    ├── Assets.xcassets                 # icons and color assets
    └── Info.plist
```

## Technical notes

- Pure SwiftUI, no third-party dependencies
- Data is stored as JSON at `Documents/muse-store.json` inside the app container
- Agent replies are generated locally from keywords; no cloud model is called
- Sandbox commands are interpreted by a Swift virtual file system, not a real shell

## Privacy

The app collects no data, requests no network entitlement and bundles no analytics SDK. Everything stays on-device and is removed when the app is deleted.
