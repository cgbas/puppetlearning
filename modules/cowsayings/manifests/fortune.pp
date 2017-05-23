class cowsayings::fortune {
  package { 'fortune-mod':
    ensure => present,
  }
}
