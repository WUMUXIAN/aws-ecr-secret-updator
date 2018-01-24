### Docker image that works as initContainers for pods to refresh the image pull secret for AWS ECR.

Important Notes:

1. This image only works as initContainer in Kubernetes pods because it's highly dependent on Kubernetes cluster and its service account and RBAC feature.
2. The service account the pod uses should have the permission to read, write and update the specified secret.
3. This image is meant to be working with Kubernetes 1.7.5, other versions are not tested.

#### Problem:
If you're running Kubernetes cluster outside of AWS however your docker images are stored in AWS ECR, you'll find ourself in trouble because the token you get from AWS to pull images only latest for 24 hours.

#### Solution:
Taking advantage of the Kubenertes initContainers feature, we can use a initContainer to get the token from AWS and store it in an imagePullSecret for all the other containers that pull images from AWS ECR.

### Example permission for the service account

```
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: se-api
rules:
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["aws-erc-imagepullsecret"]
  verbs: ["get", "update", "delete"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["create", "list", "watch"]

```

You need to bind the service account the pod is using to this role.

### Example pod spec.initContainers

```
initContainers:
  - name: docker-credential-updater
    image: wumuxian/ecr-secret-updater:kube-1.7.5
    imagePullPolicy: Always
    env:
    - name: AWS_ACCESS_KEY_ID
      valueFrom:
        secretKeyRef:
          name: docker-credential-updater-awscli-secret
          key: AWS_ACCESS_KEY_ID
    - name: AWS_SECRET_ACCESS_KEY
      valueFrom:
        secretKeyRef:
          name: docker-credential-updater-awscli-secret
          key: AWS_SECRET_ACCESS_KEY
    - name: AWS_DEFAULT_REGION
      valueFrom:
        secretKeyRef:
          name: docker-credential-updater-awscli-secret
          key: AWS_DEFAULT_REGION
    - name: API_SERVER
      value: https://kubenertes
    - name: SECRET_NAME
      value: tds-erc-imagepullsecret
```

Please note that for security purpose, you should set your AWS credentials using secret and use the value from it.

