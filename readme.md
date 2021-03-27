##########################################################################
#  The files listed in here are documented as I am working               #
#  This would not be the strucutre of the repo, file intended            #
#  locations will be notated within the comments of each file            #
#  most of these files will normally be created with the puppet PDk      #
##########################################################################

# Environment location 
# /etc/puppetlabs/code/<environment>
# 
# Module directory
# /etc/puppetlabs/code/<environment>/modules
#
# Default location of node-to-module mapping
# /etc/puppetlabs/code/<environment>/manifests/site.pp
#
#
# Puppet uses a master server agent relationship where the master server pushes catalogs to the puppet agent which is installed on the server. 
# modules allow you to build specific app based provisioning kits out and assign app configurations to servers or nodes and have them deployed.
#
#
# Facter is a service that puppet uses to collect various information about all the different systems that puppet is managing including 
# OS, uptime, timezone, virtualization, file system information, distro. This can be looked up on the master or node by running facter.
#
#
