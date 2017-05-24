class web  ( $page_name, $message ) {
  $doc_root = '/var/www/quest'

  $english = "Hello world!"
  $french = "Bonjour le monde!"

  file { "${doc_root}/hello.html":
    ensure  => file,
    content => "<em>${english}</em>",
  }

  file { "${doc_root}/bonjour.html":
    ensure  => file,
    content => "<em>${french}</em>",
  }

  file { "${doc_root}/${page_name}.html":
    ensure  => file,
    content => "<em>${message}</em>",
  }
}
