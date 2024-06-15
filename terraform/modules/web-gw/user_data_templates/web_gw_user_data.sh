#!/bin/bash
set -x
hostnamectl set-hostname ${hostname}
apt-get update
apt-get install -y nginx

# Add a route to send traffic to the Webstore istio ingress gateway via the Kind host
# On the kind host there is an ip forwarding rule from kind-host <--> istio ingress
ip route add ${webstore_ip} via ${kind_ip}

# Create the nginx config file
cat > /etc/nginx/sites-available/default <<EOT
upstream crm {
	server ${prd_crm_ip};
    }

upstream hrm {
	server ${prd_hrm_ip};
    }

upstream portal {
	server ${prd_portal_ip};
    }

upstream webstore {
	server ${webstore_ip};
    }

server {
    listen 80;
    server_name ${my_public_ip};
    proxy_http_version 1.1;

    location /crm/ {
	    proxy_set_header Accept-Encoding "";
        proxy_pass http://crm/;
    }

    location /hrm/ {
	    proxy_set_header Accept-Encoding "";
        proxy_pass http://hrm/;
        proxy_redirect /app/ /hrm/app/;
        sub_filter '/app/' '/hrm/app/';
        sub_filter '/web/' '/hrm/web/';
        sub_filter_once off;
    }

    location /portal/ {
	    proxy_set_header Accept-Encoding "";
        proxy_pass http://portal/;
	    sub_filter "${prd_portal_ip}/" "${my_public_ip}/portal/";
	    sub_filter "${prd_portal_ip}\/" "${my_public_ip}\/portal\/";
        sub_filter_once off;
    }

    location /webstore/ {
	    proxy_set_header Accept-Encoding "";
        proxy_pass http://webstore/;
	    sub_filter 'href="/' 'href="/webstore/';
	    sub_filter 'src="/' 'src="/webstore/';
	    sub_filter_once off;
    }

    location /webstore/static/ {
	    proxy_set_header Accept-Encoding "";
        proxy_pass http://webstore/static/;
        sub_filter 'href=/"' 'href="/webstore/static/';
        sub_filter 'src="/' 'src="/webstore/static/';
        sub_filter_once off;
    }
}
EOT

# Load the new config file into nginx
systemctl restart nginx

# Create a script to generate web traffic via the gateway's public IP
mkdir -p /opt/acme/
cat > /opt/acme/web-agent.sh <<EOT
#!/bin/bash

date > /var/log/web-agent.log
for url in "crm" "hrm" "portal" "webstore/productpage"
do
    echo "*** \$url ***" >> /var/log/web-agent.log
    curl -L "http://${my_public_ip}/\$url" >> /var/log/web-agent.log
done
EOT

chmod +x /opt/acme/web-agent.sh
# Script is ready

# Run the web traffic script via cron
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/acme/web-agent.sh" ) | crontab -
