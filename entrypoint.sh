#!/bin/bash
# entrypoint.sh: Automates vulnerability scanning across multiple system configurations.
# This script handles date calculation, directory mapping, and legacy report matching.

set -eu  # -e: exit on error, -u: treat unset variables as an error

# --- Argument Parsing ---
# Initialize the full scan toggle (default to false)
FULL_SCAN=false
ROOT_FOLDER=""
APP_FOLDER=""

# Loop through all command line arguments (e.g., ./entrypoint.sh --fullscan)
while [[ $# -gt 0 ]]; do
  case $1 in
    --fullscan)
      FULL_SCAN=true
      shift # Move to the next argument
      ;;

    --config_root)
      ROOT_FOLDER=$2
      shift 2
      ;;

    --app_folder)
      APP_FOLDER=$2
      shift 2
      ;;

    *)
      # Ignore unknown arguments or handle them here
      shift
      ;;
  esac
done

# --- Path Definitions ---
GLOBAL_ROOT_FOLDER=${ROOT_FOLDER:-/opt/scanner}
GLOBAL_CFG_FOLDER=${GLOBAL_ROOT_FOLDER}/configs   # Source for system.ini files
GLOBAL_GEN_FOLDER=${GLOBAL_ROOT_FOLDER}/generated # Destination for new scan outputs
GLOBAL_REV_FOLDER=${GLOBAL_ROOT_FOLDER}/reviewed  # Source for historical/reviewed reports

# --- Dynamic Date Calculation ---
# Sets end_date to the 1st of the current month (Format: YYYY-MM-DD)
end_date=$(date +%Y-%m-01)
# Sets start_date to exactly one month prior (Format: YYYY-MM-DD)
start_date=$(date -d "$end_date -1 month" +%Y-%m-01)

# Extract YYYY_MM strings for folder organization
current_folder=$(date -d "$end_date" +%Y_%m)
prior_folder=$(date -d "$start_date" +%Y_%m)

# Console feedback for logging purposes
echo "Interval: $start_date to $end_date"
echo "Targeting Folders: Current ($current_folder) | Prior ($prior_folder)"
echo "Full Scan Mode: $FULL_SCAN"

# Change directory to the application root to ensure relative python imports work
cd ${APP_FOLDER:-/app/simple_vuln_scanner}

# --- Processing Loop ---
# Locate every 'system.ini' file within the config folder recursively.
# Using -print0 and -d '' ensures paths with spaces are handled correctly.
find "${GLOBAL_CFG_FOLDER}" -type f -name "system.ini" -print0 | while read -r -d '' config_file; do
    
    # Path Manipulation
    # Strip the base config path to get the relative subdirectory structure
    rel_path="${config_file#${GLOBAL_CFG_FOLDER}/}"
    subdir=$(dirname "$rel_path")
    
    # Define where today's output goes and where last month's reviewed data lives
    target_dir="${GLOBAL_GEN_FOLDER}/$current_folder/$subdir"
    prior_dir="${GLOBAL_REV_FOLDER}/$prior_folder/$subdir"

    # Ensure the target directory exists before running the scanner
    mkdir -p "$target_dir"
    
    echo
    echo "+++++++++++++++++++++++++++++++++++++++++++++++++"
    echo "Processing $config_file -> $target_dir"
    echo "-------------------------------------------------"
    
    # Scanner Execution
    # If --fullscan was passed, we omit the --start and --end date flags.
    if [ "$FULL_SCAN" = true ]; then
        echo "Executing FULL SCAN (no date constraints)..."
        python3 -u src/main.py \
            --config "${GLOBAL_ROOT_FOLDER}/config.ini" \
            --system_override "$config_file" \
            --outdir "$target_dir"
    else
        # Standard execution using the calculated monthly window
        python3 -u src/main.py \
            --config "${GLOBAL_ROOT_FOLDER}/config.ini" \
            --system_override "$config_file" \
            --outdir "$target_dir" \
            --start "$start_date" \
            --end "$end_date"
    fi

    echo "================================================="
    echo

    # Post-Process: Legacy Match Checking
    # Search for Excel reports generated in the target_dir
    find "$target_dir" -type f -name "*.xlsm" -print0 | while read -r -d '' xlsm_file; do
        filename=$(basename "$xlsm_file")
        
        echo "  Checking for legacy match: $filename"
        
        # Determine if this exact report was already reviewed in the prior month's folder
        if [ -f "${prior_dir}/${filename}" ]; then
            echo "    MATCH FOUND: $filename exists in $prior_dir"
        else
            echo "    NO MATCH: $filename not found in legacy data ($prior_dir)"
        fi
    done
    
done