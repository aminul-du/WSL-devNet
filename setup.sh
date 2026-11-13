#!/usr/bin/env bash
set -e

echo "🚀 Deploying WSL-devNet Linux components..."

# Install core namespace and service scripts
sudo cp mcore-fix.sh /usr/local/bin/mcore-fix.sh
sudo cp mcore-services.sh /usr/local/bin/mcore-services.sh
sudo chmod +x /usr/local/bin/mcore-fix.sh /usr/local/bin/mcore-services.sh

# Enable automatic namespace entry on shell launch
chmod +x enable-auto-ns-shell.sh
sudo ./enable-auto-ns-shell.sh

# Initialize namespace immediately
sudo /usr/local/bin/mcore-fix.sh

echo "✅ Linux deployment complete! Active isolated IP: $(cat /run/mcore-target-ip)"
