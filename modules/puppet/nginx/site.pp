# this folder would go into the manifests/ in the targeted environment you want to deploy too. 
node debianbasedvm.domain.com {
  class { 'nginx': }
}

node redhatbasedvm.domain.com {
  class { 'nginx': }
}
