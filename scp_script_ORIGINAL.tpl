{*sleep 60*}
{*comment out the sleep 60 and use a remote provisioner (remote-exec) to determine if k3s is bootstropped. Only then attempt the SCP below*}

scp -i /home/ubuntu/.ssh/keyaws2 \
-o StrictHostKeyChecking=no \
-o UserKnownHostsFile=/dev/null \
-q ubuntu@${nodeip}:/etc/rancher/k3s/k3s.yaml ${k3s_path}/k3s-${nodename}.yaml && 
sed -i 's/127.0.0.1/${nodeip}/' ${k3s_path}/k3s-${nodename}.yaml