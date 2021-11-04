# Testing AKS cluster

## Quick launch:

You will need to create a new DNS to hold the devops stack. This needs to be
created by hand or added in terraform.More info here : 

https://docs.microsoft.com/en-us/azure/dns/dns-zones-records

You will need to feed the public_ssh_fie variable. 

```
terraform apply  -var public_ssh_file=/home/[MYUSER]/.ssh/id_rsa.pub -var
base_domain=your.base.doma.in
```

