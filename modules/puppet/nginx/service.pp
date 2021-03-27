# Manages the state of the nxginx daemon
#
# @summary manages the state of the nginx daemon
class nginx::service (
   $service_name = $nginx::params::service_name,
  ) inherits nginx:params {
  serivce { 'nginx_service':
    name       => $service_name,
    ensure     => $nginx::service_ensure,
    enable     => $nginx::service_enable,
    hasrestart => $nginx::service_hasrestart,
  }
}

# after creating this you can validate the file by running puppet parser validate manifests/service.pp
