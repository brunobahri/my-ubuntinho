# Testing Guide

This document describes how to test the TLP power profiles system to ensure everything is working correctly at the hardware level.

## Quick Test

After installation, run this command to verify the current profile:

```bash
tlp-perfil status
```

Expected output should show:
- Current active profile
- CPU EPP (Energy Performance Preference)
- CPU Turbo status
- GPU Max frequency

## Complete Test Suite

### Test 1: Profile Switching

Test all possible profile transitions:

```bash
# Start with balanced
tlp-perfil balanceado

# Test 1: Balanced → Performance
tlp-perfil performance
# Wait 3 seconds for changes to apply

# Test 2: Performance → Economy
tlp-perfil economia
# Wait 3 seconds

# Test 3: Economy → Balanced
tlp-perfil balanceado
# Wait 3 seconds

# Test 4: Balanced → Economy
tlp-perfil economia
# Wait 3 seconds

# Test 5: Economy → Performance
tlp-perfil performance
# Wait 3 seconds

# Test 6: Performance → Balanced
tlp-perfil balanceado
```

Each transition should show a visual table with configuration changes.

### Test 2: Hardware-Level Verification

After switching to each profile, verify the changes were applied at the kernel level:

#### Check CPU EPP
```bash
cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference
```

Expected values:
- Balanced: `balance_power`
- Economy: `power`
- Performance: `balance_performance`

#### Check CPU Turbo
```bash
cat /sys/devices/system/cpu/intel_pstate/no_turbo
```

Expected values:
- Balanced: `1` (OFF)
- Economy: `1` (OFF)
- Performance: `0` (ON)

#### Check CPU Max Performance
```bash
cat /sys/devices/system/cpu/intel_pstate/max_perf_pct
```

Expected values:
- Balanced: `100`
- Economy: `60`
- Performance: `100`

#### Check GPU Max Frequency
```bash
cat /sys/class/drm/card*/gt_max_freq_mhz | head -1
```

Expected values:
- Balanced: `1000`
- Economy: `700`
- Performance: `1400`

### Test 3: Runtime PM Verification

Check if power management is active for PCIe devices:

```bash
cat /sys/bus/pci/devices/*/power/control 2>/dev/null | sort | uniq -c
```

Expected:
- Most devices should show `auto` when on battery
- Count varies by hardware (typically 20+ devices)

### Test 4: CPU Frequency Monitoring

Monitor CPU frequency in real-time while switching profiles:

```bash
watch -n 1 'cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq | awk "{sum+=\$1; count++} END {print \"Average: \" sum/count/1000 \" MHz\"}" && cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq | awk "{print \"Max allowed: \" \$1/1000 \" MHz\"}"'
```

Observations:
- **Economy**: Max should not exceed ~1320 MHz (60% limit)
- **Balanced**: Can reach 2200 MHz (no turbo)
- **Performance**: Can reach 4800 MHz (turbo enabled)

## Automated Testing Script

Create a test script:

```bash
#!/bin/bash
# Test all profile transitions

profiles=("balanceado" "performance" "economia" "balanceado" "economia" "performance" "balanceado")
results=()

for i in $(seq 0 $((${#profiles[@]}-2))); do
    from="${profiles[$i]}"
    to="${profiles[$((i+1))]}"

    echo "Testing: $from → $to"
    tlp-perfil "$to" > /dev/null 2>&1
    sleep 3

    # Verify
    epp=$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference)
    turbo=$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)
    cpu_max=$(cat /sys/devices/system/cpu/intel_pstate/max_perf_pct)
    gpu_max=$(cat /sys/class/drm/card*/gt_max_freq_mhz | head -1)

    case "$to" in
        "balanceado")
            expected_epp="balance_power"
            expected_turbo="1"
            expected_cpu="100"
            expected_gpu="1000"
            ;;
        "economia")
            expected_epp="power"
            expected_turbo="1"
            expected_cpu="60"
            expected_gpu="700"
            ;;
        "performance")
            expected_epp="balance_performance"
            expected_turbo="0"
            expected_cpu="100"
            expected_gpu="1400"
            ;;
    esac

    if [ "$epp" = "$expected_epp" ] && [ "$turbo" = "$expected_turbo" ] && \
       [ "$cpu_max" = "$expected_cpu" ] && [ "$gpu_max" = "$expected_gpu" ]; then
        echo "✓ PASS"
        results+=("PASS")
    else
        echo "✗ FAIL"
        results+=("FAIL")
    fi
done

# Summary
echo ""
echo "Test Results:"
passed=$(echo "${results[@]}" | tr ' ' '\n' | grep -c "PASS")
total=${#results[@]}
echo "$passed/$total tests passed"
```

