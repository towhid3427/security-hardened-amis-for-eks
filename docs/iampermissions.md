# IAM Permissions

## Permissions required to deploy the BOTTLEROCKET Pattern

```json
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": [
				"ec2:CreateTags",
				"ec2:DeleteKeyPair",
				"ec2:DescribeAddresses",
				"ec2:DescribeAddressesAttribute",
				"ec2:DescribeAvailabilityZones",
				"ec2:DescribeImages",
				"ec2:DescribeInstances",
				"ec2:DescribeInternetGateways",
				"ec2:DescribeLaunchTemplateVersions",
				"ec2:DescribeLaunchTemplates",
				"ec2:DescribeNatGateways",
				"ec2:DescribeNetworkAcls",
				"ec2:DescribeNetworkInterfaces",
				"ec2:DescribeRegions",
				"ec2:DescribeRouteTables",
				"ec2:DescribeSecurityGroupRules",
				"ec2:DescribeSecurityGroups",
				"ec2:DescribeSubnets",
				"ec2:DescribeVolumes",
				"ec2:DescribeVpcs",
				"ec2:DisassociateAddress",
				"ec2:DisassociateRouteTable",
				"ec2:ReleaseAddress",
				"ecr:GetAuthorizationToken",
				"eks:CreateCluster",
				"eks:DescribeAddonVersions",
				"kms:CreateKey",
				"kms:ListAliases",
				"logs:DescribeLogGroups",
				"logs:ListTagsForResource",
				"ssm:DescribeParameters",
				"ssm:ListTagsForResource",
				"sts:GetCallerIdentity"
			],
			"Resource": "*"
		},
		{
			"Effect": "Allow",
			"Action": "ec2:AllocateAddress",
			"Resource": "arn:aws:ec2:${Region}:${Account}:elastic-ip/${AllocationId}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"ec2:CreateImage",
				"ec2:RunInstances",
				"ec2:StopInstances",
				"ec2:TerminateInstances"
			],
			"Resource": "arn:aws:ec2:${Region}:${Account}:instance/${InstanceId}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"ec2:AttachInternetGateway",
				"ec2:CreateInternetGateway",
				"ec2:DeleteInternetGateway",
				"ec2:DetachInternetGateway"
			],
			"Resource": "arn:aws:ec2:${Region}:${Account}:internet-gateway/${InternetGatewayId}"
		},
		{
			"Effect": "Allow",
			"Action": "ec2:CreateKeyPair",
			"Resource": "arn:aws:ec2:${Region}:${Account}:key-pair/${KeyPairName}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"ec2:CreateLaunchTemplate",
				"ec2:DeleteLaunchTemplate"
			],
			"Resource": "arn:aws:ec2:${Region}:${Account}:launch-template/${LaunchTemplateId}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"ec2:CreateNatGateway",
				"ec2:DeleteNatGateway"
			],
			"Resource": "arn:aws:ec2:${Region}:${Account}:natgateway/${NatGatewayId}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"ec2:CreateNetworkAclEntry",
				"ec2:DeleteNetworkAclEntry"
			],
			"Resource": "arn:aws:ec2:${Region}:${Account}:network-acl/${NaclId}"
		},
		{
			"Effect": "Allow",
			"Action": "ec2:RunInstances",
			"Resource": "arn:aws:ec2:${Region}:${Account}:network-interface/${NetworkInterfaceId}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"ec2:AssociateRouteTable",
				"ec2:CreateRoute",
				"ec2:CreateRouteTable",
				"ec2:DeleteRoute",
				"ec2:DeleteRouteTable"
			],
			"Resource": "arn:aws:ec2:${Region}:${Account}:route-table/${RouteTableId}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"ec2:AuthorizeSecurityGroupEgress",
				"ec2:AuthorizeSecurityGroupIngress",
				"ec2:CreateSecurityGroup",
				"ec2:DeleteSecurityGroup",
				"ec2:RevokeSecurityGroupEgress",
				"ec2:RevokeSecurityGroupIngress",
				"ec2:RunInstances"
			],
			"Resource": "arn:aws:ec2:${Region}:${Account}:security-group/${SecurityGroupId}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"ec2:CreateNatGateway",
				"ec2:CreateSubnet",
				"ec2:DeleteSubnet",
				"ec2:RunInstances"
			],
			"Resource": "arn:aws:ec2:${Region}:${Account}:subnet/${SubnetId}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"ec2:AttachInternetGateway",
				"ec2:CreateRouteTable",
				"ec2:CreateSubnet",
				"ec2:CreateVpc",
				"ec2:DeleteVpc",
				"ec2:DescribeVpcAttribute",
				"ec2:DetachInternetGateway",
				"ec2:ModifyVpcAttribute"
			],
			"Resource": "arn:aws:ec2:${Region}:${Account}:vpc/${VpcId}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"ec2:CreateImage",
				"ec2:ModifyImageAttribute",
				"ec2:RunInstances"
			],
			"Resource": "arn:aws:ec2:${Region}::image/${ImageId}"
		},
		{
			"Effect": "Allow",
			"Action": "ec2:CreateImage",
			"Resource": "arn:aws:ec2:${Region}::snapshot/${SnapshotId}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"ecr:BatchCheckLayerAvailability",
				"ecr:CompleteLayerUpload",
				"ecr:CreateRepository",
				"ecr:DeleteRepository",
				"ecr:DescribeRepositories",
				"ecr:InitiateLayerUpload",
				"ecr:ListTagsForResource",
				"ecr:PutImage",
				"ecr:TagResource",
				"ecr:UploadLayerPart"
			],
			"Resource": "arn:aws:ecr:${Region}:${Account}:repository/${RepositoryName}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"eks:AssociateAccessPolicy",
				"eks:DeleteAccessEntry",
				"eks:DescribeAccessEntry",
				"eks:DisassociateAccessPolicy",
				"eks:ListAssociatedAccessPolicies"
			],
			"Resource": "arn:aws:eks:${Region}:${Account}:access-entry/${ClusterName}/${IamIdentityType}/${IamIdentityAccountID}/${IamIdentityName}/${UUID}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"eks:DeleteAddon",
				"eks:DescribeAddon"
			],
			"Resource": "arn:aws:eks:${Region}:${Account}:addon/${ClusterName}/${AddonName}/${UUID}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"eks:CreateAccessEntry",
				"eks:CreateAddon",
				"eks:CreateNodegroup",
				"eks:DeleteCluster",
				"eks:DescribeCluster"
			],
			"Resource": "arn:aws:eks:${Region}:${Account}:cluster/${ClusterName}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"eks:DeleteNodegroup",
				"eks:DescribeNodegroup"
			],
			"Resource": "arn:aws:eks:${Region}:${Account}:nodegroup/${ClusterName}/${NodegroupName}/${UUID}"
		},
		{
			"Effect": "Allow",
			"Action": "iam:CreateServiceLinkedRole",
			"Resource": "arn:aws:iam::${Account}:role/${RoleNameWithPath}"
		},
		{
			"Effect": "Allow",
			"Action": "inspector2:CreateCisScanConfiguration",
			"Resource": "arn:aws:inspector2:${Region}:${Account}:owner/${OwnerId}/cis-configuration/${CISScanConfigurationId}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"kms:CreateAlias",
				"kms:DeleteAlias"
			],
			"Resource": "arn:aws:kms:${Region}:${Account}:alias/${Alias}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"kms:CreateAlias",
				"kms:CreateGrant",
				"kms:DeleteAlias",
				"kms:DescribeKey",
				"kms:EnableKeyRotation",
				"kms:GetKeyPolicy",
				"kms:GetKeyRotationStatus",
				"kms:ListResourceTags",
				"kms:PutKeyPolicy",
				"kms:RetireGrant",
				"kms:ScheduleKeyDeletion",
				"kms:TagResource"
			],
			"Resource": "arn:aws:kms:${Region}:${Account}:key/${KeyId}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"logs:CreateLogGroup",
				"logs:DeleteLogGroup",
				"logs:PutRetentionPolicy"
			],
			"Resource": "arn:aws:logs:${Region}:${Account}:log-group:${LogGroupName}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"ssm:DeleteParameter",
				"ssm:GetParameter",
				"ssm:GetParameters",
				"ssm:PutParameter"
			],
			"Resource": "arn:aws:ssm:${Region}:${Account}:parameter/${ParameterNameWithoutLeadingSlash}"
		}
	]
}
```


