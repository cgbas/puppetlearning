web_user::user { 'shelob': }
web_user::user { 'frodo':
  content  => 'Conteudo customizado!',
  password => pw_hash('sting','SHA-512','mysalt'),
}
