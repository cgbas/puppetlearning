class sshd {
  package { 'openssh-server':
    ensure  => present,
    require => Service['sshd'],
  }
  service { 'sshd':
    ensure => running,
    enable => true,
  }

}
