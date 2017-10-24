
# Intuito desse repositório

Comecei a estudar puppet e me encantei pelas possibilidades que se abriram. Como o material da VM de aprendizagem esta em inglês, resolvi compartilhar todas minhas notas e o que julguei que era interessante traduzir da da documentação além de demais itens que forem criados no processo de estudo da mesma. As notas estarão divididas pelas buscas (quests) do material oficial, todo e qualquer artefato estará dividido nessa mesma hierarquia. Alguns termos eu realmente preferi manter no original e citar sua tradução apenas uma vez - como no caso das _quests_, quando for assim manterei a palavra em italico.

Para acompanhar as notas, utilize o _Quest Guide_ e a VM contidas no _.zip_ disponível via: https://puppet.com/download-learning-vm

O script `gitsays.sh` foi uma brincadeira com o módulo `cowsays` do material. E apenas um wrapper para eu transferir as coisas da VM para meu repositorio local (atualizando), dar um commit e enviar para o GitHub (utilizo chave SSH para isso).

A minha trajetoria rumo a um legado totalmente administrado com código pode ser conferida nesse outro repositorio, o "Legado Legal": https://github.com/cgbas/legadolegal

# Força do Puppet

Para buscar um módulo:
    
```
    puppet module search graphite
    puppet module install dwerder-graphite -v 5.16.1
      --module_repository=https://forge.puppet.com
```

* Para o puppet, classe e um bloco que serve para agrupar recursos
* Um módulo pode abrigar varias classes, mas geralmente vai ter uma classe main, com o mesmo nome do módulo (como no java)
    - geralmente responsavel por instalar/configurar o componente primario desse módulo
* class + node = classificacao (classification)
* grupo de no (node group): permite classificar _nodes_ baseados no certname e nas informações coletadas via `facter`
* Utilizar para disparar atualização no Puppet
    `puppet agent -t`
* O daemon de agente do puppet roda, por padrão, a cada 30min. Pede um catálogo ao master, parseia, gera um catálogo do node e devolve ao agente, o agente então aplica qualquer change necessaria para estar up-to-date com o catálogo
* Executa manualmente essa sincronia com master
    `puppet agent --test`


# Recursos

Recursos são  os alicerces da linguagem de modelagem declarativa do puppet. são  todo e qualquer aspecto da configuração de sistema que deseja-se gerenciar, traduzidas em uma unidade chamada recurso. Essa e a base da RAL (Resource Abstraction Layer, camada de abstracao de rescursos) do Puppet.

Descrevemos recursos dentro de uma declaração de recurso (resource declaration), fazemos isso em código puppet, uma linguagem de dominio especifico (DSL, domain specific language) baseada em Ruby.

A _DSL_ do puppet e declarativa e não imperativa, dependendo de provedores para cuidar da implementacao. Dito isso, a preocupacao esta apenas em descrevermos/declararmos um estado final desejado.

A base para a _DSL_ vem da sintaxe de _hash_ do proprio Ruby, que vai ser o objetivo da declaração de recursos nessa _quest_. Uma das facilidades dessa _DSL_ esta em podermos inpecionar o estado de um recurso da mesma maneira que declaramos seu estado desejado.

## Tarefa 1:

Consultar as informações da conta de usuário root:

```
    puppet resource user root

    user { 'root':
      ensure           => 'present',
      comment          => 'root',
      gid              => '0',
      home             => '/root',
      password         => '$1$PDA6nUdk$VuCzgPhfmyAww/ifIwP35/',
      password_max_age => '99999',
      password_min_age => '0',
      shell            => '/bin/bash',
      uid              => '0',
    }
```

Essa linguagem de declaração possui três elementos: tipo, título, par-valor do atributo

## Tipo

```
    user { 'root':
      ...
    }
```

Outros tipos principais são : _group, file, package, service, cron, exec e host_Para consultar todos os tipos, use: https://docs.puppet.com/puppet/latest/type.html ou utilize `puppet describe --list`


## título

```
    user { 'root':
      ...
    }
```

No exemplo acima, `'root'` e nosso título. Trata-se do identificador interno - e unico - para esse recurso. Serve como uma chave primaria, já que _dois recursos do mesmo tipo jamais podem compatilhar o mesmo nome_. Geralmente o título do recurso condiz com o nome da coisa que esse recurso gerencia: usuários e pacotes com seus nomes, arquivos com seus paths completos. O Puppet permite que você declare explicitamente os títulos de seus recursos, mas isso pode ser tornar mais dificil a gestao do seu código e impedir economizar algumas linhas.

## Par-valor de um atributo

Utilizando a sintaxe abaixo,

```
    user { 'root':
        shell            => '/bin/bash',
    }
    
```

No corpo da declaração de um recurso temos seus atributos, compostos por: atributo, hash rocket (=>) e seu valor correspondente. Sendo assim, no exemplo acima, temos que _/bin/bash_ e o shell do usuário _root_.

Note que ha uma virgula mesmo com apenas um recurso declarado no exemplo, isso e uma boa pratica, de forma a garantir que não esqueçamos de colocar virgulas em alguma outra declaração de atributo, caso um recurso precise ser atualizado

## Tarefa 2

Percebemos então que o outro esta em saber manipular bem os atributos de um recurso, para conhece-los melhor e explorar isso, utilizamos o comando describe. Como abaixo:

`puppet describe user | less`

__Dica:__ executar o comando acima em uma sessão de ssh propria, no webshell o mesmo pode truncar.

## Puppet Apply

A ferramenta `puppet apply` pode ser utilizada com a _flag_ (bandeira) -e (de --execute) para executar código puppet. Dessa maneira a execução acontece apenas uma vez, sendo util para testes e exploracao.

## Tarefa 3

A _flag ensure_ serve para que o puppet confira no sistema se o recurso existe e, caso negativo, realize a criação do mesmo.

`puppet apply -e "user { 'galatea': ensure => present, }" `

Para conferir o usuário

`puppet resource user galatea`

O mesmo não possui ainda o atributo _Comments_ como no caso do usuário root.

## Tarefa 4

Poderiamos adicionar o atributo via `puppet apply -e`, mas nesse caso deveriamos passar a declaração toda em uma linha so, alem de que não poderiamos ver o estado do recurso antes de aplicar tudo. A ferramenta `puppet resource` possui a _flag_ `-e`, que abre o conteúdo do recurso diretamente em um editor (Vim por padrão) e nos permite editar de uma maneira melhor. Para adicionar um atributo basta incluir uma linha (nao esqueça da virgula ao vinal), com o par valor (e o _hash rocket_).

Sendo assim, para editar o recurso `galatea`, usamos:

`puppet resource -e user galatea`

Exemplo:

```
user { 'galatea':
  ensure           => 'present',
  comment          => 'Galatea Lovelace',
  (...)
```

# Classes e Manifestos

## Manifestos

Um manifesto e basicamente um arquivo `.pp` que contém as informações vistas via `puppet resource` e inseridas via `puppet apply`, o que importa mesmo e a localizacao desse manifesto. Tanto sua localizacao como sua estrutura em relacao ao FS do Puppet master são  devido as classes.

## Classes

E o proximo nivel de abstracao acima de um recurso, declara um grupo de rescursos relacionados a um unico componente de sistema. Possui parâmetros para adapta-la as suas necessidades. Dessa maneira podemos administrar recursos de acordo com sua funcao.

Para utilizar uma classe, cumprimos dois passos: definir (e salvar em um manifesto), assim o Puppet realizara o parse para lembrar a definição da mesma. só então a mesma pode ser declarada para aplicar todas as declaracoes de recurso que contém em um _node_ da sua infraestrutura.

Dentro de um _node_, classes são  _singletons_ portanto só podem ser declaradas uma unica vez por _node_ (nao confundir com a ideia de classes em OOP, por exemplo).

# Cowsayings (Vacas Falantes)

O objetivo aqui vai ser utilizar o recurso do tipo _package_ (pacote) e a VM já preparou um diretório no _modulepath_ do Puppet, com os diretórios _manifests_ e _examples_, em:

`/etc/puppetlabs/code/environments/production/modules`

## Cowsay

Para utilizar o comando `cowsay`, precisamos instalar o _package cowsay_. Podemos utilizar o recurso _package_ porém essa declaração precisa ir para algum lugar.

### Tarefa 1

Crie a estrutura de diretório do nosso módulo (lembrando que entendemos módulo como um abrigador de classes, com suas classes homonimas sendo responsaveis por instalar/conigurar os pacotes primarios desse módulo):

```
    mkdir -p cowsayings/{manifests,examples}
```

__Nota:__ por convencao, o diretório _manifests_ contém as classes, cada uma em seu respectivo arquivo homônimo. O diretório _examples_ contém os testes para essas classes.

Crie um manifesto com o vim:

```
    vim cowsayings/manifests/cowsay.pp
```

Insira a seguinte definição:

```
    class cowsayings::cowsay {
      package { 'cowsay':
        ensure   => present,
        provider => 'gem',
      }
    }
```

Para validar o manifesto, usamos:

```
    puppet parser validate cowsayings/manifests/cowsay.pp
```

O comando só retorna alguma saida caso exista algum erro (recomendo colocar algo errado no manifesto e testar). Como a classe esta apenas definida e não declarada, ficamos impossibilitados de aplica-la, apesar do comando de apply concluir, o resultado  de `puppet resource package cowsay` e:

```
    package { 'cowsay':
      ensure => 'purged',
    }
```

Resultado caso tentemos aplicar antes de declarar:

```
# puppet apply cowsayings/manifests/cowsay.pp 
    Notice: Compiled catalog for learning.puppetlabs.vm in environment production in 0.08 seconds
    Notice: Applied catalog in 0.80 seconds
```

### Tarefa 2

Arquivos de manifesto .pp contidos em _examples_ ou _tests_ geralmente são  utilizados para validarmos classes que estamos desenvolvendo em um módulo. Por convencao vamos utilizar o diretório _examples_ que criamos anteriormente.

`vim cowsayings/examples/cowsay.pp`

Nesse manifesto, vamos _declarar_ a classe com a palavra chave __include__:

`include cowsayings::cowsay`

__Dica:__ a _flag_ `--noop` faz uma dry run (execução enxuta) do agente, compilando o catálogo e notificando as mudanças que seriam aplicadas sem realmente aplicar nada ao sistema.

Para testar, usamos então:

`puppet apply --noop cowsayings/examples/cowsay.pp`

Exemplo da saida com `--noop`:

```
    Notice: Compiled catalog for learning.puppetlabs.vm in environment production in 0.12 seconds
    Notice: /Stage[main]/Cowsayings::Cowsay/Package[cowsay]/ensure: current_value absent, should be present (noop)
    Notice: Class[Cowsayings::Cowsay]: Would have triggered 'refresh' from 1 events
    Notice: Stage[main]: Would have triggered 'refresh' from 1 events
    Notice: Applied catalog in 1.42 seconds
```

__Nota:__ em uma Instalação offline ou com um firewall você pode necessitar instalar o gem de um cache local da VM. Em uma infra real, você pode configurar um _mirror_ (espelho) de um _rubygems_ com uma ferramenta como o __Stickler__ (`gem install --local --no-rdoc --no-ri /var/cache/rubygems/gems/cowsay-*.gem`).

### Tarefa 3

Caso a execução com `--noop` seja bem sucedida, aplique o manifesto removendo a _flag_ `--noop`:

```
    puppet apply cowsayings/examples/cowsay.pp 
    Notice: Compiled catalog for learning.puppetlabs.vm in environment production in 0.14 seconds
    Notice: /Stage[main]/Cowsayings::Cowsay/Package[cowsay]/ensure: created
    Notice: Applied catalog in 2.25 seconds
```

Teste de execução:

```
# cowsay Can I Haz Soy Milk?

 _____________________ 
| Can I Haz Soy Milk? |
 --------------------- 
      \   ^__^
       \  (oo)\_______
          (__)\       )\/\
              ||----w |
              ||     ||
```

## Sorte

Esse módulo não e inteiramente sobre nossa vaca, mas tambem sobre o que ela fala. Com o package `fortune` podemos fornecer uma base de dados com frases de sabedoria.

### Tarefa 4

Vamos criar um novo manifesto para nossa definição da classe _fortune_: `vim cowsayings/manifests/fortune.pp`

E inserir a seguinte definição (_atencao aqui ao título sendo customizado_):

```
    class cowsayings::fortune {
      package { 'fortune-mod':
        ensure => present,
      }
    }
```

### Tarefa 5

Precisamos validar nosso manifesto via `puppet parser validate`, caso tudo esteja ok, podemos criar nosso manifesto de teste.

`vim cowsayings/examples/fortune.pp`

Aqui, devemos adicionar o `include` para declarar nossa classe `cowsayings::fortune`.

### Tarefa 6

Aplique o `coswsayings/examples/fortune.pp` com a _flag_ `--noop`. Caso tudo corra bem, aplique sem a _flag_. 

```
    # puppet apply --noop cowsayings/examples/fortune.pp 
    Notice: Compiled catalog for learning.puppetlabs.vm in environment production in 0.13 seconds
    Notice: /Stage[main]/Cowsayings::Fortune/Package[fortune-mod]/ensure: current_value purged, should be present (noop)
    Notice: Class[Cowsayings::Fortune]: Would have triggered 'refresh' from 1 events
    Notice: Stage[main]: Would have triggered 'refresh' from 1 events
    Notice: Applied catalog in 1.96 seconds
```

Com ambos pacotes instalados, podemos combinar comandos, como `fortune | cowsay`. Apesar de um exemplo simples, instalamos dois pacotes de maneira parecida como instalariamos o Apache e o PHP em nosso servidor.

```
    # puppet apply cowsayings/examples/fortune.pp 
    Notice: Compiled catalog for learning.puppetlabs.vm in environment production in 0.13 seconds
    Notice: /Stage[main]/Cowsayings::Fortune/Package[fortune-mod]/ensure: created
    Notice: Applied catalog in 5.96 seconds
```

```
    fortune | cowsay
     _________________________________________ 
    | When in doubt, use brute force. -- Ken  |
    | Thompson                                |
     ----------------------------------------- 
          \   ^__^
           \  (oo)\_______
              (__)\       )\/\
                  ||----w |
                  ||     ||
```

## Classe principal: init.pp

Um módulo geralmente reune varias classes que trabalham juntas assim declaramos tudo de uma vez. No entanto precisamos fazer uma ressalva em relacao ao __escopo__. As classes que escrevemos para cowsay, são  todas precedidas por `cowsayings::`. Quando declaramos uma classe, dizemos com essa sintaxe de escopo que essa classe pode ser encontrada no módulo _cowsayings_.

No caso da classe principal de um módulo, as coisas mudam um pouco. Ao inves de nomearmos o manifesto utilizando o nome da classe que ele contém, o Puppet reconhece o arquivo especial __init.pp__ como contenedor do manifesto de nossa classe principal.

### Tarefa 7

Para conter nossa classe `cowsayings`, crie um arquivo de manifesto `init.pp` no diretório `cowsayings\manifests`:

`vim cowsayings\manifests\init.pp`

Nele, vamos definir a classe _cowsayings_, dentro da mesma utilizamos a mesma sintaxe (`include módulo::classe`) para declarar as classes contidas.

```
    class cowsayings {
        include cowsayings::cowsay
        include cowsayings::fortune
    }
```

Salve o manifesto e teste com a ferramanta `puppert parser validate`.

### Tarefa 8

Nesse estagio, tanto o pacote __fortune__ como o __cowsays__ já estão  instalados na VM. Aplicar nossas mudanças não alteraria em nada, então utilizaremos a ferramenta `puppet resource` para deletar esses pacotes e testarmos a funcionalidade da nossa classe __cowsays__ recém criada:

```
    #puppet resource package fortune-mod ensure=absent

    Notice: /Package[fortune-mod]/ensure: removed
    package { 'fortune-mod':
      ensure => 'purged',
    }

    # puppet resource package cowsay ensure=absent provider=gem

    Notice: /Package[cowsay]/ensure: removed
    package { 'cowsay':
      ensure => 'absent',
    }
```

Agora crie um teste para o manifesto _init.pp_ no diretório de exemplos:

```
    vim cowsayings/examples/init.pp
```

Agora inclua a classe:

```
    include cowsayings
```

### Tarefa 9

Agora que os pacotes foram removidos, execute o _init.pp_ com `--noop` e apos isso aplique-o caso esteja tudo ok.

```
    # puppet apply --noop cowsayings/examples/init.pp
    Notice: Compiled catalog for learning.puppetlabs.vm in environment production in 0.17 seconds
    Notice: /Stage[main]/Cowsayings::Cowsay/Package[cowsay]/ensure: current_value absent, should be present (noop)
    Notice: Class[Cowsayings::Cowsay]: Would have triggered 'refresh' from 1 events
    Notice: /Stage[main]/Cowsayings::Fortune/Package[fortune-mod]/ensure: current_value purged, should be present (noop)
    Notice: Class[Cowsayings::Fortune]: Would have triggered 'refresh' from 1 events
    Notice: Stage[main]: Would have triggered 'refresh' from 2 events
    Notice: Applied catalog in 1.59 seconds

    # puppet apply cowsayings/examples/init.pp 
    Notice: Compiled catalog for learning.puppetlabs.vm in environment production in 0.16 seconds
    Notice: /Stage[main]/Cowsayings::Cowsay/Package[cowsay]/ensure: created
    Notice: /Stage[main]/Cowsayings::Fortune/Package[fortune-mod]/ensure: created
    Notice: Applied catalog in 8.21 seconds
    root@learning:/etc/puppetlabs/code/environments/production/modules # fortune | cowsay
     _______________________________________ 
    | CPU-angle has to be adjusted because  |
    | of vibrations coming from the nearby  |
    | road                                  |
     --------------------------------------- 
          \   ^__^
           \  (oo)\_______
              (__)\       )\/\
                  ||----w |
                  ||     ||
```

