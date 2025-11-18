#!/bin/bash

chmod +x server-stats.sh

# Function to get total CPU usage on Linux
get_total_cpu_usage() {
    # Calculate CPU usage by sampling /proc/stat
    local cpu_line1=$(grep '^cpu ' /proc/stat)
    sleep 1
    local cpu_line2=$(grep '^cpu ' /proc/stat)
    
    local cpu1=(${cpu_line1})
    local cpu2=(${cpu_line2})
    
    local idle1=${cpu1[4]}
    local idle2=${cpu2[4]}
    
    local total1=0
    local total2=0
    
    for val in ${cpu1[@]:1}; do
        total1=$((total1 + val))
    done
    
    for val in ${cpu2[@]:1}; do
        total2=$((total2 + val))
    done
    
    local total_diff=$((total2 - total1))
    local idle_diff=$((idle2 - idle1))
    
    if [ $total_diff -gt 0 ]; then
        local cpu_usage=$(awk "BEGIN {printf \"%.2f\", (($total_diff - $idle_diff) / $total_diff) * 100}")
    else
        local cpu_usage="0.00"
    fi
    
    echo "$cpu_usage"
}

# Function to get memory usage statistics on Linux
get_memory_usage() {
    # Parse /proc/meminfo for memory statistics
    local total_mem=$(grep '^MemTotal:' /proc/meminfo | awk '{print $2}')
    local free_mem=$(grep '^MemFree:' /proc/meminfo | awk '{print $2}')
    local available_mem=$(grep '^MemAvailable:' /proc/meminfo | awk '{print $2}')
    local buffers=$(grep '^Buffers:' /proc/meminfo | awk '{print $2}')
    local cached=$(grep '^Cached:' /proc/meminfo | awk '{print $2}')
    
    # Convert to MB
    local TOTAL_MEM=$((total_mem / 1024))
    local FREE_MEM=$((available_mem / 1024))
    local USED_MEM=$((TOTAL_MEM - FREE_MEM))
    
    # Calculate percentages
    if [ $TOTAL_MEM -gt 0 ]; then
        local USED_PERCENT=$(awk "BEGIN {printf \"%.2f\", ($USED_MEM / $TOTAL_MEM) * 100}")
        local FREE_PERCENT=$(awk "BEGIN {printf \"%.2f\", ($FREE_MEM / $TOTAL_MEM) * 100}")
    else
        local USED_PERCENT="0.00"
        local FREE_PERCENT="0.00"
    fi
    
    echo "$TOTAL_MEM|$USED_MEM|$USED_PERCENT|$FREE_MEM|$FREE_PERCENT"
}

# Function to get top 5 processes by CPU usage on Linux
get_top_cpu_processes() {
    # Use ps to get top 5 processes by CPU usage
    ps aux --sort=-%cpu | head -6 | tail -5 | awk '{print $11"|"$2"|"$3}'
}

# Function to get top 5 processes by Memory usage on Linux
get_top_memory_processes() {
    # Use ps to get top 5 processes by memory usage
    ps aux --sort=-%mem | head -6 | tail -5 | awk '{mem_mb=$6/1024; printf "%s|%s|%.2f\n", $11, $2, mem_mb}'
}

# Function to get OS version on Linux
get_os_version() {
    # Get OS information from /etc/os-release or lsb_release
    if [ -f /etc/os-release ]; then
        local os_name=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d'"' -f2)
        local os_version=$(grep '^VERSION_ID=' /etc/os-release | cut -d'"' -f2)
        local os_id=$(grep '^ID=' /etc/os-release | head -1 | cut -d'=' -f2 | tr -d '"')
    elif command -v lsb_release &> /dev/null; then
        local os_name=$(lsb_release -d | cut -f2)
        local os_version=$(lsb_release -r | cut -f2)
        local os_id=$(lsb_release -i | cut -f2)
    else
        local os_name=$(uname -s)
        local os_version=$(uname -r)
        local os_id="unknown"
    fi
    
    local kernel_version=$(uname -r)
    local architecture=$(uname -m)
    
    echo "$os_name|$os_version|$kernel_version|$architecture"
}

