#!/bin/bash

# ------------------------------
# Config
# ------------------------------

# The directory in which your logs will be found. The default should work.
SRC_IN_DIR="${HOME}/.local/share/Neverwinter Nights/logs"

# The directory for the output of logs.
# I personally like to keep it local to my log rotator script.
# Some other good options could be "${HOME}/Documents/nwnlogs" maybe
OUT_DIR="."

# ------------------------------
LOG_FILE="./nwnlogrotator_operations.log"

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

  # Get timestamp from the file
  echo "$(date '+%Y-%m-%d %H:%M:%S'): Extracting timestamp from ${f##*/}" >> "$LOG_FILE"
  rB=$(date -r "${f}" +"%B")              # Modified Month Name
  rA=$(date -r "${f}" +"%A")              # Modified Day Name
  rY=$(date -r "${f}" +"%Y")              # Modified Year Num
  rm=$(date -r "${f}" +"%m")              # Modified Month Num
  rd=$(date -r "${f}" +"%d")              # Modified Day Num
  rH=$(date -r "${f}" +"%H")              # Modified Hour Num
  rM=$(date -r "${f}" +"%M")              # Modified Minute Num
  rS=$(date -r "${f}" +"%S")              # Modified Second Num
  echo "$(date '+%Y-%m-%d %H:%M:%S'): Timestamp extracted: $rY-$rm-$rd $rH:$rM:$rS ($rB $rA)" >> "$LOG_FILE"

  # Create the destination directory structure
  dest_dir="${OUT_DIR}/${rY}/${rm}-${rB}/${rd}-${rA}"
  echo "$(date '+%Y-%m-%d %H:%M:%S'): Creating destination directory: $dest_dir" >> "$LOG_FILE"
  if ! mkdir -p "$dest_dir"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S'): ERROR - Failed to create destination directory $dest_dir" >> "$LOG_FILE"
    echo "[NWN Log Rotator]: ERROR - Failed to create destination directory $dest_dir"
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

  echo "$(date '+%Y-%m-%d %H:%M:%S'): Copying $f to $dest_path" >> "$LOG_FILE"
  if cp "$f" "$dest_path"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Successfully copied $f to $dest_path" >> "$LOG_FILE"
    echo "[NWN Log Rotator]: Copied log to $dest_path"
    # Remove the original file
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Removing original file: ${f##*/}" >> "$LOG_FILE"
    if rm -f "$f"; then
      echo "$(date '+%Y-%m-%d %H:%M:%S'): Successfully removed original file: ${f##*/}" >> "$LOG_FILE"
    else
      echo "$(date '+%Y-%m-%d %H:%M:%S'): WARNING - Failed to remove original file: ${f##*/}" >> "$LOG_FILE"
      echo "[NWN Log Rotator]: Warning - Failed to remove $f"
    fi
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Sending notification for copied logfile: ${outname}" >> "$LOG_FILE"
    notify-send -t 4000 "Logfile copied: ${outname}"
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Completed processing of ${f##*/}" >> "$LOG_FILE"
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S'): ERROR - Failed to copy $f to $dest_path" >> "$LOG_FILE"
    echo "[NWN Log Rotator]: ERROR - Failed to copy $f to $dest_path"
  fi
done

echo "$(date '+%Y-%m-%d %H:%M:%S'): NWN log rotator script completed" >> "$LOG_FILE"
