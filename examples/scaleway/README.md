## Introduction
The terraform project will instanciated a devops-stack on Scaleway.

## Installation

Add your credentials to launch the project. At least the following environement variables are required: `SCW_ACCESS_KEY,SCW_ACCESS_KEY,SCW_DEFAULT_ORGANIZATION_ID,SCW_DEFAULT_PROJECT_ID,SCW_DEFAULT_PROJECT_ID`.

We also use an environement variable for the variable PROJECT\_ID called `TF_VAR_PROJECT_ID`

Configure the stack by modifying `inputs.tfvars` (e.g: cluster\_name) and launch the terraform apply with:

If you want to create a Kapsule cluster, you will have to use the scaleway provider in version 2.33.0.

If you modify the base\_domain, be sure to add a new star record that points to the load balancer ip address created by the stack in your domain.

```bash
terraform init
terraform apply -var-file inputs.tfvars 
```

## Usage
Get the kubeconfig file and the domain name with the following commands:

```bash
terraform output -raw kubeconfig_file > kubeconfig.json
terraform output base_domain 
```
 
Your application are available at the following address: $APP\_NAME.apps.$CLUSTER\_NAME.$BASE\_DOMAIN.
e.g: prometheus.apps.devops-stack.51-51-52-52.np.io

For authentication on oidc, users and password are available in the output:
```bash
terraform output passwords
```

