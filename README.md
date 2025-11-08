# NWN Log Rotator for Linux

A Bash script to automatically organize and archive Neverwinter Nights: Enhanced Edition (NWN:EE) client log files on Linux systems.

## Features

- **Individual File Processing**: Processes each `nwclientLog` file individually from the source directory.
- **Automatic Organization**: Creates a hierarchical directory structure based on the file's modification timestamp:
  - `Year/MonthNum-MonthName/DayNum-DayName/`
  - Example: `2025/11-November/08-Saturday/`
- **Unique Filenames**: Generates filenames like `nwclientLog_2025-11-08_143541.txt` using the file's timestamp. If a file with the same name already exists, appends an incremental number (e.g., `_2`, `_3`) to avoid overwriting.
- **Safe Operations**: 
  - Only creates directories that don't exist.
  - Never overwrites existing files.
- **Cleanup**: Removes original log files after successful copying.
- **Detailed Logging**: Logs all operations with timestamps to `nwnlogrotator_operations.log` (cleared at each run).
- **Notifications**: Sends desktop notifications for successful operations.
- **Error Handling**: Comprehensive error checking and logging for failures.

## Requirements

- Bash shell
- Standard Unix tools: `date`, `mkdir`, `cp`, `rm`, `notify-send`
- Neverwinter Nights game with log files in the default location

## Installation

1. Clone or download the repository:
   ```bash
   git clone https://github.com/yourusername/nwnlogrotator_linux.git
   cd nwnlogrotator_linux
   ```
2. Ensure the script is executable:
   ```bash
   chmod +x nwnlogrotator.sh
   ```
3. Optionally, configure the source and output directories in the script (see Configuration below).

### Setting Up for GitHub (Optional)

To version control and share your organized logs on GitHub:

1. **Option 1: Keep logs in the script directory (recommended for portability)**  
   Leave `OUT_DIR="."` (default). This keeps logs as subdirectories within the script's folder, making the entire setup self-contained and portable. You can clone the repo anywhere and run the script without additional configuration.  
   Initialize Git in the script directory:  
   ```bash
   git init
   git remote add origin https://github.com/yourusername/nwnlogrotator_linux.git
   ```

2. **Option 2: Separate logs directory**  
   Set `OUT_DIR` to a dedicated directory, e.g., `OUT_DIR="${HOME}/nwn_logs"`.  
   Initialize a Git repository in your output directory:  
   ```bash
   mkdir -p "${HOME}/nwn_logs"
   cd "${HOME}/nwn_logs"
   git init
   git remote add origin https://github.com/yourusername/nwn-logs.git
   ```

Keeping the initial folder (script directory) for GitHub enhances portability, as the entire repository—including the script, logs, and configuration—can be cloned and used on any machine without path dependencies. This is ideal for sharing or backing up your NWN logging setup.

To enable automatic git commits and pushes after each run, set `ENABLE_GIT_AUTO_COMMIT=true` in the script. This will add, commit, and push all changes to the remote repository after processing logs.

## Usage

Run the script manually or via a cron job:

```bash
./nwnlogrotator.sh
```

The script will:
1. Scan for `nwclientLog*.txt` files in the source directory.
2. For each file, extract its modification timestamp.
3. Create the appropriate dated directory structure in the output directory.
4. Copy the file with a unique timestamp-based name.
5. Remove the original file.
6. Log all actions and send notifications.

## Steam Launch Options

To automatically run the log rotator before launching NWN via Steam:

1. Right-click NWN in your Steam library and select "Properties".
2. In the "Launch Options" field, enter: `"/path/to/nwnlogrotator.sh && %command%"`
   - Replace `/path/to/nwnlogrotator.sh` with the actual path to the script.
3. If using tools like MangoHud or GameMode, place them between `&&` and `%command%`, e.g.: `"/path/to/nwnlogrotator.sh && mangohud %command%"`

This ensures the script runs before the game starts each time.

## Configuration

Edit the top of `nwnlogrotator.sh` to customize:

- `SRC_IN_DIR`: Source directory for NWN logs (default: `${HOME}/.local/share/Neverwinter Nights/logs`)
- `OUT_DIR`: Root output directory for organized logs (default: current directory `.`)
- `LOG_FILE`: Path to the operations log file (default: `./nwnlogrotator_operations.log`)
- `ENABLE_GIT_AUTO_COMMIT`: Enable automatic git commit and push after processing (default: `false`)

## Example Output Structure

```
output_directory/
├── 2025/
│   └── 11-November/
│       └── 08-Saturday/
│           ├── nwclientLog_2025-11-08_143541.txt
│           └── nwclientLog_2025-11-08_150012.txt
└── 2024/
    └── 12-December/
        └── 25-Wednesday/
            └── nwclientLog_2024-12-25_120000.txt
```

## Logging

All operations are logged (by default) to `nwnlogrotator_operations.log` with timestamps. The log is cleared at the start of each run. Check this file for detailed information on script execution, including any errors.

## Searching Logs

Once your NWN logs are organized into dated directories, you can efficiently search for specific occurrences using fuzzy finders or IDEs. This is particularly useful for tracking down particular events, errors, or gameplay moments:

- **Command-line tools**: Use `grep`, `ripgrep` (rg), or `fzf` for fast, fuzzy searches across multiple files.
- **IDEs**: Open the output directory in an IDE like VS Code, which provides powerful search and filtering capabilities with regex support.
- **Fuzzy finders**: Tools like `fzf` can help navigate and preview large numbers of log files quickly.

For example, to search for a specific player name or error message across all logs: `rg "search_term" /path/to/output_directory`

## Troubleshooting

- Ensure the source directory contains `nwclientLog*.txt` files.
- Check file permissions for reading/writing in source and output directories.
- Review the log file for error messages.
- If notifications don't appear, ensure `notify-send` is installed and configured.

## License

This project is open-source. Feel free to modify and distribute.