# módulos

Sao basicamente _bundles_ (agrupamentos) de todo o código e dados que você precisa para gerenciar algum aspecto de sua configuração.

## Por que se meter com módulos?

módulos permitem que o código seja organizado em unidades reutilizaveis, testaveis e portaveis (ou seja, modulares). Garantimos assim transparencia e reproducibilidade da maneira menos dolorosa possivel.

Solucoes podem misturar e combinar módulos auto-contidos, que são  mais faceis de testar, manter e compartilhar. Em essencia, módulos são  pouco mais que uma estrutura de arquivos e diretórios que seguem as convencoes do Puppet. Essas convencoes dao ao Puppet uma maneira consistente de localizar classes, arquivos, templates, plugins e binarios destinados a realizar o objetivo desse módulo. são  tambem importantes para gerenciar o escopo, já que que tudo fica contido em seu módulo evita-se em muito os problemas de colisao.

Como módulos são  padronizados e auto-contidos, o compartilhamento fica realmente facil, sendo o __Forge__ (Forja) o serviço gratuito de hospedagem de módulos desenvolvidos e mantidos por outros usuários da comunidade.

## O _modulepath_

Todos os módulos acessiveis pelo seu _Puppet Master_ estão  localizados nos diretórios especificados pela variavel _modulepath_ no arquivo de configuração do Puppet.

### Tarefa 1

O valor da variavel _modulepath_ pode ser acessado via `puppet master --configprint modulepath`. O resultado contém os diretórios a serem utilizados alem da ordem em que isso ocorre.

* módulos utilizados nessa VM: _/etc/puppetlabs/code/environments/production/modules_
* módulos do site necessarios para todos os ambientes: _/etc/puppetlabs/code/modules_
* módulos necessarios do Puppet Enterprise: _/opt/puppetlabs/puppet/modules_

## Estrutura do módulo

Um módulo consiste em uma estrutura pre definida que permite que o Puppet encontre confiavelmente o conteúdo desse módulo. Para verificar que módulos estão  instalados, utilizamos `puppet module list`.

Apenas para visualizar melhor a estrutura de diretórios de um módulo, vamos utilizar o comando `tree` com alguns parâmetros para limitar a profundidade de diretórios em dois niveis:

`tree -L 2 -d /etc/puppetlabs/code/environments/production/modules/`

Exemplo da saida:

```
    /etc/puppetlabs/code/environments/production/modules/
    ├── cowsayings
    │   ├── examples
    │   └── manifests
    ├── docker
    │   ├── doc
    │   ├── junit
    │   ├── lib
    │   ├── log
    │   ├── manifests
    (...)
```

Para essa _quest_ iremos escrever um módulo que trabalha com o recurso do tipo _file_ (arquivo) e utiliza-lo para gerencias nossas configuracoes do _Vim_. Alem de ser um bom exemplo para gerenciar arquivos de configuração, o tipo _file_ possui algumas abstracoes de _URI_ baseadas na estrutura de módulo para encontrar as fontes dos arquivos.

Antes de iniciar vamos para o diretório do _modulepath_:

`cd /etc/puppetlabs/code/environments/production/modules`

### Tarefa 2

O diretório de topo sera o nome do nosso módulo, vamos utilizar _vimrc_:

`mkdir vimrc`

### Tarefa 3

Agora iremos criar outros três diretórios: um para manifestos, um para exemplos e outro para arquivos:

`mkdir -p vimrc/{manifests,examples,files}`

Para validar, podemos utilizar o `tree`:

```   
    # tree vimrc
    vimrc/
    ├── examples
    ├── files
    └── manifests

    3 directories, 0 files
```

## Gerenciando Arquivos

A VM de aprendizagem já possui algumas customizacoes para o Vim, ao inves de criar um _.vimrc_ do zero, podemos copiar o existente para o diretório arquivo do nosso novo módulo. Qualquer arquivo disponível no diretório `files` de um módulo no `modulepath` esta disponível a todos os nos atraves do servidor de arquivos do proprio Puppet.

### Tarefa 4

Copiando o _.vimrc_ para o diretório _files_ do nosso módulo:

`cp ~/.vimrc vimrc/files/vimrc`

### Tarefa 5

Uma vez copiado, podemos fazer uma adicao as configuracoes. 

`vim vimrc/files/vimrc`

Por padrão no _Vim_ os numeros de linha estão  desabilitados, então iremos adicionar essa configuração no arquivo com a linha:

`set number`

Salve e saia.

### Tarefa 6

Agora que nosso arquivo fonte esta criados, precisamos de um manifesto para dizer o que o Puppet deve fazer com isso, lembrando-se que o manifesto que contém a classe principal do módulo sempre se chamara _init.pp_

`vim vimrc/manifests/init.pp`

O código Puppet aqui vai ser bem simples: vamos definir uma classe vimrc, realizar uma declaração de recurso tipo _file_ para enviar o arquivo _vimrc_ de nosso módulo para a localizacao especifica. Nesse caso, o arquivo que se encontra no diretório `/root`, então seu caminho completo sera o título do recurso no arquivo da declaração.

Nosso recurso precisara de dois atributos tambem. já haviamos utilizado `ensure => present,` para garantir que o arquivo existisse no _filesystem_, no entando o Linux entende que isso e valido tanto para arquivos normais como para diretórios. Para garantir então que seja um arquivo presente, utilizaremos `ensure => file,` explicitamente.

O segundo atributo deve indicar ao Puppet qual o conteúdo que o arquivo deve ter. O valor do atributo com a fonte do arquivo deve ser a URI desse arquivo fonte.

Todas as URIs do servidor de arquivos do Puppet e estruturada assim:

`puppet://{nome de host do server (opcional)}/{ponto de montagem}/{restante do caminho}`

Mas ha ainda um pouco mais de magica embutida no Puppet para deixar essas URIs mais concisas:

* O nome de host do server vai ser quase sempre omitido, já que seu valor padrão aponta para o _Puppet Master_. Utilizamos somente quando necessitarmos apontar outro servidor de arquivos. Por padrão, então, usamos 3 barras `puppet:///`
* Quase todos os arquivos do Puppet são  servidos via módulos, para os quais o Puppet fornece alguns atalhos. Ele trata `modules` como um ponto de montagem especial que aponta para o _modulepath_ do _Puppet Master_. A URI fica agora assim `puppet:///modules/`
* Como todos os os arquivos a serem servidos por um módulo devem estar no diretório _files_, o nome do mesmo tambem e implicito e fica fora da URI.

Sendo assim, ainda que nosso arquivo `vimrc` esteja em:

`/etc/puppetlabs/code/environments/production/modules/vimrc/files/vimrc`

O atributo com a URI para acesso do mesmo sera:

`source => puppet:///modules/vimrc/vimrc,`

Nosso `init.pp` fica assim:

```
    class vimrc {
        file { '/root/.vimrc':
            ensure => file,
            source => 'puppet:///modules/vimrc/vimrc',
        }

    }
```

Apos salvar, validamos nosso manifest:

`puppet parser validate vimrc/manifests/init.pp`

## Testando seu módulo

Lembrando, o manifesto define/descreve nossa classe `vimrc` mas precisamos declara-la para fazer algum efeito.

### Tarefa 7

Para testar, temos que criar o manifesto no diretório _examples_

`vim vimrc/examples/init.pp`

E realizar a declaração atraves de um  `include`:

`include vimrc`

### Tarefa 8

Aplique o manifesto com a _flag_ `--noop`. Se tudo estiver certo, dispense a mesma e execute pra valer.

O output deve ser parecido com esse

```
    Notice: Compiled catalog for learning.puppetlabs.vm in environment production in 0.17 seconds
    Notice: /Stage[main]/Vimrc/File[/root/.vimrc]/content: content changed '{md5}9cccec66ddbdf2cb32992c81e5281c8d' to '{md5}d1f40457544e7c0826da35bb0481afde'
    Notice: Applied catalog in 0.62 seconds
```

Quando o Puppet gerencia um arquivo, ele compara o _hash_ do arquivo algo com o do arquivo fonte, caso não batam fica sabido que o arquivo foi alterado e ocorre uma substituição do mesmo para atingir o estado desejado.

# NTP

O objetivo dessa quest e simples: utilizar um módulo Puppet para gerenciar o serviço de NTP na nossa VM.

Tanto quanto saber escrever módulos e importante para melhor integra-los em nossa infraestrutura, entender como utilizar módulos existentes tambem e muito importante (escolhendo entre módulos _Puppet Approved_ e _Puppet Supported_ como uma camada extra de seguranca). Ao utilizarmos código publico, estamos utilizando código já executado e testado em centenas e ate milhares de infraestruturas diferentes.

__Nota:__ independentemente da fonte do seu módulo, uma revisao externa jamais sera substituta de uma revisao feita em casa antes de utilizar o mesmo em producao.

## O que e NTP

Diversos serviçoes de uma infinidade de dominios dependem de relogios precisos e coordenados para funcionarem corretamente. Dada a variabilidade da latencia de rede e demais variaveis, precisamos de excelentes algoritmos para garantir isso.

O Network Time Protocol (NTP, Protolo de Hora em Rede) garante precisao de milissegundos entre servidores enquanto mantem a sincronia com Coordinated Universal Time (UTC, Tempo Universal Coordenado ) atraves de servidores acessiveis publicamente.

NTP e um dos serviços mais fundamentais a serem incluidos em uma infraestrutura. O módulo de gestao e configuração desse serviço e mantido pela Puppet Labs.

## Pacote/Arquivo/serviço

Antes de instalar o módulo do NTP, vamos primeiro entender o estado atual do nosso sistema, assim mantemos registro do que o Puppet altera e porque o NTP faz o que faz.

O Puppet ira gerenciar três recursos chave para deixar o serviço do NTP rodando. A ferramenta `puppet resource` pode mostrar o estado atual de cada um desses recursos:

Verifique o estado do pacote:

```
    # puppet resource package ntp

    package { 'ntp':
      ensure => 'purged',
    }
```

O arquivo de configuração:

```
    # puppet resource file /etc/ntp.conf

    file { '/etc/ntp.conf':
      ensure => 'absent',
    }
```

O estado do serviço:

```
    # puppet resource service ntpd

    service { 'ntpd':
      ensure => 'stopped',
      enable => 'false',
    }
```

O padrão package/file/service (pacote, arquivo e serviço) e bem comum no Puppet. Esses três tipos de recurso correspondem a sequencia de instalar um _package_, customizar sua funcionalidade com arquivos de configuração e iniciar o serviço que esse _package_ prove.

Esse padrão tambem os relacionamentos tipocos de dependência entre esses recursos: uma classe bem escrita define tais relacionamentos, dizendo ao Puppet pra reiniciar o serviço se o arquivo de configuração foi modificado e recriar o arquivo de configuração quando o _package_ e instalado ou atualizado. Nessa quest nosso objetivo ainda não e esse, e sim trabalar com módulos. então maos a obra!

## Instalação

Antes de classificar a nossa VM com a classe do NTP, precisamos  instalar o módulo de NTP direto do __Forge__. Por mais que o módulo chame `ntp`, lembre-se que módulos no __Forge__ tem o nome da conta associada no prefixo. então para obter o módulo, usaremos `puppetlabs-ntp`, mas ao conferir o _modulepath_ no nosso _Puppet Master_, veremos apenas `ntp`. __Tenha em mente isso__ ao instalar módulos com mesmo nome, para evitar conflitos.

### Tarefa 1

Utilizar a ferramenta `puppet module` para instalar o `ntp` via __Forge__. 
(Caso você tenha instalado os módulos do cache essa tarefa pode já estar concluída e você pode pular para o proximo passo)

```
    # puppet module install puppetlabs-ntp
    
    Notice: Preparing to install into /etc/puppetlabs/code/environments/production/modules ...
    Notice: Downloading from http://localhost:8085 ...
    Notice: Installing -- do not interrupt ...
    /etc/puppetlabs/code/environments/production/modules
    └─┬ puppetlabs-ntp (v6.0.0)
      └── puppetlabs-stdlib (v4.15.0)
```

Esse comando diz ao Puppet para obter o módulo direto do __Forge__ e colocado dentro do nosso _modulepath_, no caso:

`/etc/puppetlabs/code/environments/production/modules`

## Classificacao com o manifesto site.pp

Agora que o módulo ntp esta instalado, todas suas classes ficam disponíveis para classificarmos os _nodes_. Na segunda quest (_Força do Puppet_), fizemos uma classificacao via console do _Puppet Enterprise_. Iremos introduzir uma outra maneira nessa quest, o arquivo de manifesto `sites.pp`.

`site.pp` e o primeiro manifesto que o agente do Puppet verifica ao conectar no _master_. Ele define configuracoes globais e padrões de recurso que se aplicam a __todos__ os nodes na infraestrutura. E tambem o local onde colocamos _definicoes de nos_ (tambem conhecidos como `node statements`).

Uma _definição de no_ e o equivalente a definição em código do que fizemos no _Puppet Enterprise_:

```
    node 'learning.puppetlabs.vm' {
        ...
    }
```

Como e mais acessivel monitorar com a ferramenta de `quest` do material, vamos utilizar principalmente o `site.pp` daqui em diante. O que aprendermos sobre definição de nos e classes se aplica a qualquer metodo de classificacao escolhido, incluindo o classificador do PE.

### Tarefa 2

Abrir o manifesto `site.pp` em algum editor:

`vim /etc/puppetlabs/code/environments/production/manifests/site.pp`

__Dica:_ a tecla `G` pula para o final do arquivo.

O a definição node `default` se trata de uma definição especial, aplicada a qualquer node que não esteja especificamente incluso em alguma outra definição.

Como queremos que nossas mudanças sejam aplicadas apenas a VM de aprendizagem, vamos colocar a declaração de classe `ntp` em um novo bloco de node 'learning.puppetlabs.vm'.

```
    node 'learning.puppetlabs.vm' {
        include ntp
    }
```

### Tarefa 3

Disparar uma execução do Puppet via ferramenta `puppet agent` e interessante para aprendizagem e testes, no entanto na producao você deve preferir que o Puppet execute conforme agendamento, a cada 30 minutos, por padrão. Como você ira executar o Puppet logo depois de alterar o manifesto `site.pp` talvez o cache não tenha sido atualizado. Caso as mudanças não estejam refletidas apos uma execução via `puppet agent -t`, tente executar o comando mais uma vez.

Teste o manifesto `site.pp` via  `puppet parser validate` e dispare uma execução do Puppet via:

`puppet agent -t`

Utilize a ferramenta `puppet resource` para inspecionar o serviço `ntpd` mais uma vez, caso a classe tenha sido aplicada com sucesso o serviço estara no ar.

### Sincronizando

Para evitar a quebra de processos que dependem de horario consistente, o serviço de NTP funciona gradualmente, adicionando/removendo microsegundos a cada ciclo do relogio ate que exista sincronia com o servidor NTP.

Utilize o comando `ntpstat` para conferir o estado da sincronizacao. não se preocupe caso a VM demore algum tempo para sincronizar visto que seu horario esta atrelado ao horario de criação da imagem (ou a ultima vez que ela foi suspensa).

## padrões e parâmetros de Classe

A classe `ntp`  inclui configuracoes padrões para a maioria dos seus parâmetros. A sintaxe de `include` utilizada ha pouco permite que você declare a classe de maneira consisa sem modificar esses padrões.

Um desses padrões, por exemplo, diz quais servidores de NTP devem ser incluidos no arquivo de configuração. Para ver quais servidores foram especificados por padrão, podemos verificar direto no arquivo, via:

`grep server /etc/ntp.conf`

você verá a listagem de servidores:

```
    server 0.centos.pool.ntp.org
    server 1.centos.pool.ntp.org
    server 2.centos.pool.ntp.org
```

Esses não são  servidores de hora e sim pontos de acesso que irao passar você a servidores publicos. A maioria de tais servidores assinalados são  fornecidos por voluntarios rodando um servidor NTP como um serviço extra em um servidor de e-mail ou web.

Apesar de funcionarem bem, você tera um horario mais preciso e utilizara menos rede caso utilize servidores publicos na sua regiao.

Para especificar manualmente quais servidores o serviço NTPD vai consultar, você deverá sobrescrever os servidores padrões definidos pelo módulo NTP.

Nesse momento os _parâmetros de classe_ do Puppet entram em acao, fornecendo um metodo para definir variaveis em uma classe no momento em que e declarada. A sintaxe de classes parametrizadas e bem parecida com a da declaração de recursos:

```
    class { 'ntp':
        servers => [
            'nist-time-server.eoni.com',
            'nist1-lv.ustiming.org',
            'ntp-nist.ldbsc.edu',
        ]
    }
```

