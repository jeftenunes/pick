sudo swapoff -a

sudo dnf install -y iproute-tc

sudo modprobe overlay
sudo modprobe br_netfilter

sudo cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system
sudo curl https://raw.githubusercontent.com/cri-o/packaging/main/get | sudo tee crio-install > /dev/null

sudo bash crio-install

sudo systemctl daemon-reload
sudo systemctl enable --now crio.service

sudo cp /etc/cni/net.d/10-crio-bridge.conflist.disabled /etc/cni/net.d/10-crio-bridge.conflist

sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubelet"

sudo chmod 777 kubelet

sudo tee /etc/systemd/system/kubelet.service <<EOF
[Unit]
Description=Kubelet

[Service]
ExecStart=/usr/bin/kubelet \
 --config=/etc/kubernetes/kubelet.yaml
Restart=always

[Install]
WantedBy=multi-user.target
EOF


sudo systemctl daemon-reload
sudo systemctl enable --now kubelet.service

# kubeadmin
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config


cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

# only on the control plane
#sudo kubeadm init --pod-network-cidr=10.10.0.0/16 --apiserver-advertise-address=10.0.1.105

# weavenet - rodar só no control plane
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml