# Configure webdrivers for Chromium in Docker
# Allow automatic Chromedriver management with fallback options

# Don't pin to a specific version to allow webdrivers to find compatible version
# Webdrivers::Chromedriver.required_version = '114.0.5735.90'

# Set the path to the system-installed Chromedriver as fallback
ENV["WEBDRIVERS_CHROMEDRIVER_PATH"] = "/usr/bin/chromedriver"