O parametro `servers` na nossa declaração de classes recebe uma lista de servidores como valor, não apenas um. Trata-se de um array e permite atribuir uma lista de valores a uma variavel - sempre contidos entre colchetes "[" e "]", separados por virgula.

### Tarefa 4

No seu `site.pp` substituia a declaração `include ntp` por uma que seja parametrizada com outros servidores. Pode-se utilizar os três do exemplo ou outros de sua preferencia, lembrando de declarar ao menos três para garantir a confiabilidade do funcionamento do NTP.

`vim /etc/puppetlabs/code/environments/production/manifests/site.pp`

A declaração deve ficar assim:

```
    node 'learning.puppetlabs.vm' {
      class {'ntp':
        servers => [
          'nist-time-server.eoni.com',
          'nist1-lv.ustiming.org',
          'ntp-nist.ldbsc.edu'
        ]
      }
    }
```

### Tarefa 5

Assim que efetuar a alteracao no manifesto `site.pp` utilize a ferramenta `puppet parser` para validar que esta tudo Ok e então dispare uma execução via ferramenta `puppet agent`.


Exemplo do Puppet verificando alteracao no ntp.conf e alterando-o:

```
    Notice: /Stage[main]/Ntp::Config/File[/etc/ntp.conf]/content: content changed '{md5}1f44e40bd99abd89f0a209e823285332' to '{md5}4d816fab9d055ad275398a4a2fd47bd6'
    Notice: /Stage[main]/Ntp::Config/File[/etc/ntp/step-tickers]/content: 
    --- /etc/ntp/step-tickers       2017-05-23 18:44:35.727200823 -0700
    +++ /tmp/puppet-file20170523-8109-77rxqk        2017-05-23 19:32:36.943200823 -0700
    @@ -1,5 +1,5 @@
     # List of NTP servers used by the ntpdate service.
     
    -0.centos.pool.ntp.org
    -1.centos.pool.ntp.org
    -2.centos.pool.ntp.org
    +nist-time-server.eoni.com
    +nist1-lv.ustiming.org
    +ntp-nist.ldbsc.edu

    Notice: /Stage[main]/Ntp::Config/File[/etc/ntp/step-tickers]/content: content changed '{md5}413c531d0533c4dba18b9acf7a29ad5d' to '{md5}ded69bf18df1fe1d9833f16f9f867e8a'
    Info: Class[Ntp::Config]: Scheduling refresh of Class[Ntp::Service]
    Info: Class[Ntp::Service]: Scheduling refresh of Service[ntp]
    Notice: /Stage[main]/Ntp::Service/Service[ntp]: Triggered 'refresh' from 1 events
    Notice: Applied catalog in 39.73 seconds
```

Verifique que o arquivo `/etc/ntp.conf` foi alterado e que o serviço `ntpd` foi reiniciado. 

# MySQL

## PorQueSQL?

O módulo de MySQL (mantido) e utilizado para simplificar tarefas complexas sem sacrificar robustez e controle. O módulo permite que você instale e configure tanto instancias de servidor como de cliente. Permite tambem estender o tipo de recurso para gerenciar usuários, grants e bases de dados MySQL com a linguagem de recurso padrão do Puppet.

## Instalação do Servidor

### Tarefa 1

Antes de iniciarmos, vamos pegar o módulo `puppetlabs-mysql` do __Forge__ atraves da ferramenta `puppet module`. (Caso você tenha instalado os módulos do cache essa tarefa pode já estar concluída e você pode pular para o proximo passo)

`puppet module install puppetlabs-mysql`

Agora que este módulo esta instalado no _modulepath_ do _Puppet Master_, todas suas classes ficam disponíveis para classificarmos os _nodes_.

### Tarefa 2

Editar o `site.pp` para classificar a VM de aprendizagem como uma classe MySQL.

`vim /etc/puppetlabs/code/environments/production/manifests/site.pp`

Se você completou a quest do NTP, já tem uma entrada para o certname `learning.puppetlabs.vm`, do contrario crie agora:

```
  node 'learning.puppetlabs.vm' {

  }
```

Dentro desse bloco de no, podemos declarar nossa classe `::mysql::server` e definir seus parâmetros. Para esse exemplo vamos definir a senha de `root` e definir o maximo de conexoes com o servidor como 1024. 

__Dica:__ altere o `vimrc` utilizado anteriormente para incluir `set paste` e garantir que o _vim_ não quebre a formatacao ao colar hashes aninhados.

```
  node 'learning.puppetlabs.vm' {
    class { '::mysql::server':
      root_password     => 'strongpassword',
      override_options  => {
        'mysqld' => { 'max_connections' => '1024' }
      },
    }
  }
```

Nao apenas opcoes padrão como `root_password`, a classe aceita `override_options` como um hash, que você pode utilizar para qualquer configuração que você normalmente faria no arquivo `/etc/my.cnf`. Ao utilizar um hash permite a gestao dessas configuracoes sem requerer que fossem escritas na classe como parâmetros distintos. Essa estrutura e analoga a sintaxe de `[section] , var_name = value` de um arquivo `my.cnf`

### Tarefa 3

Utilize a ferramenta `puppet parser validade` para verificar sua sintaxe, então dispare uma execução:

```
  # puppet agent -t
  Info: Using configured environment 'production'
  Info: Retrieving pluginfacts
  Info: Retrieving plugin
  Info: Loading facts
  Info: Caching catalog for learning.puppetlabs.vm
  Info: Applying configuration version '1495613765'
  Notice: /Stage[main]/Mysql::Server::Config/File[mysql-config-file]/ensure: defined content as '{md5}15d890f0648fc49e43fcffc6ed7bd2d8'
  Notice: /Stage[main]/Mysql::Server::Install/Package[mysql-server]/ensure: created
  Notice: /Stage[main]/Mysql::Server::Installdb/Mysql_datadir[/var/lib/mysql]/ensure: created
  Notice: /Stage[main]/Mysql::Server::Service/Service[mysqld]/ensure: ensure changed 'stopped' to 'running'
  Info: /Stage[main]/Mysql::Server::Service/Service[mysqld]: Unscheduling refresh on Service[mysqld]
  Notice: /Stage[main]/Mysql::Server::Root_password/Mysql_user[root@localhost]/password_hash: defined 'password_hash' as '*FAB0955B2CE7AE2DAFEE46C36501AFC5E65D445D'
  Notice: /Stage[main]/Mysql::Server::Root_password/File[/root/.my.cnf]/ensure: defined content as '{md5}e31a08f361a550c6909c0a39ea4b68f6'
  Notice: Applied catalog in 33.53 seconds
```

Para conferir sua nova base (!) basta acessar o MySQL Monitor via `mysql` e sair via `\q`. Para conferir o resultado do `override_options` basta validar no arquivo `/etc/my.cnf.d/server.cnf`

`less /etc/my.cnf.d/server/cnf`

Ou,

```
  # grep max_conn /etc/my.cnf.d/server.cnf                          
  max_connections = 1024
```

## Escopo

Alem de instalar e configurar um banco MySQL, o módulo `puppetlabs-mysql` inclui diversas outras classes para ajudar a gerir outros aspectos da sua implementacao MySQL.

Essas classes estão  organizadas em uma estrutura diretórios de módulo que combina com a sintaxe de escopo do Puppet. Escopo ajuda a organizar as classes, dizendo ao Puppet onde olhar na estrutura de diretórios de módulo para encontrar cada classe. O escopo tambem ajuda a separar os _namespaces_ dentro dos módulos e nos manifestos Puppet, prevenindo o conflito entre classes e variaveis com o mesmo nome.

De uma olhada nos diretórios e manifestos dentro do módulo MySQL (utilize um filtro do `tree` para exibir apenas arquivos de manifesto):

```
  # tree -P "*.pp" /etc/puppetlabs/code/environments/production/modules/mysql/manifests/

  ├── backup
  │   ├── mysqlbackup.pp
  │   ├── mysqldump.pp
  │   └── xtrabackup.pp
  ├── bindings
  │   ├── client_dev.pp
  │   ├── daemon_dev.pp
  │   ├── java.pp
  │   ├── perl.pp
  │   ├── php.pp
  │   ├── python.pp
  │   └── ruby.pp
  ├── bindings.pp
  ├── client
  │   └── install.pp
  ├── client.pp
  ├── db.pp
  ├── params.pp
  ├── server
  │   ├── account_security.pp
  │   ├── backup.pp
  │   ├── binarylog.pp
  │   ├── config.pp
  │   ├── installdb.pp
  │   ├── install.pp
  │   ├── monitor.pp
  │   ├── mysqltuner.pp
  │   ├── providers.pp
  │   ├── root_password.pp
  │   └── service.pp
  └── server.pp

4 directories, 27 files
```

Note o arquivo `server.pp` no topo do diretório `mysql/manifests`. Baseado nesse nome de classe em escopo, o Puppet consegue encontrar o manifesto chamado `server.pp` no diretório de manifestos do módulo MySQL.

então, `mysql::server` significa:

`/etc/puppetlabs/code/environments/production/modules/mysql/manifests/server.pp`

Para levar o exemplo um nivel abaixo, `mysql::server::account_security` e o mesmo que:

`/etc/puppetlabs/code/environments/production/modules/mysql/manifests/server/account_security.pp`

## Seguranca da Conta

Por razoes de seguranca você vai querer remover os usuários padrão e as bases de teste de uma Instalação MySQL. A classe `accoount_security` faz justamente isso.

### Tarefa 4

Volte ao manifesto `site.pp` e inclua a classe `::mysql::server::account_security` no node `learning.puppetlabs.vm` apos a declaração `::mysql::server`. Como você não precisa passar parâmetros a essa classe, um simples _include_ sera suficiente.

```
  # node 'learning.puppetlabs.vm' {
    ...
    include ::mysql::server::account_security
    ...
  }
```

Valide seu `site.pp`

`puppet parser validate /etc/puppetlabs/code/environments/production/manifests/site.pp`

Dispare uma execução do puppet apos validar:

```
  # puppet agent -t
  Info: Using configured environment 'production'
  Info: Retrieving pluginfacts
  Info: Retrieving plugin
  Info: Loading facts
  Info: Caching catalog for learning.puppetlabs.vm
  Info: Applying configuration version '1495616327'
  Notice: /Stage[main]/Mysql::Server::Account_security/Mysql_user[root@127.0.0.1]/ensure: removed
  Notice: /Stage[main]/Mysql::Server::Account_security/Mysql_user[root@::1]/ensure: removed
  Notice: /Stage[main]/Mysql::Server::Account_security/Mysql_user[@localhost]/ensure: removed
  Notice: /Stage[main]/Mysql::Server::Account_security/Mysql_user[root@learning.puppetlabs.vm]/ensure: removed
  Notice: /Stage[main]/Mysql::Server::Account_security/Mysql_user[@learning.puppetlabs.vm]/ensure: removed
  Notice: /Stage[main]/Mysql::Server::Account_security/Mysql_database[test]/ensure: removed
  Notice: Applied catalog in 22.31 seconds
```

você comecara a visualizar avisos de que a base de teste e dois usuários padrões foram removidos.

__Nota:__ nenhuma ferramenta de automatizacao substitui os requisitos de seguranca de seu sistema.

## Tipos e provedores

O módulo de MySQL do Puppet contém tipos e provedores customizados que permitem a gestao de itens criticos ao MySQL como recursos via DSL, da mesma maneira que você faria com um usuário de sistema ou serviço.

Um __tipo__ define a interface para um recurso: um conjunto de propriedades que descrevem o estado desejado para um recurso e parâmetros que não necessariamente correspondem a coisas no sistema, mas dizem ao Puppet como gerenciar o recurso. Tanto as propriedades como os parâmetros aparecém na sintaxe de declaração de recursos como um par de valores de atributo.

O __provedor__ levanta o peso para manter o sistema em linha com o estado definido numa declaração de recurso. são  implementados em uma variedade de sistemas operacionais. são  essenciais a camada de abstracao de recursos (RAL), traduzindo a interface universal definida pelo __tipo__ em uma implementacao especifica do sistema.

O módulo MySQL inclui tipos e provedores customizados que fazem com que `mysql_user`, `mysql_database` e `mysql_grant` fiquem disponíveis como recursos.

## Base de dados, usuário, permissão

### Tarefa 5

Esses tipos de recurso customizados permitem gerenciar uma base de dados nova com apenas algumas linhas de código.

Adicione declaração de recurso a definição do no `learning.puppetlabs.vm` no seu manifesto `site.pp`

```
  node 'learning.puppetlabs.vm' {
    mysql_database { 'lvm':
        ensure  => present,
        charset => 'utf8',
    }
    ...
  }
```

De maneira similar, com um usuário você apenas precisa especificar o nome e o host como título, alem de declarar o atributo `ensure` como `present`. Insira o seguinte:

```
  node 'learning.puppetlabs.vm' {
    mysql_user { 'lvm_user@localhost':
      ensure => present,
    }
    ...
  }
```

Agora que você tem um usuário e um banco, pode utilizar o grant para definir privilégios para esse usuário. Note que o caracter `*` ira combinar com qualquer tabela. Logo, `table => lvm.*` abaixo significa que o usuário `lvm_user` tem TODAS as permissões para todas as tabelas da base `lvm`.

```
  node 'learning.puppetlabs.vm' {
    mysql_grant { 'lvm_user@localhost/lvm.*':
      ensure     => present,
      options    => ['GRANT'],
      privileges => ['ALL'],
      table      => 'lvm.*',
      user       => 'lvm_user@localhost',
    }
    ...
  }
```


Utilize a ferramenta `puppet parser validate` no manifesto `site.pp` para verificar a sintaxe desses três recursos inseridos.

`puppet parser validate /etc/puppetlabs/code/environments/production/modules/manifests/site.pp`

Quando o código estiver bonito, dispare uma execução.

```
  # puppet agent -t
  Info: Using configured environment 'production'
  Info: Retrieving pluginfacts
  Info: Retrieving plugin
  Info: Loading facts
  Info: Caching catalog for learning.puppetlabs.vm
  Info: Applying configuration version '1495618606'
  Notice: /Stage[main]/Main/Node[learning.puppetlabs.vm]/Mysql_database[lvm]/ensure: created
  Notice: /Stage[main]/Main/Node[learning.puppetlabs.vm]/Mysql_user[lvm_user@localhost]/ensure: created
  Notice: /Stage[main]/Main/Node[learning.puppetlabs.vm]/Mysql_grant[lvm_user@localhost/lvm.*]/ensure: created
  Notice: Applied catalog in 20.36 seconds
```

# Variaveis e parâmetros

Pelas quests de NTP e MySQL você já viu como parâmetros de classe possibilitam que você ajuste as classes de um módulo de acordo com sua necessidade. Nessa quest, o objetivo e vermos como integrar variaveis em suas classes e faze-las acessiveis via parâmetros.

Para isso, você vai escrever um módulo que gerencia um site de HTML estatico. Primeiro criara uma classe web com declaracoes de recurso _file_ para gerenciar seus documentos HTML. Ao atribuir valores repetidos como caminhos de arquivo a variaveis, sua classe sera mais concisa e facil de refatorar depois. Uma vez que essa estrutura basica da classe esteja concluída, adicionara parâmetros. Isso permitira que se definam os valores das variaveis de sua classe a medida que a declara.

## Variaveis

No Puppet, variaveis são  prefixadas por um `$` e atribui-se valor a elas com `=`. Por exemplo, para atribuir uma _string_ a uma variavel, fazemos:

`$minhavariavel = 'olhe, uma string'`

Uma vez definida, você pode utilizar a variavel em qualquer lugar em que poderia utilizar o valor atribuido.

O basico sobre variaveis parecera familiar se você já conhece qualquer outra linguagem de script, no entanto ha algumas advertencias sobre a utilizacao de variaveis no Puppet:

* Diferente da declaração de recursos, atribuicoes de variaveis são  dependentes da ordem de _parse_. Ou seja, você deve atribuir em seu manifesto antes de utilizar.
* Se você tentar utilizar uma variavel não definida, o parser do Puppet não ira reclamar. Ao inves disso ira tratar a variavel como contendo o valor especial `undef`. Apesar de que isso deve causar erros de compilacao mais adiante, em algumas situacoes o processo pode concluir e causar resultados inesperados
* você pode atribuir uma variavel apenas uma vez em um escopo. Uma vez atribuida, seu valor não pode ser alterado. O valor de uma variavel pode alterar-se entre sistemas diferentes, mas não dentro deles.

### Interpolacao de variaveis

A interpolacao permite que você utilize o valor de uma variavel em uma _string_. Por acaso, se você quisesse que o Puppet gerenciasse varios arquivos dentro do diretório `/var/www/quest`, você poderia ter atribuido esse caminho de diretório a uma variavel:

`$doc_root = '/var/www/quest'`

Uma vez definida, você não precisa mais repetir o caminho inserindo a variavel `$doc_root` no inicio de qualquer _string_.

Por exemplo, você pode utilizar no título da declaração de alguns recursos _file_:

```
  file { "${doc_root}/index.html":
    ...
  }
  file { "${doc_root}/about.html":
    ...
  }
```

