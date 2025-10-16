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

### TLP Power Profiles

Advanced power management with three switchable profiles for optimal battery life.

**Profiles:**
- Balanceado: ~25-30% more battery (recommended)
- Economia: ~50-60% more battery (long trips)
- Performance: Maximum CPU/GPU performance

**Installation:**
```bash
cd tlp-power-profiles
chmod +x install.sh
sudo ./install.sh
```

**Usage:**
```bash
tlp-perfil balanceado   # Default profile
tlp-perfil economia     # Maximum battery saving
tlp-perfil performance  # Maximum performance
```

See [tlp-power-profiles/README.md](tlp-power-profiles/README.md) for detailed documentation.

## Structure

```
my-ubuntinho/
├── install.sh                           # Installation script (touchpad)
├── scripts/
│   └── touchpad/
│       └── disable-tap-drag.sh          # Disables tap-and-drag
├── autostart/
│   └── touchpad-config.desktop          # GNOME autostart configuration
└── tlp-power-profiles/
    ├── README.md                        # TLP profiles documentation
    ├── install.sh                       # TLP profiles installer
    ├── configs/                         # TLP configuration files
    ├── scripts/                         # Profile manager script
    └── docs/                            # Technical documentation
```

## License

MIT License

## Author

Bruno Bahri
GitHub: [@brunobahri](https://github.com/brunobahri)
