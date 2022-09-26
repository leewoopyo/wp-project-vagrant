#! /bin/bash
# This script needed run only master node
pod_network="192.168.235.0/24"
apiserver_network=$(hostname -i)
# configure pod network
kubeadm init --pod-network-cidr=$pod_network --apiserver-advertise-address=$apiserver_network | tee /home/vagrant/kubeadm_init_output
grep -A 2 'kubeadm join' /home/vagrant/kubeadm_init_output > /home/vagrant/token

if [ $? -ne 0 ]
then
	echo "kubeadm init failed"
	echo "fix error and retry"
	exit
fi

# kubectl 명령어 사용을 위한 환경변수 설정
export KUBECONFIG=/etc/kubernetes/admin.conf

# CNI(Container Network Interface) install
# - weave install

kubectl apply -f https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')
if [ $? -ne 0 ]
then
	echo "weave install failed"
	echo "fix error and retry"
	exit
fi

