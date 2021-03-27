# This file installs, configues and sets up nginx on the virtual host
#
# by typiing class nginx contain, we are saying we want to pass through the install. config, and service files to the node
#
# the block below tells the inti file we want to run install first, and then config after install. The ~> tells puppet to only run the service file if changes to the higher files have been made.
# this file would be in the manifests folder

class nginx ( 
  $package_name  = $nginx::params::package_name,  #these values come from the params.pp file
  $config_path   = $nginx::params::config::path,  #these values come from the params.pp file
  $config_source = $nginx::params::config_source,  #these values come from the params.pp file
  $service_name  = $nginx::params::service_name,  #these values come from the params.pp file
  $vhosts_dir    = $nginx::params::vhosts_dir, #these values come from the params.pp file
  String $package_ensure, #these values come from Hiera key values, declared the common.yaml file
  String $config_ensure, #these values come from Hiera key values, declared the common.yaml file
  String $service_ensure, #these values come from Hiera key values, declared the common.yaml file
  Boolean $service_enable, #these values come from Hiera key values, declared the common.yaml file
  Boolean $service_hasrestart, #these values come from Hiera key values, declared the common.yaml file
  String $vhosts_port,  #these values come from Hiera key values, declared the common.yaml file
  String $vhosts_root,  #these values come from Hiera key values, declared the common.yaml file
  String $vhosts_name,  #these values come from Hiera key values, declared the common.yaml file 
) inherits nginx::params {
  contain nginx::install
  contain nginx::config
  contain nginx::service
  contain nginx::vhosts

  Class['nginx::install']
  -> Class['nginx::config']
  ~> Class['nginx::service']
  -> Class['nginx:vhosts']

