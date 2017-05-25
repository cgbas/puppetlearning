define web_user::user {
  $home_dir = "/home/${title}"
  user { $title:
    ensure => present,
  }
  file { $home_dir:
    ensure => directory,
    owner  => $title,
    group  => $title,
    mode   => '0775',
  }
}