# Function to get system uptime on Linux
get_system_uptime() {
    # Read uptime from /proc/uptime
    local uptime_seconds=$(cat /proc/uptime | cut -d' ' -f1 | cut -d'.' -f1)
    
    local days=$((uptime_seconds / 86400))
    local hours=$(((uptime_seconds % 86400) / 3600))
    local minutes=$(((uptime_seconds % 3600) / 60))
    local seconds=$((uptime_seconds % 60))
    
    echo "$days|$hours|$minutes|$seconds"
}

# Function to get system load average on Linux
get_load_average() {
    # Read load average from /proc/loadavg
    local load_avg=$(cat /proc/loadavg)
    local load_1min=$(echo $load_avg | cut -d' ' -f1)
    local load_5min=$(echo $load_avg | cut -d' ' -f2)
    local load_15min=$(echo $load_avg | cut -d' ' -f3)
    
    # Get number of CPU cores
    local cpu_count=$(nproc)
    
    echo "$load_1min|$load_5min|$load_15min|$cpu_count"
}

# Function to get disk usage statistics for all disks on Linux
get_disk_usage() {
    # Use df to get disk statistics
    echo "INDIVIDUAL_DISKS_START"
    
    local total_size=0
    local total_used=0
    local total_free=0
    
    # Get mounted filesystems (excluding tmpfs, devtmpfs, etc.)
    df -BG -x tmpfs -x devtmpfs -x squashfs -x overlay | tail -n +2 | while read -r line; do
        local filesystem=$(echo "$line" | awk '{print $1}')
        local size=$(echo "$line" | awk '{print $2}' | sed 's/G//')
        local used=$(echo "$line" | awk '{print $3}' | sed 's/G//')
        local avail=$(echo "$line" | awk '{print $4}' | sed 's/G//')
        local mount_point=$(echo "$line" | awk '{print $6}')
        
        local used_percent=$(awk "BEGIN {printf \"%.2f\", ($used / $size) * 100}" 2>/dev/null || echo "0.00")
        local free_percent=$(awk "BEGIN {printf \"%.2f\", ($avail / $size) * 100}" 2>/dev/null || echo "0.00")
        
        echo "$mount_point|$size|$used|$used_percent|$avail|$free_percent"
    done
    
    echo "INDIVIDUAL_DISKS_END"
    
    # Calculate total disk usage
    local disk_totals=$(df -BG -x tmpfs -x devtmpfs -x squashfs -x overlay | tail -n +2 | awk '{
        gsub(/G/, "", $2); gsub(/G/, "", $3); gsub(/G/, "", $4);
        total_size += $2; total_used += $3; total_avail += $4
    } END {
        if (total_size > 0) {
            used_percent = (total_used / total_size) * 100;
            free_percent = (total_avail / total_size) * 100;
            printf "%.0f|%.0f|%.2f|%.0f|%.2f", total_size, total_used, used_percent, total_avail, free_percent
        } else {
            print "0|0|0.00|0|0.00"
        }
    }')
    
    echo "TOTAL|$disk_totals"
}

# Function to get currently logged in users on Linux
get_logged_in_users() {
    # Use who command to get logged in users
    local users_info=$(who | awk '{
        user=$1; tty=$2; login_time=$3" "$4; 
        if ($5 != "") ip=$5; else ip="local";
        printf "%s|%s|Active|.|%s (%s)\n", user, tty, login_time, ip
    }')
    
    if [ -z "$users_info" ]; then
        users_info="No users currently logged in"
    fi
    
    echo "$users_info"
}

