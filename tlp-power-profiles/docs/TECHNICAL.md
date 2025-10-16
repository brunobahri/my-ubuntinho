# Technical Documentation

Deep dive into the implementation details of the TLP Power Profiles system.

## Architecture Overview

The system consists of three layers:

1. **Configuration Layer**: TLP configuration files
2. **Management Layer**: Profile switching script
3. **Kernel Interface Layer**: Direct hardware control via sysfs

```
User Command (tlp-perfil economia)
    ↓
Profile Manager Script
    ↓
TLP Configuration Files
    ↓
TLP Daemon (tlp start)
    ↓
Kernel Interfaces (/sys/devices/...)
    ↓
Hardware (CPU, GPU, PCIe devices)
```

## Configuration File Hierarchy

TLP reads configuration in this order:

1. Intrinsic defaults (built into TLP)
2. `/etc/tlp.d/*.conf` (in alphabetical order)
3. `/etc/tlp.conf` (last, overrides everything)

### Design Decision: Why Drop-in Configs?

Initially, all settings were in `/etc/tlp.conf`, but this caused profile override issues. The solution:

- `/etc/tlp.conf`: Contains only AC (plugged in) settings
- `/etc/tlp.d/90-perfil-*.conf`: Contains BAT (battery) settings
- Only ONE profile file is active (without `.disabled` extension)

This ensures battery settings can be switched without conflicts.

## Profile Switching Mechanism

### File Naming Convention

- Active profile: `90-perfil-[name].conf`
- Inactive profile: `90-perfil-[name].conf.disabled`

The `.disabled` extension prevents TLP from reading the file.

### Switching Process

```bash
# User runs: tlp-perfil economia

1. Detect current profile (check which .conf file exists)
2. Rename all profiles to .disabled:
   - mv 90-perfil-balanceado.conf → .disabled
   - mv 90-perfil-economia.conf.disabled → .disabled (no-op)
   - mv 90-perfil-performance.conf.disabled → .disabled (no-op)

3. Activate target profile:
   - mv 90-perfil-economia.conf.disabled → 90-perfil-economia.conf

4. Apply changes:
   - sudo tlp start

5. Verify (reads from /sys/devices/...)
```

## Kernel Interfaces

### CPU Energy Performance Preference (EPP)

**Path**: `/sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference`

**Driver**: intel_pstate (required)

**Values**:
- `performance`: Maximum frequency, minimum latency
- `balance_performance`: Favor performance over power saving
- `default`: Firmware/BIOS default
- `balance_power`: Favor power saving over performance
- `power`: Maximum power saving, higher latency acceptable

**How it works**: EPP is a hardware hint to the CPU's internal power management. It affects P-state selection, voltage, and frequency transitions. The CPU microcode interprets these hints to balance performance and power.

**TLP Configuration**:
```bash
CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power
```

### CPU Turbo Boost

**Path**: `/sys/devices/system/cpu/intel_pstate/no_turbo`

**Values**:
- `0`: Turbo enabled (CPU can exceed base frequency)
- `1`: Turbo disabled (CPU limited to base frequency)

**How it works**: Intel Turbo Boost allows the CPU to run above its base frequency when thermal and power budgets allow. Disabling it saves power by preventing frequency spikes.

**Impact**:
- Enabled: Base 2200 MHz, turbo up to 4800 MHz
- Disabled: Maximum 2200 MHz (base frequency)

**TLP Configuration**:
```bash
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0
```

### CPU Max Performance Percentage

**Path**: `/sys/devices/system/cpu/intel_pstate/max_perf_pct`

**Range**: 0-100 (percentage)

**How it works**: Limits the maximum P-state the CPU can enter. For example, 60% on a 2200 MHz CPU means maximum ~1320 MHz.

**TLP Configuration**:
```bash
CPU_MAX_PERF_ON_AC=100
CPU_MAX_PERF_ON_BAT=60
```

### Intel GPU Frequency Control

