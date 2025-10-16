# TLP Power Profiles

Advanced power management system for Linux laptops using TLP with three switchable profiles optimized for different usage scenarios.

## Overview

This system provides intelligent battery management through three distinct power profiles that can be switched instantly without rebooting. Each profile adjusts CPU performance, GPU frequency, and power management settings at the hardware level.

## Profiles

### Balanceado (Balanced)
**Default profile - Recommended for daily use**

- CPU EPP: balance_power
- CPU Turbo: OFF
- CPU Max: 100%
- GPU Max: 1000 MHz
- Battery gain: ~25-30% longer battery life
- Performance impact: Nearly imperceptible

Ideal for: General productivity, web browsing, coding, document editing.

### Economia (Economy)
**Maximum battery conservation**

- CPU EPP: power
- CPU Turbo: OFF
- CPU Max: 60% (limited to 1320 MHz)
- GPU Max: 700 MHz
- Battery gain: ~50-60% longer battery life
- Performance impact: System noticeably slower (~30% reduction)

Ideal for: Long trips, presentations, when maximum battery life is critical.

### Performance
**Maximum performance**

- CPU EPP: balance_performance
- CPU Turbo: ON (up to 4800 MHz)
- CPU Max: 100%
- GPU Max: 1400 MHz
- Battery gain: 0% (consumes ~40% more than balanced)
- Performance impact: Maximum CPU/GPU performance

Ideal for: Compilation, video editing, gaming (when plugged in or short battery tasks).

## Quick Start

### Installation

```bash
cd ~/Documents/Projetos/my-ubuntinho/tlp-power-profiles
chmod +x install.sh
sudo ./install.sh
```

The installer will:
1. Backup your current TLP configuration
2. Install optimized TLP configurations
3. Install profile management script
4. Apply the balanced profile by default

### Usage

```bash
# Switch profiles (instant, no reboot required)
tlp-perfil balanceado
tlp-perfil economia
tlp-perfil performance

# Check current status
tlp-perfil status
```

## System Requirements

- Ubuntu 20.04+ or Ubuntu-based distribution
- TLP 1.3+
- Intel CPU with P-state driver
- Intel integrated GPU
- Root/sudo access

## Technical Details

The system works by:
1. Modifying TLP configuration files in `/etc/tlp.conf` and `/etc/tlp.d/`
2. Managing profile files with `.disabled` extensions
3. Applying settings directly to kernel interfaces:
   - `/sys/devices/system/cpu/intel_pstate/`
   - `/sys/class/drm/card*/`
   - `/sys/bus/pci/devices/*/power/control`

Changes take effect immediately (2-3 seconds) without requiring system restart.

## Files Structure

```
tlp-power-profiles/
├── README.md                                    # This file
├── install.sh                                   # Installation script
├── configs/
│   ├── tlp.conf                                 # Main TLP configuration (AC settings)
│   └── tlp.d/
│       ├── 90-perfil-balanceado.conf.disabled   # Balanced profile
│       ├── 90-perfil-economia.conf.disabled     # Economy profile
│       └── 90-perfil-performance.conf.disabled  # Performance profile
├── scripts/
│   └── tlp-perfil                               # Profile manager script
└── docs/
    ├── TESTING.md                               # Testing procedures
    ├── TROUBLESHOOTING.md                       # Common issues and solutions
    └── TECHNICAL.md                             # Technical implementation details
```

## Compatibility

### Tested Hardware
- Alienware 16 Aurora AC16250
- Intel Core 5 210H
- Intel integrated graphics
- NVIDIA GPU (managed separately via EnvyControl)

### Limitations
- Requires Intel CPU with intel_pstate driver
- AMD CPUs require configuration adjustments
- NVIDIA Optimus configurations need EnvyControl or similar tool
- Some Dell/Alienware models may need BIOS updates for full functionality

## Integration with Other Tools

### EnvyControl
This system works alongside EnvyControl for NVIDIA GPU management:
- `envycontrol -s integrated`: Disables NVIDIA GPU (best battery life)
- `envycontrol -s hybrid`: Switches between Intel and NVIDIA as needed
- `envycontrol -s nvidia`: Uses only NVIDIA GPU (gaming/rendering)

TLP profiles manage CPU/Intel GPU, EnvyControl manages NVIDIA GPU.

## Uninstallation

```bash
cd ~/Documents/Projetos/my-ubuntinho/tlp-power-profiles
sudo ./install.sh --uninstall
```

This will restore your original TLP configuration from backup.

## Documentation

- [TESTING.md](docs/TESTING.md) - How to test profiles and verify functionality
- [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - Common issues and solutions
- [TECHNICAL.md](docs/TECHNICAL.md) - Deep dive into implementation

## License

MIT License

## Author

Bruno Bahri
GitHub: [@brunobahri](https://github.com/brunobahri)
