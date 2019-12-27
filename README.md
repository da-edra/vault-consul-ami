# Vault and Consul AMI

This folder shows an example of how to use the [install-vault module](https://github.com/hashicorp/terraform-aws-vault/tree/master/modules/install-vault) from this Module and
the [install-consul](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/install-consul)
and [install-dnsmasq](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/install-dnsmasq) or the
[setup-systemd-resolved](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/setup-systemd-resolved)
modules from the Consul AWS Module with [Packer](https://www.packer.io/) to create [Amazon Machine Images
(AMIs)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) that have Vault and Consul installed on top of Amazon Linux 2

You can use this AMI to deploy a [Vault cluster](https://www.vaultproject.io/) by using the [vault-cluster
module](https://github.com/hashicorp/terraform-aws-vault/tree/master/modules/vault-cluster). This Vault cluster will use Consul as its storage backend, so you can also use the
same AMI to deploy a separate [Consul server cluster](https://www.consul.io/) by using the [consul-cluster
module](https://github.com/hashicorp/terraform-aws-consul/tree/master/modules/consul-cluster).

Check out the [vault-cluster-private](https://github.com/hashicorp/terraform-aws-vault/tree/master/examples/vault-cluster-private) and
[the root example](https://github.com/hashicorp/terraform-aws-vault/tree/master/examples/root-example) examples for working sample code. For more info on Vault
installation and configuration, check out the [install-vault](https://github.com/hashicorp/terraform-aws-vault/tree/master/modules/install-vault) documentation.
