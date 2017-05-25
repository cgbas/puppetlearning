class sshd {
  package { 'openssh-server':
    ensure  => present,
  }
  service { 'sshd':
    ensure    => running,
    enable    => true,
    require   => Package['openssh-server'],
    subscribe => File['/etc/ssh/sshd_config'],
  }
  file { '/etc/ssh/sshd_config':
    ensure  => present,
    require => Package['openssh-server'],
  }

}