Note a sintaxe diferente aqui, o nome da variavel e envolto entre chaves (`{ }`) e tudo isso precedido pelo `$` (`${nome_da_variavel}`). Perceba tambem que uma _string_ que inclui uma variavel interpolada deve estar envolta entre aspas duplas `"..."` ao inves das simples que utilizamos em _strings_ comuns. Tais aspas sinalizam ao Puppet que ele deve encontrar e analisar sintaxe dentro da _string_ e não apenas interpreta-la como literal.

## Gerenciando conteúdo Web com variaveis

Pra entender melhor como trabalhar com variaveis nesse contexto, te guiaremos atraves da criação de um módulo `web` que colocara isso em pratica.

### Tarefa 1

Primeiro, você vai precisar da estrutura de diretório do seu módulo.

Confira que você esta no diretório `modules` do seu _modulepath_:

`cd /etc/puppetlabs/code/environments/production/modules/`

Agora crie um diretório `web` e seus diretórios `manifests` e `examples`:

`mkdir -p web/{manifests,examples}`

### Tarefa 2

Com essa estrutura no lugar, você já pode comecar a criar seu manifesto principal onde você define sua classe `web`.

`vim web/manifests/init.pp`

E adicione o seguinte conteúdo (lembre-se do `:set paste`, caso não tenha ajustado seu `.vimrc` automaticamente)

```
class web {

    $doc_root = '/var/www/quest'

    $english = 'Hello world!'
    $french  = 'Bonjour le monde!'

    file { "${doc_root}/hello.html":
      ensure  => file,
      content => "<em>${english}</em>",
    }

    file { "${doc_root}/bonjour.html":
      ensure  => file,
      content => "<em>${french}</em>",
    }

  }
```

Note que se você quisesse alterar o valor do `$doc_root` só precisaria faze-lo em um lugar. Apesar de existirem formas mais avancadas de separacao de dados no Puppet o principio e o mesmo: quanto mais separado for seu código dos dados abaixo dele, mais reutilizavel ele e, e mais facil de refatorar quando você precisar altera-lo no futuro.

### Tarefa 3

Uma vez que você validou seu manifesto com a ferramenta `puppet parser`, você ainda precisa criar um teste pro seu manifesto com uma declaração `include` para a classe que você criou (vimos isso na quest módulos).

Crie um arquivo de manifesto `web/examples/init.pp` e insira `include web`. Salve e saia.

### Tarefa 4

Aplique o teste recém criado com a _flag_ `--noop`

```
  #puppet apply --noop web/examples/init.pp

  Notice: Compiled catalog for learning.puppetlabs.vm in environment production in 0.16 seconds
  Notice: /Stage[main]/Web/File[/var/www/quest/hello.html]/ensure: current_value absent, should be file (noop)
  Notice: /Stage[main]/Web/File[/var/www/quest/bonjour.html]/ensure: current_value absent, should be file (noop)
  Notice: Class[Web]: Would have triggered 'refresh' from 2 events
  Notice: Stage[main]: Would have triggered 'refresh' from 1 events
  Notice: Applied catalog in 0.67 seconds
```

Se sua execução enxuta parecer Ok, execute o `puppet apply` sem a _flag_. De uma olhada em `http://<IP DA VM>/hello.html` e `http://<IP DA VM>/bonjour.html` para conferir suas páginas novas.

## parâmetros de Classe

Agora que temos uma classe `web` basica, vamos abordar os parâmetros de classe. Eles te fornecem uma maneira de atribuir as variaveis de uma classe __enquanto ela é declarada__ ao inves de ter isso _hardcoded_ durante a definição da classe.

Ao definir uma classe, inclua uma lista de parâmetros e valores padrões opcionais entre o nome da classe e o inicio do bloco de classe.

```
  class classname ( $parameter = 'default' ) {
    ...
  }
```

Uma vez definida, uma classe parametrizada pode ser __declarada__ como uma sintaxe similar a de declaração de recursos, incluindo par-valor de cada parametro que você quer definir.


```
  class {'classname':
    parameter => 'value',
  }
```

então se você quer implementar páginas em servidores ao redor do mundo, com conteúdo dependente do idioma da regiao. Ao inves de reescrever toda uma classe ou módulo por regiao, você pode utilizar parametos de classe para customizar esses valores enquanto a classe e declarada.

### Tarefa 5

Para comecarmos a reescrever nossa classe `web` com parâmetros, reabra o manifesto `web/manifests/init.pp`. Para criar uma nova página regionalizada, você deverá ser capaz de definir a mensagem e o nome da página via parâmetros de classe.

`class web ( $page_name, $message ) {`

Agora crie uma terceira declaração de recurso _file_ que utilize as variaveis dos seus parâmetros

```
  file { "${doc_root}/${page_name}.html":
     ensure  => file,
     content => "<em>${message}</em>",
   }
```

### Tarefa 6

Assim como antes, use o manifesto de teste para declarar a classe. você ira abrir o manifesto `web/examples/init.pp` e substituir o `include` simples por uma sintaxe de declaração de classe parametrizada que define cada um dos parâmetros (basicamente, a SDL do Puppet =P)

```
  class {'web':
    page_name => 'hola',
    message   => 'hola mundo',
  }
```

### Tarefa 7

Agora faca um teste, execute uma vez com `--noop` e então aplique o teste. A nova página deve estar disponível em `http://<IP DA VM>/hola.html`


```
  # puppet apply --noop web/examples/init.pp 
  Notice: Compiled catalog for learning.puppetlabs.vm in environment production in 0.16 seconds
  Notice: /Stage[main]/Web/File[/var/www/quest/hola.html]/ensure: current_value absent, should be file (noop)
  Notice: Class[Web]: Would have triggered 'refresh' from 1 events
  Notice: Stage[main]: Would have triggered 'refresh' from 1 events
  Notice: Applied catalog in 0.60 seconds

  # puppet apply web/examples/init.pp 
  Notice: Compiled catalog for learning.puppetlabs.vm in environment production in 0.13 seconds
  Notice: /Stage[main]/Web/File[/var/www/quest/hola.html]/ensure: defined content as '{md5}e4b486becbc46475a52abb5c904a6690'
  Notice: Applied catalog in 0.58 seconds
```

__Importante:__ lembre-se que classes no Puppet são  singletons, então só podem ser aplicadas uma vez por node (no nosso exemplo só seria possivel ter uma página espeficada por parâmetros alem das duas outras já existentes). Caso você deseje repetir o mesmo recurso ou grupo deles __em um mesmo no__, podemos utilizar o conceito de _tipo de recurso definido_, que veremos em uma proxima quest.

# Declaracoes condicionais

## Escrevendo pela flexibilidade

código excelente == código flexivel e portavel. Apesar dos tipos e provedores que são  o _code_ do __RAL__ do Puppet fazerem a maior parte do trabalho pesado nessas adaptacoes, ha varias coisas que são  melhores nas maos de usuários competentes.

E sensato que os provedores do Puppet `package` tomem conta de instalar e manter pacotes. As entradas e saidas são  padronizadas e estaveis o suficiente pra, seja la o que acontecer entre isso, desde que aconteca de maneira confiavel, esta livre pra ser escondido pela abstracao. Uma fez feito, os detalhes deixam de ser importantes. 

__AJUDA CHRIS!:__ Oi, então a ideia acima eh o seguinte: quem implementou e prove o `package` esta livre para implementar da maneira que quiser, desde que sua entrega seja confiavel entre o _input_ ou entrada e o _output_ ou saida. Os fins justificam os meios na maneira Puppet de se pensar.

_Qual_ pacote esta instalado, por outro lado, não e algo que você simplesmente esquece. Nesse caso, os _inputs_ e _outputs_ não estão  tao bem definidos assim. apesar de que existam pacotes equivalentes entre as muitas plataformas por ai, __a equivalencia nunca e completa__; detalhes de configuração vao variar, e esses detalhes vao precisar ser levados em conta em algum lugar do seu módulo Puppet.

Mas mesmo o os provedores _built-in_ do Puppet não sendo capazes de garantir a portabilidade do seu código Puppet nesse nivel tao alto de abstracao, a DSL do Puppet te da as __ferramentas para contruir *adaptabilidade*__ nos seus módulos. __Fatos__ e __declaracoes condicionais__ são  o arroz feijao dessa funcionalidade.

## Fatos

você já se deparou com a ferramenta `facter` quando a gente te pediu pra executar `facter ipaddress` na secao de Instalação do guia. Mas apesar de ser  bacana poder executar o facter pela linha de comando, ele se torna valioso mesmo no back end, tornando informação sobre um sistema disponível para utilizacao como variaveis em seus manifestos.

__N.T.__realmente, isso e pra aplaudir de pe mesmo. quando eu vi do que o `orawls` era capaz, me emocionei.

Enquanto o facter e tao importante pro Puppet que vem junto do Puppet Enterprise, ele tambem e um dos projetos open-source separados que estão  integrados ao ecossistema Puppet.

Combinado com condicionais, que a gente vai chegar em seguida, __fatos__ te dao um montao de Força pra codificar a tal portabilidade nos seus módulos.

Pra ter uma lista completa dos fatos disponíveis, use o comando:

`facter -p | less`

você pode referenciar qualquer um dos fatos listados por esse comando como se fossem variaveisque você tivesse definido em seus manifestos. __Entretanto__, existe uma diferenca _notavel_: porque os fatos estão  disponíveis para qualquer manifesto compilado para aquele no, eles existem em um tal _top scope_ (escopo de topo). Isso significa que por mais que um fato possa ser acessado de qualquer lugar, ele tambem pode ser sobrescrito por qualquer variavel de mesmo nome em um escopo mais baixo (por ex.: escopo de no ou de classe). Pra evitar potenciais colisoes, fica melhor colocar explicitamente o escopo dos fatos. você especifica o _top scope_ prefixando o seu _factname_ com dois pontos duplos `::`, pronunciado _scope scope_. então um fato no seu manifesto vai parecer com isso `$::factname`.

## Condicoes

Declaracoes condicionais retornam valores ou executam blocos de código diferentes dependendo do valor de uma variavel determinada. Essa e a chave para fazer seu Puppet funcionar da maneira desejada em diferentes sistemas operacionais e cumprir diferentes papeis na sua infraestrutura.

Algumas maneiras suportadas de logica condicional são :

* declaracoes `if` (se)
* declaracoes `unless` (a menos que)
* declaracoes `case`
* _Selectors_ (seletores)

Ja que o mesmo conceito que esta por baixo desses modos de logica, vamos explicar somente o `if` aqui. Assim que você estiver confortavel com o `if`, ha as descricoes dos outros modos e algumas anotacoes quando forem uteis.

### If (se)

O `if` no Puppet funciona da mesma forma que a maioria das outras linguagens de script e programacao. Uma declaração `if` inclui uma condicao seguida de um bloco de código que só sera executado __se__ tal condicao for uma verdade, avaliando como __true__. Opcionalmente um `if` (se) pode incluir uma quantidade qualquer de `elseif` (se nao, se) e uma clausula `else` (então).

* se a condicao do `if` falhar, avanca para a condicao `elsif` (se existir)
* se tanto as condicoes `if` como o `elsif` falharem, avanca para o código da clausula `else` (se existir)
* se todas as condicoes falharem e não existir um bloco `else`, o Puppet não faz nada e segue

Digamos que você quer dar privilégio administrativos ao usuário que você esta criando pelo módulo `accounts`. você tem um mix de CentOS e Debian na sua infraestrutura. Nas suas maquinas CentOS, você usa o grupo `wheel` para gerenciar privilégios de superusuários, enquanto no Debian você usa o grupo `admin`. Usando a condicao `if` e o fato `operatingsystem` do Facter, esse tipo de ajuste se torna facil com o Puppet.

Antes de comecar a escrever seu módulo, garanta que você esta trabalhando do diretório de módulos (_modules_)

`cd /etc/puppetlabs/code/environments/production/modules`


### Tarefa 1

Crie um diretório `accounts` e seus diretórios `manifests` e `examples`

`mkdir -p accounts/{manifests,examples}`

### Tarefa 2

Abra o manifesto `accounts/manifests/init.pp` no Vim. No inicio da sua definição de classe de `accounts`, você ira incluir logica condicional para atribuir a variavel `$groups` baseada no valor do fato `::operatingsystem`. Se o só for CentOS, o Puppet ira adicionar o usuário ao grupo `wheel`, se for Debian ira adicionar ao grupo `admin`.

O inicio da sua definição de classe deveria se parecer com isso aqui:

```
  class accounts ($user_name) {

    if $::operatingsystem == 'centos' {
      $groups = 'wheel'
    }
    elsif $::operatingsystem == 'debian' {
      $groups = 'admin'
    }
    else {
      fail( "This module doesn't support ${::operatingsystem}." )
    }

    notice ( "Groups for user ${user_name} set to ${groups}" )
  }
```

Note que esses _matches_ de strings __nao__ são  _case-sensitive_, então 'CENTOS' tambem funcionaria. Pra finalizar, no bloco `else`, você vai sinalizar um erro caso o módulo não suporte o SO.

Com a logica para o grupo (`$groups`) finalizada, crie uma declaração de recurso `user`. Utilize a variavel `$user_name` definida pelo seu parametro de classe pra atribuir o home e o título do usuário, e use a variavel `$groups` para definir o atributo `groups`

```
class accounts ($user_name) {
  ...

  user { $user_name:
    ensure  => present,
    home    => "/home/${user_name}",
    groups  => $groups
  }
  ...
}
```

Pra garantir, que tal seu código passar em um `puppet parser validate` antes de continuar? :D

### Tarefa 3

Crie um manifesto de teste `accounts/example/init.pp` e declare o manifesto de contas, com o parametro de nome definido como `dana`.

```
  class {'accounts':
    user_name => 'dana',
  }
```

### Tarefa 4

Como nossa VM esta rodando CentOS e gostariamos de simular que esta com Debian, vamos utilizar um pouco de magica para sobrescrever o fato `operatingsystem` para o facter. Para isso, basta incluir o fato na seguinte sintaxe antes do seu comando `puppet apply`, podendo tambem compor com a _flag_ `--noop` para testar como seria com um só diferente. Nosso exemplo ficaria assim:

`FACTER_operatingsystem=Debian puppet apply --noop accounts/examples/init.pp`

```
  Notice: Scope(Class[Accounts]): Grupos  para usuário dana definidos para debian
  Notice: Compiled catalog for learning.puppetlabs.vm in environment production in 0.13 seconds
  Notice: /Stage[main]/Accounts/User[dana]/ensure: current_value absent, should be present (noop)
  Notice: Class[Accounts]: Would have triggered 'refresh' from 1 events
  Notice: Stage[main]: Would have triggered 'refresh' from 1 events
  Notice: Applied catalog in 0.73 seconds
```

Confira as notificacoes e você verá como as mudanças seriam aplicadas.

### Tarefa 5

Tente mais uma vez, agora com um só não suportado, para verificarmos a condicao de falha.

`FACTER_operatingsystem=Darwin puppet apply --noop accounts/examples/init.pp`

```
  Error: Evaluation Error: Error while evaluating a Function Call, Esse módulo não suporta Darwin. at /etc/puppetlabs/code/environments/production/modules/accounts/manifests/init.pp:8:3 on node learning.puppetlabs.vm
```

### Tarefa 6

Agora va em frente e execute um `puppet apply --noop` no seu manifesto de teste sem definir a variavel de ambiente. Se parecer bom, dispense a _flag_ `--noop` para aplicar o catálogo gerado pelo seu manifesto.

```
  Notice: Scope(Class[Accounts]): Grupos  para usuário dana definidos para wheel
  Notice: Compiled catalog for learning.puppetlabs.vm in environment production in 0.12 seconds
  Notice: /Stage[main]/Accounts/User[dana]/ensure: current_value absent, should be present (noop)
  Notice: Class[Accounts]: Would have triggered 'refresh' from 1 events
  Notice: Stage[main]: Would have triggered 'refresh' from 1 events
  Notice: Applied catalog in 0.62 seconds
  root@learning:/etc/puppetlabs/code/environments/production/modules/accounts # puppet apply  examples/init.pp 
  Notice: Scope(Class[Accounts]): Grupos  para usuário dana definidos para wheel
  Notice: Compiled catalog for learning.puppetlabs.vm in environment production in 0.18 seconds
  Notice: /Stage[main]/Accounts/User[dana]/ensure: created
  Notice: Applied catalog in 0.92 seconds
```

você pode usar a ferramenta `puppet resource` para validar os resultados.

```
  # puppet resource user dana
  user { 'dana':
    ensure           => 'present',
    gid              => '1005',
    groups           => ['wheel'],
    home             => '/home/dana',
    password         => '!!',
    password_max_age => '99999',
    password_min_age => '0',
    shell            => '/bin/bash',
    uid              => '1005',
  }
```

### Unless (a menos que)

A declaração `unless` funciona como o inverso de um `if`. O `unless` recebe uma condicao e um bloco de código Puppet. só ira executar __se__ a condicao for __falsa__. Se a condicao for verdadeira, o Puppet não fara nada e seguira. não existe um equivalente de clausulas `elsif` ou `else` para declaracoes `unless`.

### Case (caso)

Declaracoes condicionais permitem que você escreva código que retorne valores diferentes ou execute blocos diferentes de código dependendo do que você especificar. Junto ao `Facter`, que disponibiliza os detalhes de uma maquina como _variaveis_, permite que você escreva um código que acomode flexivelmente diferentes plataformas, sistemas operacionais e requisitos funcionais.

