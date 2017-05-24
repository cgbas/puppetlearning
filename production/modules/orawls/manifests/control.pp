#
# control define
#
# Weblogic Server control, starts or stops a managed server
#
# installs WebLogic 11g BSU patch
#
# @example Starting an AdminServer,Cluster or OHS
#   orawls::control{'startAdmin':
#     domain_name       => 'domainX',
#     weblogic_password => 'weblogic1',
#   }
#
#   orawls::control{'startCluster':
#     domain_name         => 'domainX',
#     weblogic_user       => 'weblogic',
#     weblogic_password   => 'weblogic1',
#     server_type         => 'managed',
#     target              => 'Cluster',
#     server              => 'MyCluster',
#     adminserver_address => '10.10.10.10',
#     action              => 'start',
#     jsse_enabled        =>  true,
#   }
#
#   orawls::control{'startOHS1server':
#     domain_name         => 'domainX',
#     weblogic_user       => 'weblogic',
#     weblogic_password   => 'weblogic1',
#     server_type         => 'ohs_standalone',
#     target              => 'Server',
#     server              => 'ohs1',
#     adminserver_address => '10.10.10.10',
#     action              => 'start',
#     wls_domains_dir     =>  '',
#     os_user             => 'oracle',
#     os_group            => 'dba'
#     download_dir        => '/var/tmp/install',
#     weblogic_home_dir   => '/opt/oracle/middleware12c/wlserver',
#     middleware_home_dir => '/opt/oracle/middleware12c',
#     jdk_home_dir        => '/usr/java/latest',
#   }
#
# @param wls_domains_dir root directory for all the WebLogic domains
# @param middleware_home_dir directory of the Oracle software inside the oracle base directory
# @param domain_name the domain name which to connect to
# @param adminserver_address the adminserver network name or ip, default = localhost
# @param adminserver_port the adminserver port number, default = 7001
# @param weblogic_user the weblogic administrator username
# @param weblogic_password the weblogic domain password
# @param weblogic_home_dir directory of the WebLogic software inside the middleware directory
# @param jdk_home_dir full path to the java home directory like /usr/java/default
# @param os_user the user name with oracle as default
# @param os_group the group name with dba as default
# @param log_output show all the output of the the exec actions
# @param download_dir the directory for temporary created files by this class
# @param jsse_enabled enable JSSE on the JVM
# @param custom_trust have your own trustore JKS or using the default
# @param trust_keystore_file the full path to the trust keystore
# @param trust_keystore_passphrase the password of the trust keystore
# @param server_type admin, ohs or a managed server
# @param target Server or Cluster
# @param server name of the WebLogic object
# @param adminserver_secure_listener use t3s or not
# @param nodemanager_port the nodemanager port number
# @param nodemanager_secure_listener use secure nodemenager
# @param action start or stop the server
# @param extra_arguments extra.java arguments for the startup
#
define orawls::control (
  String $weblogic_home_dir                               = $::orawls::weblogic::weblogic_home_dir,
  String $middleware_home_dir                             = $::orawls::weblogic::middleware_home_dir,
  String $jdk_home_dir                                    = $::orawls::weblogic::jdk_home_dir,
  Optional[String] $wls_domains_dir                       = $::orawls::weblogic::wls_domains_dir,
  String $domain_name                                     = undef,
  String $os_user                                         = $::orawls::weblogic::os_user,
  String $os_group                                        = $::orawls::weblogic::os_group,
  String $download_dir                                    = $::orawls::weblogic::download_dir,
  Boolean $log_output                                     = $::orawls::weblogic::log_output,
  Enum['admin','managed','ohs_standalone'] $server_type   = 'admin',
  Enum['Server','Cluster'] $target                        = 'Server',
  String $server                                          = 'AdminServer',
  String $adminserver_address                             = 'localhost',
  Integer $adminserver_port                               = 7001,
  Boolean $adminserver_secure_listener                    = false,
  Integer $nodemanager_port                               = 5556,
  Boolean $nodemanager_secure_listener                    = true,
  Enum['start','stop','running','abort'] $action          = 'start',
  String $weblogic_user                                   = 'weblogic',
  String $weblogic_password                               = undef,
  Boolean $jsse_enabled                                   = false,
  Boolean $custom_trust                                   = false,
  Optional[String] $trust_keystore_file                   = undef,
  Optional[String] $trust_keystore_passphrase             = undef,
  String $extra_arguments                                 = '', # '-Dweblogic.security.SSL.minimumProtocolVersion=TLSv1'
)
{
  if ( $wls_domains_dir == undef or $wls_domains_dir == '') {
    $domains_dir = "${middleware_home_dir}/user_projects/domains"
  } else {
    $domains_dir =  $wls_domains_dir
  }

  $domain_dir = "${domains_dir}/${domain_name}"

  if $server_type == 'admin' {
    wls_adminserver{"${title}:AdminServer":
      ensure                      => $action,   #running|start|abort|stop
      server_name                 => $server,
      domain_name                 => $domain_name,
      domain_path                 => $domain_dir,
      os_user                     => $os_user,
      weblogic_home_dir           => $weblogic_home_dir,
      weblogic_user               => $weblogic_user,
      weblogic_password           => $weblogic_password,
      jdk_home_dir                => $jdk_home_dir,
      nodemanager_address         => $adminserver_address,
      nodemanager_port            => $nodemanager_port,
      nodemanager_secure_listener => $nodemanager_secure_listener,
      jsse_enabled                => $jsse_enabled,
      custom_trust                => $custom_trust,
      trust_keystore_file         => $trust_keystore_file,
      trust_keystore_passphrase   => $trust_keystore_passphrase,
      extra_arguments             => $extra_arguments,
    }
  }
  elsif $server_type == 'ohs_standalone' {
    wls_ohsserver{"${title}:AdminServer":
      ensure                      => $action,   #running|start|abort|stop
      server_name                 => $server,
      domain_name                 => $domain_name,
      domain_path                 => $domain_dir,
      os_user                     => $os_user,
      weblogic_home_dir           => $weblogic_home_dir,
      weblogic_user               => $weblogic_user,
      weblogic_password           => $weblogic_password,
      jdk_home_dir                => $jdk_home_dir,
      nodemanager_address         => $adminserver_address,
      nodemanager_port            => $nodemanager_port,
      nodemanager_secure_listener => $nodemanager_secure_listener,
      jsse_enabled                => $jsse_enabled,
      custom_trust                => $custom_trust,
      trust_keystore_file         => $trust_keystore_file,
      trust_keystore_passphrase   => $trust_keystore_passphrase,
      extra_arguments             => $extra_arguments,
    }
  }
  else {
    wls_managedserver{"${title}:Server":
      ensure                      => $action,   #running|start|abort|stop
      target                      => $target,
      server_name                 => $server,
      domain_name                 => $domain_name,
      os_user                     => $os_user,
      weblogic_home_dir           => $weblogic_home_dir,
      weblogic_user               => $weblogic_user,
      weblogic_password           => $weblogic_password,
      jdk_home_dir                => $jdk_home_dir,
      adminserver_address         => $adminserver_address,
      adminserver_port            => $adminserver_port,
      adminserver_secure_listener => $adminserver_secure_listener,
    }
  }
}
