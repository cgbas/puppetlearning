class web {
  $doc_root = '/var/www/quest'

  $english = "Hello world!"
  $french = "Bonjour le monde!"

  file { "${doc_root}/hello.html":
    ensure  => file,
    content => "<em>${english}</em>",
  }

  file { "${doc_root}/hello.html":
    ensure  => file,
    content => "<em>${french}</em>",
  }
}