### Selector (seletores)

Declaracoes seletoras são  parecidas com declaracoes `case`, mas ao inves de selecionar um bloco de código, um seletor atribuem um valor diretamente. Um seletor deve ser algo assim:

```
  $rootgroup = $::osfamily ? {
    'Solaris' => 'wheel',
    'Darwin'  => 'wheel',
    'FreeBSD' => 'wheel',
    'default' => 'root',
  }
```

Aqui, o valor de `$rootgroup` e determinado baseado na variavel de controle `$::osfamily`. Depois dessa variavel vem um `?`, ponto de interrogacao. No bloco que esta envolto por chaves `{...}` ha uma serie de valores possiveis para o fato `$::osfamily`, seguido pelo valor que o seletor deveria retornar se o valor bater com o da variavel de controle.

Agora porque um seletor somente retorna um valor e não pode executar uma funcao como `fail()` ou `warning()`, fica por sua conta garantir que o código de conta condicoes inesperadas de uma maneira elegante. você não ia gostar do Puppet tomando as redeas com algum padrão inapropriado e encontrasse erros la na frente por causa disso.

# Ordenacao de recursos

## Ordenacao de recursos

Ate agora os módulos escritos foram bem simples. Te guiamos atraves de exemplos projetados para demonstrar as diversas caracteristicas do Puppet e seus construtos de linguagem. Como você só cuidou de poucos recursos por vez, a gente não se preocupou com a dependência entre esses recursos.

Assim que você comecar a trabalhar em problemas mais complexos, vai ficar claro bem rapido que as coisas precisam funcionar na ordem correta. você não consegue configurar um pacote que ainda não foi instalado, ou dar controle de um arquivo para um usuário que ainda não criou.

então, como o Puppet gerencia esses relacionamentos?

O Puppet precisa de uma outra maneira de gerenciar a ordem dos recursos já que por ser uma linguagem declarativa não temos uma ordem linear implicita das coisas. Lembre-se que na DSL nos definimos o estado desejado, não como se chega ate la.

Aqui entram os __relacionamentos de recursos__. A sintaxe do Puppet permite que você defina explicitamente a dependência entre seus recursos.

Existem algumas maneiras de fazer isso, a mais simples e atraves de __metaparâmetros de relacionamento__. Basicamente, e um tipo de par-valor de atributo que diz ao Puppet _como_ você quer implementar um recurso, ao inves de detalhes do recurso em si. Esses metaparâmetros são  definidos na declaração dos recursos, junto com o resto dos atributos de par-valor.

Se você esta escrevendo um módulo para gerenciar o SSH, você precisa garantir que o pacote `openssh-server` esta instalado _antes_ de você gerenciar o serviço `sshd`. Pra conseguir isso, você inclui um metaparametro `before`, com o valor `Service[sshd]`.

```
  package {'openssh-server':
    ensure => present,
    before => Service[sshd],
  }
```

você pode abordar o problema a partir da direcao contraria, tambem. O metaparametro `require` e o reflexo do `before`. O `require` diz ao Puppet que o recurso atual _requer_ o recurso especificado pelo outro parametro.

Utilizando `before` no pacote `openssh-server` e o mesmo que utilizar o `require` no recurso de serviço `sshd`.

```
  service { 'sshd':
    ensure  => running,
    enable  => true,
    require => Package['openssh-server'],
  }
```

Em ambos os casos preste atencao em como você se refere ao recurso alvo, o _tipo_ esta capitalizado e seguido por um _array_ (dentro de `[]` colchetes) de _títulos_ de recurso:

`Tipo['título']`

Ja que cobrimos alguns dos recursos que você vai precisar, que tal fazer um módulo ssh para explorar isso?

### Tarefa 1

Pra comecar nosso módulo, vamos criar um diretório `sshd` com os subdiretórios `examples`, `files`, `manifests` (dentro do diretório que já estamos utilizando para módulos)

```
  cd /etc/puppetlabs/code/environment/production/modules
  mkdir -p sshd/{examples,files,manifests}
```

### Tarefa 2

Crie um manifesto `sshd/manifests/init.pp` e preencha sua classe `sshd` com o recurso de pacote `openssh-server` e o recurso de serviço `sshd`. não se esqueça de incluir um relacionamento `before` ou um `require` entre esses recursos. Dentro da sua classe, se você inclui um `before` para um recurso, não precisa incluir um `require` para o outro e vice-versa, já que ambos especificam a mesma dependência entre os recursos.

Com require:
```
  class { 'sshd':
    package { 'openssh-server':
      ensure => present,
    }
    service { 'sshd':
      ensure  => running,
      enable  => true,
      require => Package['openssh-server'],
    }
  }
```

Com before:
```
  class { 'sshd':
    package { 'openssh-server':
      ensure => present,
      before => Service['sshd'],
    }
    service { 'sshd'
      ensure => running,
      enable => true
    }
  }
```

Quando estiver pronto use a ferramenta `puppet parser validate` para validar.

Antes de adicionar um recurso _file_ para gerenciar a configuração do `sshd`, vamos vizualizar o relacionamento entre `package` e `service` de outra perspectiva: __o grafo__.

Quando o Puppet compila um catálogo, ele gera um __grafo__ representando a rede de relacionamentos entre os recursos daquele catálogo. O grafo nesse contexto se refere a um metodo utilizado na matematica e nas Ciencias da Computacao para modelar conexoes entre uma colecao de objetivos. O Puppet utiliza grafos internamente para determinar uma ordem de trabalho na hora de aplicar recursos e permite que você acesse isso para vizualizacao ou para entender melhor esses relacionamentos.

### Tarefa 3

O jeito mais rapido pra ser gerar um grafo no Puppet e criando um manifesto de teste e executando o mesmo com as _flags_ `--noop` e `--graph`. Crie um manifesto `sshd/examples/init.pp`. você não tem nenhum parametro de classe, então pode usar somente:

`include sshd`

Com isso pronto, execute um `puppet apply` com essas flags contra seu manifesto:

```
  # puppet appply sshd/examples/init.pp --noop --graph
  Notice: Compiled catalog for learning.puppetlabs.vm in environment production in 0.13 seconds
  Notice: Applied catalog in 1.71 seconds

  # ls -ltr /opt/puppetlabs/puppet/cache/state/graphs
  total 12
  -rw-r--r-- 1 root root 1524 May 25 02:52 resources.dot
  -rw-r--r-- 1 root root 1268 May 25 02:53 relationships.dot
  -rw-r--r-- 1 root root 3028 May 25 02:53 expanded_relationships.dot
```

### Tarefa 4

O Puppet gera um arquivo `.dot` em um local definido como `graphdir`. Pra saber essa localizacao utilizamos o comando `puppet config print`

`puppet config print graphdir`

O comando `dot` pode ser utilizado para converter o arquivo `relationships.dot` em uma imagem png. Para facilitar as coisas, vamos definir o diretório de _output_ (saida) como o _web dir_ do nosso guia, assim podemos visualizar direto em um navegador

`dot -Tpng /opt/puppetlabs/puppet/cache/state/graphs/relationships.dot -o /var/www/quest/relationships.png`

Agora utilizando o navegador, acesse `http://<IP DA VM>/relationships.png`. Perceba que os recursos `openssh-server` e `sshd` estão  conectados por uma seta que indica o relacionamento de dependência.

__Dica:__ altere o seu manifesto `sshd/manifests/init.pp` para utilizar `require` ou `before` duplamente gere/converta novamente o grafo para visualizar. O Puppet tambem previne que manifestos com referencias ciclicas sejam aplicados no ambiente :D

```
  Notice: Compiled catalog for learning.puppetlabs.vm in environment production in 0.18 seconds
  Error: Failed to apply catalog: Found 1 dependency cycle:
  (Package[openssh-server] => Service[sshd] => Package[openssh-server])
  Cycle graph written to /opt/puppetlabs/puppet/cache/state/graphs/cycles.dot.
```

### Tarefa 5

Vamos em frente! Utilizaremos um recuso _file_ para gerenciar a configuração do `sshd`. Primeiro vamos precisar de um arquivo fonte. Assim como você fez para o módulo `vimrc`, podemos copiar o arquivo existente para nosso diretório `files`

`cp /etc/ssh/sshd_config  sshd/files/sshd_config`

você tambem pode querer garantir que o usuário `pe-puppet` tenha permissões de leitura nesse arquivo

`chwon pe-puppet:pe-puppet sshd/files/sshd_config`

### Tarefa 6

Por razoes obvias o SSH já esta bastante configurado na nossa VM de aprendizagem, mas com o intuito de praticar nosso exemplo, vamos fazer uma alteracao e ver como o Puppet cuida disso. não estamos utilizando autenticacao GSS API, então você pode melhor a performance de conexao atribuindo a configuração `GSSAPIAuthentication` como `no`. Abra o arquivo `sshd/files/sshd_config`, encontre a configuração `GSSAPIAuthentication`, altere a linha para refletir `no` como valor, salve o arquivo e saia do editor.

### Tarefa 7

Com o arquivo fonte preparado, volte ao seu manifesto `sshd/manifests/init.pp` e adicione um recurso _file_ para gerenciar seu arquivo `sshd_config`. você quer garantir que esse arquivo seja aplicado _depois_ do pacote `openssh-server`, então inclua um parametro `require` para esse recurso

```
  file {'/etc/sshd/sshd_config':
    ensure  => file,
    source  => 'puppet:///modules/sshd/sshd_config'
    require => Package['openssh-server'],
  }
```

### Tarefa 8

Aplique seu manifesto de teste novamente com as _flags_ `--noop` e `--graph`, utilize então a ferramenta `dot` para gerar uma nova imagem.

`dot -Tpng /opt/puppetlabs/puppet/cache/state/graphs/relationships.dot -o /var/www/quest/relationships.png`

Agora utilizando o navegador, acesse `http://<IP DA VM>/relationships.png`. Fica facil ver pelo grafo que ambos recursos `file` e `service` requerem o recurso `package`. O que esta faltando nessa configuração? Se você quer que suas configuracoes façam efeito, você tera que faze-las antes do serviço ser reiniciado ou reiniciar o mesmo apos as mudanças.

O Puppet utiliza outro par de _metaparâmetros_ para gerenciar esse relacionamento especial entre um arquivo de configuração e seu serviço correspondente: `notify` e `subscribe`. Os metaparâmetros `notify` e `subscribe` estabelecem o mesmo relacionamento de dependência do `before` e `requires`, respectivamente, alem de disparar um _refresh_ sempre que o Puppet fizer uma modificacao na dependência.

Enquanto qualquer recurso pode ser a dependência que dispara um _refresh_, existem dois recursos que podem responder a um _refresh_. Na proxima tarefa, vamos olhar pra um `service` já familiar a você (o segundo e chamado `exec`, mas os detalhes de como ele trabalha estão  fora do escopo desse guia).

Assim como `before` e `require`, `notify` e `subscribe` são  reflexos entre si. Incluir um `notify` no seu recurso `file` tem o mesmo resultado que incluir um `subscribe` no seu recurso `service`.

### Tarefa 9

Edite seu manifesto `ssh/examples/init.pp` para incluir um metaparametro `subscribe` ao recurso `sshd`.

```
  class sshd {
    ...
    service { 'sshd':
      ...
      subscribe => File['/etc/ssh/sshd_config'],
      ...
    }
    ...
  }
```

Valide sua sintaxe via `puppet parser validate`. Quando estiver tudo certo aplique seu manifesto de teste novamente com as _flags_ `--noop` e `--graph`, utilize então a ferramenta `dot` para gerar uma nova imagem e conferir o resultado.

Finalmente, dispense a _flag_ `--nop` para aplicar suas modificações pra valer. você verá uma notificação que o arquivo foi alterado, seguido de uma notificação de _refresh_ do serviço.

## Encadeamento de setas (chaining arrows)

O encadeamento de setas prove uma outra maneira para definir relacionamentos entre recursos ou grupos deles. As ocasioes apropriadas para isso estão  fora do escopo desse guia, mas para ser completo, daremos uma explicacao breve.

* A seta `->` faz com que o recurso da esquerda seja aplicado antes do recurso da direita.
* A seta `~>` faz com que o recurso da esquerda seja aplicado antes do rescurso da direita __e__ envie um evento de _refresh_ para o recurso da direita caso o da esquerda tenha sofrido alguma alteracao.

Apesar de que você vai ver setas encadeadas sendo utilizadas nas proprias declaracoes de recursos, isso não e uma boa pratica. E muito facil não prestar atencao nessas setas, principalmente se você esta refatorando um manifesto grande com muitos recursos e relacionamentos.

então pra que elas são  boas? Ao contrario dos parâmetros, elas não estão  embutidas na declaração de um recurso. Isso significa que você pode utilizar as setas entre referencias de recursos, vetores de referencias de recursos, e coletores de recursos para criar, concisa e dinamicamente, relacionamentos __1:N__ ou __N:N:__ entre grupos de recursos.

## Autorequires

__Autorequires__ são  relacionamentos entre recursos que o proprio Puppet consegue advinhar sozinho. Por exemplo, o Puppet sabe que um recurso _file_ dever vir sempre depois do diretório pai que o contém, ou que um recurso _user_ deve ser gerenciado apenas depois que o grupo ao qual ele pertence seja criado. você pode encontrar esses relacionamentos na secao de _Referencias de tipo_ da documentacao oficial: https://docs.puppet.com/puppet/4.1/type.html, ou como saida da ferramenta `puppet describe`.

Por exemplo:

`puppet describe user | less`

Deve conter no texto o seguinte:

```
  **Autorequires:** If Puppet is managing the user's primary group (as
  provided in the `gid` attribute) or any group listed in the `groups`
  attribute then the user resource will autorequire that group. If Puppet
  is managing any role accounts corresponding to the user's roles, the
  user resource will autorequire those role accounts.
```

Isso significa que se eu catálogo tem uma declaração de recurso de um usuário e seu grupo primario, o Puppet sabe que precisa atuar no grupo antes do usuário. Perceba que esses relacionamentos são  documentados apenas na referencia de tipo do recurso _que requer_ (ex: usuário), não no recurso _requerido_ (ex: grupo).

# Tipos de recurso definidos

Na quest de classes parametrizadas, vimos como parâmetros podem ser utilizados para customizar uma classe no momento de sua declaração. Se você lembrar que classes, assim como recursos, só podem ser _realizados_ uma unica vez em um catálogo, você deve estar pensando no que fazer se você quiser que o Puppet repita o mesmo padrão multiplas vezes, mas com parâmetros diferentes.

Na maioria dos casos a resposta e um _tipo de recurso definido_ (__defined resource type__), um bloco de código Puppet que pode ser declarado multiplas vezes com parâmetros de valores diferentes. Uma vez definido, um _tipo de recurso definido_ se parece e age como qualquer outro tipo principal que você já esta acostumado.

Nessa quest você vai criar um _tipo de recurso definido_ para um `web_user`. Isso vai permitir que você agrupe os recursos que precisa para criar um usuário e tambem sua página inicial pessoal. Assim você consegue resolver tudo com uma declaração de recurso unica.

## Tipos de recurso definidos

Por mais que você consiga fazer bastante coisa com os principais tipos de recurso do Puppet, mais cedo ou mais tarde você vai ser deparar com coisas que não se encaixam bem nos tipos pre-definidos do Puppet. Na quest do MySQL, por exemplo, você encontrou algums tipos customizados de recursos que permitiram que você configurasse os grants, usuários e bases do MySQL. O módulo `puppetlabs-mysql` contém código Ruby que define o comportamento desses _tipos_ e dor _provedores_ customizados que os implementam no sistema.

Escrever _provedores_ customizados, no entanto, e um comprometimento enorme. Quando você escreve seus proprios _provedores_, assume a responsabilidade por toda a abstracao que o Puppet utiliza para cuidar daquele recurso em diversos sistemas operacionais e configuracoes. Apesar dessa ser uma contribuicao benefica a comunidade, não e muito apropriada para uma solucao isolada.

Os __tipos de recurso definidos__ do Puppet são  a solucao de baixo custo. Apesar de não terem a mesma Força que implementar uma funcionalidade completamente nova, você deve se surpreender quando quanto pode ser alcancado ao mesclar os tipos pre-definidos do Puppet com os fornecidos pelos módulos existentes da comunidade.

### Tarefa 1

Para comecar, vamos criar a estrutura de diretórios para nosso módulo `web_user`

```
  # cd /etc/puppetlabs/code/environment/production/modules
  mkdir -p web_user/{examples, manifests}
```

Antes de entrar nos detalhes do que vamos fazer com esse módulo, vamos escrever um _tipo de recurso definido_ simples assim você se acostuma com a sintaxe. Por hora, vamos criar um usuário e o diretório home dele. Normalmente, você poderia utilizar o parametro `managehome` para dizer ao Puppet gerenciar o home do usuário, mas queremos um pouco mais de controle sobre as permissões desse diretório, então vamos fazer por conta propria.

### Tarefa 2

Va em frente e crie um manifesto `user.pp` onde vamos definir nosso `tipo de recurso definido`. 

`vim web_user/manifests/user.pp`

Vamos comecar devagar. Insira o código abaixo no seu manifesto, tomando bastante cuidado com a sintaxe e as variaveis.