# Function to get failed login attempts on Linux
get_failed_logins() {
    # Check for failed login attempts in various log files
    local failed_logins=""
    
    # Try journalctl first (systemd systems)
    if command -v journalctl &> /dev/null; then
        failed_logins=$(journalctl -u sshd --since "24 hours ago" 2>/dev/null | grep -i "failed password\|authentication failure" | tail -10 | while read -r line; do
            local timestamp=$(echo "$line" | awk '{print $1" "$2" "$3}')
            local user=$(echo "$line" | grep -oP 'user=\K[^ ]+' || echo "$line" | grep -oP 'for \K[^ ]+' || echo "unknown")
            local ip=$(echo "$line" | grep -oP 'from \K[0-9.]+' || echo "N/A")
            echo "$timestamp|$user|$ip|SSH"
        done)
    fi
    
    # Fallback to /var/log/auth.log or /var/log/secure
    if [ -z "$failed_logins" ]; then
        if [ -f /var/log/auth.log ]; then
            failed_logins=$(grep -i "failed password\|authentication failure" /var/log/auth.log 2>/dev/null | tail -10 | while read -r line; do
                local timestamp=$(echo "$line" | awk '{print $1" "$2" "$3}')
                local user=$(echo "$line" | grep -oP 'user=\K[^ ]+' || echo "$line" | grep -oP 'for \K[^ ]+' || echo "unknown")
                local ip=$(echo "$line" | grep -oP 'from \K[0-9.]+' || echo "N/A")
                echo "$timestamp|$user|$ip|SSH"
            done)
        elif [ -f /var/log/secure ]; then
            failed_logins=$(grep -i "failed password\|authentication failure" /var/log/secure 2>/dev/null | tail -10 | while read -r line; do
                local timestamp=$(echo "$line" | awk '{print $1" "$2" "$3}')
                local user=$(echo "$line" | grep -oP 'user=\K[^ ]+' || echo "$line" | grep -oP 'for \K[^ ]+' || echo "unknown")
                local ip=$(echo "$line" | grep -oP 'from \K[0-9.]+' || echo "N/A")
                echo "$timestamp|$user|$ip|SSH"
            done)
        fi
    fi
    
    # If still no data, return a message
    if [ -z "$failed_logins" ]; then
        failed_logins="No failed login attempts in the last 24 hours or insufficient permissions to read logs"
    fi
    
    echo "$failed_logins"
}


# Get OS version information
IFS='|' read -r OS_NAME OS_VERSION KERNEL_VERSION OS_ARCH <<< "$(get_os_version)"

# Get system uptime
IFS='|' read -r UPTIME_DAYS UPTIME_HOURS UPTIME_MINUTES UPTIME_SECONDS <<< "$(get_system_uptime)"

# Get load average
IFS='|' read -r LOAD_1MIN LOAD_5MIN LOAD_15MIN CPU_COUNT <<< "$(get_load_average)"

# Get and display total CPU usage
total_cpu=$(get_total_cpu_usage)

# Get memory usage statistics
IFS='|' read -r TOTAL_MEM USED_MEM USED_PERCENT FREE_MEM FREE_PERCENT <<< "$(get_memory_usage)"

# Get disk usage statistics
DISK_OUTPUT=$(get_disk_usage)

# Get top CPU processes
TOP_CPU_PROCESSES=$(get_top_cpu_processes)

# Get top Memory processes
TOP_MEMORY_PROCESSES=$(get_top_memory_processes)

# Get logged in users
LOGGED_IN_USERS=$(get_logged_in_users)

# Get failed login attempts
FAILED_LOGINS=$(get_failed_logins)

# Parse individual disk information
INDIVIDUAL_DISKS=()
CAPTURE=false

while IFS= read -r line; do
    if [[ "$line" == "INDIVIDUAL_DISKS_START" ]]; then
        CAPTURE=true
        continue
    elif [[ "$line" == "INDIVIDUAL_DISKS_END" ]]; then
        CAPTURE=false
        continue
    elif [[ "$line" == TOTAL\|* ]]; then
        IFS='|' read -r _ TOTAL_DISK USED_DISK USED_DISK_PERCENT FREE_DISK FREE_DISK_PERCENT <<< "$line"
        continue
    fi
    
    if [ "$CAPTURE" = true ] && [ -n "$line" ]; then
        INDIVIDUAL_DISKS+=("$line")
    fi
done <<< "$DISK_OUTPUT"

# Display the results
echo "Operating System Information:"
echo "-----------------------------"
echo "OS Name:       $OS_NAME"
echo "OS Version:    $OS_VERSION"
echo "Kernel:        $KERNEL_VERSION"
echo "Architecture:  $OS_ARCH"
echo "Uptime:        ${UPTIME_DAYS}d ${UPTIME_HOURS}h ${UPTIME_MINUTES}m ${UPTIME_SECONDS}s"
echo ""
echo "System Load Average:"
echo "  1 min:  $LOAD_1MIN"
echo "  5 min:  $LOAD_5MIN"
echo "  15 min: $LOAD_15MIN"
echo "  (CPU cores: $CPU_COUNT)"
echo ""
echo "Total CPU Usage: $total_cpu%"
echo ""
echo "Memory Usage Report (in MB):"
echo "---------------------------"
echo "Total Memory: $TOTAL_MEM MB"
echo "Used Memory:  $USED_MEM MB ($USED_PERCENT%)"
echo "Free Memory:  $FREE_MEM MB ($FREE_PERCENT%)"
echo ""
echo "Disk Usage Report (in GB):"
echo "---------------------------"

