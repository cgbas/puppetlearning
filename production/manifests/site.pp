## site.pp ##

# This file (/etc/puppetlabs/puppet/manifests/site.pp) is the main entry point
# used when an agent connects to a master and asks for an updated configuration.
#
# Global objects like filebuckets and resource defaults should go in this file,
# as should the default node definition. (The default node can be omitted
# if you use the console and don't define any other nodes in site.pp. See
# http://docs.puppetlabs.com/guides/language_guide.html#nodes for more on
# node definitions.)

## Active Configurations ##

# Disable filebucket by default for all File resources:
File { backup => false }

# DEFAULT NODE
# Node definitions in this file are merged with node data from the console. See
# http://docs.puppetlabs.com/guides/language_guide.html#nodes for more on
# node definitions.

# The default node definition matches any node lacking a more specific node
# definition. If there are no other nodes in this file, classes declared here
# will be included in every node's catalog, *in addition* to any classes
# specified in the console for that node.

node default {
  # This is where you can declare classes for all nodes.
  # Example:
  #   class { 'my_class': }
  notify { "Aqui e ${::fqdn}, rodando o sistema operacional ${::operatingsystem}":  }
}

node 'learning.puppetlabs.vm' {
  mysql_database { 'lvm':
    ensure  => present,
    charset => 'utf8',
  }
  mysql_user{ 'lvm_user@localhost':
    ensure => present,
  }
  mysql_grant { 'lvm_user@localhost/lvm.*':
    ensure     => present,
    options    => ['GRANT'],
    privileges => ['ALL'],
    table      => 'lvm.*',
    user       => 'lvm_user@localhost',
  }
  class {'ntp':
    servers => [
      'nist-time-server.eoni.com',
      'nist1-lv.ustiming.org',
      'ntp-nist.ldbsc.edu'
    ]
  }
  class {'::mysql::server':
    root_password    => 'strongpassword',
    override_options => {
      'mysqld'       =>  { max_connections => 1024 }
    },
  }
  include ::mysql::server::account_security
  include multi_node
  node /^(webserver|database).*$/ {
    pe_ini_setting { 'use_cached_catalog':
      ensure  =>  present,
      path    =>  $settings::config,
      section =>  'agent',
      setting =>  'use_cached_catalog',
      value   =>  'true',
    }
    pe_ini_setting { 'pluginsync':
      ensure  =>  present,
      path    =>  $settings::config,
      section =>  'agent',
      setting =>  'pluginsync',
      value   =>  'false',
    }
  }
}

