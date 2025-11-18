#!/bin/bash

chmod +x server-stats.sh

# Function to get total CPU usage on Windows
get_total_cpu_usage() {
    # Use PowerShell to get CPU usage via WMI
    # We take two samples 1 second apart to calculate actual CPU usage
    local cpu_usage=$(powershell.exe -Command "
        \$cpu1 = Get-Counter '\\Processor(_Total)\\% Processor Time' -SampleInterval 1 -MaxSamples 2 | 
                 Select-Object -ExpandProperty CounterSamples | 
                 Select-Object -Last 1 -ExpandProperty CookedValue;
        [math]::Round(\$cpu1, 2)
    " 2>/dev/null | tr -d '\r\n' | sed 's/,/./')
    
    # Fallback to WMIC if PowerShell fails
    if [ -z "$cpu_usage" ] || [ "$cpu_usage" == "" ]; then
        cpu_usage=$(wmic cpu get loadpercentage 2>/dev/null | grep -E '^[0-9]+' | head -1 | tr -d '\r\n ')
        if [ -n "$cpu_usage" ]; then
            cpu_usage="${cpu_usage}.00"
        else
            cpu_usage="0.00"
        fi
    fi
    
    echo "$cpu_usage"
}

# Function to get memory usage statistics on Windows
get_memory_usage() {
    # Use PowerShell to get accurate memory statistics
    local mem_stats=$(powershell.exe -Command "
        \$os = Get-CimInstance Win32_OperatingSystem;
        \$totalMB = [math]::Round(\$os.TotalVisibleMemorySize / 1024);
        \$freeMB = [math]::Round(\$os.FreePhysicalMemory / 1024);
        \$usedMB = \$totalMB - \$freeMB;
        \$usedPercent = [math]::Round((\$usedMB / \$totalMB) * 100, 2);
        \$freePercent = [math]::Round((\$freeMB / \$totalMB) * 100, 2);
        Write-Output \"\$totalMB|\$usedMB|\$usedPercent|\$freeMB|\$freePercent\"
    " 2>/dev/null | tr -d '\r\n' | sed 's/,/./g')
    
    # Fallback to WMIC if PowerShell fails
    if [ -z "$mem_stats" ] || [ "$mem_stats" == "" ]; then
        local TOTAL_MEM_BYTES=$(wmic ComputerSystem get TotalPhysicalMemory /value 2>/dev/null | grep '=' | cut -d'=' -f2 | tr -d '\r\n ')
        local FREE_MEM_KB=$(wmic OS get FreePhysicalMemory /value 2>/dev/null | grep '=' | cut -d'=' -f2 | tr -d '\r\n ')
        
        if [ -n "$TOTAL_MEM_BYTES" ] && [ -n "$FREE_MEM_KB" ]; then
            local TOTAL_MEM=$((TOTAL_MEM_BYTES / 1024 / 1024))
            local FREE_MEM=$((FREE_MEM_KB / 1024))
            local USED_MEM=$((TOTAL_MEM - FREE_MEM))
            
            if [ "$TOTAL_MEM" -gt 0 ]; then
                local USED_PERCENT=$(awk "BEGIN {printf \"%.2f\", ($USED_MEM / $TOTAL_MEM) * 100}" 2>/dev/null || echo "0.00")
                local FREE_PERCENT=$(awk "BEGIN {printf \"%.2f\", ($FREE_MEM / $TOTAL_MEM) * 100}" 2>/dev/null || echo "0.00")
            else
                local USED_PERCENT="0.00"
                local FREE_PERCENT="0.00"
            fi
            
            mem_stats="$TOTAL_MEM|$USED_MEM|$USED_PERCENT|$FREE_MEM|$FREE_PERCENT"
        else
            mem_stats="0|0|0.00|0|0.00"
        fi
    fi
    
    echo "$mem_stats"
}

# Function to get top 5 processes by CPU usage on Windows
get_top_cpu_processes() {
    # Use PowerShell to get top 5 processes by CPU usage
    powershell.exe -Command "
        Get-Process | 
        Where-Object { \$_.CPU -ne \$null } | 
        Sort-Object CPU -Descending | 
        Select-Object -First 5 | 
        ForEach-Object {
            \$name = \$_.ProcessName;
            \$cpu = [math]::Round(\$_.CPU, 2);
            \$pid = \$_.Id;
            Write-Output \"\$name|\$pid|\$cpu\"
        }
    " 2>/dev/null | tr -d '\r' | sed 's/,/./g'
}

# Function to get top 5 processes by Memory usage on Windows
get_top_memory_processes() {
    # Use PowerShell to get top 5 processes by memory usage
    powershell.exe -Command "
        Get-Process | 
        Where-Object { \$_.WorkingSet -ne \$null } | 
        Sort-Object WorkingSet -Descending | 
        Select-Object -First 5 | 
        ForEach-Object {
            \$name = \$_.ProcessName;
            \$memoryMB = [math]::Round(\$_.WorkingSet / 1MB, 2);
            \$pid = \$_.Id;
            Write-Output \"\$name|\$pid|\$memoryMB\"
        }
    " 2>/dev/null | tr -d '\r' | sed 's/,/./g'
}

# Function to get disk usage statistics for all disks on Windows
get_disk_usage() {
    # Use PowerShell to get disk statistics for all local drives
    powershell.exe -Command "
        \$drives = Get-PSDrive -PSProvider FileSystem | Where-Object { \$_.Used -ne \$null };
        \$totalSize = 0;
        \$totalUsed = 0;
        \$totalFree = 0;
        
        Write-Output 'INDIVIDUAL_DISKS_START';
        
        foreach (\$drive in \$drives) {
            \$driveSize = \$drive.Used + \$drive.Free;
            \$driveUsed = \$drive.Used;
            \$driveFree = \$drive.Free;
            
            \$driveSizeGB = [math]::Round(\$driveSize / 1GB, 2);
            \$driveUsedGB = [math]::Round(\$driveUsed / 1GB, 2);
            \$driveFreeGB = [math]::Round(\$driveFree / 1GB, 2);
            
            if (\$driveSizeGB -gt 0) {
                \$driveUsedPercent = [math]::Round((\$driveUsedGB / \$driveSizeGB) * 100, 2);
                \$driveFreePercent = [math]::Round((\$driveFreeGB / \$driveSizeGB) * 100, 2);
            } else {
                \$driveUsedPercent = 0;
                \$driveFreePercent = 0;
            }
            
            Write-Output \"\$(\$drive.Name)|\$driveSizeGB|\$driveUsedGB|\$driveUsedPercent|\$driveFreeGB|\$driveFreePercent\";
            
            \$totalSize += \$driveSize;
            \$totalUsed += \$driveUsed;
            \$totalFree += \$driveFree;
        }
        
        Write-Output 'INDIVIDUAL_DISKS_END';
        
        \$totalSizeGB = [math]::Round(\$totalSize / 1GB, 2);
        \$totalUsedGB = [math]::Round(\$totalUsed / 1GB, 2);
        \$totalFreeGB = [math]::Round(\$totalFree / 1GB, 2);
        
        if (\$totalSizeGB -gt 0) {
            \$usedPercent = [math]::Round((\$totalUsedGB / \$totalSizeGB) * 100, 2);
            \$freePercent = [math]::Round((\$totalFreeGB / \$totalSizeGB) * 100, 2);
        } else {
            \$usedPercent = 0;
            \$freePercent = 0;
        }
        
        Write-Output \"TOTAL|\$totalSizeGB|\$totalUsedGB|\$usedPercent|\$totalFreeGB|\$freePercent\";
    " 2>/dev/null | tr -d '\r' | sed 's/,/./g'
}

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
    IFS='|' read -r DRIVE_NAME DRIVE_SIZE DRIVE_USED DRIVE_USED_PERCENT DRIVE_FREE DRIVE_FREE_PERCENT <<< "$disk_info"
    echo "Drive $DRIVE_NAME:"
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
printf "%-30s %-10s %-15s\n" "Process Name" "PID" "CPU Time (s)"
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




