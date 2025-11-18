#!/bin/bash

chmod +x windows-server-stats.sh

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

# Function to get OS version on Windows
get_os_version() {
    # Use PowerShell to get detailed OS information
    local os_info=$(powershell.exe -Command "
        \$os = Get-CimInstance Win32_OperatingSystem;
        \$caption = \$os.Caption;
        \$version = \$os.Version;
        \$buildNumber = \$os.BuildNumber;
        \$architecture = \$os.OSArchitecture;
        Write-Output \"\$caption|\$version|\$buildNumber|\$architecture\"
    " 2>/dev/null | tr -d '\r\n')
    
    # Fallback to WMIC if PowerShell fails
    if [ -z "$os_info" ] || [ "$os_info" == "" ]; then
        local caption=$(wmic os get Caption /value 2>/dev/null | grep '=' | cut -d'=' -f2 | tr -d '\r\n ')
        local version=$(wmic os get Version /value 2>/dev/null | grep '=' | cut -d'=' -f2 | tr -d '\r\n ')
        local architecture=$(wmic os get OSArchitecture /value 2>/dev/null | grep '=' | cut -d'=' -f2 | tr -d '\r\n ')
        os_info="$caption|$version||$architecture"
    fi
    
    echo "$os_info"
}

# Function to get system uptime on Windows
get_system_uptime() {
    # Use PowerShell to calculate uptime
    local uptime_info=$(powershell.exe -Command "
        \$os = Get-CimInstance Win32_OperatingSystem;
        \$bootTime = \$os.LastBootUpTime;
        \$currentTime = Get-Date;
        \$uptime = \$currentTime - \$bootTime;
        
        \$days = \$uptime.Days;
        \$hours = \$uptime.Hours;
        \$minutes = \$uptime.Minutes;
        \$seconds = \$uptime.Seconds;
        
        Write-Output \"\$days|\$hours|\$minutes|\$seconds\"
    " 2>/dev/null | tr -d '\r\n')
    
    # Fallback to WMIC if PowerShell fails
    if [ -z "$uptime_info" ] || [ "$uptime_info" == "" ]; then
        local boot_time=$(wmic os get LastBootUpTime /value 2>/dev/null | grep '=' | cut -d'=' -f2 | tr -d '\r\n ' | cut -c1-14)
        
        if [ -n "$boot_time" ]; then
            # Convert WMI datetime format (YYYYMMDDHHmmss) to epoch
            local boot_year=${boot_time:0:4}
            local boot_month=${boot_time:4:2}
            local boot_day=${boot_time:6:2}
            local boot_hour=${boot_time:8:2}
            local boot_min=${boot_time:10:2}
            local boot_sec=${boot_time:12:2}
            
            # Calculate uptime in seconds (simplified fallback)
            local current_epoch=$(date +%s)
            local boot_epoch=$(date -d "$boot_year-$boot_month-$boot_day $boot_hour:$boot_min:$boot_sec" +%s 2>/dev/null || echo "0")
            
            if [ "$boot_epoch" -gt 0 ]; then
                local uptime_seconds=$((current_epoch - boot_epoch))
                local days=$((uptime_seconds / 86400))
                local hours=$(((uptime_seconds % 86400) / 3600))
                local minutes=$(((uptime_seconds % 3600) / 60))
                local seconds=$((uptime_seconds % 60))
                uptime_info="$days|$hours|$minutes|$seconds"
            else
                uptime_info="0|0|0|0"
            fi
        else
            uptime_info="0|0|0|0"
        fi
    fi
    
    echo "$uptime_info"
}

# Function to get system load average on Windows
get_load_average() {
    # Windows doesn't have a direct load average like Linux
    # We'll calculate an approximation using processor queue length and CPU usage
    local load_info=$(powershell.exe -Command "
        # Get processor queue length (similar to load average)
        \$queueLength = (Get-Counter '\\System\\Processor Queue Length').CounterSamples.CookedValue;
        
        # Get number of logical processors
        \$cpuCount = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors;
        
        # Get current CPU usage
        \$cpuUsage = (Get-Counter '\\Processor(_Total)\\% Processor Time').CounterSamples.CookedValue;
        
        # Calculate load (queue length + (CPU usage / 100) * CPU count)
        \$load1min = [math]::Round(\$queueLength + ((\$cpuUsage / 100) * \$cpuCount), 2);
        
        # For 5 and 15 min averages, we'll use the same value (Windows doesn't track historical)
        # In a production script, you'd need to store historical data
        \$load5min = \$load1min;
        \$load15min = \$load1min;
        
        Write-Output \"\$load1min|\$load5min|\$load15min|\$cpuCount\"
    " 2>/dev/null | tr -d '\r\n' | sed 's/,/./g')
    
    # Fallback if PowerShell fails
    if [ -z "$load_info" ] || [ "$load_info" == "" ]; then
        # Simple fallback using CPU percentage
        local cpu_percent=$(wmic cpu get loadpercentage 2>/dev/null | grep -E '^[0-9]+' | head -1 | tr -d '\r\n ')
        local cpu_count=$(wmic cpu get NumberOfLogicalProcessors 2>/dev/null | grep -E '^[0-9]+' | head -1 | tr -d '\r\n ')
        
        if [ -n "$cpu_percent" ] && [ -n "$cpu_count" ]; then
            local load=$(awk "BEGIN {printf \"%.2f\", ($cpu_percent / 100) * $cpu_count}" 2>/dev/null || echo "0.00")
            load_info="$load|$load|$load|$cpu_count"
        else
            load_info="0.00|0.00|0.00|1"
        fi
    fi
    
    echo "$load_info"
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
        
        Write-Output "TOTAL|\$totalSizeGB|\$totalUsedGB|\$usedPercent|\$totalFreeGB|\$freePercent";
    " 2>/dev/null | tr -d '\r' | sed 's/,/./g'
}

# Function to get currently logged in users on Windows
get_logged_in_users() {
    # Use PowerShell to get logged in users with session information
    local users_info=$(powershell.exe -Command "
        \$sessions = query user 2>\$null;
        if (\$sessions) {
            \$sessions | Select-Object -Skip 1 | ForEach-Object {
                \$line = \$_.Trim() -replace '\s+', '|';
                if (\$line -match '^>') {
                    \$line = \$line -replace '^>', '';
                }
                Write-Output \$line;
            }
        } else {
            # Fallback: Get users from Win32_LogonSession
            \$loggedUsers = Get-CimInstance Win32_LoggedOnUser | 
                Select-Object -Unique Antecedent | 
                ForEach-Object {
                    \$user = \$_.Antecedent;
                    if (\$user.Domain -and \$user.Name) {
                        Write-Output \"\$((\$user.Domain))\\\$((\$user.Name))|Console|Active|N/A|N/A\";
                    }
                }
            \$loggedUsers | Select-Object -Unique;
        }
    " 2>/dev/null | tr -d '\r')
    
    # Fallback to quser command if PowerShell fails
    if [ -z "$users_info" ] || [ "$users_info" == "" ]; then
        users_info=$(quser 2>/dev/null | tail -n +2 | awk '{print $1"|"$2"|"$3"|"$4"|"$5}' | tr -d '\r')
    fi
    
    # If still no data, return a message
    if [ -z "$users_info" ] || [ "$users_info" == "" ]; then
        users_info="No users currently logged in"
    fi
    
    echo "$users_info"
}

# Function to get failed login attempts on Windows
get_failed_logins() {
    # Use PowerShell to query Security event log for failed login attempts (Event ID 4625)
    # This requires administrator privileges
    local failed_logins=$(powershell.exe -Command "
        try {
            \$startTime = (Get-Date).AddHours(-24);
            \$events = Get-WinEvent -FilterHashtable @{
                LogName='Security';
                ID=4625;
                StartTime=\$startTime
            } -MaxEvents 10 -ErrorAction SilentlyContinue | 
            ForEach-Object {
                \$event = [xml]\$_.ToXml();
                \$username = \$event.Event.EventData.Data | Where-Object {\$_.Name -eq 'TargetUserName'} | Select-Object -ExpandProperty '#text';
                \$domain = \$event.Event.EventData.Data | Where-Object {\$_.Name -eq 'TargetDomainName'} | Select-Object -ExpandProperty '#text';
                \$ipAddress = \$event.Event.EventData.Data | Where-Object {\$_.Name -eq 'IpAddress'} | Select-Object -ExpandProperty '#text';
                \$time = \$_.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss');
                \$logonType = \$event.Event.EventData.Data | Where-Object {\$_.Name -eq 'LogonType'} | Select-Object -ExpandProperty '#text';
                
                if (\$username -and \$username -ne '-' -and \$username -notmatch '^\$') {
                    Write-Output \"\$time|\$domain\\\$username|\$ipAddress|\$logonType\";
                }
            }
            
            if (-not \$events) {
                Write-Output 'No failed login attempts in the last 24 hours';
            }
        } catch {
            Write-Output 'Unable to access Security event log (requires admin privileges)';
        }
    " 2>/dev/null | tr -d '\r')
    
    # If no data or error, provide a message
    if [ -z "$failed_logins" ] || [ "$failed_logins" == "" ]; then
        failed_logins="Unable to retrieve failed login data (requires administrator privileges)"
    fi
    
    echo "$failed_logins"
}

# Get OS version information
IFS='|' read -r OS_CAPTION OS_VERSION OS_BUILD OS_ARCH <<< "$(get_os_version)"

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
echo "OS Name:       $OS_CAPTION"
if [ -n "$OS_BUILD" ] && [ "$OS_BUILD" != "" ]; then
    echo "OS Version:    $OS_VERSION (Build $OS_BUILD)"
else
    echo "OS Version:    $OS_VERSION"
fi
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
echo ""
echo "Logged In Users:"
echo "----------------"
if [[ "$LOGGED_IN_USERS" == "No users currently logged in" ]]; then
    echo "$LOGGED_IN_USERS"
else
    printf "%-20s %-15s %-10s %-15s %-15s\n" "Username" "Session" "State" "Idle Time" "Logon Time"
    echo "-------------------------------------------------------------------------------"
    while IFS='|' read -r USERNAME SESSION_NAME STATE IDLE_TIME LOGON_TIME; do
        if [ -n "$USERNAME" ]; then
            printf "%-20s %-15s %-10s %-15s %-15s\n" "$USERNAME" "$SESSION_NAME" "$STATE" "$IDLE_TIME" "$LOGON_TIME"
        fi
    done <<< "$LOGGED_IN_USERS"
fi
echo ""
echo "Failed Login Attempts (Last 24 Hours):"
echo "--------------------------------------"
if [[ "$FAILED_LOGINS" == "No failed login attempts in the last 24 hours" ]] || 
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