**Paths**:
```
/sys/class/drm/card*/gt_min_freq_mhz  - Minimum frequency (idle)
/sys/class/drm/card*/gt_max_freq_mhz  - Maximum frequency (load)
/sys/class/drm/card*/gt_boost_freq_mhz - Boost frequency (peak)
```

**How it works**: Intel's i915 driver exposes frequency controls. Lowering max frequency reduces power consumption during GPU workloads.

**TLP Configuration**:
```bash
INTEL_GPU_MIN_FREQ_ON_BAT=100
INTEL_GPU_MAX_FREQ_ON_BAT=1000
INTEL_GPU_BOOST_FREQ_ON_BAT=1000
```

### Runtime Power Management (PCIe)

**Path**: `/sys/bus/pci/devices/*/power/control`

**Values**:
- `on`: Device always powered
- `auto`: Device can enter low-power states when idle

**How it works**: Allows PCIe devices (SSD, network card, etc.) to enter D3 power state when not in use. Saves power but adds latency when device needs to wake up.

**TLP Configuration**:
```bash
RUNTIME_PM_ON_AC=on
RUNTIME_PM_ON_BAT=auto
```

## Implementation Challenges

### Challenge 1: Configuration Override Order

**Problem**: Initial implementation had all settings in `/etc/tlp.conf`. When switching profiles, BAT settings weren't changing because they were being overridden by the main file.

**Solution**: Moved all BAT settings to drop-in configs in `/etc/tlp.d/`. Only AC settings remain in main config. This allows profile files to have final say for battery settings.

### Challenge 2: Intel GPU MIN Frequency

**Problem**: TLP requires `INTEL_GPU_MIN_FREQ_ON_BAT` to be set, even if it's the same as hardware minimum (100 MHz). Without it, TLP throws configuration errors.

**Solution**: Always specify MIN frequency explicitly:
```bash
INTEL_GPU_MIN_FREQ_ON_BAT=100  # Even if this is hardware default
```

### Challenge 3: Profile Detection

**Problem**: How does the script know which profile is currently active?

**Solution**: Check filesystem for non-disabled files:
```bash
get_current_profile() {
    if [ -f "/etc/tlp.d/90-perfil-economia.conf" ]; then
        echo "economia"
    elif [ -f "/etc/tlp.d/90-perfil-performance.conf" ]; then
        echo "performance"
    elif [ -f "/etc/tlp.d/90-perfil-balanceado.conf" ]; then
        echo "balanceado"
    else
        echo "desconhecido"
    fi
}
```

### Challenge 4: Turbo Frequency Reporting

**Problem**: When turbo is disabled, `cpuinfo_max_freq` still reports 4800 MHz (turbo frequency), but actual maximum is 2200 MHz (base).

**Solution**: Check `no_turbo` value before interpreting max frequency:
```bash
turbo=$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)
if [ "$turbo" = "1" ]; then
    echo "Max: 2200 MHz (turbo disabled)"
else
    echo "Max: 4800 MHz (turbo enabled)"
fi
```

## Performance Characteristics

### Profile Application Time

Measured times for profile switching:

- File rename operations: <50ms
- `tlp start` execution: 1-2 seconds
- Kernel interface updates: <100ms
- Total user-visible time: 2-3 seconds

### CPU Frequency Transition

CPU frequency changes are handled by intel_pstate driver:

- P-state transition latency: 10-100 microseconds
- EPP hint processing: Immediate (microcode)
- Turbo enable/disable: Immediate

### GPU Frequency Transition

Intel i915 driver manages GPU frequency:

- Frequency change latency: 10-50 milliseconds
- Frequency is adjusted dynamically based on workload
- Max frequency setting is a hard limit

## System Integration

### Systemd Service

TLP runs as a systemd service:

```bash
# Service status
systemctl status tlp.service

# Manually restart
systemctl restart tlp.service

# View logs
journalctl -u tlp.service
```

### Startup Behavior

TLP automatically:
1. Starts at boot
2. Detects power source (AC/BAT)
3. Applies appropriate configuration
4. Monitors power source changes

