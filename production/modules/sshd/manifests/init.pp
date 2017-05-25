class sshd {
  package { 'openssh-server':
    ensure => present,
  }
  service { 'sshd':
    ensure => running,
    enable => true,
    require => Package['openssh-server']
  }

}
