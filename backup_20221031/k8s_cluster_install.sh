#! /bin/bash
# base package install

### 방화벽 해제 ###
systemctl disable firewalld
systemctl stop firewalld

### swap 비활성화 ###
# permanent swap off - kubernetes do not use swap memory
sed -e '/swap/s/^/#/' -i /etc/fstab
# all swap space off
swapoff -a

### IPtable 커널 옵션 활성화 ###
# k8s.conf - configure iptables for bridge network.
echo "net.bridge.bridge-nf-call-ip6tables = 1" > /etc/sysctl.d/k8s.conf
echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.d/k8s.conf
sysctl --system

### selinux 비활성화 ###
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux
setenforce 0

### Host 등록 ###
tee /etc/hosts <<EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
:1         localhost localhost.localdomain localhost6 localhost6.localdomain6
EOF

echo "192.168.50.100   k8s.master.com    master" >> /etc/hosts
echo "192.168.50.101   k8s.node1.com     node1" >> /etc/hosts
echo "192.168.50.102   k8s.node2.com     node2" >> /etc/hosts

### yum update ###
yum -y update

### 기본 유틸 설치 ###
yum -y install vim nano net-tools bridge-utils sshpass

### 도커 설치 ###
yum install -y yum-utils device-mapper-persistent-data lvm2 
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y containerd.io-1.4.9-3.1.el7 docker-ce-3:20.10.8-3.el7.x86_64 docker-ce-cli-1:20.10.8-3.el7.x86_64
systemctl start docker
systemctl enable docker

### deamon.json 설정 ###
# defautl cgroup driver(cgroupfs) to systemd
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF
mkdir -p /etc/systemd/system/docker.service.d

### 도커 재시작
# apply damon.json file
systemctl daemon-reload
systemctl restart docker

### docker test ###
docker run hello-world
if [ $? -ne 0 ]
then
    echo "docker install failed"
    echo "find the error, fix it and try again"
    exit
fi


### 쿠버네티스 yum repository 설정 ###
tee /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

### 쿠버네티스 설치 ###
# install & run
#yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
yum install -y kubelet-1.22.0-0.x86_64 kubeadm-1.22.0-0.x86_64 kubectl-1.22.0-0.x86_64 --disableexcludes=kubernetes

### 쿠버네티스 재시작 ###
systemctl enable kubelet && systemctl start kubelet
systemctl restart kubelet