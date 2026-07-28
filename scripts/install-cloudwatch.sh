#!/bin/bash

set -eux

apt-get update
apt-get install -y amazon-cloudwatch-agent

cp /tmp/amazon-cloudwatch-agent.json \
   /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

systemctl enable amazon-cloudwatch-agent