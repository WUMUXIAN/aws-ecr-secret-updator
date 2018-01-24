#!bin/bash

echo "Updating image pull secret"

password=$(aws ecr get-authorization-token --output text --query 'authorizationData[].authorizationToken' | base64 -d | cut -d: -f2)
endpoint=$(aws ecr get-authorization-token --output text --query 'authorizationData[].proxyEndpoint' | sed -e "s|https://||g")

echo password: ${password}
echo endpoint: ${endpoint}

if [ -f /var/run/secrets/kubernetes.io/serviceaccount/token ];then
	token=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
fi

if [ -f /var/run/secrets/kubernetes.io/serviceaccount/ca.crt ];then
	ca=$(base64 /var/run/secrets/kubernetes.io/serviceaccount/ca.crt | tr -d '\r\n')
fi

if [ -f /var/run/secrets/kubernetes.io/serviceaccount/namespace ];then
	namespace=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
fi

cat > kubeconfig <<EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: {{ca}}
    server: https://$API_SERVER
  name: cluster
contexts:
- context:
    cluster: cluster
    user: kubelet
  name: cluster
users:
- name: kubelet
  user:
    token: {{token}}
EOF

sed -i "s/{{ca}}/${ca}/g;s/{{token}}/${token}/g" kubeconfig

auth=$(echo -n AWS:${password} | base64 | tr -d '\r\n')
dockercfg=`cat << EOF
{"${endpoint}":{"username":"AWS","password":"${password}","email":"placeholder@gmail.com","auth":"${auth}"}}
EOF`
dockercfg=$(echo -n $dockercfg | base64 | tr -d '\r\n')

cat > aws-erc-imagepullsecret.yaml << EOF
apiVersion: v1
data:
  .dockercfg: {{dockercfg}}
kind: Secret
metadata:
  name: $SECRET_NAME
  namespace: $namespace
type: kubernetes.io/dockercfg
EOF

sed -i "s/{{dockercfg}}/${dockercfg}/g" aws-erc-imagepullsecret.yaml

/kubectl --kubeconfig=kubeconfig -n $namespace get secret $SECRET_NAME

if [ "$?"  = "1" ];then
	# Create
	/kubectl --kubeconfig=kubeconfig -n $namespace create -f aws-erc-imagepullsecret.yaml
else
	# Update
	/kubectl --kubeconfig=kubeconfig -n $namespace replace -f aws-erc-imagepullsecret.yaml
fi



