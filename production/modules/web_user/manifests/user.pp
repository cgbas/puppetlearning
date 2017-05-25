define web_user::user (
  $content = "<h1>Bem-vindx a pagina de ${title}</h1>",
  $password = undef,
){
  $home_dir = "/home/${title}"
  $public_html = "${home_dir}/public_html"
  user { $title:
    ensure   => present,
    password => $password,
  }
  file { [$home_dir, $public_html]:
    ensure => directory,
    owner  => $title,
    group  => $title,
    mode   => '0775',
  }
  file { "$public_html/index.html":
    ensure  => file,
    owner   => $title,
    group   => $title,
    replace => false,
    content => $content,
    mode    => '0664',
  }
}
