#!/bin/bash
cd "$(dirname "$0")"

# ------------------------------
# Config
# ------------------------------

# The directory in which your logs will be found. The default should work.
SRC_IN_DIR="${HOME}/.local/share/Neverwinter Nights/logs"

# The directory for the output of logs.
# I personally like to keep it local to my log rotator script.
# Some other good options could be "${HOME}/Documents/nwnlogs" maybe
OUT_DIR="$(dirname "$0")"

# The log file location. Probably don't need to change this.
LOG_FILE="./nwnlogrotator_operations.log"

# Enable automatic git commit and push after processing all files (set to true to enable)
ENABLE_GIT_AUTO_COMMIT=false

# Lines containing these patterns will be removed from processed logs (editable array)
CLEANUP_PATTERNS=(
  "has left as a player"
  "has joined as a player"
  "\[Talk\]"
  "Loading Screen"
)

# ------------------------------

# Clean up the operations log
> "$LOG_FILE"

# Log script start
echo "$(date '+%Y-%m-%d %H:%M:%S'): Starting NWN log rotator script" >> "$LOG_FILE"

# Process each client log file individually
for f in "${SRC_IN_DIR}"/nwclientLog*.txt; do
  # Skip if not a file
  if [ ! -f "${f}" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Skipping non-file: ${f##*/}" >> "$LOG_FILE"
    continue
  fi

  echo "$(date '+%Y-%m-%d %H:%M:%S'): Starting processing of file: ${f##*/}" >> "$LOG_FILE"

  # Check if file has sufficient content (minimum 100 lines)
  line_count=$(wc -l < "$f")
  if [ "$line_count" -lt 100 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Skipping file ${f##*/} - only $line_count lines (minimum 100 required)" >> "$LOG_FILE"
    continue
  fi

  # Extract year from the header
  year=$(grep "Messages for:" "$f" | head -1 | sed 's/.* \([0-9]\{4\}\)$/\1/')
  if [ -z "$year" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S'): No year found in ${f##*/}, skipping" >> "$LOG_FILE"
    continue
  fi

  # Split the file by date using awk
  base="${f%.*}"
  part_count=$(LC_ALL=C awk -v year="$year" -v base="$base" '
  BEGIN { current_date = ""; file_count = 0; out_file = "" }
  {
    line = $0
    if (match(line, /\[CHAT WINDOW TEXT\] \[([^]]+)\]/, a)) {
      ts = a[1]
      split(ts, b, " ")
      date_str = b[2] " " b[3] " " year
      if (date_str != current_date) {
        if (out_file != "") close(out_file)
        file_count++
        current_date = date_str
        out_file = base "_part" file_count ".txt"
      }
    }
    if (out_file == "" && file_count == 0) {
      file_count = 1
      out_file = base "_part1.txt"
    }
    if (out_file != "") print line > out_file
  }
  END { if (out_file != "") close(out_file); print file_count }
  ' "$f")

  echo "$(date '+%Y-%m-%d %H:%M:%S'): Split ${f##*/} into $part_count parts" >> "$LOG_FILE"

  # Process each part
  for i in $(seq 1 "$part_count"); do
    part_file="${base}_part${i}.txt"

    # Clean up the part file by removing lines containing specified patterns
    if [ ${#CLEANUP_PATTERNS[@]} -gt 0 ]; then
      grep_args=""
      for pattern in "${CLEANUP_PATTERNS[@]}"; do
        grep_args="$grep_args -e '$pattern'"
      done
      cleaned_part_file="${part_file}.cleaned"
      eval "grep -v --text $grep_args '$part_file' > '$cleaned_part_file' 2>/dev/null"
      mv "$cleaned_part_file" "$part_file"
      echo "$(date '+%Y-%m-%d %H:%M:%S'): Cleaned up $part_file, removed lines matching patterns" >> "$LOG_FILE"
    fi

    # Extract first timestamp from part (before conversion)
    first_ts=$(grep -m1 "\[CHAT WINDOW TEXT\] \[" "$part_file" | sed 's/.*\[CHAT WINDOW TEXT\] \[\([^]]*\)\].*/\1/')

    # Remove "[CHAT WINDOW TEXT] " prefix from each line
    sed -i 's/^\[CHAT WINDOW TEXT\] //' "$part_file"
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Removed [CHAT WINDOW TEXT] prefix from $part_file" >> "$LOG_FILE"

    # Convert timestamps to [HH:MM:SS] format
    sed -i 's/^\[\w\+ \w\+ \+[0-9]\+ \([0-9:]\+\)\]/[\1]/' "$part_file"
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Converted timestamps to [HH:MM:SS] format in $part_file" >> "$LOG_FILE"

    # Remove duplication lines with channel tags immediately after timestamp
    temp_file="${part_file}.dup"
    grep -v '^\[[0-9][0-9]:[0-9][0-9]:[0-9][0-9]\] \[\w\+\]' "$part_file" > "$temp_file"
    mv "$temp_file" "$part_file"
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Removed duplication lines with channel tags after timestamp from $part_file" >> "$LOG_FILE"



    # Remove lines without timestamps (keep only lines starting with [HH:MM:SS])
    temp_file="${part_file}.temp"
    grep '^\[[0-9][0-9]:[0-9][0-9]:[0-9][0-9]\]' "$part_file" > "$temp_file"
    mv "$temp_file" "$part_file"
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Removed lines without timestamps from $part_file" >> "$LOG_FILE"
    if [ -z "$first_ts" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S'): No timestamp in $part_file, skipping" >> "$LOG_FILE"
      rm -f "$part_file"
      continue
    fi

    full_date="$first_ts $year"
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Extracting timestamp from $part_file: $full_date" >> "$LOG_FILE"

    # Parse the date
    rB=$(date -d "$full_date" +"%B")
    rA=$(date -d "$full_date" +"%A")
    rY=$(date -d "$full_date" +"%Y")
    rm=$(date -d "$full_date" +"%m")
    rd=$(date -d "$full_date" +"%d")
    rH=$(date -d "$full_date" +"%H")
    rM=$(date -d "$full_date" +"%M")
    rS=$(date -d "$full_date" +"%S")
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Timestamp extracted: $rY-$rm-$rd $rH:$rM:$rS ($rB $rA)" >> "$LOG_FILE"

    # Create the destination directory structure
    dest_dir="${OUT_DIR}/${rY}/${rm}-${rB}/${rd}-${rA}"
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Creating destination directory: $dest_dir" >> "$LOG_FILE"
    if ! mkdir -p "$dest_dir"; then
      echo "$(date '+%Y-%m-%d %H:%M:%S'): ERROR - Failed to create destination directory $dest_dir" >> "$LOG_FILE"
      echo "[NWN Log Rotator]: ERROR - Failed to create destination directory $dest_dir"
      rm -f "$part_file"
      continue
    fi
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Destination directory created successfully: $dest_dir" >> "$LOG_FILE"

    base_outname="nwclientLog_${rY}-${rm}-${rd}_${rH}${rM}${rS}.txt"
    outname="$base_outname"
    dest_path="${dest_dir}/${outname}"

    # Ensure unique filename to avoid overwriting
    counter=1
    while [ -f "$dest_path" ]; do
      counter=$((counter + 1))
      outname="${base_outname%.*}_${counter}.txt"
      dest_path="${dest_dir}/${outname}"
      echo "$(date '+%Y-%m-%d %H:%M:%S'): File exists, trying unique name: $outname" >> "$LOG_FILE"
    done

    echo "$(date '+%Y-%m-%d %H:%M:%S'): Final output filename: $outname" >> "$LOG_FILE"

    echo "$(date '+%Y-%m-%d %H:%M:%S'): Copying $part_file to $dest_path" >> "$LOG_FILE"
    if cp "$part_file" "$dest_path"; then
      echo "$(date '+%Y-%m-%d %H:%M:%S'): Successfully copied $part_file to $dest_path" >> "$LOG_FILE"
      echo "[NWN Log Rotator]: Copied log to $dest_path"
      echo "$(date '+%Y-%m-%d %H:%M:%S'): Sending notification for copied logfile: ${outname}" >> "$LOG_FILE"
      notify-send -t 4000 "Logfile copied: ${outname}"
      echo "$(date '+%Y-%m-%d %H:%M:%S'): Completed processing of part $i from ${f##*/}" >> "$LOG_FILE"
    else
      echo "$(date '+%Y-%m-%d %H:%M:%S'): ERROR - Failed to copy $part_file to $dest_path" >> "$LOG_FILE"
      echo "[NWN Log Rotator]: ERROR - Failed to copy $part_file to $dest_path"
    fi

    # Remove the part file
    rm -f "$part_file"
  done

  # Remove the original file
  echo "$(date '+%Y-%m-%d %H:%M:%S'): Removing original file: ${f##*/}" >> "$LOG_FILE"
  if rm -f "$f"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Successfully removed original file: ${f##*/}" >> "$LOG_FILE"
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S'): WARNING - Failed to remove original file: ${f##*/}" >> "$LOG_FILE"
    echo "[NWN Log Rotator]: Warning - Failed to remove $f"
  fi
done

# Optional git auto-commit and push
if [ "$ENABLE_GIT_AUTO_COMMIT" = true ]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S'): Starting git auto-commit and push" >> "$LOG_FILE"
  if git add . && git commit -m "Auto-commit NWN logs $(date '+%Y-%m-%d %H:%M:%S')" && git push; then
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Git auto-commit and push successful" >> "$LOG_FILE"
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S'): WARNING - Git auto-commit and push failed" >> "$LOG_FILE"
  fi
fi

echo "$(date '+%Y-%m-%d %H:%M:%S'): NWN log rotator script completed" >> "$LOG_FILE"
