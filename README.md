# Server Performance Stats Analysis Script

A simple but powerful Bash script collection to analyze and report server performance statistics for both **Linux** and **Windows** systems. This tool provides a quick snapshot of system health, resource usage, and running processes, making it easier for sysadmins and developers to debug performance issues across different platforms.

## Project URL: https://roadmap.sh/projects/server-stats

## 🚀 Features

This repository contains two scripts tailored for different operating systems:

### 📊 Core Requirements

- ✅ **Total CPU Usage** - Calculates the current CPU load percentage
- ✅ **Memory Usage** - Display total, used, and free memory with percentage calculations
- ✅ **Disk Usage** - Displays total, used, and free disk space with percentage calculations
- ✅ **Top 5 Processes by CPU** - Identifies which processes are consuming the most processing power
- ✅ **Top 5 Processes by Memory** - Identifies which processes are consuming the most RAM

### 🎯 Extra Stats (Stretch Goals)

- 🔹 **OS Version** - Displays the Linux distribution and version
- 🔹 **Uptime** - Shows how long the server has been running
- 🔹 **Load Average** - Displays the system load averages for the last 1, 5, and 15 minutes
- 🔹 **Logged-in Users** - Lists currently active user sessions
- 🔹 **Failed Login Attempts** - Checks logs for failed authentication attempts (requires sudo/root access for full accuracy)

### 📁 Script Files

#### 1. **Linux Script** (`script/Linux/server-stats.sh`)
A comprehensive bash script for Linux systems that provides detailed performance metrics.

**Functions:**
- `get_total_cpu_usage()` - Calculates CPU usage by sampling `/proc/stat`
- `get_memory_usage()` - Parses `/proc/meminfo` for memory statistics
- `get_disk_usage()` - Uses `df` command to retrieve disk usage for all mounted filesystems
- `get_top_cpu_processes()` - Lists top 5 processes by CPU usage using `ps`
- `get_top_memory_processes()` - Lists top 5 processes by memory usage
- `get_os_version()` - Extracts OS information from `/etc/os-release` or `lsb_release`
- `get_system_uptime()` - Reads uptime from `/proc/uptime`
- `get_load_average()` - Retrieves system load averages from `/proc/loadavg`
- `get_logged_in_users()` - Uses `who` command to list active user sessions
- `get_failed_logins()` - Checks `journalctl` or log files for failed authentication attempts

#### 2. **Windows Script** (`script/windows/windows-server-stats.sh`)
A bash script designed to run on Windows systems (via Git Bash, WSL, or Cygwin) using PowerShell and WMIC commands.

