# Troubleshooting Guide

Common issues and their solutions when using TLP Power Profiles.

## Profile Not Switching

### Symptom
After running `tlp-perfil [profile]`, hardware values don't change.

### Diagnosis
Check if TLP applied the new configuration:
```bash
sudo tlp start
journalctl -u tlp.service | tail -20
```

### Common Causes

#### 1. Power-profiles-daemon Conflict

**Check**:
```bash
systemctl status power-profiles-daemon
```

**Solution**:
```bash
sudo systemctl stop power-profiles-daemon
sudo systemctl disable power-profiles-daemon
sudo systemctl mask power-profiles-daemon
sudo tlp start
```

**Why**: power-profiles-daemon conflicts with TLP and overrides EPP settings.

#### 2. TLP Service Not Running

**Check**:
```bash
systemctl status tlp.service
```

**Solution**:
```bash
sudo systemctl enable tlp.service
sudo systemctl start tlp.service
```

#### 3. Incorrect File Permissions

**Check**:
```bash
ls -l /etc/tlp.d/90-perfil-*.conf*
```

**Solution**:
```bash
sudo chown root:root /etc/tlp.d/90-perfil-*.conf*
sudo chmod 644 /etc/tlp.d/90-perfil-*.conf*
```

## GPU Frequency Not Changing

### Symptom
`cat /sys/class/drm/card*/gt_max_freq_mhz` shows wrong value after profile switch.

### Diagnosis
```bash
# Check if TLP tried to set it
tlp-stat -g

# Check current value
cat /sys/class/drm/card*/gt_max_freq_mhz
```

### Solutions

#### 1. Missing MIN Frequency Setting

**Check profile file** for `INTEL_GPU_MIN_FREQ_ON_BAT`:
```bash
grep INTEL_GPU_MIN /etc/tlp.d/90-perfil-*.conf
```

**Solution**: Add if missing:
```bash
INTEL_GPU_MIN_FREQ_ON_BAT=100
```

#### 2. i915 Driver Not Loaded

**Check**:
```bash
lsmod | grep i915
```

**Solution**:
```bash
sudo modprobe i915
```

#### 3. Hardware Reset Required

**Solution**:
```bash
# Sometimes GPU needs a hard reset
sudo systemctl restart tlp.service
# Wait 5 seconds
cat /sys/class/drm/card*/gt_max_freq_mhz
```

## CPU Turbo Won't Disable

### Symptom
`cat /sys/devices/system/cpu/intel_pstate/no_turbo` shows `0` (ON) when it should be `1` (OFF).

### Diagnosis
```bash
# Check TLP configuration
tlp-stat -p | grep -i turbo

# Check hardware state
cat /sys/devices/system/cpu/intel_pstate/no_turbo
```

### Solutions

#### 1. BIOS Override

Some BIOSes have turbo settings that override OS control.

**Solution**: Check BIOS settings:
- Look for "Intel Turbo Boost"
- If set to "Enabled (Locked)", OS cannot control it
- Change to "Enabled" or "Auto" to allow OS control

#### 2. thermald Interference

**Check**:
```bash
systemctl status thermald
```

**Solution**: thermald may enable turbo for thermal reasons. Either:
- Stop thermald: `sudo systemctl stop thermald`
- Or accept that turbo might be enabled for cooling

#### 3. Manual Override

**Temporary test**:
```bash
echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo
```

If this works but TLP doesn't, check TLP configuration for:
```bash
CPU_BOOST_ON_BAT=0  # Must be present and uncommented
```

## CPU Max Performance Not Limiting

### Symptom
CPU frequency exceeds expected limit (e.g., goes above 1320 MHz on Economy profile).

### Diagnosis
```bash
# Check limit
cat /sys/devices/system/cpu/intel_pstate/max_perf_pct

# Monitor actual frequency
watch -n 1 'cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq'
```

### Solutions

#### 1. Turbo Boost Enabled

If turbo is enabled, CPU can exceed base frequency despite max_perf_pct.

**Check**:
```bash
cat /sys/devices/system/cpu/intel_pstate/no_turbo
```

**Solution**: Disable turbo first:
```bash
echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo
```

#### 2. Thermal Throttling Override

High temperature may cause CPU to ignore limits temporarily.

**Check temperature**:
```bash
sensors
```

**Solution**: Improve cooling or accept temporary frequency increases for thermal management.

## tlp-perfil Command Not Found

