class sshd {
  package { 'openssh-server':
    ensure  => present,
  }
  service { 'sshd':
    ensure  => running,
    enable  => true,
    require => Package['openssh-server'],
  }
  file { '/etc/ssh/sshd_config':
    ensure  => present,
    require => Package['openssh-server'],
  }

}