**Functions:**
- `get_total_cpu_usage()` - Uses PowerShell `Get-Counter` or WMIC to calculate CPU load
- `get_memory_usage()` - Retrieves memory stats via `Win32_OperatingSystem` CIM instance
- `get_disk_usage()` - Uses PowerShell `Get-PSDrive` to get disk statistics for all drives
- `get_top_cpu_processes()` - Lists top 5 processes by CPU time using `Get-Process`
- `get_top_memory_processes()` - Lists top 5 processes by memory (WorkingSet) usage
- `get_os_version()` - Retrieves Windows OS version and build information
- `get_system_uptime()` - Calculates uptime from last boot time
- `get_load_average()` - Approximates load average using processor queue length (Windows doesn't have native load average)
- `get_logged_in_users()` - Uses `query user` command to list active sessions
- `get_failed_logins()` - Queries Security event log for Event ID 4625 (requires admin privileges)

### 📊 Metrics Displayed

Both scripts provide the following information:

#### Core Metrics
- **Total CPU Usage**: Current CPU load percentage
- **Memory Usage**: Total, used, and free memory with percentage calculations
- **Disk Usage**: Total, used, and free disk space with percentage calculations (per drive and total)
- **Top 5 Processes by CPU**: Processes consuming the most processing power
- **Top 5 Processes by Memory**: Processes consuming the most RAM

#### Additional Statistics
- **OS Version**: Operating system distribution/edition and version
- **Uptime**: How long the server has been running
- **Load Average**: System load averages (Linux: actual load; Windows: approximated)
- **Logged-in Users**: Currently active user sessions
- **Failed Login Attempts**: Recent failed authentication attempts (last 24 hours)

## 📋 Prerequisites

### For Linux Script (`server-stats.sh`)
- A Linux-based operating system (Ubuntu, CentOS, Debian, etc.)
- Bash shell (standard on almost all Linux distros)
- Standard Linux utilities: `ps`, `df`, `grep`, `awk` (pre-installed on most systems)
- Optional: `sudo` access for failed login attempt analysis

### For Windows Script (`windows-server-stats.sh`)
- Windows operating system (Windows 7/Server 2008 or later)
- Bash environment: Git Bash, WSL (Windows Subsystem for Linux), or Cygwin
- PowerShell (version 3.0 or later recommended)
- WMIC (Windows Management Instrumentation Command-line) - available by default on Windows
- Optional: Administrator privileges for failed login attempt analysis

## 🛠️ Installation & Usage

### Linux Systems

1. **Clone the repository:**

   ```bash
   git clone https://github.com/YevinMawathage/Server-Performance-Stats-Script.git
   cd Server-Performance-Stats-Script/script/Linux
   ```

2. **Make the script executable:**

   ```bash
   chmod +x server-stats.sh
   ```

3. **Run the script:**

   ```bash
   ./server-stats.sh
   ```

   > **Note**: Some stats, like failed login attempts, may require sudo to read log files.

   ```bash
   sudo ./server-stats.sh
   ```

### Windows Systems

1. **Clone the repository:**

   ```bash
   git clone https://github.com/YevinMawathage/Server-Performance-Stats-Script.git
   cd Server-Performance-Stats-Script/script/windows
   ```

2. **Make the script executable:**

   ```bash
   chmod +x windows-server-stats.sh
   ```

3. **Run the script:**

   Open Git Bash, WSL, or Cygwin terminal and run:

   ```bash
   ./windows-server-stats.sh
   ```

   > **Note**: For failed login attempt analysis, run as Administrator:
   > - Right-click Git Bash/terminal and select "Run as administrator"
   > - Then execute the script

## 📝 Sample Output

### Linux Sample Output
```
Operating System Information:
-----------------------------
OS Name:       Ubuntu 22.04.3 LTS
OS Version:    22.04
Kernel:        5.15.0-91-generic
Architecture:  x86_64
Uptime:        5d 12h 30m 45s

System Load Average:
  1 min:  0.45
  5 min:  0.52
  15 min: 0.48
  (CPU cores: 4)

Total CPU Usage: 12.5%

Memory Usage Report (in MB):
---------------------------
Total Memory: 16384 MB
Used Memory:  4096 MB (25.00%)
Free Memory:  12288 MB (75.00%)

Disk Usage Report (in GB):
---------------------------
Mount Point: /
  Total:  100 GB
  Used:   25 GB (25.00%)
  Free:   75 GB (75.00%)

Top 5 Processes by CPU Usage:
------------------------------
Process Name                   PID        CPU %
-----------------------------------------------------------
python3                        1234       5.5
...
```

### Windows Sample Output
```
Operating System Information:
-----------------------------
OS Name:       Microsoft Windows 11 Pro
OS Version:    10.0.22631 (Build 22631)
Architecture:  64-bit
Uptime:        3d 8h 15m 22s

System Load Average:
  1 min:  1.25
  5 min:  1.25
  15 min: 1.25
  (CPU cores: 8)

Total CPU Usage: 15.75%

Memory Usage Report (in MB):
---------------------------
Total Memory: 32768 MB
Used Memory:  16384 MB (50.00%)
Free Memory:  16384 MB (50.00%)

Disk Usage Report (in GB):
---------------------------
Drive C:
  Total:  476.89 GB
  Used:   245.32 GB (51.43%)
  Free:   231.57 GB (48.57%)

Top 5 Processes by CPU Usage:
------------------------------
Process Name                   PID        CPU Time (s)
-----------------------------------------------------------
chrome                         5678       1250.50
...
```

## 🤝 Contributing

Contributions are welcome! Feel free to fork this repository and submit pull requests to add more metrics or improve the calculation logic.

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 👨‍💻 Author

**Yevin Mawathage**
- GitHub: [@YevinMawathage](https://github.com/YevinMawathage)