# Agent Guidelines for NWN Log Rotator

## Commands
- **Lint**: `shellcheck nwnlogrotator.sh`
- **Test single run**: `./nwnlogrotator.sh` (ensure test log files exist in source dir)
- **Format**: No formatter configured, maintain 4-space indentation manually

## Code Style
- **Language**: Bash/shell scripting
- **Variables**: UPPER_CASE for config/constants, lower_case for locals
- **Indentation**: 4 spaces consistently
- **Error Handling**: Check command success with `if ! command; then`, log errors, use `continue` for skips
- **Comments**: Section headers with `# --------------`, minimal inline comments
- **Safety**: Never overwrite files, validate inputs, comprehensive logging
- **Tools**: Use standard Unix tools (date, mkdir, cp, rm, grep, awk, sed, notify-send)

## Project Structure
- Single script `nwnlogrotator.sh` with config at top
- Logs operations to `nwnlogrotator_operations.log`
- Creates dated directory structure: `Year/MonthNum-MonthName/DayNum-DayName/`
- No external dependencies beyond standard Unix tools