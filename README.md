# Server Performance Stats Analysis Script

A simple but powerful Bash script to analyze and report basic Linux server performance statistics. This tool provides a quick snapshot of system health, resource usage, and running processes, making it easier for sysadmins and developers to debug performance issues.

## Project URL: https://roadmap.sh/projects/server-stats

## 🚀 Features

The `server-stats.sh` script calculates and displays the following metrics:

### Core Requirements

- **Total CPU Usage**: Calculates the current CPU load percentage
- **Memory Usage**: Display total, used, and free memory with percentage calculations
- **Disk Usage**: Displays total, used, and free disk space with percentage calculations
- **Top 5 Processes by CPU**: Identifies which processes are consuming the most processing power
- **Top 5 Processes by Memory**: Identifies which processes are consuming the most RAM

### Extra Stats (Stretch Goals)

- **OS Version**: Displays the Linux distribution and version
- **Uptime**: Shows how long the server has been running
- **Load Average**: Displays the system load averages for the last 1, 5, and 15 minutes
- **Logged-in Users**: Lists currently active user sessions
- **Failed Login Attempts**: Checks logs for failed authentication attempts (requires sudo/root access for full accuracy)

## 📋 Prerequisites

- A Linux-based operating system (Ubuntu, CentOS, Debian, etc.)
- Bash shell (standard on almost all Linux distros)
- `sysstat` package (optional but recommended for advanced CPU stats, though this script uses standard `top`/`vmstat` logic to remain dependency-free where possible)

## 🛠️ Installation & Usage

1. **Clone the repository:**

   ```bash
   git clone https://github.com/YevinMawathage/Server-Performance-Stats-Script.git
   cd Server-Performance-Stats-Script
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

## 📝 Sample Output

```
-------------------------------------
SERVER PERFORMANCE ANALYSIS
-------------------------------------
Date: Tue Nov 18 14:30:00 UTC 2025
-------------------------------------

Total CPU Usage: 12.5%

Total Memory Usage:
Used: 4096MB / Total: 16384MB (25.00%)
Free: 12288MB

Total Disk Usage:
Used: 25GB / Total: 100GB (25.00%)
Free: 75GB

Top 5 Processes by CPU:
PID    USER   %CPU   COMMAND
1234   root   5.5    python3
...

Top 5 Processes by Memory:
PID    USER   %MEM   COMMAND
5678   www    12.2   java
...
-------------------------------------
```

## 🤝 Contributing

Contributions are welcome! Feel free to fork this repository and submit pull requests to add more metrics or improve the calculation logic.

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 👨‍💻 Author

**Yevin Mawathage**
- GitHub: [@YevinMawathage](https://github.com/YevinMawathage)