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

# Get and display total CPU usage
total_cpu=$(get_total_cpu_usage)

# Get memory usage statistics
IFS='|' read -r TOTAL_MEM USED_MEM USED_PERCENT FREE_MEM FREE_PERCENT <<< "$(get_memory_usage)"















# Display the results
echo "Total CPU Usage: $total_cpu%"
echo "Memory Usage Report (in MB):"
echo "---------------------------"
echo "Total Memory: $TOTAL_MEM MB"
echo "Used Memory:  $USED_MEM MB ($USED_PERCENT%)"
echo "Free Memory:  $FREE_MEM MB ($FREE_PERCENT%)"


