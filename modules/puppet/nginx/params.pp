# Stores OS specific parameters
#
# @summary Sotres OS specific paramters
#
#
#
class nginx::params {
  $package_name = 'nginx'
  $service_name = 'nginx'

  case $::osfamily {
    'RedHat': {
      $config_path = '/etc/nginx/nginx.conf'
      $config_source = 'puppet:///modules/nginx/rh-nginx.conf'
      $vhosts_dir = 'etc/nginx/conf.d'
    }
    'Debian': {
      $config_path = 'etc/nginx/nginx.conf'
      $config_source = 'puppet:///modules/nginx/deb-nginx.conf'
      $vhosts_dir = '/etc/nginx/sites-available'
    }
  }
}