```
  define web_user::user {
    $home_dir = "/home/${title}"
    user { $title:
      ensure => present,
    }
    file { $home_dir:
      ensure  => directory,
      owner  => $title,
      group  => $title,
      mode   => '0775',
    }
  }
```

O que você percebeu? Primeiro que essa sintaxe e praticamente identica a de uma classe. A unica diferenca e que você usa a palavra `define` ao inves de `class`.

Assim como uma classe, um tipo de recurso definido traz uma colecao de recursos em uma unidade configuravel. A diferenca chave e, como mencionamos, que ele pode ser realizado diversas vezes em um sistema, enquanto classes são  sempre _singletons_.

Isso nos leva a segunda diferenca de código que você deve ter percebido. Nos utilizamos a variavel `$title` em varios lugares, mas não atribuimos ela explicitamente! Perceba tambem que `$title` esta sendo usada tanto em `file` como em `user` que estamos declarando. O que esta acontecendo aqui? 

### Tarefa 3

Para entender a importancia dessa variavel de título em um _tipo de recurso definido_, va em frente e crie um manifesto de teste.:

`vim web_user/examples/user.pp`

Declare um recurso `web_user::user`:

`web_user::user { 'shelob': }`

Aqui, atribuimos o título ('shelob', no nosso caso) da mesma maneira que fariamos para qualquer outro recurso. Esse título passa atraves do nosso _tipo de recurso definido_ como a variavel `$title`. você deve se lembrar da quest Resources, onde vimos que títulos de recurso devem ser unicos, vez que são  a chave para o Puppet referenciar um recurso internamente. Quando você cria um _tipo de recurso definido_, deve garantir que todos os recursos inclusos contenham um título unico para seu tipo. A melhor maneira de fazer isso e passando a variavel `$title` no título de cada recurso. Apesar de que o título do seu recurso de arquivo que você declarou para o diretório `home` esteja definido pela variavel `$home_dir`, essa variavel tem atribuida uma string que inclui a variavel `$title`: `"/home/${title}"`.

você tambem pode estar se perguntando pela falta de parâmetros. Se um recurso ou classe não tem parâmetros, ou possui padrões aceitaveis para seus parâmetros, e possivel declarar a mesma na forma resumida sem uma lista de parâmetros no formado de pares chave valor (você vai ver menos disso no caso de classes, já que a sintaxe idempotente do `include` e quase sempre preferida).

### Tarefa 4

Va em frente , execute seu manifesto com `--noop` e então aplique-o:

`puppet apply web_user/examples/user.pp`

Agora de uma olhada no diretório `home`:

`ls -la /home`

você deve ver um diretório home para 'shelob' com as permissões que você definiu:

`drwxrwxr-x   2 shelob              shelob                 6 May 25 04:58 shelob`

### páginas HTML publicas

Agora que você viu um exemplo simples de um _tipo de recurso definido_, vamos fazer algo mais util com isso.

Nos já configuramos o servidor Nginx que esta hospedando esse guia para criar um alias de todas as localizacoes que comecem com `~` para um diretório `public_html` no diretório home do usuário correspondente.

você não precisa entender os detalhes dessa configuração para essa quest. Dito isso, o código que utilizamos para essa configuração e um exemplo real de um _tipo de recurso definido_, então vale dar uma olhada. Esse _tipo de recurso definido_ que utilizamos vem com o módulo `jfryman-nginx`. Declaramos isso com alguns poucos parâmetros para configurar uma localizacao que ira lidar automaticamente com nossas páginas `~` especiais. não se preocupe com a expressao regular assustadora no título. Ela e especifica da maneira que nossa configuração do Nginx funciona, e você não precisa entender nada disso para utilizar _tipos definidos de recurso_ em geral.

```
  nginx::resource::location { '~ ^/~(.+?)(/.*)?$':
    vhost           => '_',
    location_alias  => '/home/$1/public_html$2',
    autoindex       => true,
  }
```

Essa expressao regular no título (`~ ^/~(.+?)(/.*)?$`) captura qualquer caminho de segmento URL precedido por um `~` como um grupo de captura e o restante da URL como um segundo grupo de captura. Ela então mapeia o primeiro grupo ao diretório home do usuário, e o resto para o conteúdo do diretório `public_html` daquele usuário. então `/~username/index.html` correspondera a `/home/username/public_html/index.html`.

Se você se interessar, você pode dar uma olhada no arquivo `_.conf` para ver como esse _tipo de recurso definido_ se traduz em um bloco de localizacao no nosso arquivo de configuração do Nginx:

`cat /etc/nginx/sites-enabled/_.conf` 

### Tarefa 5

Vamos la então dar ao nosso recurso `web_user::user` um diretório `public_html` e uma página `index.html` padrão. Vamos precisar adicionar um diretório e um arquivo. Porque os parâmetros de nosso diretório `public_html` serao identicos aos do diretório home, podemos utilizar um vetor para declarar ambos de uma vez. Perceba que o _autorequires_ do Puppet ira cuidar da ordem nesse caso, garantindo que o diretório home seja criado antes do `public_html` que o contém.

Nos vamos definir o parametro `replace` do arquivo `index.html` para `false`. Isso significa que o Puppet vai criar esse arquivo caso não exista, mas não ira substituir um arquivo já existente. Isso permite que criemos uma página padrão para o usuário, mas permite que o usuário substitua o conteúdo padrão sem que o Puppet a sobrescreva em uma proxima execução.

Finalmente, podemos utilizar a interpolacao de strings para customizar o conteúdo padrão da página inicial do usuário. (O Puppet tambem suporta templates de estilo `.erb` e `.epp`, que nos dariam uma maneira ainda mais potente de customizar uma página. Como ainda não os vimos, vamos nos virar com interpolacao de variaveis!)

Reabra seu manifesto:

`vim web_user/manifest/user.pp`

E adicione código para configurar o diretório `public_html` de seu usuário e o arquivo `index.html` padrão:

```
  define web_user::user {
    $home_dir = "/home/${title}"
    $public_html = "${home_dir}/public_html"

    user { $title:
      ensure => present,
    }
    file { [$home_dir, $public_html]:
      ensure  => directory,
      owner   => $title,
      group   => $title,
      mode    => '0775',
    }
    file { "${public_html}/index.html":
      ensure  => file,
      owner   => $title,
      group   => $title,
      replace => false,
      content => "<h1>Bem-vindx a página inicial de ${title}</h1>",
      mode    => '0664',
    }

  }
```

### Tarefa 6

Assim que fizer as alteracoes, faca uma execução `--noop` e então aplique seu manifesto de teste:

```
  # puppet apply web_user/examples/user.pp --noop
  Notice: Compiled catalog for learning.puppetlabs.vm in environment production in 0.12 seconds
  Notice: /Stage[main]/Main/Web_user::User[shelob]/File[/home/shelob/public_html]/ensure: current_value absent, should be directory (noop)
  Notice: /Stage[main]/Main/Web_user::User[shelob]/File[/home/shelob/public_html/index.html]/ensure: current_value absent, should be file (noop)
  Notice: Web_user::User[shelob]: Would have triggered 'refresh' from 2 events
  Notice: Class[Main]: Would have triggered 'refresh' from 1 events
  Notice: Stage[main]: Would have triggered 'refresh' from 1 events
  Notice: Applied catalog in 0.61 seconds

  # puppet apply web_user/examples/user.pp
    Notice: Compiled catalog for learning.puppetlabs.vm in environment production in 0.29 seconds
  Notice: /Stage[main]/Main/Web_user::User[shelob]/File[/home/shelob/public_html]/ensure: created
  Notice: /Stage[main]/Main/Web_user::User[shelob]/File[/home/shelob/public_html/index.html]/ensure: defined content as '{md5}de6cd1997ca9388eae6bbcbdef3593bb'
  Notice: Applied catalog in 0.71 seconds
```

Uma vez que a execução do Puppet concluir, confira a nova página de usuário em `http://<IP DA VM>/~shelob/index.html`

### parâmetros

Do jeito que esta, seu _tipo de recurso definido_ não te permite uma maneira de especificar nada alem do título. Utilizando parâmetros, a gente pode passar um pouco mais de informação aos recursos contidos e customiza-los a nossa maneira. Vamos adicionar alguns parâmetros que nos permitirao definir uma senha para o usuário e algum conteúdo customizado para a página padrão. 

### Tarefa 7

A sintaxe para adicionar parâmetros a _tipos de recurso definidos_ e a mesma que das classes parametrizadas. Dentro de um conjunto de parenteses antes das chaves de abertura da definição, inclua uma lista separada por virgulas das variaveis a serem definidas por parâmetros. O operador `=` pode ser utilizado opcionalmente para atribuir valores padrões.

```
  define web_user::user (
    $content  = "<h1>Bem-vindx a página de ${title}</h1>",
    $password = undef,
    ){
      ..
    }
```

Existe um par de detalhes que você deve perceber ai.

Primeiro, apesar de termos utilizado a variavel `$title` para definir o conteúdo padrão, não podemos utilizar o valor de um parametro como padrão de outro. A ligacao (binding) desses parâmetros acontece em paralelo, não sequencialmente. Qualquer atribuicao que dependa dos valores de outro parametro deve ser feita no corpo do _tipo de recurso definido_. A variavel `$title` e atribuida antes da ligacao dos outros parâmetros, então ela e uma execao.

Segundo, demos a variavel `$password` o valor especial `undef` como padrão. Quaquer parametro sem um valor padrão especificado ira causar um erro caso você declare o _tipo de recurso definido_ sem especificar um valor para aquele parametro. Se deixassemos o parametro `$password` sem um padrão, você teria que __sempre__ especificar uma senha. Para o tipo de recurso `user` que esta por baixo, entretanto, o parametro `password` e opcional para sistemas Linux. Ao utilizar o valor especial `undef` como padrão, podemos dizer ao Puppet explicitamente que trate aquele valor como indefinido, e aja como se simplesmente não tivessemos incluido-o em nossa lista de pares chave-valor para nosso recurso `user`.

Agora que você tem seus parâmetros configurados, atualize o corpo do seu _tipo de recurso definido_ para utiliza-los.

```
  define web_user::user (
    $content  = "<h1>Welcome to ${title}'s home page!</h1>",
    $password = undef,
  ) {
    $home_dir    = "/home/${title}"
    $public_html = "${home_dir}/public_html"
    user { $title:
      ensure   => present,
      password => $password,
    }
    file { [$home_dir, $public_html]:
      ensure => directory,
      owner  => $title,
      group  => $title,
      mode    => '0775',
    }
    file { "${public_html}/index.html":
      ensure  => file,
      owner   => $title,
      group   => $title,
      replace => false,
      content => $content,
      mode    => '0664',
    }
  }
```

### Tarefa 8

Edite seu manifesto de teste para incluir mais um usuário para testarmos:

```
  web_user::user { 'shelob': }
  web_user::user { 'frodo':
    content   => 'Custom Content',
    password  => pw_hash('sting', 'SHA-512', 'mysalt'),
  }
```

Perceba que estamos utilizando a funcao `pw_hash` para gerar um hash SHA-512 da senha 'sting' e salt 'mysalt'.

### Tarefa 9

Assim que fizer as alteracoes, faca uma execução `--noop` e então aplique seu manifesto de teste:

`puppet apply web_user/examples/user.pp`

Uma vez que a execução do Puppet concluir, confira sua nova página de usuário em `http://<IP DA VM>/~frodo/index.html`

# Instalação de agente de no

Ate então, você tem gerenciado um no, a VM de aprendizagem, que esta rodando o servidor master do Puppet. Em um ambiente real, no entanto, a maioria dos seus nos vao rodar apenas o agente do Puppet.

Nessa quest, utilizamos uma ferramenta chamada `docker` para simular múltiplos nos na VM de aprendizagem. Com esses nos novos, você pode aprender como instalar o agente do Puppet, assinar o certificado dos seus nos novos para permitir que ingressem na sua infraestrutura Puppetizada, e finalmente utilizar o manifesto `site.pp` para aplicar um pouco de código Puppet nesses nos.

__Por favor, tome nota__: Essa quest e a proxima "Orquestrador de aplicações" requerem conexao a internet, se você esta executando a VM offline, por favor  verifique as instrucoes para que ela acesse a internet. __Por enquanto não ha uma maneira de executar essas quests offline e a Puppetlabs esta trabalhando nisso__.

## Consiga alguns nos

Ate então, estavamos utilizando 2 comandos para aplicar nosso código Puppet: `puppet apply` e `puppet agent -t`. Se você não se sentiu confiante da diferenca desses dois comandos, isso pode ser porque estivemos fazendo tudo num unico no onde a diferenca entre aplicar mudanças localmente e envolver o Puppet master não esta bem clara. Vamos revisar por um momento.

`puppet apply` compila o catálogo baseado num manifesto especificado e aplica tal catálogo localmente. Qualquer node com o agente Puppet instalado pode aplicar um manifesto. você pode acabar utilizando bastante o `puppet apply` caso você queira utilizar o agente do Puppet sem envolver um Puppet master. Por exemplo, caso você esteja fazendo alguns testes locais ou experimentando com uma infraestrutura sem um servidor mestre.

`puppet agent -t` dispara uma execução do Puppet. Essa execução e uma conversa entre o no agente e o Puppet master. Primeiro, o agente envia uma colecao de fatos para o mestre. O mestre pega esses fatos e utiliza-os para saber qual código precisa ser aplicado no no. você viu duas maneiras dessa classificacao ser configurada: no manifesto `site.pp` ou no classificador de nos do Puppet Enterprise. O mestre então avalia o código Puppet para compilar um catálogo que descreva exatamente como os recursos no no devem estar configurados. O mestre envia esse catálogo para o agente no no, que o aplica. Finalmente, o agente envia um relatorio da execução Puppet de volta ao mestre. Apesar de termos desabilitado execucoes automaticas na VM, elas são  agendadas para ocorrer a cada meia hora.

Apesar de que você só vai precisar de um no para escrever e aplicar código Puppet, ter a imagem completa de como o Puppet mestre e o no se comunicam vai ser bem mais facil se você tem mais de um no para trabalhar.

### Conteineres

Nos criamos um módulo `multi_node` que ira configurar um par de conteineres docker pra agirem como nos adicionais de agente na sua infraestrutura. __O docker não e um componente do Puppet__, trata-se de uma ferramenta open-source que estamos utilizando para construir esse ambiente de aprendizado multi-no. Executar um agente Puppet em um conteiner Docker nos da uma maneira conveniente de observar como o Puppet trabalha com múltiplos nos, mas tenha em mente que essa não e a maneira recomendada de montar sua infraestrutura Puppet!

### Tarefa 1

Primeiro, precisamos instalar uma dependência para esse módulo. Normalmente a ferramenta `puppet module` daria conta disso, mas porque o módulo `multi_node` e especifico pra essa quest e não e publicado no __Forge__, faremos isso manualmente.

```
  # puppet module install puppetlabs-concat

  Notice: Preparing to install into /etc/puppetlabs/code/environments/production/modules ...
  Notice: Downloading from http://localhost:8085 ...
  Notice: Installing -- do not interrupt ...
  /etc/puppetlabs/code/environments/production/modules
  └─┬ puppetlabs-concat (v2.2.0)
    └── puppetlabs-stdlib (v4.15.0)
```

Agora, para aplicar a classe `multi_node` na VM, adicione-a a declaração do no `learning.puppetlabs.vm` no manifesto `site.pp` do mestre.

`vim /etc/puppetlabs/code/environment/production/manifests/site.pp`

Insira `include multi_node` na declaração de no `learning.puppetlabs.vm`

```
  node learning.puppetlabs.vm {
    include multi_node
  }
```

E importante que você não tenha colocado isso na sua declaração de no `default`. Se você fez isso o Puppet vai tentar criar conteineres Docker nos seus conteineres Docker toda vez que você fizesse uma execução Puppet.

### Tarefa 2

Agora dispare uma execução do `puppet agent -t`. Isso pode levar um tempo.

`puppet agent -t`

Assim que essa execução terminar, você pode executar `docker ps` para ver seus dois nos novos. você deve ver um chamado `database` e outro chamado `webserver`.

```
  CONTAINER ID        IMAGE                      COMMAND             CREATED             STATUS              PORTS                     NAMES
20668180d1fa        phusion/baseimage:0.9.18   "/sbin/my_init"     6 minutes ago       Up 6 minutes        0.0.0.0:10080->80/tcp     webserver
819f26d9e356        phusion/baseimage:0.9.18   "/sbin/my_init"     6 minutes ago       Up 6 minutes        0.0.0.0:23306->3306/tcp   database
```

__AJUDA CHRIS__: eu comecei a levar `connection refused` ao executar `puppet agent -t` quando passei a placa de rede para modo bridged no Virtual Box, pra resolver isso bastou adicionar o novo IP do host no `/etc/hosts` para responder tanto `learning` como `learning.puppetlabs.vm`

### Instale o agente do Puppet

Agora você tem dois nos fresquinhos, mas não tem o agente Puppet instalado em nenhum deles! Instalar o agente vai ser o primeiro passo para colocar esses nos na nossa infraestrutura.

### Tarefa 3

