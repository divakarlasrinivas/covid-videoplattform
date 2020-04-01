locals {
  vm_hosts_with_groups = {
    for hostname, host in var.vm_hosts: hostname => host if contains(keys(host),"groups")
  }
  vm_hosts_without_groups = {
    for hostname, host in var.vm_hosts: hostname => host if !contains(keys(host),"groups")
  }
  vm_groups = distinct(flatten(values(local.hetzner_vm_hosts_with_groups)[*].groups))
}

output "ansible_inventory" {
  value = {
    all = {
      hosts = {
        for hostname,hostvars in var.vm_hosts: hostname => local.providers[hostvars.provider].hostvars[hostname]
      }
      children = merge(
        {
          for group in local.vm_groups: group => {
            hosts = {
              for hostname, host in local.vm_hosts_with_groups:
                hostname => {}
                if contains(host.groups,group)
            }
          }
        },{
          for providername, provider in local.providers: "provider_${providername}" => {
            hosts = {
              for hostname, host in local.vm_hosts_with_groups:
                hostname => {}
                if host.provider == providername
            }
          }
        }
      )
    }
  }
}
