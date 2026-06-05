# OpenClaw Matrix üü¢

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> **Matrix Edition** ‚Ä?A fork of [openclaw-termux](https://github.com/mithun50/openclaw-termux) with Matrix/hacker-themed UI, Chinese mirror sources, and a pure-form configuration experience.

Run **OpenClaw AI Gateway** on Android ‚Ä?standalone Flutter app with one-tap setup, AI provider configuration, and web dashboard, all wrapped in a green-on-black Matrix terminal aesthetic.

---

## üîå Based On

This project is a modified fork of **[mithun50/openclaw-termux](https://github.com/mithun50/openclaw-termux)** (MIT License).

### What's different in Matrix Edition:

| Feature | Original | Matrix Edition |
|---|---|---|
| UI Theme | Material 3 (light/dark) | **Matrix hacker green** üíö |
| Onboarding | Terminal emulator | **Pure form UI** |
| Download Sources | Official (slow in CN) | **Tsinghua + npmmirror mirrors** |
| API Key Config | `openclaw onboard` TUI | **Dropdown + text field** |
| AI Providers | 7 providers | **Same 7, form-based config** |
| Setup Progress | Terminal output | **Step-by-step progress bars** |

---

## ‚ú?Features

- **One-Tap Setup** ‚Ä?Downloads Ubuntu rootfs, Node.js 22, and OpenClaw automatically
- **Form-Based Onboarding** ‚Ä?Select AI provider, enter API key, done. No terminal needed
- **Matrix UI** ‚Ä?Green-on-black terminal aesthetic throughout
- **Gateway Controls** ‚Ä?Start/stop gateway with status indicator
- **AI Providers** ‚Ä?Configure 7 providers (Anthropic, OpenAI, Google Gemini, OpenRouter, NVIDIA NIM, DeepSeek, xAI)
- **Web Dashboard** ‚Ä?Embedded WebView with auth token
- **Node Device Capabilities** ‚Ä?Camera, flash, location, sensors, screen recording
- **Foreground Service** ‚Ä?Keeps the gateway alive in background
- **Built-in Terminal** ‚Ä?Full terminal emulator if you need it

---

## üöÄ Quick Start

1. Download the latest APK from [Releases](https://github.com/leoshumcom/openclaw-termux-matrix/releases)
2. Install on your Android device (Android 10+)
3. Tap **Begin Setup** ‚Ä?wait for Ubuntu + Node.js + OpenClaw to install
4. Select your **AI provider**, enter **API key**, tap **Save**
5. Start the Gateway and connect via Feishu/Web

### Build from Source

```bash
git clone https://github.com/leoshumcom/openclaw-termux-matrix.git
cd openclaw-termux-matrix/flutter_app
flutter build apk --release --target-platform android-arm64
```

---

## üñ•Ô∏?Screenshots

*(Add your Matrix-themed screenshots here)*

---

## üì¶ Tech Stack

- **Frontend**: Flutter 3.24+ (Dart)
- **Runtime**: Node.js 22 + proot-distro (Ubuntu 24.04)
- **AI Gateway**: OpenClaw
- **Fonts**: JetBrains Mono + DejaVu Sans Mono

---

## üôè Credits

- [mithun50/openclaw-termux](https://github.com/mithun50/openclaw-termux) ‚Ä?original project (MIT)
- [OpenClaw](https://github.com/openclaw/openclaw) ‚Ä?AI Gateway
- The Matrix movies üé¨

## üìÑ License

MIT ‚Ä?based on [openclaw-termux](https://github.com/mithun50/openclaw-termux) (MIT).

