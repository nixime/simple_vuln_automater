FROM python:3.11-slim

# Install git
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

ENV ROOT_FOLDER=/opt/scanner

WORKDIR /app

# Clone the repository first (so we can check for its requirements)
RUN git clone https://github.com/nixime/simple_vuln_scanner.git

# Create your custom list of dependencies
RUN printf "requests\nopenpyxl\ncyclonedx-python-lib\ncvss\nosv\n" > /app/my_requirements.txt

# Conditional Install Logic
# This checks if the repo has a requirements.txt. 
# If yes, it installs both. If no, it only installs yours.
RUN if [ -f simple_vuln_scanner/requirements.txt ]; then \
        pip install --no-cache-dir -r /app/my_requirements.txt -r simple_vuln_scanner/requirements.txt; \
    else \
        pip install --no-cache-dir -r /app/my_requirements.txt; \
    fi

# Setup Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/bin/sh", "-c", "/entrypoint.sh --app_folder /app/simple_vuln_scanner --config_root ${ROOT_FOLDER} \"$@\"", "--"]