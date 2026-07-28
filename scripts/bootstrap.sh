#!/bin/bash

set -eux

cat > /tmp/install-nginx.sh <<'EOF'
${install_nginx_script}
EOF

cat > /tmp/install-cloudwatch.sh <<'EOF'
${install_cloudwatch_script}
EOF

cat > /tmp/amazon-cloudwatch-agent.json <<'EOF'
${cloudwatch_config}
EOF

chmod +x /tmp/install-nginx.sh
chmod +x /tmp/install-cloudwatch.sh

bash /tmp/install-nginx.sh
bash /tmp/install-cloudwatch.sh