Server Performance Stats Analysis Script

A simple but powerful Bash script to analyse and report basic Linux server performance statistics. This tool provides a quick snapshot of system health, resource usage, and running processes, making it easier for sysadmins and developers to debug performance issues.

🚀 Features

The server-stats.sh script calculates and displays the following metrics:

Core Requirements

Total CPU Usage: Calculates the current CPU load percentage.

Memory Usage: Display total, used, and free memory with percentage calculations.

Disk Usage: Displays total, used, and free disk space with percentage calculations.

Top 5 Processes by CPU: Identifies which processes are consuming the most processing power.

Top 5 Processes by Memory: Identifies which processes are consuming the most RAM.

Extra Stats (Stretch Goals)

OS Version: Displays the Linux distribution and version.

Uptime: Shows how long the server has been running.

Load Average: Displays the system load averages for the last 1, 5, and 15 minutes.

Logged-in Users: Lists currently active user sessions.

Failed Login Attempts: Checks logs for failed authentication attempts (requires sudo/root access for full accuracy).

📋 Prerequisites

A Linux-based operating system (Ubuntu, CentOS, Debian, etc.).

Bash shell (standard on almost all Linux distros).

sysstat package (optional but recommended for advanced CPU stats, though this script uses standard top/vmstat logic to remain dependency-free where possible).

🛠️ Installation & Usage

Clone the repository:

git clone [https://github.com/yourusername/server-stats.git](https://github.com/yourusername/server-stats.git)
cd server-stats


Make the script executable:

chmod +x server-stats.sh


Run the script:

./server-stats.sh


(Note: Some stats, like failed login attempts, may require sudo to read log files).

sudo ./server-stats.sh