Na maioria dos casos, o jeito mais simples de instalar o agente e atraves do comando `curl` para transferir o script de Instalação direto do mestre e executa-lo. Como nossos agentes estão  rodando sobre Ubuntu, primeiro precisamos garantir que nosso Puppet mestre tem o script certo pra fornecer.

Navegue ate o console do Puppet Enterprise em `https://<IP DA VM>`. As credenciais são  as mesmas do começo do guia:

* usuário: `admin`
* senha: `puppetlabs`

No caminho __Nodes > Classification__, clique em __PE Infrastructure__ e selecione o grupo de nos __PE Master__. Na aba __Classes__, insira `pe_repo::platform::ubuntu_1404_amd64`. Clique no botao __Add class__ e confirme a mudanca clicando em __Commit 1 change__.

Dispare uma execução no Puppet mestre.

`puppet agent -t`

### Tarefa 4

Normalmente você deve usar `ssh` para conectar nos seus nos e executar essa Instalação. Entretanto como estamos utilizando o docker, a maneira de conectar vai ser um pouco diferente. Pra conectar no seu no `webserver`, rode o seguinte comando para executar um bash interativo no conteiner:

`docker exec -it webserver bash`

Cole o comando `curl` da console do __PE__ para instalar o agente Puppet no no. (Para referencia futura, você pode encontrar esse comando em __Nodes > Unsigned Certificates__ na console do Puppet Enterprise (__PE__)).

`curl -k https://learning.puppetlabs.vm:8140/packages/current/install.bash | sudo bash`

A Instalação pode levar alguns minutos. (Se você encontrar algum erro aqui, pode ser necessario reiniciar o serviço do seu Puppet mestre `service pe-puppetserver restart`). Assim que concluir, termine seu bash no conteiner e saia `exit`. Repita o processo para instalar no seu banco de dados.

`docker exec -it database bash`

Agora você tem dois novos nos com o agente Puppet instalado. Enquanto você ainda esta com a sessão aberta com o no de banco de dados, você pode experimentar alguns comandos:

`facter operatingsystem`

Repare que mesmo nossa VM rodando CentOS, nossos novos nos rodam Ubuntu.

`facter fqdn`

Podemos ver tambem que o fqdn do nosso no e `database.learning.puppetlabs.vm`. E assim que podemos identificar o no na console PE ou no manifesto `site.pp` no nosso mestre.

### Tarefa 5

Podemos utilizar a ferramenta `puppet resource` pra criar um arquivo de teste novo no no de banco de dados. Ainda conectado a ele, execute o seguinte comando:

`puppet resource file /tmp/test ensure=file`

você verá o novo arquivo criado:

```
  Notice: /File[/tmp/test]/ensure: created 
  file { '/tmp/test': 
    ensure => 'file',
  }
```

você tambem pode utilizar o `puppet apply` para aplicar o conteúdo de um manifesto. Crie um manifesto de teste e experimente:

`vim /tmp/test.pp`

Vamos definir apenas uma mensagem:

`notify { "Oi, sou um manifesto aplicado localmente em um no de agent": }`

E aplique-o:

`puppet apply /tmp/test.pp`

você deveria visualizar a seguinte saida:

```
  Notice: Compiled catalog for database.learning.puppetlabs.vm in environment production in 0.14 seconds
  Notice: Oi, sou um manifesto aplicado localmente em um no de agent
  Notice: /Stage[main]/Main/Notify[Oi, sou um manifesto aplicado localmente em um no de agent]/message: defined 'message' as 'Oi, sou um manifesto aplicado localmente em um no de agent'
  Notice: Applied catalog in 0.02 seconds
```

Pra enfatizar a diferenca entre um no de agente e um mestre, vamos dar uma olhada onde você encontraria seu código Puppet no mestre:

`ls /etc/puppetlabs/code/environment/production/manifests`

e

`ls /etc/puppetlabs/code/environment/production/modules`

você pode ver que não existem módulos nem um manifesto `site.pp`. A menos que você esteja fazendo desenvolvimento local ou teste de um módulo, todo o código Puppet da sua infraestrutura e mantido no no mestre do Puppet, não em cada agente individual. Quando uma execução Puppet e disparada - seja agendada ou manualmente com o comando `puppet agent -`, o Puppet mestre compila seu código Puppet em um catálogo e envia de volta para o agente aplica-lo.

Vamos testar. Dispare uma execução Puppet no seu no de banco de dados:

`puppet agent -t`

você verá que ao inves de completar a execução Puppet, o Puppet saiu com a seguinte mensagem:

`Exiting; no certificate found and waitforcert is disabled`

Isso nos leva ao proximo topico: certificacao.

### Certificados

O mestre Puppet, mantem uma lista de certificados assinados pra cada no da sua infraestrutura. Isso ajuda tanto a manter sua infraestrutura segura, como previne que o Puppet faca alguma mudanca indesejada a sistemas na sua rede.

Antes que você possa rodar o Puppet nos novos nos agente, você precisa assinar os certificados no mestre Puppet. Se você ainda esta conectado no seu no agente, retorne ao mestre:

`exit`

### Tarefa 6

Use `puppet cert list` para visualizar os certificados __nao__ assinados. (Que você tambem pode visualizar e assinar via página de inventario no console PE).

`puppet cert list`

```
    "database.learning.puppetlabs.vm"  (SHA256) C5:23:29:43:21:00:28:AE:FD:D3:4C:B7:4A:17:1A:28:7D:B6:FD:F0:2F:FF:6E:D6:F5:16:80:36:4C:71:72:3D
    "webserver.learning.puppetlabs.vm" (SHA256) 18:CD:EA:57:7F:5A:76:C6:3B:6C:A2:B9:51:88:9F:69:96:81:31:ED:4B:31:B5:CE:DA:0F:29:74:AA:8E:AC:49
```

Agora assine cada um dos certificados dos seus nos:

`puppet cert sign webserver.learning.puppetlabs.vm`

```
  Signing Certificate Request for:
    "database.learning.puppetlabs.vm" (SHA256) C5:23:29:43:21:00:28:AE:FD:D3:4C:B7:4A:17:1A:28:7D:B6:FD:F0:2F:FF:6E:D6:F5:16:80:36:4C:71:72:3D
  Notice: Signed certificate request for database.learning.puppetlabs.vm
  Notice: Removing file Puppet::SSL::CertificateRequest database.learning.puppetlabs.vm at '/etc/puppetlabs/puppet/ssl/ca/requests/database.learning.puppetlabs.vm.pem'
```

e

`puppet cert sign database.learning.puppetlabs.vm`

```
  Signing Certificate Request for:
  "webserver.learning.puppetlabs.vm" (SHA256) 18:CD:EA:57:7F:5A:76:C6:3B:6C:A2:B9:51:88:9F:69:96:81:31:ED:4B:31:B5:CE:DA:0F:29:74:AA:8E:AC:49
  Notice: Signed certificate request for webserver.learning.puppetlabs.vm
  Notice: Removing file Puppet::SSL::CertificateRequest webserver.learning.puppetlabs.vm at '/etc/puppetlabs/puppet/ssl/ca/requests/webserver.learning.puppetlabs.vm.pem'
```

### Tarefa 7

Agora que seus certificados estão  assinados, seus nos podem ser gerenciados pelo Puppet. Pra testar isso, vamos adicionar um recurso `notify` simples ao manifesto `site.pp` no mestre.

`vim /etc/puppetlabs/code/environments/production/manifests/site.pp`

Encontre a declaração de no `default` e edite-a para incluir um recurso `notify` que nos dira algumas informações basicas do no.

```
  node default {
    notify { "Aqui e ${::fqdn}, rodando o sistema operacional ${::operatingsystem}": }
  }
```

Agora conecte novamente no nosso no de banco de dados:

`docker exec -it database bash`

E tente outra execução Puppet:

`puppet agent -t`

```
  Info: Using configured environment 'production'
  Info: Retrieving pluginfacts
  Info: Retrieving plugin
  Info: Loading facts
  Info: Caching catalog for database.learning.puppetlabs.vm
  Info: Applying configuration version '1495767971'
  Notice: Aqui e database.learning.puppetlabs.vm, rodando o sistema operacional Ubuntu
  Notice: /Stage[main]/Main/Node[default]/Notify[Aqui e database.learning.puppetlabs.vm, rodando o sistema operacional Ubuntu]/message: defined 'message' as 'Aqui e database.learning.puppetlabs.vm, rodando o sistema operacional Ubuntu'
  Notice: Applied catalog in 1.44 seconds
```

Com seu certificado assinado, o agente no seu no foi capaz de requisitar corretamente um catálogo ao mestre e aplica-lo para concluir a execução Puppet.

# Orquestrador de aplicação

Se você gerencia aplicações compostas de múltiplos serviços distribuidos atraves de múltiplos nos, você tambem sabe que a orquestracao de múltiplos nos pode se apresentar alguns desafios especiais. Sua aplicação tende a necessitar compartilhar informação entre os nos involvidos e mudanças de configuração precisam ser feitas na ordem correta para garantir que seus componentes de aplicação não fiquem fora de sincronia.

O Orquestrador de aplicação do Puppet estende o poderoso modelo declarativo do nivel de um unico no para o de uma aplicação complexa. Descreva sua aplicação em código Puppet, e deixe o Orquestrador de aplicação cuidar da implementacao.

__Atencao__: Antes de iniciar, você deve saber que essa quest vai ser um significantemente mais complexa das outras que vimos antes, tanto em termos de conceitos envolvidos, variedade de ferramentas e configuracoes com que você vai trabalhar. Entenda que o Orquestrador de aplicação e uma funcionalidade nova, e apesar de já ser uma ferramenta poderosa, ela continuara a ser estendida, refinada e integrada com o resto do ecossistema Puppet. Enquanto isso, seja paciente com os problemas que encontrar. Pode ser util pra ti se referir a documentacao do Orquestrador de aplicações para suplementar a informação dessa quest, aqui: https://docs.puppet.com/pe/latest/app_orchestration_overview.html

Saiba tambem que a Instalação do `multi_node` para a quest anterior e um pre-requisito para essa. Como mencionado nela, a tecnologia _Docker_ que estamos utilizando para disponibilizar múltiplos nos em uma unica VM vem com um certo custo sobre a performance e a estabilidade. Se você encontrar com qualquer problema, por favor contate learningvm@puppetlabs.com.


__NOTA DO CHRIS__: Caso você esteja acompanhando esse guia somente pela minha adaptacao, tente ler essa quest no material oficial. Como havia como visualizar os grafos exportando na outra quest, as imagens do guia eram possiveis de serem emuladas. Essa quest tem alguns desenhos explicativos da aplicação com que vamos trabalhar aqui.


# O Orquestrador de aplicação

Para entender como o Orquestrador de aplicações opera, vamos imaginar uma aplicação web de duas camadas simples, com um balanceador de carga.

__CORRE LA VER A IMAGEM, MO FI!__

Temos um unico balanceador de carga, que a distribui entre três servidores web, que por sua vez conectam ao mesmo banco de dados.

Cada um dos nos envolvidos nessa aplicação vai ter algum tipo de configuração para coisas que não envolvem diretamente na aplicação. Itens como `sshd` e `ntp` normalmente são  comuns a varios nos na sua infraestrutura e o Puppet não vai requisitar informação especifica sobre a aplicação em que o no esteja envolvido para configura-los corretamente. Alem dessas classes e recursos que são  independentes da aplicação, cada no nesse exemplo contém algum componente da aplicação: o servidor web, o banco de dados e o balanceador de carga alem de qualquer outro recurso necessario para suportar e configurar o conteúdo e servidos especificos da aplicação.

Essa configuração especifica da aplicação e chamada componente. No nosso exemplo nos definimos componentes para o banco de dados, o servidor web e o balanceador de carga. Cada um contém todas as classes e recursos necessarios para um no cumprir seu papel na aplicação. Um componente e, geralmente, um _tipo de recurso definido_, apesar de que ele tambem pode ser uma classe ou um recurso unico. Um _tipo de recurso definido_ e flexivel o bastante para incluir varios recursos e subclasses, e diferente de uma classe ele pode ser declarado multiplas vezes dentro do mesmo escopo, permitindo que seu ambiente tenha varias instancias de, assim por dizer, um componente de servidor web.

__CORRE LA VER A IMAGEM, MO FI!__

Com todos os componentes definidos, a proxima coisa a definir são  os relacionamentos entre eles como uma aplicação. Se sua aplicação esta empacotada como um módulo, a definição dessa aplicação geralmente vai no manifesto `init.pp`.

__CORRE LA VER A IMAGEM, MO FI!__

A definição da aplicação diz pra esses componentes como eles irao comunicar-se entre si e permite que o Orquestrador de aplicação a ordem das execucoes Puppet necessarias para implementar corretamente a aplicação nos nos da sua infraestrutura.

Esse ordenamento de execucoes Puppet e um papel importante em como as ferramentas no orquestrador de aplicações trabalham. E requer um pouco mais de control direto sobre quando o agente do Puppet executa nos nos envolvidos na sua aplicação .Se as execucoes Puppet ocorreram no intervalo padrão agendado de meia hora, não teriamos nenhuma maneira de garantir que os componentes de nossa aplicação fossem configurados na ordem correta. Se, por exemplo, uma execução Puppet em nosso servidor web disparasse antes da execução no servidor de BD, uma mudanca no nome do BD quebraria nossa aplicação. Nosso servidor web ainda tentaria conectar ao BD de uma configuração anterior, resultando em um erro quando aquela base estava indisponível.
  
### configuração de no

Pra evitar esse tipo de mudanca descoordenada, você vai precisar configurar os nos para que utilizem uma versao em cache do catálogo quando o Puppet executar. Isso permite que o Puppet execute conforme agendado para evitar um desvio de configuração, mas só ira fazer mudanças no catálogo somente quando você reimplementar intencionalmente sua aplicação. Tambem dessa maneira você deve desabilitar os plugins para que qualquer funcionalidade disponibilizada por plugins (ex.: funcoes ou provedores) não causem mudances descoordenadas aos nos da sua aplicação.

### Tarefa 1

Claro que poderiamos logar em cada um dos nos e alterar diretamente a configuração, mas por que não utilizar o Puppet para configurar a si mesmo? Existe um recurso `init_setting` que nos permitira realizar as mudanças as configuracoes `use_cached_catalog` e  `pluginsync` em cada arquivo de configuração `puppet.conf` nos agentes.

`vim /etc/puppetlabs/code/environment/production/manifests/site.pp`

Como queremos aplicar essas configuracoes tanto no no `webserver.learning.puppetlabs.vm` quanto no `database.learning.puppetlabs.vm` podemos utilizar uma expressao regular para combinar os dois direto na definição de no. Crie um novo grupo de nos com o nome `/^(webserver|database).*$/` e inclua dois recursos `ini_setting` para as mudanças que queremos realizar nas configuracoes.

```
  node /^(webserver|database).*$/ {
    pe_ini_setting { 'use_cached_catalog':
      ensure  =>  present,
      path    =>  $settings::config,
      section =>  'agent',
      setting =>  'use_cached_catalog',
      value   =>  'true',
    }
    pe_ini_setting { 'pluginsync':
      ensure  =>  present,
      path    =>  $settings::config,
      section =>  'agent',
      setting =>  'pluginsync',
      value   =>  'false',
    }
  }
```


### Tarefa 2

você pode disparar uma execução Puppet nos dois nos atraves do console PE. Navegue ate o console atraves de `https://<IP DA VM>` no seu navegador. Utilize as seguintes credenciais:

* usuário: admin
* senha: puppetlabs

Va ate a secao __Nodes > Inventory__ no console. Clique no no `database.learning.puppetlabs.vm` e clique nos botoes `Run Puppet...` e depois em `Run` para iniciar. você não precisa aguardar que a execução termine, retorne ate a secao __Inventory__ e faca o mesmo para o no `webserver.learning.puppetlabs.vm`. Enquanto essas execucoes acontecem fique a vontade para continuar o exercicio - vamos conferir o resultado das mesmas quando precisarmos aplicar código aos nos novamente.

### configuração Master

Antes que a gente saia escrevendo e implementando uma aplicação, no entanto, tem alguns passos ate que tenhamos o Orquestrador de aplicações do Puppet (_Puppet Application Orchestrator_) configurado corretamente.

