#!/bin/bash

set -eux 

host=$(hostname)

sudo apt update 
sudo apt install -y nginx 

cat > /var/www/html/index.html <<EOF 
<h1>Elthebel API Server </h1>
<p>Healthy from $host</p>
EOF

echo "OK" > /var/www/html/health 


sudo systemctl enable nginx 
sudo systemctl restart nginx 
