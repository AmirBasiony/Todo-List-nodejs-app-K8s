 #!/bin/bash
 
# Install and start SSM Agent
if ! command -v amazon-ssm-agent &> /dev/null
then
curl -o "amazon-ssm-agent.deb" https://s3.amazonaws.com/amazon-ssm-us-east-1/latest/debian_amd64/amazon-ssm-agent.deb
dpkg -i amazon-ssm-agent.deb
fi
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent