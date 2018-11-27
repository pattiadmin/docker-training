#!/bin/bash

echo "Installing Docker"

# jq, net-tools required for troubleshooting needs
yum install -y yum-utils jq net-tools

# actual Docker Installation
yum-config-manager --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo
yum-config-manager --enable docker-ce-edge

yum info docker-ce --disablerepo=* --enablerepo=docker-ce-edge && \
yum install -y docker-ce 

sed -i 's@\(ExecStart=/usr/bin/dockerd\).*@\1@' /usr/lib/systemd/system/docker.service

mkdir -p /etc/docker
cat <<EOF > /etc/docker/daemon.json
{
    "hosts": [
        "unix:///var/run/docker.sock",
        "tcp://127.0.0.1:2375",
        "$(hostname -I | awk '{print $2}')"
    ],
    "swarm-default-advertise-addr": "$(hostname -I | awk '{print $2}')",
    "log-driver": "journald",
    "labels": [
    	"host=$(hostname -s)"
    ]
}
EOF

systemctl daemon-reload
systemctl enable docker
systemctl restart docker

# The docker daemon binds to a Unix socket /var/run/docker.sock which is owned by root:docker
# Non-root user just needs to be added to the docker group.
usermod -aG docker vagrant

docker info