### Power Source Detection

TLP detects AC/BAT through:
- `/sys/class/power_supply/AC*/online`
- When AC is unplugged, applies _ON_BAT settings
- When AC is plugged, applies _ON_AC settings
- Transition happens within 1-2 seconds

## Compatibility Notes

### Intel P-State Driver

**Required**: intel_pstate in "active" mode

**Check current driver**:
```bash
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver
# Should output: intel_pstate
```

**Alternative drivers NOT supported**:
- acpi-cpufreq (older Intel CPUs)
- cpufreq-powersave (generic)
- AMD-specific drivers

### NVIDIA Optimus

NVIDIA GPU is managed separately:

**Not affected by TLP profiles**:
- NVIDIA GPU frequency
- NVIDIA power states
- NVIDIA driver settings

**Managed by EnvyControl**:
- GPU on/off state
- Driver loading
- X11/Wayland configuration

**TLP manages**:
- Runtime PM for NVIDIA when in hybrid mode
- File: `/etc/tlp.d/50-nvidia.conf`
- Setting: `RUNTIME_PM_ENABLE="0000:01:00.0"`

### Platform Profile

Some laptops support platform profiles via ACPI:
- `/sys/firmware/acpi/platform_profile`

**Status on Alienware 16**: Not available

If available, TLP can set:
```bash
PLATFORM_PROFILE_ON_AC=performance
PLATFORM_PROFILE_ON_BAT=low-power
```

## Debugging

### Enable TLP Verbose Mode

Add to profile config:
```bash
TLP_WARN_LEVEL=3
```

View detailed logs:
```bash
journalctl -u tlp.service -f
```

### Check Applied Settings

```bash
# CPU settings
tlp-stat -p

# Disk settings
tlp-stat -d

# GPU settings
tlp-stat -g

# Battery settings
tlp-stat -b

# Complete status
tlp-stat
```

### Verify File Read Order

```bash
# TLP will log which files it reads
sudo tlp start --verbose
```

### Manual Hardware Control

For testing without TLP:

```bash
# Set CPU EPP
echo "power" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference

# Disable turbo
echo "1" | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo

# Limit CPU max
echo "60" | sudo tee /sys/devices/system/cpu/intel_pstate/max_perf_pct

# Limit GPU
echo "700" | sudo tee /sys/class/drm/card*/gt_max_freq_mhz
```

Note: Manual changes are lost on reboot or when TLP restarts.

## Security Considerations

### Sudo Requirements

The `tlp-perfil` script requires sudo for:
- Renaming files in `/etc/tlp.d/`
- Executing `tlp start`

### File Permissions

Configuration files should be:
- Owner: root:root
- Permissions: 644 (readable by all, writable by root)

```bash
sudo chown root:root /etc/tlp.d/90-perfil-*.conf*
sudo chmod 644 /etc/tlp.d/90-perfil-*.conf*
```

### Sudoers Configuration (Optional)

To allow profile switching without password:

```bash
# /etc/sudoers.d/tlp-perfil
yourusername ALL=(root) NOPASSWD: /usr/sbin/tlp, /bin/mv /etc/tlp.d/*
```

**Warning**: Only do this if you understand the security implications.

## Future Improvements

Potential enhancements:

1. **Per-application profiles**: Automatically switch based on running applications
2. **Battery threshold integration**: Adjust profile based on remaining battery
3. **Temperature-based switching**: More aggressive cooling in performance mode
4. **GUI indicator**: System tray icon showing current profile
5. **Profile scheduling**: Time-based automatic switching
6. **Custom profiles**: User-defined fourth profile with custom settings

## References

- TLP Documentation: https://linrunner.de/tlp/
- Intel P-State Driver: https://www.kernel.org/doc/html/latest/admin-guide/pm/intel_pstate.html
- Intel i915 Driver: https://www.kernel.org/doc/html/latest/gpu/i915.html
- Linux Power Management: https://www.kernel.org/doc/html/latest/admin-guide/pm/