A ferramenta _Puppet Orchestrator_ que vamos utilizar nessa quest e uma interface de linha de comando que interage com o serviço de Orquestracao de aplicação no Puppet mestre. Nos habilitamos esse serviço por padrão na VM de aprendizagem, e ele sera habilitado por padrão em versoes futuras do PE. (Caso você queira habilitar no seu proprio Puppet mestre, as intrucoes estão  em: https://docs.puppet.com/pe/latest/orchestrator_install.html#enable-the-application-orchestration-service-and-orchestrator-client)

### configuração do client e permissões

Enquanto o serviço de Orquestracao de aplicações roda no seu Puppet mestre, o cliente pode rodar em qualquer sistema com conexao de rede para o mestre. Isso significa que você pode gerenciar sua infraestrutura direto da sua maquina. Como não podemos assumir que o cliente ira rodar em um sistema com a configuração do Puppet apontando a URL e ambiente corretos, vamos ter que defini-los explicitamente. Apesar de que esses itens pudessem ser especificadas como _flags_ da linha de comando, criar um arquivo de configuração evita que você tenha que digita-las toda vez.

### Tarefa 3

Primeiro, crie a estrutura de diretórios onde esse arquivo de configuração sera mantido.

`mkdir -p ~/.puppetlabs/client-tools`

Agora crie o arquivo de configuração do Orquestrador

`vim ~/.puppetlabs/client-tools/orchestrator.conf`

Esse arquivo e formatado em JSON. (Lembre-se de que enquanto as virgulas são  boas praticas no seu código Puppet, elas são  proibidas no JSON!) Insira as seguintes opcoes:

```
  {
    "options": {
      "url" : "https://learning.puppetlabs.vm:443"
      "environment" : "production"
    }

  }
```

Agora o cliente do Orquestrador Puppet sabe onde esta o mestre, mas o mestre ainda precisa verificar que o usuário que esta executando comandos tem as permissões corretas. Isso e conseguido pelo sistema de RBAC (_role based access control_) do PE, que podemos configurar pelo console do PE.

Volte ao console do PE e encontre a secao __Access control__ na barra de navegacao esquerda.

Vamos criar um novo usuário `orchestrator` e atribuir permissões para utilizar o orquestrador de aplicações. Clique na secao __Users__ da barra de navegacao. Adicione um novo usuário com o nome completo _Orquestrador_ e login "orquestrador".

Agora que esse usuário existe, precisamos definir a senha dele. Clique no nome do usuário para acertar os detalhes, e clique no link __Generate password reset__. Copie e cole a url fornecida na sua barra de endereco e defina a senha como `puppet`.

Agora vamos dar permissão para esse usuário executar o Orquestrador Puppet. Va ate a secao __User Roles__ e crie uma nova funcao com o nome _Orquestradores_ e descricao _Executar o Orquestrador Puppet_.

Uma vez que essa nova funcao esta criada, clique no nome dela para modifica-la. Selecione seu usuário __Orquestrador__ no menu suspenso e adicione-o a funcao.

Finalmente, va ate a aba __Permission__. Selecione "Puppet Agent" do menu suspenso __Type__ e "Run Puppet on agent nodes" do menu __Permission__. Clique em __Add permission__ e aplique um _commit_ na alteracao.

### Token do client

Agora que você tem um usuário com as configuracoes certas, você pode gerar um token de acesso RBAC para autenticar com o serviço de Orquestracao.

### Tarefa 4

A ferramenta `puppet access` ajuda a gerenciar a autenticacao. Utilize o comando `puppet access login` para autenticar e ele ira salvar um token. Adicione a _flag_ `--lifetime=1d` assim você não precisa ficar gerando novos tokens enquanto trabalha.

`puppet access login --service-url https://learning.puppetlabs.vm:4433/rbac-api --lifetime=1d`

Quando solicitado, forneca o usuário e senha que você definiu no sistema RBAC do console PE: __orchestrator__ e __puppet__.

(Se receber uma mensagem de erro, confira se a URL esta correta)

## aplicações Puppetizadas

Agora que você já instalou seus nos master e agent para o orquestrador de aplicações alem de configurar seu cliente, você esta pronto para definir sua aplicação.

Assim como o código Puppet que você utilizou nas ultimas quests, uma definição de aplicação e geralmente empacotada em um módulo Puppet. A aplicação que você vai criar sera baseada no _stack pattern_ LAMP (Linux, Apache, MySQL e PHP).

Antes que a gente se jogue no código, vamos revisar por um momento os planos pra essa aplicação. O que a gente faz aqui vai ser um pouco mais simples que a aplicação com balanceamento de carga que discutimos acima. A gente vai te poupar um pouco da escrita e ainda apresentar as principais caracteristicas do orquestrador de aplicações.

__CORRE LA VER A IMAGEM, MO FI!__

Nos vamos definir dois componentes que serao aplicados a dois nos separados. Um vai definir a configuração do banco MySQL e sera aplicado ao no `database.learning.puppetlabs.vm`. O segundo vai definir a configuração pra um servidor web Apache e uma aplicação PHP e sera aplicado ao no `webserver.learning.puppetlabs.vm`.

Podemos utilizar os módulos existentes pra configurar o MySQL e o Apache. Garanta que os seguintes módulos estejam instalados no mestre:

`puppet module install puppetlabs-mysql`

e

`puppet module install puppetlabs-apache`

então pra esses dois nos serem implementados corretamente, o que precisa acontecer? Primeiro, temos que garantir que os nos sejam implementados na ordem correta. Porque o no do nosso servidor web depende do nosso servidor MySQL, a gente precisa garantir que o Puppet rode nosso servidor de BD primeiro e nosso servidor Web depois. A gente tambem precisa de um metodo pra passar informações entre nossos nos. Porque a informação que nosso servidor Web precisa para conectar na base de dados pode ser baseada em fatos `facter`, logica condicional ou funcoes no manifesto Puppet que define o componente, o Puppet não vai saber o que e ate que ele enfim gere o catálogo para o no de banco de dados. Assim que o Puppet tem essa informação, ele precisa de um jeito para passa-la como parâmetros para o nosso componente de servidor Web.

Ambos os requisitos são  atendidos atraves de algo que chamamos _recurso de ambiente_. Diferente dos recursos especificos de um no (como um `user` ou um `file`) que dizem ao puppet como configurar uma unica maquina, recursos de ambiente carregam dados e definem relacionamentos entre múltiplos nos em um ambiente. Nos vamos entrar mais no detalhe de como isso funciona a medida que implementamos nossa aplicação.

então o primeiro passo ao criar uma aplicação e determinar exatamente qual informação precisa ser passada entre os componentes. Com o que se parece isso no caso da nossa aplicação LAMP?

* __Host__: nosso servidor web precisa saber do nome de host do servidor de banco de dados
* __Banco de dados__: a gente precisa do nome especifico do banco que devemos conectar
* __usuário__: se a gente quer se conectar ao banco, vamos precisar do usuário
* __Senha__: e vamos precisar tambem da senha pra esse usuário

Essa lista especifica o que nosso servidor de BD _produz_ e o que o nosso servidor Web _consome_. Se passarmos essa informação pro nosso servidor Web, ele vai ter tudo o que precisa pra se conectar ao BD hospedado no nosso servidor de banco de dados. 

Pra permitir que toda essa informação seja produzida quando rodarmos o Puppet no servidor de banco de dados e consumida pelo nosso servidor Web, nos vamos criar um _tipo derecurso customizado_ chamado `sql`. Diferente de um recurso de no tipico, nosso recurso `sql` não vai especificar diretamente nenhuma mudanca nos nossos sistemas. você pode pensar nele como um recurso _dummy_, bobo. Uma vez que seus parâmetros são  definidos pelo componente de BD, ele só fica ali sentado para que aqueles parâmetros possam ser consumidos pelo componente do web Server. (Veja que recursos de ambiente podem incluir um código de sondagem mais complexo que permita ao Puppet aguardar ate que um serviço pre-requisito fique online antes de seguir para os componentes dependentes. Como isso requer um conhecimento mais aprofundado do Ruby, esta fora do escopo dessa quest)

Ao contrario dos tipos de recurso definidos que podem ser escritos em código Puppet nativo, criar um tipo customizado requer uma rapida incursao ao Ruby. A sintaxe sera bem simples, então não se preocupe caso não seja familiarizado com a linguagem.

### Tarefa 5

Como antes, o primeiro passo e criar a estrutura de diretórios do seu módulo. Garanta que você esta no diretório de módulos:

`cd /etc/puppetlabs/code/environments/production/modules`

E crie seus diretórios

`mkdir -p lamp/{manifests,lib/puppet/type}`

Perceba que estamos enterrando nosso tipo no diretório `lib/puppet/type`. Esse diretório e onde você deve manter qualquer extensao a linguagem base do Puppet que seu módulo prove. Por exemplo, alem de tipos, você tambem pode definir novos providers ou funcoes.

### Tarefa 6

Vamos agora criar nosso novo tipo de recurso `sql`.

`vim lamp/lib/puppet/type/sql.rb`

Esse novo tipo e definido por um bloco de código Ruby, desse jeito:

```
  Puppet:Type.newtype :sql, :is_capability => true do
    newparam :name, :is_namevar => true
    newparam :user
    newparam :password
    newparam :host
    newparam :database
  end
```

Viu so? Nada mal! Veja que e o trecho `is_capability => true` que permite a esse recurso existir no nivel de ambiente, ao inves de aplicado a um no especifico. Tudo mais deveria ser razoavelmente auto-explicativo. Mais uma vez, não temos que _fazer_ nada com esse recurso, e sim apenas dizer como queremos chamar nossos parâmetros.

### Tarefa 7

Agora que já temos nosso tipo de recurso `sql`, já podemos avancar para o componente de banco de dados que ira produzi-lo. Esse componente vive em nosso módulo `lamp` e define a configuração de um servidor MySQL, então iremos chama-lo `lamp::mysql`.

`vim lamp/manifests/mysql.pp`

Ele vai ficar assim

```
  define lamp::mysql (
      $db_user,
      $db_password,
      $host     = $::hostname,
      $database = $name,
    ) {
      class { '::mysql::server':
        service_provider  => 'debian',
        override_options  => {
          'mysqld' => { 'bind-address' => '0.0.0.0' }
        },
      }

      class { $name:
        user      => $db_user,
        password  => $db_password,
        host      => '%',
        grant     => ['SELECT','INSERT','UPDATE','DELETE'],
      }

      class { '::mysql::bindings': 
        php_enable        => true,
        php_package_name  => 'php5-mysql',
      }
    }
    Lamp::Mysql produces Sql {
      user      => $db_user,
      password  => $db_password,
      host      => $host,
      database  => $database,
    }
```

Verifique o manifesto com a ferramenta `puppet parser`. Como a orquestracao insere uma sintaxe nova, inclua a _flag_ `--app_management`

`puppet parser validate --app_management lamp/manifests/mysql.pp`

### Tarefa 8

Agora, crie um componente _webapp_ para configurar um servidor Apache e uma aplicação PHP simples.

`vim lamp/manifests/webapp.pp`

Ele vai ficar assim

```
  define lamp::webapp (
    $db_user,
    $db_password,
    $db_host,
    $db_name,
    $docroot = '/var/www/html'
  ) {
    class { 'apache':
      default_mods  => false,
      mpm_module    => 'prefork',
      default_vhost => false,
    }

    apache::vhost { $name:
      port           => '80',
      docroot        => $docroot,
      directoryindex => ['index.php','index.html'],
    }

    package { 'php5-mysql':
      ensure => installed,
      notify => Service['httpd'],
    }

    include apache::mod::php

    $indexphp = @("EOT"/)
      <?php
      \$conn = mysql_connect('${db_host}', '${db_user}', '${db_password}');
      if (!\$conn) {
        echo 'Connection to ${db_host} as ${db_user} failed';
      } else {
        echo 'Connected successfully to ${db_host} as ${db_user}';
      }
      ?>
      | EOT

    file { "${docroot}/index.php":
      ensure  => file,
      content => $indexphp,
    }

  }
  Lamp::Webapp consumes Sql {
    db_user     => $user,
    db_password => $password,
    db_host     => $host,
    db_name     => $database,
  }
```

Agora, verifique a sintaxe do seu manifesto

`puppet parser validate --app_management lamp/manifests/webapp.pp`

### Tarefa 9

Temos todos nossos componentes prontos, então vamos definir nossa aplicação. Como ela e o item principal do nosso módulo `lamp`, ela vai no manifesto `init.pp`

`vim lamp/manifests.init.pp`

Ja incluimos o trabalho pesado nos nossos componentes, então esse sera bem simples. A sintaxe de uma aplicação e parecida com a de uma classe ou um _recurso de tipo definido_. A unica diferenca esta em utilizarmos a palavra `application` no lugar de `define` ou `class`.

```
  application lamp (
    $db_user,
    $db_password,
  ) {

    lamp::mysql { $name:
      db_user     => $db_user,
      db_password => $db_password,
      export      => Sql[$name],
    }

    lamp::webapp { $name:
      consume => Sql[$name],
    }

  }
```

A aplicação possui dois parâmetros, `db_user` e `db_password`. O corpo da aplicação declara os componentes `lamp::webapp` e `lamp::mysql`. Nos passamos nossos parâmetros `db_user` e `db_password` atraves do componente `lamp::mysql`. E tambem nele onde utilizamos o metaparametro especial `export` para dizer ao Puppet que queremos que esse componente crie um recurso de ambiente `sql`, que podera ser consumido pelo componente `lamp::webapp`. Lembra-se do bloco `Lamp::Mysql produces Sql` que colocamos depois da definição de componente?

```
  Lamp::Mysql produces Sql {
    user     => $db_user,
    password => $db_password,
    host     => $host,
    database => $database,
  }
```

Isso diz ao Puppet como mapear as variaveis do nosso componente `lamp::mysql` em um recurso de ambiente `sql` quando utilizarmos o metaparametro `export`. Perceba que apesar de estarmos definindo explicitamente os parâmetros `db_user` e `db_password` somente na declaração desse componente, os padrões desse parametro serao passados mesmo assim.

O bloco de _matching_ `Lamp::Webapp consumes sql` no manifesto `webapp.pp` diz ao Puppet como mapear os parâmetros do recurso de ambiente `sql` com o nosso componente `lamp::webapp` quando incluimos o metaparametro `consume => Sql[$name]`.

```
  Lamp::Webapp consumes Sql {
    db_name     => $name,
    db_user     => $user,
    db_host     => $host,
    db_password => $password,
  }
```

Uma vez que tenha terminado a definição da aplicação, valide sua sintaxe e faca qualquer correcao necessaria

`puppet parser validate --app_management lamp/manifests/init.pp`

Agora, use o comando `tree` para verificar que todos os componentes do seu módulo estão  no lugar

`tree lamp`

Seu módulo deve parecer com isso

```
  modules/lamp/
  ├── lib
  │   └── puppet
  │       └── type
  │           └── sql.rb
  └── manifests
      ├── init.pp
      ├── mysql.pp
      └── webapp.pp

  4 directories, 4 files
```

### Tarefa 10

Agora que sua aplicação esta definida, o passo final e declara-la no manifesto `site.pp`

`vim /etc/puppetlabs/code/environments/production/manifests/site.pp`

Ate agora, a maior parte da configuração feita no seu `site.pp` foi no contexto de blocos de nos. Uma aplicação, entretanto, e aplicada ao seu ambiente independentemente de qualquer classificacao definida nos seus blocos de no ou no classificador de nos do PE. Para expressar essa distincao, declaramos a aplicação com o bloco especial chamado `site`.

```
  site { 
    lamp { 'app1':
      db_user     => 'roland',
      db_password => '12345',
      nodes       => {
        Node['database.learning.puppetlabs.vm']  => Lamp::Mysql['app1'],
        Node['webserver.learning.puppetlabs.vm'] => Lamp::Webapp['app1'],
      }
    }
  }
```

A sintaxe para declarar uma aplicação e similar a de uma classe ou recurso. Os parâmetros `db_user` e `db_password` são  definidos do mesmo jeito.

O parametro `nodes` e onde a magica da orquestracao acontece. Esse parametro toma um _hash_ de nos pareados com um ou mais componentes. No nosso caso, atribuimos o componente `Lamp::Mysql['app1']` a `database.learning.puppetlabs.vm` e `Lamp::Webapp['app1']` a `webserver.learning.puppetlabs.vm`. Quando o Orquestrador de aplicações roda, ele usa os metaparâmetros `exports` e `consumes` na sua definição de aplicação (em `lamp/manifests/init.pp`, por exemplo) para determinar a ordem correta de execucoes Puppet entre os nos da aplicação.

Agora que a aplicação esta declarada no nosso manifesto `site.pp`, podemos utilizar a ferramenta `puppet app` para visualiza-la

`puppet app show`

você deve ver um resultado parecido com esse

```
  Lamp['app1']
    Lamp::Mysql['app1'] => database.learning.puppetlabs.vm
        - produces Sql['app1']
    Lamp::Webapp['app1'] => webserver.learning.puppetlabs.vm
        - consumes Sql['app1']
```

### Tarefa 11

Utilize o comando `puppet job` para implementar a aplicação.

`puppet job run Lamp['app1']`

você pode verificar o estado de qualquer job executado ou em execução com o comando `puppet job show`.

Agora que seus nos estão  configurados com sua aplicação nova, vamos parar para conferir os resultados. Primeiro, podemos logar no servidor de banco de dados e dar uma olhada na nossa instancia MySQL.

`docker exec -it database bash`

Lembre-se, não importa em que só você esteja, você pode utilizar o comando `puppet resource` para verificar o estado de um serviço. Vamos ver se o MySQL esta rodando:

`puppet resource service mysql`

você deveria ver que o recurso esta rodando. Se quiser, você tambem pode abrir o cliente com o comando `mysql`. Quando terminar, utilize `\q` para sair.

Agora va em frente e desconecte-se do no do banco de dados.

Ao inves de logar no nosso no de servidor web, vamos apenas conferir se esta rodando. Na Instalação pre-configurada do docker para essa tarefa, nos mapeamos a porta `80` no conteiner `webserver.learning.puppetlabs.vm` para a porta `10080` no no `learning.puppetlabs.vm` - nossa VM de aprendizagem. Em um navegador web, va para `http://<IP DA VM>:10080/index.php` para visualizar seu site PHP.