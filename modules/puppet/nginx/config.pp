# Manges the nginx.conf file
# 
# @summary Managed the nginx.conf file
#
#

class nginx::config (
  $config_path    = $nginx::params::config_path
  $config_source  = $nginx::params::config_source
  ) inherits nginx:params {
  file { 'nginx_conf':
    path   => $config_path,
    source => $config_source, # the "puppet:///" URI allows us to tell puppet to automatically search the enivorinment code directory and nginx. You will not need to reference the files folder 
    ensure => $nginx::config_ensure,
    notify => Service['nginx_service'], #this ensures that puppet will trigger a restart everytime theres a change in this file
  }
}

# after creating this you can validate the file by running puppet parser validate manifests/config.pp