## Permissions required to deploy the Patterns: CIS_AL2, CIS_AL2023, EKS_Optimized_AL2, EKS_Optimized_AL2023

```json
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": [
				"ec2:CreateTags",
				"ec2:DeleteKeyPair",
				"ec2:DescribeAddresses",
				"ec2:DescribeAddressesAttribute",
				"ec2:DescribeAvailabilityZones",
				"ec2:DescribeImages",
				"ec2:DescribeInstances",
				"ec2:DescribeInternetGateways",
				"ec2:DescribeLaunchTemplateVersions",
				"ec2:DescribeLaunchTemplates",
				"ec2:DescribeNatGateways",
				"ec2:DescribeNetworkAcls",
				"ec2:DescribeRegions",
				"ec2:DescribeRouteTables",
				"ec2:DescribeSecurityGroupRules",
				"ec2:DescribeSecurityGroups",
				"ec2:DescribeSubnets",
				"ec2:DescribeVolumes",
				"ec2:DescribeVpcs",
				"eks:CreateCluster",
				"eks:DescribeAddonVersions",
				"kms:CreateKey",
				"kms:ListAliases",
				"logs:DescribeLogGroups",
				"logs:ListTagsForResource",
				"ssm:DescribeParameters",
				"ssm:ListTagsForResource",
				"sts:GetCallerIdentity"
			],
			"Resource": "*"
		},
		{
			"Effect": "Allow",
			"Action": "ec2:AllocateAddress",
			"Resource": "arn:aws:ec2:${Region}:${Account}:elastic-ip/${AllocationId}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"ec2:CreateImage",
				"ec2:RunInstances",
				"ec2:StopInstances",
				"ec2:TerminateInstances"
			],
			"Resource": "arn:aws:ec2:${Region}:${Account}:instance/${InstanceId}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"ec2:AttachInternetGateway",
				"ec2:CreateInternetGateway"
			],
			"Resource": "arn:aws:ec2:${Region}:${Account}:internet-gateway/${InternetGatewayId}"
		},
		{
			"Effect": "Allow",
			"Action": "ec2:CreateKeyPair",
			"Resource": "arn:aws:ec2:${Region}:${Account}:key-pair/${KeyPairName}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"ec2:CreateLaunchTemplate",
				"ec2:DeleteLaunchTemplate"
			],
			"Resource": "arn:aws:ec2:${Region}:${Account}:launch-template/${LaunchTemplateId}"
		},
		{
			"Effect": "Allow",
			"Action": "ec2:CreateNatGateway",
			"Resource": "arn:aws:ec2:${Region}:${Account}:natgateway/${NatGatewayId}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"ec2:CreateNetworkAclEntry",
				"ec2:DeleteNetworkAclEntry"
			],
			"Resource": "arn:aws:ec2:${Region}:${Account}:network-acl/${NaclId}"
		},
		{
			"Effect": "Allow",
			"Action": "ec2:RunInstances",
			"Resource": "arn:aws:ec2:${Region}:${Account}:network-interface/${NetworkInterfaceId}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"ec2:AssociateRouteTable",
				"ec2:CreateRoute",
				"ec2:CreateRouteTable"
			],
			"Resource": "arn:aws:ec2:${Region}:${Account}:route-table/${RouteTableId}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"ec2:AuthorizeSecurityGroupEgress",
				"ec2:AuthorizeSecurityGroupIngress",
				"ec2:CreateSecurityGroup",
				"ec2:DeleteSecurityGroup",
				"ec2:RevokeSecurityGroupEgress",
				"ec2:RevokeSecurityGroupIngress",
				"ec2:RunInstances"
			],
			"Resource": "arn:aws:ec2:${Region}:${Account}:security-group/${SecurityGroupId}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"ec2:CreateNatGateway",
				"ec2:CreateSubnet",
				"ec2:RunInstances"
			],
			"Resource": "arn:aws:ec2:${Region}:${Account}:subnet/${SubnetId}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"ec2:AttachInternetGateway",
				"ec2:CreateRouteTable",
				"ec2:CreateSubnet",
				"ec2:CreateVpc",
				"ec2:DescribeVpcAttribute",
				"ec2:ModifyVpcAttribute"
			],
			"Resource": "arn:aws:ec2:${Region}:${Account}:vpc/${VpcId}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"ec2:CreateImage",
				"ec2:ModifyImageAttribute",
				"ec2:RunInstances"
			],
			"Resource": "arn:aws:ec2:${Region}::image/${ImageId}"
		},
		{
			"Effect": "Allow",
			"Action": "ec2:CreateImage",
			"Resource": "arn:aws:ec2:${Region}::snapshot/${SnapshotId}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"eks:AssociateAccessPolicy",
				"eks:DeleteAccessEntry",
				"eks:DescribeAccessEntry",
				"eks:DisassociateAccessPolicy",
				"eks:ListAssociatedAccessPolicies"
			],
			"Resource": "arn:aws:eks:${Region}:${Account}:access-entry/${ClusterName}/${IamIdentityType}/${IamIdentityAccountID}/${IamIdentityName}/${UUID}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"eks:DeleteAddon",
				"eks:DescribeAddon"
			],
			"Resource": "arn:aws:eks:${Region}:${Account}:addon/${ClusterName}/${AddonName}/${UUID}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"eks:CreateAccessEntry",
				"eks:CreateAddon",
				"eks:CreateNodegroup",
				"eks:DeleteCluster",
				"eks:DescribeCluster"
			],
			"Resource": "arn:aws:eks:${Region}:${Account}:cluster/${ClusterName}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"eks:DeleteNodegroup",
				"eks:DescribeNodegroup"
			],
			"Resource": "arn:aws:eks:${Region}:${Account}:nodegroup/${ClusterName}/${NodegroupName}/${UUID}"
		},
		{
			"Effect": "Allow",
			"Action": "iam:CreateServiceLinkedRole",
			"Resource": "arn:aws:iam::${Account}:role/${RoleNameWithPath}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"kms:CreateAlias",
				"kms:DeleteAlias"
			],
			"Resource": "arn:aws:kms:${Region}:${Account}:alias/${Alias}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"kms:CreateAlias",
				"kms:CreateGrant",
				"kms:DeleteAlias",
				"kms:DescribeKey",
				"kms:EnableKeyRotation",
				"kms:GetKeyPolicy",
				"kms:GetKeyRotationStatus",
				"kms:ListResourceTags",
				"kms:PutKeyPolicy",
				"kms:TagResource"
			],
			"Resource": "arn:aws:kms:${Region}:${Account}:key/${KeyId}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"logs:CreateLogGroup",
				"logs:PutRetentionPolicy"
			],
			"Resource": "arn:aws:logs:${Region}:${Account}:log-group:${LogGroupName}"
		},
		{
			"Effect": "Allow",
			"Action": [
				"ssm:DeleteParameter",
				"ssm:GetParameter",
				"ssm:GetParameters",
				"ssm:PutParameter"
			],
			"Resource": "arn:aws:ssm:${Region}:${Account}:parameter/${ParameterNameWithoutLeadingSlash}"
		},
		{
			"Effect": "Allow",
			"Action": "inspector2:CreateCisScanConfiguration",
			"Resource": "arn:aws:inspector2:${Region}:${Account}:owner/${OwnerId}/cis-configuration/${CISScanConfigurationId}"
		},
	]
}

```

