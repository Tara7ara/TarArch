#!/usr/bin/env python3
import json
import os
import glob
import time

def get_cpu_usage():
    try:
        with open('/proc/stat', 'r') as f:
            line = f.readline()
        parts = [float(x) for x in line.split()[1:]]
        idle = parts[3] + parts[4]
        total = sum(parts)
        return idle, total
    except Exception:
        return 0, 0

idle1, total1 = get_cpu_usage()
time.sleep(0.15)
idle2, total2 = get_cpu_usage()

idle_diff = idle2 - idle1
total_diff = total2 - total1

cpu_percent = int(round((1.0 - (idle_diff / total_diff)) * 100)) if total_diff > 0 else 0

freq_ghz = 0.0
try:
    freq_files = glob.glob('/sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq')
    if freq_files:
        freqs = [int(open(ff).read().strip()) for ff in freq_files]
        if freqs:
            freq_ghz = (sum(freqs) / len(freqs)) / 1000000.0
except Exception:
    pass

fan_cpu = 'N/A'
fan_gpu = 'N/A'

try:
    for hwmon in glob.glob('/sys/class/hwmon/hwmon*'):
        name_file = os.path.join(hwmon, 'name')
        if os.path.isfile(name_file):
            name = open(name_file).read().strip()
            if name == 'asus':
                f1 = os.path.join(hwmon, 'fan1_input')
                f2 = os.path.join(hwmon, 'fan2_input')
                if os.path.isfile(f1):
                    val = open(f1).read().strip()
                    if val.isdigit():
                        fan_cpu = f"{val} RPM"
                if os.path.isfile(f2):
                    val = open(f2).read().strip()
                    if val.isdigit():
                        fan_gpu = f"{val} RPM"
                break
except Exception:
    pass

tooltip = (
    f"Uso de CPU: {cpu_percent}%\n"
    f"Frecuencia: {freq_ghz:.2f} GHz\n"
    f"Vent. CPU: {fan_cpu}\n"
    f"Vent. GPU: {fan_gpu}"
)

out = {
    "text": f"󰍛  {cpu_percent}%",
    "tooltip": tooltip
}

print(json.dumps(out, ensure_ascii=False))
