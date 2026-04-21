FROM python:3.11-slim

# 1. Install git
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 2. Clone the repository first (so we can check for its requirements)
RUN git clone https://github.com/nixime/simple_vuln_scanner.git

# 3. Create your custom list of dependencies
RUN printf "requests\nopenpyxl\ncyclonedx-python-lib\ncvss\nosv\n" > /app/my_requirements.txt

# 4. Conditional Install Logic
# This checks if the repo has a requirements.txt. 
# If yes, it installs both. If no, it only installs yours.
RUN if [ -f simple_vuln_scanner/requirements.txt ]; then \
        pip install --no-cache-dir -r /app/my_requirements.txt -r simple_vuln_scanner/requirements.txt; \
    else \
        pip install --no-cache-dir -r /app/my_requirements.txt; \
    fi

# 5. Setup Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]