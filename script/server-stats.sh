#!/bin/bash

chmod +x server-stats.sh

# Function to get CPU times from /proc/stat
get_cpu_times() {
    cat /proc/stat | grep '^cpu ' | awk '{print $2, $3, $4, $5, $6, $7, $8, $9, $10}'
}

# Function to get total CPU usage
get_total_cpu_usage() {
    # Get initial CPU times
    read -r user nice system idle iowait irq softirq steal guest guest_nice <<< "$(get_cpu_times)"
    total_cpu_time_prev=$((user + nice + system + idle + iowait + irq + softirq + steal + guest + guest_nice))
    idle_cpu_time_prev=$((idle + iowait))

    # Wait for a short interval
    sleep 1

    # Get current CPU times
    read -r user nice system idle iowait irq softirq steal guest guest_nice <<< "$(get_cpu_times)"
    total_cpu_time_curr=$((user + nice + system + idle + iowait + irq + softirq + steal + guest + guest_nice))
    idle_cpu_time_curr=$((idle + iowait))

    # Calculate differences
    total_diff=$((total_cpu_time_curr - total_cpu_time_prev))
    idle_diff=$((idle_cpu_time_curr - idle_cpu_time_prev))

    # Calculate CPU usage percentage
    if [ "$total_diff" -gt 0 ]; then
        cpu_usage=$(echo "scale=2; (1 - ($idle_diff / $total_diff)) * 100" | bc)
    else
        cpu_usage=0.00
    fi

    echo "$cpu_usage"
}

# Get and display total CPU usage
total_cpu=$(get_total_cpu_usage)
echo "Total CPU Usage: $total_cpu%"