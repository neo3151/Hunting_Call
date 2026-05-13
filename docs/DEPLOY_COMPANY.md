# Deploy Benchmark Apps LLC Landing Page

## Quick Deploy (One-liner)

```bash
scp company.html root@YOUR_DROPLET_IP:/var/www/html/index.html
```

Replace `YOUR_DROPLET_IP` with your actual droplet IP address.

## Full Deploy Script

```bash
# Make script executable
chmod +x deploy-company.sh

# Run it
./deploy-company.sh root@YOUR_DROPLET_IP
```

## Manual Steps (if needed)

### 1. SSH into your droplet
```bash
ssh root@YOUR_DROPLET_IP
```

### 2. Check web server is running
```bash
# For Nginx
systemctl status nginx

# For Apache
systemctl status apache2
```

### 3. Copy files to web root
```bash
# Default web directories:
# Nginx: /var/www/html/
# Apache: /var/www/html/

scp company.html root@YOUR_DROPLET_IP:/var/www/html/index.html
```

### 4. Copy assets (if you add images later)
```bash
scp -r images root@YOUR_DROPLET_IP:/var/www/html/
```

## Post-Deploy

- **Site URL**: `http://YOUR_DROPLET_IP`
- **File location**: `/var/www/html/index.html`

### Optional: Set up a domain
1. Point your domain's A record to your droplet IP
2. Update nginx/apache config for the domain
3. Consider adding SSL with Let's Encrypt:
   ```bash
   certbot --nginx -d benchmarkappsllc.com
   ```
