class vimrc {
  file { '/root/.vimrc':
    ensure => file,
    source => 'puppet:///modules/vimrc/vimrc'
  }
}