# Display individual disk information
for disk_info in "${INDIVIDUAL_DISKS[@]}"; do
    IFS='|' read -r MOUNT_POINT DRIVE_SIZE DRIVE_USED DRIVE_USED_PERCENT DRIVE_FREE DRIVE_FREE_PERCENT <<< "$disk_info"
    echo "Mount Point: $MOUNT_POINT"
    echo "  Total:  $DRIVE_SIZE GB"
    echo "  Used:   $DRIVE_USED GB ($DRIVE_USED_PERCENT%)"
    echo "  Free:   $DRIVE_FREE GB ($DRIVE_FREE_PERCENT%)"
    echo ""
done

# Display total disk statistics
echo "Total Disk Statistics:"
echo "  Total:  $TOTAL_DISK GB"
echo "  Used:   $USED_DISK GB ($USED_DISK_PERCENT%)"
echo "  Free:   $FREE_DISK GB ($FREE_DISK_PERCENT%)"
echo ""
echo "Top 5 Processes by CPU Usage:"
echo "------------------------------"
printf "%-30s %-10s %-15s\n" "Process Name" "PID" "CPU %"
echo "-----------------------------------------------------------"

# Display top CPU processes
if [ -n "$TOP_CPU_PROCESSES" ]; then
    while IFS='|' read -r PROC_NAME PROC_PID PROC_CPU; do
        if [ -n "$PROC_NAME" ]; then
            printf "%-30s %-10s %-15s\n" "$PROC_NAME" "$PROC_PID" "$PROC_CPU"
        fi
    done <<< "$TOP_CPU_PROCESSES"
else
    echo "No process data available"
fi
echo ""
echo "Top 5 Processes by Memory Usage:"
echo "---------------------------------"
printf "%-30s %-10s %-15s\n" "Process Name" "PID" "Memory (MB)"
echo "-----------------------------------------------------------"

# Display top Memory processes
if [ -n "$TOP_MEMORY_PROCESSES" ]; then
    while IFS='|' read -r PROC_NAME PROC_PID PROC_MEM; do
        if [ -n "$PROC_NAME" ]; then
            printf "%-30s %-10s %-15s\n" "$PROC_NAME" "$PROC_PID" "$PROC_MEM"
        fi
    done <<< "$TOP_MEMORY_PROCESSES"
else
    echo "No process data available"
fi
echo ""
echo "Logged In Users:"
echo "----------------"
if [[ "$LOGGED_IN_USERS" == "No users currently logged in" ]]; then
    echo "$LOGGED_IN_USERS"
else
    printf "%-20s %-15s %-10s %-15s %-25s\n" "Username" "Terminal" "State" "Idle" "Login Time"
    echo "-------------------------------------------------------------------------------------"
    while IFS='|' read -r USERNAME TERMINAL STATE IDLE_TIME LOGON_TIME; do
        if [ -n "$USERNAME" ]; then
            printf "%-20s %-15s %-10s %-15s %-25s\n" "$USERNAME" "$TERMINAL" "$STATE" "$IDLE_TIME" "$LOGON_TIME"
        fi
    done <<< "$LOGGED_IN_USERS"
fi
echo ""
echo "Failed Login Attempts (Last 24 Hours):"
echo "--------------------------------------"
if [[ "$FAILED_LOGINS" == "No failed login attempts"* ]] || 
   [[ "$FAILED_LOGINS" == "Unable to"* ]]; then
    echo "$FAILED_LOGINS"
else
    printf "%-20s %-25s %-20s %-10s\n" "Time" "User" "IP Address" "Type"
    echo "-------------------------------------------------------------------------------"
    while IFS='|' read -r TIME USER IP_ADDR LOGON_TYPE; do
        if [ -n "$TIME" ]; then
            printf "%-20s %-25s %-20s %-10s\n" "$TIME" "$USER" "$IP_ADDR" "$LOGON_TYPE"
        fi
    done <<< "$FAILED_LOGINS"
fi





