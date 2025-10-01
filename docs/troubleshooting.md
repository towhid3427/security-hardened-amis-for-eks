# Troubleshooting

# Nodes not joining the cluster

1. Check on Codebuild logs for any error while building the AMI
2. Check if any of the dependencies have released a breaking change.
To see list of dependencies please refer to (cis-hardened-amis-for-eks#-dependencies)(./README.md#-dependencies)
3. If you performed changes to the Terraform code, would be worthwhile checking the following docs:
https://repost.aws/knowledge-center/eks-worker-nodes-cluster
https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html#worker-node-fail

Feel free to open an issue if you need help.

# Unauthorized or access denied (kubectl)

1. Ensure you followed steps from the README reg "How to access the EKS Cluster".
2. Check the following documentation for further help:
https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html#unauthorized

# An error occurred (AccessDeniedException) when calling the CreateCisScanConfiguration operation: Invoking account is not enabled.
 
1. AWS Inspector needs to be enabled for the region to resolve this item.
For more information, please refer to https://docs.aws.amazon.com/inspector/latest/user/getting_started_tutorial.html

# AccessDenied errors

1. Please refer to the required IAM Permissions to deploy each of the patterns on [IAM Permissions doc](../../docs/iampermissions.md)

#  ERROR: Cannot connect to the Docker daemon at unix:///Users/alegrm/.docker/run/docker.sock. Is the docker daemon running?

1. Ensure Docker daemon is running.

# Failed to get existing workspaces: Unable to list objects in S3 bucket "BUCKET_NAME" with prefix "env:/": operation error S3: ListObjectsV2, https response error StatusCode: 301,

1. Ensure you have update the BUCKET_NAME to store the Terraform State file on the file versions.tf.