#
# opatch define
#
# installs oracle patches for Oracle products
#
# @param ensure should exist or not
# @param jdk_home_dir full path to the java home directory like /usr/java/default
# @param os_user the user name with oracle as default
# @param os_group the group name with dba as default
# @param log_output show all the output of the the exec actions
# @param download_dir the directory for temporary created files by this class
# @param oracle_product_home_dir on what Oracle home to patch should be applied
# @param patch_id id of the patch
# @param patch_file only the full name of the patch
# @param puppet_download_mnt_point the source of the installation files
# @param orainstpath_dir the location of orainst.loc, default it will the default directory for Linux or Solaris
# @param remote_file to control if the filename is already accessiable on the VM 
#
define orawls::opatch(
  Enum['present','absent'] $ensure  = 'present',
  String $oracle_product_home_dir   = undef, # /opt/oracle/middleware11gR1
  String $jdk_home_dir              = $::orawls::weblogic::jdk_home_dir,
  Integer $patch_id                 = undef,
  String $patch_file                = undef,
  String $os_user                   = $::orawls::weblogic::os_user,
  String $os_group                  = $::orawls::weblogic::os_group,
  String $download_dir              = $::orawls::weblogic::download_dir,
  String $puppet_download_mnt_point = $::orawls::weblogic::puppet_download_mnt_point,
  Boolean $remote_file              = $::orawls::weblogic::remote_file,
  Boolean $log_output               = $::orawls::weblogic::log_output,
  Optional[String] $orainstpath_dir = $::orawls::weblogic::orainstpath_dir,
)
{
  if $ensure == 'present' {
    if $remote_file == true {
      if ! defined(File["${download_dir}/${patch_file}"]) {
        file { "${download_dir}/${patch_file}":
          ensure => file,
          source => "${puppet_download_mnt_point}/${patch_file}",
          backup => false,
          mode   => '0775',
          owner  => $os_user,
          group  => $os_group,
          before => Wls_opatch["${oracle_product_home_dir}:${patch_id}"],
        }
      }
      $disk1_file = "${download_dir}/${patch_file}"
    } else {
      $disk1_file = "${puppet_download_mnt_point}/${patch_file}"
    }
  } else {
    $disk1_file = undef
  }

  wls_opatch{"${oracle_product_home_dir}:${patch_id}":
    ensure       => $ensure,
    os_user      => $os_user,
    source       => $disk1_file,
    jdk_home_dir => $jdk_home_dir,
    orainst_dir  => $orainstpath_dir,
    tmp_dir      => $download_dir,
  }
}