## Expected Test Results

All 6 profile transitions should pass hardware verification:

1. BALANCEADO → PERFORMANCE: PASS
2. PERFORMANCE → ECONOMIA: PASS
3. ECONOMIA → BALANCEADO: PASS
4. BALANCEADO → ECONOMIA: PASS
5. ECONOMIA → PERFORMANCE: PASS
6. PERFORMANCE → BALANCEADO: PASS

## Troubleshooting Failed Tests

### Test Fails: CPU EPP Not Changing
**Symptom**: EPP stays the same after profile switch

**Cause**: Power-profiles-daemon may be running

**Solution**:
```bash
# Check if running
systemctl status power-profiles-daemon

# If running, stop and disable it
sudo systemctl stop power-profiles-daemon
sudo systemctl disable power-profiles-daemon
sudo systemctl mask power-profiles-daemon

# Reapply profile
tlp-perfil [profile-name]
```

### Test Fails: GPU Frequency Not Changing
**Symptom**: GPU max frequency doesn't match expected value

**Cause**: TLP may not have written the setting

**Solution**:
```bash
# Restart TLP service
sudo systemctl restart tlp.service

# Reapply profile
tlp-perfil [profile-name]
```

### Test Fails: CPU Max Performance Stuck
**Symptom**: CPU max percentage doesn't change from previous value

**Cause**: Kernel may have cached the value

**Solution**:
```bash
# Force TLP restart
sudo systemctl stop tlp.service
sleep 2
sudo systemctl start tlp.service

# Reapply profile
tlp-perfil [profile-name]
```

## Battery Life Testing

To measure actual battery improvement:

1. Charge battery to 100%
2. Disconnect power
3. Switch to desired profile
4. Run consistent workload (e.g., browsing with same websites)
5. Measure time until specific battery percentage (e.g., 50%)

Expected improvements over baseline (no TLP):
- Balanced: 25-30% longer
- Economy: 50-60% longer
- Performance: Similar or 10-20% shorter

## Performance Impact Testing

### CPU Benchmark
```bash
# Install sysbench if needed
sudo apt install sysbench

# Test each profile
for profile in balanceado economia performance; do
    echo "Testing $profile"
    tlp-perfil $profile
    sleep 5
    sysbench cpu --cpu-max-prime=20000 run
done
```

### GPU Benchmark
```bash
# Install glmark2
sudo apt install glmark2

# Test each profile
for profile in balanceado economia performance; do
    echo "Testing $profile"
    tlp-perfil $profile
    sleep 5
    glmark2 --fullscreen
done
```

## Regression Testing Checklist

Run these tests after any system update:

- [ ] All 6 profile transitions succeed
- [ ] Hardware values match expected for each profile
- [ ] `tlp-perfil status` shows correct information
- [ ] No errors in `/var/log/syslog` related to TLP
- [ ] Battery percentage decreases slower with economy profile
- [ ] Performance profile shows higher benchmarks scores
- [ ] Switching profiles takes less than 5 seconds
- [ ] System remains stable after multiple switches

## Logging Test Results

For future reference, save test results:

```bash
{
    echo "=== TLP Profile Test - $(date) ==="
    echo "System: $(uname -a)"
    echo "TLP Version: $(tlp --version)"
    echo ""

    for profile in balanceado economia performance; do
        echo "Profile: $profile"
        tlp-perfil $profile
        sleep 3
        echo "  EPP: $(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference)"
        echo "  Turbo: $(cat /sys/devices/system/cpu/intel_pstate/no_turbo)"
        echo "  CPU Max: $(cat /sys/devices/system/cpu/intel_pstate/max_perf_pct)%"
        echo "  GPU Max: $(cat /sys/class/drm/card*/gt_max_freq_mhz | head -1) MHz"
        echo ""
    done
} | tee tlp-test-results-$(date +%Y%m%d).log
```

This creates a timestamped log file with test results for comparison.
