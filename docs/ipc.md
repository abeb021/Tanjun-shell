# IPC

The running shell listens as target `tanjun`. Binds and scripts call this; they do not start a second Quickshell.

```bash
qs ipc call tanjun toggleLauncher
```

| Verb | |
|------|--|
| `toggleLauncher` | App search / rest card |
| `toggleSidebar` | System drawer |
| `toggleClipboard` | Clipboard |
| `toggleSettings` | Settings |
| `toggleOverview` | Live window previews |
| `toggleDnd` | Do not disturb |
| `lock` | Session lock |
