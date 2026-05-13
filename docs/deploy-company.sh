#!/bin/bash
# Deploy Benchmark Apps LLC landing page to droplet
# Usage: ./deploy-company.sh user@your-droplet-ip

DROPLET=$1

if [ -z "$DROPLET" ]; then
    echo "Usage: ./deploy-company.sh user@your-droplet-ip"
    echo "Example: ./deploy-company.sh root@192.168.1.100"
    exit 1
fi

echo "Deploying company.html to $DROPLET..."

# Copy the company page to the droplet's web directory
scp company.html $DROPLET:/var/www/html/index.html

# Also copy any necessary assets (images, etc.)
if [ -d "images" ]; then
    echo "Copying images..."
    scp -r images $DROPLET:/var/www/html/
fi

echo "Deployment complete!"
echo "Your site should be live at: http://$(echo $DROPLET | cut -d'@' -f2)"
