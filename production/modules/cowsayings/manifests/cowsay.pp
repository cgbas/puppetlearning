class cowsayings::cowsay {
  package { 'cowsay':
    ensure   => present,
    provider => 'gem',
  }
}
