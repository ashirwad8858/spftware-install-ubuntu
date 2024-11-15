#Launch 3 EC2 instance

# Set host name of each
hostnamectl set-hostname controlplane


hostnamectl set-hostname node01


hostnamectl set-hostname node02

# Change Private IP and put into /etc/hosts
172.31.39.60 controlplane
172.31.81.40 node01
172.31.80.52 node02


# Run Following command on each node
{
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl
}

{
    cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

    sudo modprobe overlay
    sudo modprobe br_netfilter
}


{
    cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

    sudo sysctl --system
}

sudo apt-get install -y containerd

{
    
    sudo mkdir -p /etc/containerd
    containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/' | sudo tee /etc/containerd/config.toml
}

sudo systemctl restart containerd

KUBE_LATEST=$(curl -L -s https://dl.k8s.io/release/stable.txt | awk 'BEGIN { FS="." } { printf "%s.%s", $1, $2 }')

{
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://pkgs.k8s.io/core:/stable:/${KUBE_LATEST}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
}

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBE_LATEST}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

{
    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl
}


# Update IP 
sudo crictl config \
    --set runtime-endpoint=unix:///run/containerd/containerd.sock \
    --set image-endpoint=unix:///run/containerd/containerd.sock

cat <<EOF | sudo tee /etc/default/kubelet
KUBELET_EXTRA_ARGS='--node-ip 172.31.39.60'
EOF



## Update IP and Run on master node
POD_CIDR=10.244.0.0/16
SERVICE_CIDR=10.96.0.0/16
sudo kubeadm init --pod-network-cidr $POD_CIDR --service-cidr $SERVICE_CIDR --apiserver-advertise-address 172.31.39.60


{
    mkdir ~/.kube
    sudo cp /etc/kubernetes/admin.conf ~/.kube/config
    sudo chown $(id -u):$(id -g) ~/.kube/config
    chmod 600 ~/.kube/config
}


kubectl get pods -n kube-system

kubectl apply -f "https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s-1.11.yaml"


kubectl get pods -n kube-system

# join worker node
kubeadm token create --print-join-command

# Run output on node01 node01
 


