# This generates a virtual host file for nginx
#
# @This generates a virtual host file for nginx
#
#
#
#
#
class nginx::vhosts (
  $vhosts_dir = $nginx::params::vhosts_dir,
) inherits nginx::params{
  file { "${nginx::vhosts_name}.conf": 
    content => epp('nginx/vhosts.conf.epp') #this is telling the class that the content its looking for is in nginx and that its a puppet template file named vhosts.conf.epp
    ensure  => $nginx::vhosts_ensure,
    path    => "${vhosts_dir}/${nginx::vhosts_name}.conf",  
  }
  file { "$nginx::vhosts_root":
    ensure  => 'directory',
  }
}