### Symptom
```bash
tlp-perfil: command not found
```

### Solutions

#### 1. Script Not in PATH

**Check**:
```bash
ls ~/.local/bin/tlp-perfil
```

**Solution**:
```bash
# Add to PATH if missing
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

#### 2. Script Not Executable

**Check**:
```bash
ls -l ~/.local/bin/tlp-perfil
```

**Solution**:
```bash
chmod +x ~/.local/bin/tlp-perfil
```

#### 3. Script Missing

**Restore from repository**:
```bash
cp ~/Documents/Projetos/my-ubuntinho/tlp-power-profiles/scripts/tlp-perfil ~/.local/bin/
chmod +x ~/.local/bin/tlp-perfil
```

## Profile Shows Wrong Name

### Symptom
`tlp-perfil status` shows incorrect profile name.

### Diagnosis
```bash
ls /etc/tlp.d/90-perfil-*.conf
ls /etc/tlp.d/90-perfil-*.conf.disabled
```

### Solutions

#### 1. Multiple Active Profiles

If multiple `.conf` files exist (no `.disabled` extension), the detection logic breaks.

**Solution**: Manually fix:
```bash
# Disable all profiles
sudo mv /etc/tlp.d/90-perfil-balanceado.conf /etc/tlp.d/90-perfil-balanceado.conf.disabled 2>/dev/null
sudo mv /etc/tlp.d/90-perfil-economia.conf /etc/tlp.d/90-perfil-economia.conf.disabled 2>/dev/null
sudo mv /etc/tlp.d/90-perfil-performance.conf /etc/tlp.d/90-perfil-performance.conf.disabled 2>/dev/null

# Enable desired profile
sudo mv /etc/tlp.d/90-perfil-balanceado.conf.disabled /etc/tlp.d/90-perfil-balanceado.conf

# Apply
sudo tlp start
```

#### 2. Profile Files Missing

**Restore from repository**:
```bash
cd ~/Documents/Projetos/my-ubuntinho/tlp-power-profiles
sudo ./install.sh
```

## Battery Life Not Improving

### Symptom
Battery drains at same rate despite using Economy profile.

### Diagnosis Checklist

1. Verify profile is actually active:
```bash
tlp-perfil status
```

2. Check hardware settings:
```bash
cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference
cat /sys/devices/system/cpu/intel_pstate/max_perf_pct
```

3. Check power consumption:
```bash
# Install powertop
sudo apt install powertop
sudo powertop
```

### Common Non-TLP Causes

#### 1. Display Brightness
**Solution**: Reduce screen brightness to 30-50%

#### 2. Background Processes
**Check**:
```bash
top -o %CPU
```
**Solution**: Close unnecessary applications

#### 3. NVIDIA GPU Active
If using Optimus laptop:
```bash
# Check if NVIDIA is active
nvidia-smi
```
**Solution**: Use EnvyControl to switch to integrated mode:
```bash
envycontrol -s integrated
sudo reboot
```

#### 4. WiFi/Bluetooth
**Solution**: Disable if not needed:
```bash
# WiFi
nmcli radio wifi off

# Bluetooth
bluetoothctl power off
```

## System Freezes After Profile Switch

### Symptom
System becomes unresponsive after changing profile.

### Emergency Recovery
1. Press `Ctrl+Alt+F3` to switch to TTY3
2. Login with username/password
3. Run:
```bash
sudo systemctl stop tlp.service
sudo tlp-perfil balanceado
sudo systemctl start tlp.service
```

### Root Causes

#### 1. CPU Frequency Too Low
Economy profile with 60% limit may be too aggressive for some systems.

**Solution**: Create custom profile with 70-80% limit:
```bash
sudo nano /etc/tlp.d/90-perfil-custom.conf
```

Content:
```bash
CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power
CPU_MAX_PERF_ON_BAT=80  # Less aggressive than 60%
CPU_BOOST_ON_BAT=0
INTEL_GPU_MAX_FREQ_ON_BAT=900
```

#### 2. GPU Frequency Too Low
Some applications require minimum GPU frequency.

**Solution**: Increase GPU minimum in profile:
```bash
INTEL_GPU_MIN_FREQ_ON_BAT=300  # Instead of 100
```

## Configuration Errors on Boot

### Symptom
TLP shows errors in journal at boot:
```bash
journalctl -u tlp.service | grep -i error
```

### Common Errors

#### 1. "Error in configuration at INTEL_GPU_MIN_FREQ_ON_BAT"
**Cause**: Value out of hardware range

**Check valid range**:
```bash
cat /sys/class/drm/card*/gt_RPn_freq_mhz  # Min
cat /sys/class/drm/card*/gt_RP0_freq_mhz  # Max
```

**Solution**: Adjust values in profile to match hardware capabilities.

#### 2. "Runtime PM for PCI device not available"
**This is normal for**:
- Disabled NVIDIA GPU (when using integrated mode)
- Other PCIe devices that don't support runtime PM

**No action needed** - TLP will skip these devices.

## Performance Profile Shows No Speed Increase

### Symptom
Benchmarks show same performance on Performance profile as Balanced.

### Diagnosis

Check if turbo is actually enabled:
```bash
# Should show 0 (enabled)
cat /sys/devices/system/cpu/intel_pstate/no_turbo

