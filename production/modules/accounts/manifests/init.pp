class accounts($user_name) {
  if $::operatingsystem == 'centos' {
    $groups = 'wheel'
  }
  elsif $::operatingsystem == 'debian' {
    $groups = 'debian'
  }
  else {
    fail("Esse modulo nao suporta ${::operatingsystem}.")
  }

  notice("Grupos  para usuario ${user_name} definidos para ${groups}")

  user { $user_name:
    ensure => present,
    home   => "/home/${user_name}",
    groups => $groups,
  }

}
