## This is an example of a class file to install nginx
## "class nginx:install" refers to the name that we are calling this class file
## "package" is a predefined resource block that is static to call a package in puppet
## "install_ngnix" is the name we are giving the package
## "name => 'nginx'" is the name of the software we are installing
## "ensure => 'present'" is telling the class file that this package "nginx" must be prersent. 
# install nginx
#
# @summary installs nginx
#
# @example
#    include nginx::install
class nginx::install (
  $package_name = $nginx::params::package_name,
) inherits nginx::params {
    package { 'install_nginx':
        name    => $package_name,
        ensure  => $nginx::package_ensure,
    }
}