# Should show frequencies up to 4800 MHz under load
watch -n 1 'cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq'
```

### Solutions

#### 1. Thermal Throttling
CPU might not reach turbo frequencies due to temperature.

**Check**:
```bash
sudo apt install lm-sensors
sensors
```

**Solution**: Ensure proper cooling, clean vents, use cooling pad.

#### 2. Power Limit Throttling
System might be hitting power limits.

**Check** (requires MSR tools):
```bash
sudo apt install msr-tools
sudo rdmsr 0x1b0 -f 10:10  # Check throttling status
```

**Solution**: This is hardware limited, no software fix possible.

#### 3. Turbo Not Enabled in BIOS
**Solution**: Check BIOS settings for "Intel Turbo Boost Technology" and enable it.

## Reverting All Changes

### Complete Uninstall

If you want to completely remove TLP Power Profiles:

```bash
cd ~/Documents/Projetos/my-ubuntinho/tlp-power-profiles

# Restore original TLP configuration
sudo cp /etc/tlp.conf.backup /etc/tlp.conf

# Remove profile files
sudo rm /etc/tlp.d/90-perfil-*.conf*

# Remove script
rm ~/.local/bin/tlp-perfil

# Restart TLP
sudo systemctl restart tlp.service
```

### Factory Reset TLP

If TLP is completely broken:

```bash
# Purge TLP
sudo apt purge tlp tlp-rdw

# Reinstall
sudo apt install tlp tlp-rdw

# Enable service
sudo systemctl enable tlp.service
sudo systemctl start tlp.service
```

## Getting Help

If issues persist:

1. **Gather information**:
```bash
{
    echo "System Information:"
    uname -a
    echo ""
    echo "TLP Version:"
    tlp --version
    echo ""
    echo "TLP Status:"
    sudo tlp-stat -s
    echo ""
    echo "Active Profile:"
    tlp-perfil status
    echo ""
    echo "Recent TLP Logs:"
    journalctl -u tlp.service | tail -50
} > tlp-debug-$(date +%Y%m%d-%H%M%S).log
```

2. **Check GitHub issues**: https://github.com/brunobahri/my-ubuntinho/issues

3. **Review TLP documentation**: https://linrunner.de/tlp/

4. **Test with default TLP**: Temporarily disable profiles to see if issue is TLP-related:
```bash
sudo mv /etc/tlp.d/90-perfil-balanceado.conf /etc/tlp.d/90-perfil-balanceado.conf.disabled
sudo tlp start
```

## Known Issues

### Issue: NVIDIA GPU Not Managed
**Status**: By design

**Explanation**: This system only manages Intel CPU/GPU. NVIDIA GPU should be managed with EnvyControl separately.

### Issue: Values Revert After Sleep/Suspend
**Status**: Known limitation

**Workaround**: Run `tlp-perfil [current-profile]` after resume to reapply settings.

Possible automation:
```bash
# Create systemd service
sudo nano /etc/systemd/system/tlp-perfil-resume.service
```

Content:
```ini
[Unit]
Description=Reapply TLP profile after resume
After=suspend.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/tlp start

[Install]
WantedBy=suspend.target
```

Enable:
```bash
sudo systemctl enable tlp-perfil-resume.service
```

### Issue: Switching Profiles Takes 3-5 Seconds
**Status**: Expected behavior

**Explanation**: TLP needs time to:
1. Read configuration files
2. Apply kernel parameters
3. Configure all devices
4. Update sysfs interfaces

This is normal and cannot be significantly improved.
