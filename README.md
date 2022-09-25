# Highly-available vanilla Kubernetes cluster with Windows workers in Azure
Featuring secure access via Bastion host, load balancing for control plane and Calico for Windows using HostProcess containers
## Control Plane
### Cluster Bootstrap
SSH into **Alpha** node with Bastion native client:
```sh
az network bastion ssh --name bas-k8s-dev-weu --resource-group rg-k8s-dev-weu --auth-type ssh-key --username azure --target-resource-id /subscriptions/<ID>/resourceGroups/rg-k8s-dev-weu/providers/Microsoft.Compute/virtualMachines/vm-k8s-dev-weu-alpha --ssh-key ~/.ssh/id_rsa
```
Bootstrap cluster with custom pod CIDR and load balancer endpoint:
```sh
kubeadm init --pod-network-cidr 10.244.0.0/16 --control-plane-endpoint k8s.contoso.net --upload-certs
```
Configure kubectl:
```sh
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
Install Calico CNI:
```sh
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.1/manifests/tigera-operator.yaml
cat << EOF | kubectl create -f -
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    # Note: The ipPools section cannot be modified post-install.
    ipPools:
    - blockSize: 26
      cidr: 10.244.0.0/16
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
---
apiVersion: operator.tigera.io/v1
kind: APIServer 
metadata: 
  name: default 
spec: {}
EOF
```
Wait until all pods are in Running state:
```sh
kubectl get pod -o wide -A -w
```
### Other nodes
For the rest of control plane nodes (e.g. bravo, charlie):
```sh
az network bastion ssh --name bas-k8s-dev-weu --resource-group rg-k8s-dev-weu --auth-type ssh-key --username azure --target-resource-id /subscriptions/<ID>/resourceGroups/rg-k8s-dev-weu/providers/Microsoft.Compute/virtualMachines/vm-k8s-dev-weu-<vm> --ssh-key ~/.ssh/id_rsa

kubeadm join k8s.contoso.net:6443 --token abcdef.1234567890abcdef --discovery-token-ca-cert-hash sha256:b4e8c71d4eb0e1ff3693585877610d6c189ac9c3a6c674f9e94ad0e5ba4e5de5 --control-plane --certificate-key 08dd9019a03b05153297d3e1454523f1ebdc48890217437c47e883203c1d257a
```
## Workers
### 1st Worker
RDP into **Delta** node with Bastion native client:
```sh
az network bastion rdp --name bas-k8s-dev-weu --resource-group rg-k8s-dev-weu --target-resource-id /subscriptions/<ID>/resourceGroups/rg-k8s-dev-weu/providers/Microsoft.Compute/virtualMachines/vm-k8s-dev-weu-delta --resource-port 3389
```
Run [Install-Containerd.ps1](./scripts/Install-Containerd.ps1) and restart node after enabling Containers feature:
```pwsh
Restart-Computer -Force
```
Run [Install-Containerd.ps1](./scripts/Install-Containerd.ps1) again and wait until installation and configuration is ready
Run [PrepareNode.ps1](./scripts/PrepareNode.ps1) and wait until kubelet installation and configuration is ready
Generate join token on **one of the masters**:
```sh
kubeadm token create --print-join-command
```
Execute the command on Windows node and wait until join operation completes.
Download, adjust and install the manifest of Calico for Windows on of the masters:
```sh
curl https://raw.githubusercontent.com/projectcalico/calico/v3.24.1/manifests/calico-windows-vxlan.yaml -o calico-windows.yaml
sed -i 's/KUBERNETES_SERVICE_HOST = ""/KUBERNETES_SERVICE_HOST = "k8s.contoso.net"/' calico-windows.yaml
sed -i 's/KUBERNETES_SERVICE_PORT = ""/KUBERNETES_SERVICE_PORT = "6443"/' calico-windows.yaml
kubectl create -f calico-windows.yaml
```
Wait until installation completes:
```sh
kubectl logs -f -n calico-system -l k8s-app=calico-node-windows -c install
kubectl logs -f -n calico-system -l k8s-app=calico-node-windows -c node
kubectl logs -f -n calico-system -l k8s-app=calico-node-windows -c felix
```
Download, adjust and install kube-proxy manifest:
```sh
curl https://raw.githubusercontent.com/projectcalico/calico/v3.24.1/manifests/windows-kube-proxy.yaml -o windows-kube-proxy.yaml
sed -i 's/K8S_VERSION/1.25.2/g' windows-kube-proxy.yaml
sed -i 's/VERSION/ltsc2022/g' windows-kube-proxy.yaml
kubectl create -f windows-kube-proxy.yaml
```
Verify that daemon set is running:
```sh
kubectl describe ds -n kube-system kube-proxy-windows
```
### Other nodes
Repeat only script steps on every Windows node.