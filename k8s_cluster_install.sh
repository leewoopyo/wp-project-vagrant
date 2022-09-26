#! /bin/bash
# base package install

yum -y install vim nano net-tools bridge-utils sshpass
# docker install
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum -y install docker-ce docker-ce-cli containerd.io
systemctl start docker
systemctl enable docker

# docker test
docker run hello-world
if [ $? -ne 0 ]
then
    echo "docker install failed"
    echo "find the error, fix it and try again"
    exit
fi

# disable firewall
systemctl disable firewalld
systemctl stop firewalld

# k8s.conf - configure iptables for bridge network.
echo "net.bridge.bridge-nf-call-ip6tables = 1" > /etc/sysctl.d/k8s.conf
echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.d/k8s.conf
sysctl --system

# disable selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux
setenforce 0

# permanent swap off - kubernetes do not use swap memory
sed -e '/swap/s/^/#/' -i /etc/fstab


# all swap space off
swapoff -a

# add yum repository file
tee /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=0
EOF

# install & run
#yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
yum install -y kubelet-1.23.5 kubeadm-1.23.5 kubectl-1.23.5 --disableexcludes=kubernetes
systemctl enable kubelet &&  systemctl start kubelet

# defautl cgroup driver(cgroupfs) to systemd

tee /etc/docker/daemon.json <<EOF
{
"exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

# apply damon.json file
systemctl daemon-reload
systemctl restart docker
systemctl restart kubelet

tee /etc/hosts <<EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
:1         localhost localhost.localdomain localhost6 localhost6.localdomain6
EOF

echo "192.168.50.50   master.example.com    master" >> /etc/hosts
echo "192.168.50.51   node1.example.com     node1" >> /etc/hosts
echo "192.168.50.52   node2.example.com     node2" >> /etc/hosts
