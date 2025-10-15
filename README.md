# my-ubuntinho

Personal Ubuntu configuration scripts and dotfiles.

## What it fixes

### Touchpad tap-and-drag

Disables the annoying tap-and-drag feature where two quick taps on the touchpad activate drag mode, causing accidental clicks and unwanted selections.

**Before:** Double-tap on touchpad = automatic drag mode (frustrating missclicks)
**After:** Double-tap disabled, only intentional drags work

## Installation

```bash
git clone git@github.com:brunobahri/my-ubuntinho.git
cd my-ubuntinho
chmod +x install.sh
./install.sh
```

The script will run automatically on login.

## Manual execution

```bash
./scripts/touchpad/disable-tap-drag.sh
```

## Requirements

- Ubuntu 20.04+ (or Ubuntu-based distributions)
- GNOME Desktop Environment
- `gsettings` (usually pre-installed)

## Structure

```
my-ubuntinho/
├── install.sh                           # Installation script
├── scripts/
│   └── touchpad/
│       └── disable-tap-drag.sh          # Disables tap-and-drag
└── autostart/
    └── touchpad-config.desktop          # GNOME autostart configuration
```

## License

MIT License

## Author

Bruno Bahri
GitHub: [@brunobahri](https://github.com/brunobahri)
