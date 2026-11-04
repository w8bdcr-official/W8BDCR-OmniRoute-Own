# W8BDCR OmniRoute — Termux AI Gateway

One command on your phone to talk to many AI model providers, with a
fallback when one provider fails and a clear view of how many tokens
you used. Built by W8BDCR, for Termux on Android.

## ⚡ 1) Install & run

### 📱 Termux (Android) Quick Install & Auto-Update:

```bash
curl -fsSL https://raw.githubusercontent.com/w8bdcr-official/W8BDCR-OmniRoute-Own/main/install.sh | bash
```

💡 Tip: To update on Termux anytime, run `omniroute-update`.

![W8BDCR OmniRoute dashboard](thumbnail-draft.png)

## 🚀 W8BDCR OmniRoute — One Gateway for Every AI Model

Start it, then open the dashboard:

```bash
omniroute serve
```

```
http://localhost:20128
```

## Quick start — copy, paste, run

No keys and no config are needed for the first test. With the server
running, ask it a question:

```bash
curl http://localhost:20128/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "auto", "messages": [{"role": "user", "content": "Hello!"}]}'
```

Python:

```python
import requests
r = requests.post(
    "http://localhost:20128/v1/chat/completions",
    json={"model": "auto", "messages": [{"role": "user", "content": "Hello!"}]},
)
print(r.json())
```

Node.js:

```javascript
const r = await fetch("http://localhost:20128/v1/chat/completions", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({
    model: "auto",
    messages: [{ role: "user", content: "Hello!" }],
  }),
});
console.log(await r.json());
```

Pick a specific provider when you want one, and let the gateway fall
back to another when your first pick fails.

## What it does

- **One gateway, many providers.** Point your tools at one local
  address instead of wiring each provider separately.
- **Fallback, not failure.** If the provider you picked is down or
  refuses a request, the gateway can try the next one in your list.
- **Token use you can see.** The dashboard shows usage, so you can
  spot waste and keep costs down.
- **CLI first.** Everything the dashboard does starts from the
  command line, so it fits a Termux workflow.

## Providers, privacy, and keys

Providers are configured by you, on your own phone, with your own API
keys in environment variables. This repo contains no keys, no accounts,
and no provider credentials — copy `.env.example` to your own config
and fill in only the providers you actually use.

Your requests go to the providers you chose. Nothing in this installer
sends your keys anywhere else, and the gateway runs locally on your
device.

## How it works, in short

1. `install.sh` installs Node.js, Git and esbuild in Termux.
2. It installs the upstream OmniRoute gateway from npm.
3. It applies Android fixes the phone build needs: browser automation
   is skipped on Android, server binding is guarded, and the local
   database file is linked where the built server expects it.
4. It adds `omniroute-update`, which checks npm, reinstalls when a
   newer version exists, and re-runs the installer so the fixes are
   re-applied.

## Community

- Telegram channel: @BDCRTEAM
- YouTube: @w8bdcrteam
- Bots: @w8bdcraibot, @w8appstorebot

## Documentation index

Files in this repo, in the order GitHub lists them:

- `.env.example` — placeholder config, no real keys
- `CONTRIBUTING.md` — how to contribute
- `install.sh` — the Termux installer
- `LICENSE` — MIT
- `README.md` — this file
- `SECURITY.md` — how to report a security problem
- `thumbnail-draft.png` — dashboard banner image (1280×720)
- `thumbnail-draft-720x1640.png` — same banner, phone-video size
- `uninstall.sh` — removal, with an optional `--purge` for config
- `update.sh` — the updater behind `omniroute-update`

Remove it any time with `bash uninstall.sh` (add `--purge` to also
remove its local config).

## Notes and limits

- Termux on Android only. This installer checks for Termux and stops
  plainly outside it.
- A phone has little memory: the installer retries the npm install
  with a low-memory Node setting if the first attempt fails.
- The gateway itself is upstream open source; this repo is W8BDCR's
  own installer, updater, uninstaller and documentation for it.

## License

MIT — see `LICENSE`. Copyright (c) 2026 W8BDCR.
