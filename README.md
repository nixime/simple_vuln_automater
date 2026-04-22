> **Note:** This code and documentation was developed with the assistance of AI and subsequently reviewed and refined by human editors to ensure technical accuracy.

# Vulnerability Scanner Docker Guide

This document provides the setup and execution commands for the Dockerized vulnerability scanner. It automates the processing of configuration files, handles monthly date logic, and preserves folder structures across local mounts.

## Docker & Podman Commands

### 1. Build the Image
Execute this command in the directory where your `Containerfile` and `entrypoint.sh` are located.

```bash
podman build -t vuln-scanner .
```

### 2. Run the Container
Run the following command to link your local directories and start the scan. By default, this runs for the **previous month's window**.

```bash
podman run --rm \
  -e ROOT_FOLDER=/opt/scanner \
  -v (localpath)/generated:/opt/scanner/generated \
  -v (localpath)/reviewed:/opt/scanner/reviewed \
  -v (localpath)/configs:/opt/scanner/configs \
  vuln-scanner
```

### 3. Run a Full History Scan
To run the scanner without date constraints, pass the `--fullscan` flag at the end of the command.

```bash
podman run --rm \
  -e ROOT_FOLDER=/opt/scanner \
  -v (localpath)/generated:/opt/scanner/generated \
  -v (localpath)/reviewed:/opt/scanner/reviewed \
  -v (localpath)/configs:/opt/scanner/configs \
  vuln-scanner --fullscan
```

---

## Folder Mappings Explained

| Host Machine Path (Local) | Container Path (Internal) | Description |
| :--- | :--- | :--- |
| `(localpath)/configs` | `/opt/scanner/configs` | **Source:** Contains SBOMs and `system.ini` files. |
| `(localpath)/generated` | `/opt/scanner/generated` | **Destination:** Results are saved here, versioned by `YYYY_MM`. |
| `(localpath)/reviewed` | `/opt/scanner/reviewed` | **Legacy Check:** Used to compare new findings against last month's reviewed data. |

---

## How the Automation Works

### 1. Flexible Scan Modes
* **Standard Monthly Scan**: The script automatically determines the scanning interval based on the current system date (e.g., if run in April 2026, it targets March 2026).
* **Full History Scan**: Passing the `--fullscan` flag omits the `--start` and `--end` parameters in the Python call.

### 2. Directory Mirroring
* The automation preserves your organizational structure. 
* If a configuration exists at `/configs/department_a/system.ini`, the scanner will output results to `/generated/YYYY_MM/department_a/`.

### 3. Legacy Match Checking
* For every `.xlsm` report generated, the script searches the `/reviewed/` directory from the **prior month**.
* **Match Found**: Indicates the finding was present in the previous reporting cycle.
* **No Match**: Indicates a new finding or a change in the report filename.

### 4. Clean Execution
* **Automatic Cleanup**: The `--rm` flag ensures the container environment is wiped after the job is done.
* **Git Integration**: The Docker image pulls the latest source code from the repository during the build phase to ensure the `src/main.py` logic is up to date.
