
# Intuito desse repositorio

Comecei a estudar puppet e me encantei pelas possibilidades que se abriram. Como o material da VM de aprendizagem esta em ingles, resolvi compartilhar todas minhas notas e o que julguei que era interessante traduzir da da documentacao alem de demais itens que forem criados no processo de estudo da mesma. As notas estarao divididas pelas buscas (quests) do material oficial, todo e qualquer artefato estara dividido nessa mesma hierarquia. Alguns termos eu realmente preferi manter no original e citar sua traducao apenas uma vez - como no caso das _quests_, quando for assim manterei a palavra em italico.

Para acompanhar as notas, utilize o _Quest Guide_ e a VM contidas no _.zip_ disponivel via: https://puppet.com/download-learning-vm

O script `gitsays.sh` foi uma brincadeira com o modulo `cowsays` do material. E apenas um wrapper para eu transferir as coisas da VM para meu repositorio local (atualizando), dar um commit e enviar para o GitHub (utilizo chave SSH para isso).

# Forca do Puppet

Para buscar um modulo:
    
```
    puppet module search graphite
    puppet module install dwerder-graphite -v 5.16.1
    	--module_repository=https://forge.puppet.com
```

* Para o puppet, classe e um bloco que serve para agrupar recursos
* Um modulo pode abrigar varias classes, mas geralmente vai ter uma classe main, com o mesmo nome do modulo (como no java)
    - geralmente responsavel por instalar/configurar o componente primario desse modulo
* class + node = classificacao (classification)
* grupo de no (node group): permite classificar _nodes_ baseados no certname e nas informacoes coletadas via `facter`
* Utilizar para disparar atualizacao no Puppet
    `puppet agent -t`
* O daemon de agente do puppet roda, por padrao, a cada 30min. Pede um catalogo ao master, parseia, gera um catalogo do node e devolve ao agente, o agente entao aplica qualquer change necessaria para estar up-to-date com o catalogo
* Executa manualmente essa sincronia com master
    `puppet agent --test`


# Recursos

Recursos sao os alicerces da linguagem de modelagem declarativa do puppet. Sao todo e qualquer aspecto da configuracao de sistema que deseja-se gerenciar, traduzidas em uma unidade chamada recurso. Essa e a base da RAL (Resource Abstraction Layer, camada de abstracao de rescursos) do Puppet.

Descrevemos recursos dentro de uma declaracao de recurso (resource declaration), fazemos isso em codigo puppet, uma linguagem de dominio especifico (DSL, domain specific language) baseada em Ruby.

A _DSL_ do puppet e declarativa e nao imperativa, dependendo de provedores para cuidar da implementacao. Dito isso, a preocupacao esta apenas em descrevermos/declararmos um estado final desejado.

A base para a _DSL_ vem da sintaxe de _hash_ do proprio Ruby, que vai ser o objetivo da declaracao de recursos nessa _quest_. Uma das facilidades dessa _DSL_ esta em podermos inpecionar o estado de um recurso da mesma maneira que declaramos seu estado desejado.

## Tarefa 1:

Consultar as informacoes da conta de usuario root:

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

Essa linguagem de declaracao possui tres elementos: tipo, titulo, par-valor do atributo

## Tipo

```
    user { 'root':
      ...
    }
```

Outros tipos principais sao: _group, file, package, service, cron, exec e host_Para consultar todos os tipos, use: https://docs.puppet.com/puppet/latest/type.html ou utilize `puppet describe --list`


## Titulo

```
    user { 'root':
      ...
    }
```

No exemplo acima, `'root'` e nosso titulo. Trata-se do identificador interno - e unico - para esse recurso. Serve como uma chave primaria, ja que _dois recursos do mesmo tipo jamais podem compatilhar o mesmo nome_. Geralmente o titulo do recurso condiz com o nome da coisa que esse recurso gerencia: usuarios e pacotes com seus nomes, arquivos com seus paths completos. O Puppet permite que voce declare explicitamente os titulos de seus recursos, mas isso pode ser tornar mais dificil a gestao do seu codigo e impedir economizar algumas linhas.

## Par-valor de um atributo

Utilizando a sintaxe abaixo,

```
    user { 'root':
        shell            => '/bin/bash',
    }
    
```

No corpo da declaracao de um recurso temos seus atributos, compostos por: atributo, hash rocket (=>) e seu valor correspondente. Sendo assim, no exemplo acima, temos que _/bin/bash_ e o shell do usuario _root_.

Note que ha uma virgula mesmo com apenas um recurso declarado no exemplo, isso e uma boa pratica, de forma a garantir que nao esquecamos de colocar virgulas em alguma outra declaracao de atributo, caso um recurso precise ser atualizado

## Tarefa 2

Percebemos entao que o outro esta em saber manipular bem os atributos de um recurso, para conhece-los melhor e explorar isso, utilizamos o comando describe. Como abaixo:

`puppet describe user | less`

__Dica:__ executar o comando acima em uma sessao de ssh propria, no webshell o mesmo pode truncar.

## Puppet Apply

A ferramenta `puppet apply` pode ser utilizada com a _flag_ (bandeira) -e (de --execute) para executar codigo puppet. Dessa maneira a execucao acontece apenas uma vez, sendo util para testes e exploracao.

## Tarefa 3

A _flag ensure_ serve para que o puppet confira no sistema se o recurso existe e, caso negativo, realize a criacao do mesmo.

`puppet apply -e "user { 'galatea': ensure => present, }" `

Para conferir o usuario

`puppet resource user galatea`

O mesmo nao possui ainda o atributo _Comments_ como no caso do usuario root.

## Tarefa 4

Poderiamos adicionar o atributo via `puppet apply -e`, mas nesse caso deveriamos passar a declaracao toda em uma linha so, alem de que nao poderiamos ver o estado do recurso antes de aplicar tudo. A ferramenta `puppet resource` possui a _flag_ `-e`, que abre o conteudo do recurso diretamente em um editor (Vim por padrao) e nos permite editar de uma maneira melhor. Para adicionar um atributo basta incluir uma linha (nao esqueca da virgula ao vinal), com o par valor (e o _hash rocket_).

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

Um manifesto e basicamente um arquivo `.pp` que contem as informacoes vistas via `puppet resource` e inseridas via `puppet apply`, o que importa mesmo e a localizacao desse manifesto. Tanto sua localizacao como sua estrutura em relacao ao FS do Puppet master sao devido as classes.

## Classes

E o proximo nivel de abstracao acima de um recurso, declara um grupo de rescursos relacionados a um unico componente de sistema. Possui parametros para adapta-la as suas necessidades. Dessa maneira podemos administrar recursos de acordo com sua funcao.

Para utilizar uma classe, cumprimos dois passos: definir (e salvar em um manifesto), assim o Puppet realizara o parse para lembrar a definicao da mesma. So entao a mesma pode ser declarada para aplicar todas as declaracoes de recurso que contem em um _node_ da sua infraestrutura.

Dentro de um _node_, classes sao _singletons_ portando so podem ser declaradas uma unica vez por _node_ (nao confundir com a ideia de classes em OOP, por exemplo).

# Cowsayings (Vacas Falantes)

O objetivo aqui vai ser utilizar o recurso do tipo _package_ (pacote) e a VM ja preparou um diretorio no _modulepath_ do Puppet, com os diretorios _manifests_ e _examples_, em:

`/etc/puppetlabs/code/environments/production/modules`

## Cowsay

Para utilizar o comando `cowsay`, precisamos instalar o _package cowsay_. Podemos utilizar o recurso _package_ porem essa declaracao precisa ir para algum lugar.

### Tarefa 1

Crie a estrutura de diretorio do nosso modulo (lembrando que entendemos modulo como um abrigador de classes, com suas classes homonimas sendo responsaveis por instalar/conigurar os pacotes primarios desse modulo):

```
    mkdir -p cowsayings/{manifests,examples}
```

__Nota:__ por convencao, o diretorio _manifests_ contem as classes, cada uma em seu respectivo arquivo homonimo. O diretorio _examples_ contem os testes para essas classes.

Crie um manifesto com o vim:

```
    vim cowsayings/manifests/cowsay.pp
```

Insira a seguinte definicao:

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

O comando so retorna alguma saida caso exista algum erro (recomendo colocar algo errado no manifesto e testar). Como a classe esta apenas definida e nao declarada, ficamos impossibilitados de aplica-la, apesar do comando de apply concluir, o resultado  de `puppet resource package cowsay` e:

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

Arquivos de manifesto .pp contidos em _examples_ ou _tests_ geralmente sao utilizados para validarmos classes que estamos desenvolvendo em um modulo. Por convencao vamos utilizar o diretorio _examples_ que criamos anteriormente.

`vim cowsayings/examples/cowsay.pp`

Nesse manifesto, vamos _declarar_ a classe com a palavra chave __include__:

`include cowsayings::cowsay`

__Dica:__ a _flag_ `--noop` faz uma dry run (execucao enxuta) do agente, compilando o catalogo e notificando as mudancas que seriam aplicadas sem realmente aplicar nada ao sistema.

Para testar, usamos entao:

`puppet apply --noop cowsayings/examples/cowsay.pp`

Exemplo da saida com `--noop`:

```
    Notice: Compiled catalog for learning.puppetlabs.vm in environment production in 0.12 seconds
    Notice: /Stage[main]/Cowsayings::Cowsay/Package[cowsay]/ensure: current_value absent, should be present (noop)
    Notice: Class[Cowsayings::Cowsay]: Would have triggered 'refresh' from 1 events
    Notice: Stage[main]: Would have triggered 'refresh' from 1 events
    Notice: Applied catalog in 1.42 seconds
```

__Nota:__ em uma instalacao offline ou com um firewall voce pode necessitar instalar o gem de um cache local da VM. Em uma infra real, voce pode configurar um _mirror_ (espelho) de um _rubygems_ com uma ferramenta como o __Stickler__ (`gem install --local --no-rdoc --no-ri /var/cache/rubygems/gems/cowsay-*.gem`).

### Tarefa 3

Caso a execucao com `--noop` seja bem sucedida, aplique o manifesto removendo a _flag_ `--noop`:

```
    puppet apply cowsayings/examples/cowsay.pp 
    Notice: Compiled catalog for learning.puppetlabs.vm in environment production in 0.14 seconds
    Notice: /Stage[main]/Cowsayings::Cowsay/Package[cowsay]/ensure: created
    Notice: Applied catalog in 2.25 seconds
```

Teste de execucao:

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

Esse modulo nao e inteiramente sobre nossa vaca, mas tambem sobre o que ela fala. Com o package `fortune` podemos fornecer uma base de dados com frases de sabedoria.

### Tarefa 4

Vamos criar um novo manifesto para nossa definicao da classe _fortune_: `vim cowsayings/manifests/fortune.pp`

E inserir a seguinte definicao (_atencao aqui ao titulo sendo customizado_):

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

Um modulo geralmente reune varias classes que trabalham juntas assim declaramos tudo de uma vez. No entanto precisamos fazer uma ressalva em relacao ao __escopo__. As classes que escrevemos para cowsay, sao todas precedidas por `cowsayings::`. Quando declaramos uma classe, dizemos com essa sintaxe de escopo que essa classe pode ser encontrada no modulo _cowsayings_.

No caso da classe principal de um modulo, as coisas mudam um pouco. Ao inves de nomearmos o manifesto utilizando o nome da classe que ele contem, o Puppet reconhece o arquivo especial __init.pp__ como contenedor do manifesto de nossa classe principal.

### Tarefa 7

Para conter nossa classe `cowsayings`, crie um arquivo de manifesto `init.pp` no diretorio `cowsayings\manifests`:

`vim cowsayings\manifests\init.pp`

Nele, vamos definir a classe _cowsayings_, dentro da mesma utilizamos a mesma sintaxe (`include modulo::classe`) para declarar as classes contidas.

```
    class cowsayings {
        include cowsayings::cowsay
        include cowsayings::fortune
    }
```

Salve o manifesto e teste com a ferramanta `puppert parser validate`.

### Tarefa 8

Nesse estagio, tanto o pacote __fortune__ como o __cowsays__ ja estao instalados na VM. Aplicar nossas mudancas nao alteraria em nada, entao utilizaremos a ferramenta `puppet resource` para deletar esses pacotes e testarmos a funcionalidade da nossa classe __cowsays__ recem criada:

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

Agora crie um teste para o manifesto _init.pp_ no diretorio de exemplos:

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

# Modulos

Sao basicamente _bundles_ (agrupamentos) de todo o codigo e dados que voce precisa para gerenciar algum aspecto de sua configuracao.

## Por que se meter com modulos?

Modulos permitem que o codigo seja organizado em unidades reutilizaveis, testaveis e portaveis (ou seja, modulares). Garantimos assim transparencia e reproducibilidade da maneira menos dolorosa possivel.

Solucoes podem misturar e combinar modulos auto-contidos, que sao mais faceis de testar, manter e compartilhar. Em essencia, modulos sao pouco mais que uma estrutura de arquivos e diretorios que seguem as convencoes do Puppet. Essas convencoes dao ao Puppet uma maneira consistente de localizar classes, arquivos, templates, plugins e binarios destinados a realizar o objetivo desse modulo. Sao tambem importantes para gerenciar o escopo, ja que que tudo fica contido em seu modulo evita-se em muito os problemas de colisao.

Como modulos sao padronizados e auto-contidos, o compartilhamento fica realmente facil, sendo o __Forge__ (Forja) o servico gratuito de hospedagem de modulos desenvolvidos e mantidos por outros usuarios da comunidade.

## O _modulepath_

Todos os modulos acessiveis pelo seu _Puppet Master_ estao localizados nos diretorios especificados pela variavel _modulepath_ no arquivo de configuracao do Puppet.

### Tarefa 1

O valor da variavel _modulepath_ pode ser acessado via `puppet master --configprint modulepath`. O resultado contem os diretorios a serem utilizados alem da ordem em que isso ocorre.

* Modulos utilizados nessa VM: _/etc/puppetlabs/code/environments/production/modules_
* Modulos do site necessarios para todos os ambientes: _/etc/puppetlabs/code/modules_
* Modulos necessarios do Puppet Enterprise: _/opt/puppetlabs/puppet/modules_

## Estrutura do Modulo

Um modulo consiste em uma estrutura pre definida que permite que o Puppet encontre confiavelmente o conteudo desse modulo. Para verificar que modulos estao instalados, utilizamos `puppet module list`.

Apenas para visualizar melhor a estrutura de diretorios de um modulo, vamos utilizar o comando `tree` com alguns parametros para limitar a profundidade de diretorios em dois niveis:

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

Para essa _quest_ iremos escrever um modulo que trabalha com o recurso do tipo _file_ (arquivo) e utiliza-lo para gerencias nossas configuracoes do _Vim_. Alem de ser um bom exemplo para gerenciar arquivos de configuracao, o tipo _file_ possui algumas abstracoes de _URI_ baseadas na estrutura de modulo para encontrar as fontes dos arquivos.

Antes de iniciar vamos para o diretorio do _modulepath_:

`cd /etc/puppetlabs/code/environments/production/modules`

### Tarefa 2

O diretorio de topo sera o nome do nosso modulo, vamos utilizar _vimrc_:

`mkdir vimrc`

### Tarefa 3

Agora iremos criar outros tres diretorios: um para manifestos, um para exemplos e outro para arquivos:

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

A VM de aprendizagem ja possui algumas customizacoes para o Vim, ao inves de criar um _.vimrc_ do zero, podemos copiar o existente para o diretorio arquivo do nosso novo modulo. Qualquer arquivo disponivel no diretorio `files` de um modulo no `modulepath` esta disponivel a todos os nos atraves do servidor de arquivos do proprio Puppet.

### Tarefa 4

Copiando o _.vimrc_ para o diretorio _files_ do nosso modulo:

`cp ~/.vimrc vimrc/files/vimrc`

### Tarefa 5

Uma vez copiado, podemos fazer uma adicao as configuracoes. 

`vim vimrc/files/vimrc`

Por padrao no _Vim_ os numeros de linha estao desabilitados, entao iremos adicionar essa configuracao no arquivo com a linha:

`set number`

Salve e saia.

### Tarefa 6

Agora que nosso arquivo fonte esta criados, precisamos de um manifesto para dizer o que o Puppet deve fazer com isso, lembrando-se que o manifesto que contem a classe principal do modulo sempre se chamara _init.pp_

`vim vimrc/manifests/init.pp`

O codigo Puppet aqui vai ser bem simples: vamos definir uma classe vimrc, realizar uma declaracao de recurso tipo _file_ para enviar o arquivo _vimrc_ de nosso modulo para a localizacao especifica. Nesse caso, o arquivo que se encontra no diretorio `/root`, entao seu caminho completo sera o titulo do recurso no arquivo da declaracao.

Nosso recurso precisara de dois atributos tambem. Ja haviamos utilizado `ensure => present,` para garantir que o arquivo existisse no _filesystem_, no entando o Linux entende que isso e valido tanto para arquivos normais como para diretorios. Para garantir entao que seja um arquivo presente, utilizaremos `ensure => file,` explicitamente.

O segundo atributo deve indicar ao Puppet qual o conteudo que o arquivo deve ter. O valor do atributo com a fonte do arquivo deve ser a URI desse arquivo fonte.

Todas as URIs do servidor de arquivos do Puppet e estruturada assim:

`puppet://{nome de host do server (opcional)}/{ponto de montagem}/{restante do caminho}`

Mas ha ainda um pouco mais de magica embutida no Puppet para deixar essas URIs mais concisas:

* O nome de host do server vai ser quase sempre omitido, ja que seu valor padrao aponta para o _Puppet Master_. Utilizamos somente quando necessitarmos apontar outro servidor de arquivos. Por padrao, entao, usamos 3 barras `puppet:///`
* Quase todos os arquivos do Puppet sao servidos via modulos, para os quais o Puppet fornece alguns atalhos. Ele trata `modules` como um ponto de montagem especial que aponta para o _modulepath_ do _Puppet Master_. A URI fica agora assim `puppet:///modules/`
* Como todos os os arquivos a serem servidos por um modulo devem estar no diretorio _files_, o nome do mesmo tambem e implicito e fica fora da URI.

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

## Testando seu modulo

Lembrando, o manifesto define/descreve nossa classe `vimrc` mas precisamos declara-la para fazer algum efeito.

### Tarefa 7

Para testar, temos que criar o manifesto no diretorio _examples_

`vim vimrc/examples/init.pp`

E realizar a declaracao atraves de um  `include`:

`include vimrc`

### Tarefa 8

Aplique o manifesto com a _flag_ `--noop`. Se tudo estiver certo, dispense a mesma e execute pra valer.

O output deve ser parecido com esse

```
    Notice: Compiled catalog for learning.puppetlabs.vm in environment production in 0.17 seconds
    Notice: /Stage[main]/Vimrc/File[/root/.vimrc]/content: content changed '{md5}9cccec66ddbdf2cb32992c81e5281c8d' to '{md5}d1f40457544e7c0826da35bb0481afde'
    Notice: Applied catalog in 0.62 seconds
```

Quando o Puppet gerencia um arquivo, ele compara o _hash_ do arquivo algo com o do arquivo fonte, caso nao batam fica sabido que o arquivo foi alterado e ocorre uma substituicao do mesmo para atingir o estado desejado.

# NTP

O objetivo dessa quest e simples: utilizar um modulo Puppet para gerenciar o servico de NTP na nossa VM.

Tanto quanto saber escrever modulos e importante para melhor integra-los em nossa infraestrutura, entender como utilizar modulos existentes tambem e muito importante (escolhendo entre modulos _Puppet Approved_ e _Puppet Supported_ como uma camada extra de seguranca). Ao utilizarmos codigo publico, estamos utilizando codigo ja executado e testado em centenas e ate milhares de infraestruturas diferentes.

__Nota:__ independentemente da fonte do seu modulo, uma revisao externa jamais sera substituta de uma revisao feita em casa antes de utilizar o mesmo em producao.

## O que e NTP

Diversos servicoes de uma infinidade de dominios dependem de relogios precisos e coordenados para funcionarem corretamente. Dada a variabilidade da latencia de rede e demais variaveis, precisamos de excelentes algoritmos para garantir isso.

O Network Time Protocol (NTP, Protolo de Hora em Rede) garante precisao de milissegundos entre servidores enquanto mantem a sincronia com Coordinated Universal Time (UTC, Tempo Universal Coordenado ) atraves de servidores acessiveis publicamente.

NTP e um dos servicos mais fundamentais a serem incluidos em uma infraestrutura. O modulo de gestao e configuracao desse servico e mantido pela Puppet Labs.

## Pacote/Arquivo/Servico

Antes de instalar o modulo do NTP, vamos primeiro entender o estado atual do nosso sistema, assim mantemos registro do que o Puppet altera e porque o NTP faz o que faz.

O Puppet ira gerenciar tres recursos chave para deixar o servico do NTP rodando. A ferramenta `puppet resource` pode mostrar o estado atual de cada um desses recursos:

Verifique o estado do pacote:

```
    # puppet resource package ntp

    package { 'ntp':
      ensure => 'purged',
    }
```

O arquivo de configuracao:

```
    # puppet resource file /etc/ntp.conf

    file { '/etc/ntp.conf':
      ensure => 'absent',
    }
```

O estado do servico:

```
    # puppet resource service ntpd

    service { 'ntpd':
      ensure => 'stopped',
      enable => 'false',
    }
```

O padrao package/file/service (pacote, arquivo e servico) e bem comum no Puppet. Esses tres tipos de recurso correspondem a sequencia de instalar um _package_, customizar sua funcionalidade com arquivos de configuracao e iniciar o servico que esse _package_ prove.

Esse padrao tambem os relacionamentos tipocos de dependencia entre esses recursos: uma classe bem escrita define tais relacionamentos, dizendo ao Puppet pra reiniciar o servico se o arquivo de configuracao foi modificado e recriar o arquivo de configuracao quando o _package_ e instalado ou atualizado. Nessa quest nosso objetivo ainda nao e esse, e sim trabalar com modulos. Entao maos a obra!

## Instalacao

Antes de classificar a nossa VM com a classe do NTP, precisamos  instalar o modulo de NTP direto do __Forge__. Por mais que o modulo chame `ntp`, lembre-se que modulos no __Forge__ tem o nome da conta associada no prefixo. Entao para obter o modulo, usaremos `puppetlabs-ntp`, mas ao conferir o _modulepath_ no nosso _Puppet Master_, veremos apenas `ntp`. __Tenha em mente isso__ ao instalar modulos com mesmo nome, para evitar conflitos.

### Tarefa 1

Utilizar a ferramenta `puppet module` para instalar o `ntp` via __Forge__. 
(Caso voce tenha instalado os modulos do cache essa tarefa pode ja estar concluida e voce pode pular para o proximo passo)

```
    # puppet module install puppetlabs-ntp
    
    Notice: Preparing to install into /etc/puppetlabs/code/environments/production/modules ...
    Notice: Downloading from http://localhost:8085 ...
    Notice: Installing -- do not interrupt ...
    /etc/puppetlabs/code/environments/production/modules
    └─┬ puppetlabs-ntp (v6.0.0)
      └── puppetlabs-stdlib (v4.15.0)
```

Esse comando diz ao Puppet para obter o modulo direto do __Forge__ e colocado dentro do nosso _modulepath_, no caso:

`/etc/puppetlabs/code/environments/production/modules`

## Classificacao com o manifesto site.pp

Agora que o modulo ntp esta instalado, todas suas classes ficam disponiveis para classificarmos os _nodes_. Na segunda quest (_Forca do Puppet_), fizemos uma classificacao via console do _Puppet Enterprise_. Iremos introduzir uma outra maneira nessa quest, o arquivo de manifesto `sites.pp`.

`site.pp` e o primeiro manifesto que o agente do Puppet verifica ao conectar no _master_. Ele define configuracoes globais e padroes de recurso que se aplicam a __todos__ os nodes na infraestrutura. E tambem o local onde colocamos _definicoes de nos_ (tambem conhecidos como `node statements`).

Uma _definicao de no_ e o equivalente a definicao em codigo do que fizemos no _Puppet Enterprise_:

```
    node 'learning.puppetlabs.vm' {
        ...
    }
```

Como e mais acessivel monitorar com a ferramenta de `quest` do material, vamos utilizar principalmente o `site.pp` daqui em diante. O que aprendermos sobre definicao de nos e classes se aplica a qualquer metodo de classificacao escolhido, incluindo o classificador do PE.

### Tarefa 2

Abrir o manifesto `site.pp` em algum editor:

`vim /etc/puppetlabs/code/environments/production/manifests/site.pp`

__Dica:_ a tecla `G` pula para o final do arquivo.

O a definicao node `default` se trata de uma definicao especial, aplicada a qualquer node que nao esteja especificamente incluso em alguma outra definicao.

Como queremos que nossas mudancas sejam aplicadas apenas a VM de aprendizagem, vamos colocar a declaracao de classe `ntp` em um novo bloco de node 'learning.puppetlabs.vm'.

```
    node 'learning.puppetlabs.vm' {
        include ntp
    }
```

### Tarefa 3

Disparar uma execucao do Puppet via ferramenta `puppet agent` e interessante para aprendizagem e testes, no entanto na producao voce deve preferir que o Puppet execute conforme agendamento, a cada 30 minutos, por padrao. Como voce ira executar o Puppet logo depois de alterar o manifesto `site.pp` talvez o cache nao tenha sido atualizado. Caso as mudancas nao estejam refletidas apos uma execucao via `puppet agent -t`, tente executar o comando mais uma vez.

Teste o manifesto `site.pp` via  `puppet parser validate` e dispare uma execucao do Puppet via:

`puppet agent -t`

Utilize a ferramenta `puppet resource` para inspecionar o servico `ntpd` mais uma vez, caso a classe tenha sido aplicada com sucesso o servico estara no ar.

### Sincronizando

Para evitar a quebra de processos que dependem de horario consistente, o servico de NTP funciona gradualmente, adicionando/removendo microsegundos a cada ciclo do relogio ate que exista sincronia com o servidor NTP.

Utilize o comando `ntpstat` para conferir o estado da sincronizacao. Nao se preocupe caso a VM demore algum tempo para sincronizar visto que seu horario esta atrelado ao horario de criacao da imagem (ou a ultima vez que ela foi suspensa).

## Padroes e parametros de Classe

A classe `ntp`  inclui configuracoes padroes para a maioria dos seus parametros. A sintaxe de `include` utilizada ha pouco permite que voce declare a classe de maneira consisa sem modificar esses padroes.

Um desses padroes, por exemplo, diz quais servidores de NTP devem ser incluidos no arquivo de configuracao. Para ver quais servidores foram especificados por padrao, podemos verificar direto no arquivo, via:

`grep server /etc/ntp.conf`

Voce vera a listagem de servidores:

```
    server 0.centos.pool.ntp.org
    server 1.centos.pool.ntp.org
    server 2.centos.pool.ntp.org
```

Esses nao sao servidores de hora e sim pontos de acesso que irao passar voce a servidores publicos. A maioria de tais servidores assinalados sao fornecidos por voluntarios rodando um servidor NTP como um servico extra em um servidor de e-mail ou web.

Apesar de funcionarem bem, voce tera um horario mais preciso e utilizara menos rede caso utilize servidores publicos na sua regiao.

Para especificar manualmente quais servidores o servico NTPD vai consultar, voce devera sobrescrever os servidores padroes definidos pelo modulo NTP.

Nesse momento os _parametros de classe_ do Puppet entram em acao, fornecendo um metodo para definir variaveis em uma classe no momento em que e declarada. A sintaxe de classes parametrizadas e bem parecida com a da declaracao de recursos:

```
    class { 'ntp':
        servers => [
            'nist-time-server.eoni.com',
            'nist1-lv.ustiming.org',
            'ntp-nist.ldbsc.edu',
        ]
    }
```

O parametro `servers` na nossa declaracao de classes recebe uma lista de servidores como valor, nao apenas um. Trata-se de um array e permite atribuir uma lista de valores a uma variavel - sempre contidos entre colchetes "[" e "]", separados por virgula.

### Tarefa 4

No seu `site.pp` substituia a declaracao `include ntp` por uma que seja parametrizada com outros servidores. Pode-se utilizar os tres do exemplo ou outros de sua preferencia, lembrando de declarar ao menos tres para garantir a confiabilidade do funcionamento do NTP.

`vim /etc/puppetlabs/code/environments/production/manifests/site.pp`

A declaracao deve ficar assim:

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

Assim que efetuar a alteracao no manifesto `site.pp` utilize a ferramenta `puppet parser` para validar que esta tudo Ok e entao dispare uma execucao via ferramenta `puppet agent`.


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

Verifique que o arquivo `/etc/ntp.conf` foi alterado e que o servico `ntpd` foi reiniciado. 

# MySQL

## PorQueSQL?

O modulo de MySQL (mantido) e utilizado para simplificar tarefas complexas sem sacrificar robustez e controle. O modulo permite que voce instale e configure tanto instancias de servidor como de cliente. Permite tambem estender o tipo de recurso para gerenciar usuarios, grants e bases de dados MySQL com a linguagem de recurso padrao do Puppet.

## Instalacao do Servidor

### Tarefa 1

Antes de iniciarmos, vamos pegar o modulo `puppetlabs-mysql` do __Forge__ atraves da ferramenta `puppet module`. (Caso voce tenha instalado os modulos do cache essa tarefa pode ja estar concluida e voce pode pular para o proximo passo)

`puppet module install puppetlabs-mysql`

Agora que este modulo esta instalado no _modulepath_ do _Puppet Master_, todas suas classes ficam disponiveis para classificarmos os _nodes_.

### Tarefa 2

Editar o `site.pp` para classificar a VM de aprendizagem como uma classe MySQL.

`vim /etc/puppetlabs/code/environments/production/manifests/site.pp`

Se voce completou a quest do NTP, ja tem uma entrada para o certname `learning.puppetlabs.vm`, do contrario crie agora:

```
  node 'learning.puppetlabs.vm' {

  }
```

Dentro desse bloco de no, podemos declarar nossa classe `::mysql::server` e definir seus parametros. Para esse exemplo vamos definir a senha de `root` e definir o maximo de conexoes com o servidor como 1024. 

__Dica:__ altere o `vimrc` utilizado anteriormente para incluir `set paste` e garantir que o _vim_ nao quebre a formatacao ao colar hashes aninhados.

```
  node 'learning.puppetlabs.vm' {
    class { '::mysql::server':
      root_password    => 'strongpassword',
      override_options => {
        'mysqld' => { 'max_connections' => '1024' }
      },
    }
  }
```

Nao apenas opcoes padrao como `root_password`, a classe aceita `override_options` como um hash, que voce pode utilizar para qualquer configuracao que voce normalmente faria no arquivo `/etc/my.cnf`. Ao utilizar um hash permite a gestao dessas configuracoes sem requerer que fossem escritas na classe como parametros distintos. Essa estrutura e analoga a sintaxe de `[section] , var_name = value` de um arquivo `my.cnf`

### Tarefa 3

Utilize a ferramenta `puppet parser validade` para verificar sua sintaxe, entao dispare uma execucao:

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

Alem de instalar e configurar um banco MySQL, o modulo `puppetlabs-mysql` inclui diversas outras classes para ajudar a gerir outros aspectos da sua implementacao MySQL.

Essas classes estao organizadas em uma estrutura diretorios de modulo que combina com a sintaxe de escopo do Puppet. Escopo ajuda a organizar as classes, dizendo ao Puppet onde olhar na estrutura de diretorios de modulo para encontrar cada classe. O escopo tambem ajuda a separar os _namespaces_ dentro dos modulos e nos manifestos Puppet, prevenindo o conflito entre classes e variaveis com o mesmo nome.

De uma olhada nos diretorios e manifestos dentro do modulo MySQL (utilize um filtro do `tree` para exibir apenas arquivos de manifesto):

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

Note o arquivo `server.pp` no topo do diretorio `mysql/manifests`. Baseado nesse nome de classe em escopo, o Puppet consegue encontrar o manifesto chamado `server.pp` no diretorio de manifestos do modulo MySQL.

Entao, `mysql::server` significa:

`/etc/puppetlabs/code/environments/production/modules/mysql/manifests/server.pp`

Para levar o exemplo um nivel abaixo, `mysql::server::account_security` e o mesmo que:

`/etc/puppetlabs/code/environments/production/modules/mysql/manifests/server/account_security.pp`

## Seguranca da Conta

Por razoes de seguranca voce vai querer remover os usuarios padrao e as bases de teste de uma instalacao MySQL. A classe `accoount_security` faz justamente isso.

### Tarefa 4

Volte ao manifesto `site.pp` e inclua a classe `::mysql::server::account_security` no node `learning.puppetlabs.vm` apos a declaracao `::mysql::server`. Como voce nao precisa passar parametros a essa classe, um simples _include_ sera suficiente.

```
  # node 'learning.puppetlabs.vm' {
    ...
    include ::mysql::server::account_security
    ...
  }
```

Valide seu `site.pp`

`puppet parser validate /etc/puppetlabs/code/environments/production/manifests/site.pp`

Dispare uma execucao do puppet apos validar:

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

Voce comecara a visualizar avisos de que a base de teste e dois usuarios padroes foram removidos.

__Nota:__ nenhuma ferramenta de automatizacao substitui os requisitos de seguranca de seu sistema.

## Tipos e provedores

O modulo de MySQL do Puppet contem tipos e provedores customizados que permitem a gestao de itens criticos ao MySQL como recursos via DSL, da mesma maneira que voce faria com um usuario de sistema ou servico.

Um __tipo__ define a interface para um recurso: um conjunto de propriedades que descrevem o estado desejado para um recurso e parametros que nao necessariamente correspondem a coisas no sistema, mas dizem ao Puppet como gerenciar o recurso. Tanto as propriedades como os parametros aparecem na sintaxe de declaracao de recursos como um par de valores de atributo.

O __provedor__ levanta o peso para manter o sistema em linha com o estado definido numa declaracao de recurso. Sao implementados em uma variedade de sistemas operacionais. Sao essenciais a camada de abstracao de recursos (RAL), traduzindo a interface universal definida pelo __tipo__ em uma implementacao especifica do sistema.

O modulo MySQL inclui tipos e provedores customizados que fazem com que `mysql_user`, `mysql_database` e `mysql_grant` fiquem disponiveis como recursos.

## Base de dados, usuario, permissao

### Tarefa 5

Esses tipos de recurso customizados permitem gerenciar uma base de dados nova com apenas algumas linhas de codigo.

Adicione declaracao de recurso a definicao do no `learning.puppetlabs.vm` no seu manifesto `site.pp`

```
  node 'learning.puppetlabs.vm' {
    mysql_database { 'lvm':
        ensure  => present,
        charset => 'utf8',
    }
    ...
  }
```

De maneira similar, com um usuario voce apenas precisa especificar o nome e o host como titulo, alem de declarar o atributo `ensure` como `present`. Insira o seguinte:

```
  node 'learning.puppetlabs.vm' {
    mysql_user { 'lvm_user@localhost':
      ensure => present,
    }
    ...
  }
```

Agora que voce tem um usuario e um banco, pode utilizar o grant para definir privilegios para esse usuario. Note que o caracter `*` ira combinar com qualquer tabela. Logo, `table => lvm.*` abaixo significa que o usuario `lvm_user` tem TODAS as permissoes para todas as tabelas da base `lvm`.

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


Utilize a ferramenta `puppet parser validate` no manifesto `site.pp` para verificar a sintaxe desses tres recursos inseridos.

`puppet parser validate /etc/puppetlabs/code/environments/production/modules/manifests/site.pp`

Quando o codigo estiver bonito, dispare uma execucao.

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

# Variaveis e Parametros

Pelas quests de NTP e MySQL voce ja viu como parametros de classe possibilitam que voce ajuste as classes de um modulo de acordo com sua necessidade. Nessa quest, o objetivo e vermos como integrar variaveis em suas classes e faze-las acessiveis via parametros.

Para isso, voce vai escrever um modulo que gerencia um site de HTML estatico. Primeiro criara uma classe web com declaracoes de recurso _file_ para gerenciar seus documentos HTML. Ao atribuir valores repetidos como caminhos de arquivo a variaveis, sua classe sera mais concisa e facil de refatorar depois. Uma vez que essa estrutura basica da classe esteja concluida, adicionara parametros. Isso permitira que se definam os valores das variaveis de sua classe a medida que a declara.

## Variaveis

No Puppet, variaveis sao prefixadas por um `$` e atribui-se valor a elas com `=`. Por exemplo, para atribuir uma _string_ a uma variavel, fazemos:

`$minhavariavel = 'olhe, uma string'`

Uma vez definida, voce pode utilizar a variavel em qualquer lugar em que poderia utilizar o valor atribuido.

O basico sobre variaveis parecera familiar se voce ja conhece qualquer outra linguagem de script, no entanto ha algumas advertencias sobre a utilizacao de variaveis no Puppet:

* Diferente da declaracao de recursos, atribuicoes de variaveis sao dependentes da ordem de _parse_. Ou seja, voce deve atribuir em seu manifesto antes de utilizar.
* Se voce tentar utilizar uma variavel nao definida, o parser do Puppet nao ira reclamar. Ao inves disso ira tratar a variavel como contendo o valor especial `undef`. Apesar de que isso deve causar erros de compilacao mais adiante, em algumas situacoes o processo pode concluir e causar resultados inesperados
* Voce pode atribuir uma variavel apenas uma vez em um escopo. Uma vez atribuida, seu valor nao pode ser alterado. O valor de uma variavel pode alterar-se entre sistemas diferentes, mas nao dentro deles.

### Interpolacao de variaveis

A interpolacao permite que voce utilize o valor de uma variavel em uma _string_. Por acaso, se voce quisesse que o Puppet gerenciasse varios arquivos dentro do diretorio `/var/www/quest`, voce poderia ter atribuido esse caminho de diretorio a uma variavel:

`$doc_root = '/var/www/quest'`

Uma vez definida, voce nao precisa mais repetir o caminho inserindo a variavel `$doc_root` no inicio de qualquer _string_.

Por exemplo, voce pode utilizar no titulo da declaracao de alguns recursos _file_:

```
  file { "${doc_root}/index.html":
    ...
  }
  file { "${doc_root}/about.html":
    ...
  }
```

Note a sintaxe diferente aqui, o nome da variavel e envolto entre chaves (`{ }`) e tudo isso precedido pelo `$` (`${nome_da_variavel}`). Perceba tambem que uma _string_ que inclui uma variavel interpolada deve estar envolta entre aspas duplas `"..."` ao inves das simples que utilizamos em _strings_ comuns. Tais aspas sinalizam ao Puppet que ele deve encontrar e analisar sintaxe dentro da _string_ e nao apenas interpreta-la como literal.

## Gerenciando conteudo Web com variaveis

Pra entender melhor como trabalhar com variaveis nesse contexto, te guiaremos atraves da criacao de um modulo `web` que colocara isso em pratica.

### Tarefa 1

Primeiro, voce vai precisar da estrutura de diretorio do seu modulo.

Confira que voce esta no diretorio `modules` do seu _modulepath_:

`cd /etc/puppetlabs/code/environments/production/modules/`

Agora crie um diretorio `web` e seus diretorios `manifests` e `examples`:

`mkdir -p web/{manifests,examples}`

### Tarefa 2

Com essa estrutura no lugar, voce ja pode comecar a criar seu manifesto principal onde voce define sua classe `web`.

`vim web/manifests/init.pp`

E adicione o seguinte conteudo (lembre-se do `:set paste`, caso nao tenha ajustado seu `.vimrc` automaticamente)

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

Note que se voce quisesse alterar o valor do `$doc_root` so precisaria faze-lo em um lugar. Apesar de existirem formas mais avancadas de separacao de dados no Puppet o principio e o mesmo: quanto mais separado for seu codigo dos dados abaixo dele, mais reutilizavel ele e, e mais facil de refatorar quando voce precisar altera-lo no futuro.

### Tarefa 3

Uma vez que voce validou seu manifesto com a ferramenta `puppet parser`, voce ainda precisa criar um teste pro seu manifesto com uma declaracao `include` para a classe que voce criou (vimos isso na quest Modulos).

Crie um arquivo de manifesto `web/examples/init.pp` e insira `include web`. Salve e saia.

### Tarefa 4

Aplique o teste recem criado com a _flag_ `--noop`

```
  #puppet apply --noop web/examples/init.pp

  Notice: Compiled catalog for learning.puppetlabs.vm in environment production in 0.16 seconds
  Notice: /Stage[main]/Web/File[/var/www/quest/hello.html]/ensure: current_value absent, should be file (noop)
  Notice: /Stage[main]/Web/File[/var/www/quest/bonjour.html]/ensure: current_value absent, should be file (noop)
  Notice: Class[Web]: Would have triggered 'refresh' from 2 events
  Notice: Stage[main]: Would have triggered 'refresh' from 1 events
  Notice: Applied catalog in 0.67 seconds
```

Se sua execucao enxuta parecer Ok, execute o `puppet apply` sem a _flag_. De uma olhada em `http://<IP DA VM>/hello.html` e `http://<IP DA VM>/bonjour.html` para conferir suas paginas novas.

## Parametros de Classe

Agora que temos uma classe `web` basica, vamos abordar os parametros de classe. Eles te fornecem uma maneira de atribuir as variaveis de uma classe __enquanto ela e declarada__ ao inves de ter isso _hardcoded_ durante a definicao da classe.

Ao definir uma classe, inclua uma lista de parametros e valores padroes opcionais entre o nome da classe e o inicio do bloco de classe.

```
  class classname ( $parameter = 'default' ) {
    ...
  }
```

Uma vez definida, uma classe parametrizada pode ser __declarada__ como uma sintaxe similar a de declaracao de recursos, incluindo par-valor de cada parametro que voce quer definir.


```
  class {'classname':
    parameter => 'value',
  }
```

Entao se voce quer implementar paginas em servidores ao redor do mundo, com conteudo dependente do idioma da regiao. Ao inves de reescrever toda uma classe ou modulo por regiao, voce pode utilizar parametos de classe para customizar esses valores enquanto a classe e declarada.

### Tarefa 5

Para comecarmos a reescrever nossa classe `web` com parametros, reabra o manifesto `web/manifests/init.pp`. Para criar uma nova pagina regionalizada, voce devera ser capaz de definir a mensagem e o nome da pagina via parametros de classe.

`class web ( $page_name, $message ) {`

Agora crie uma terceira declaracao de recurso _file_ que utilize as variaveis dos seus parametros

```
  file { "${doc_root}/${page_name}.html":
     ensure  => file,
     content => "<em>${message}</em>",
   }
```

### Tarefa 6

Assim como antes, use o manifesto de teste para declarar a classe. Voce ira abrir o manifesto `web/examples/init.pp` e substituir o `include` simples por uma sintaxe de declaracao de classe parametrizada que define cada um dos parametros (basicamente, a SDL do Puppet =P)

```
  class {'web':
    page_name => 'hola',
    message => 'hola mundo',
  }
```

### Tarefa 7

Agora faca um teste, execute uma vez com `--noop` e entao aplique o teste. A nova pagina deve estar disponivel em `http://<IP DA VM>/hola.html`


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

__Importante:__ lembre-se que classes no Puppet sao singletons, entao so podem ser aplicadas uma vez por node (no nosso exemplo so seria possivel ter uma pagina espeficada por parametros alem das duas outras ja existentes). Caso voce deseje repetir o mesmo recurso ou grupo deles __em um mesmo no__, podemos utilizar o conceito de _tipo de recurso definido_, que veremos em uma proxima quest.

# Declaracoes condicionais

## Escrevendo pela flexibilidade

Codigo excelente == codigo flexivel e portavel. Apesar dos tipos e provedores que sao o _code_ do __RAL__ do Puppet fazerem a maior parte do trabalho pesado nessas adaptacoes, ha varias coisas que sao melhores nas maos de usuarios competentes.

E sensato que os provedores do Puppet `package` tomem conta de instalar e manter pacotes. As entradas e saidas sao padronizadas e estaveis o suficiente pra, seja la o que acontecer entre isso, desde que aconteca de maneira confiavel, esta livre pra ser escondido pela abstracao. Uma fez feito, os detalhes deixam de ser importantes. 

__AJUDA CHRIS!:__ Oi, entao a ideia acima eh o seguinte: quem implementou e prove o `package` esta livre para implementar da maneira que quiser, desde que sua entrega seja confiavel entre o _input_ ou entrada e o _output_ ou saida. Os fins justificam os meios na maneira Puppet de se pensar.

_Qual_ pacote esta instalado, por outro lado, nao e algo que voce simplesmente esquece. Nesse caso, os _inputs_ e _outputs_ nao estao tao bem definidos assim. apesar de que existam pacotes equivalentes entre as muitas plataformas por ai, __a equivalencia nunca e completa__; detalhes de configuracao vao variar, e esses detalhes vao precisar ser levados em conta em algum lugar do seu modulo Puppet.

Mas mesmo o os provedores _built-in_ do Puppet nao sendo capazes de garantir a portabilidade do seu codigo Puppet nesse nivel tao alto de abstracao, a DSL do Puppet te da as __ferramentas para contruir *adaptabilidade*__ nos seus modulos. __Fatos__ e __declaracoes condicionais__ sao o arroz feijao dessa funcionalidade.

## Fatos
## Condicoes
### If
### Tarefa 1

Crie um diretorio `accounts` e seus diretorios `manifests` e `examples`:


`mkdir -p accounts/{manifests,examples}`

### Tarefa 2

Abra o manifesto `accounts/manifests/init.pp` no Vim. No inicio da sua definicao de classe de `accounts`, voce ira incluir logica condicional para atribuir a variavel `$groups` baseada no valor do fato `::operatingsystem`. Se o SO for CentOS, o Puppet ira adicionar o usuario ao grupo `wheel`, se for Debian ira adicionar ao grupo `admin`.

O inicio da sua definicao de classe deveria se parecer com isso aqui:

```
  class accounts ($user_name) {

    if $::operatingsystem == 'centos' {
      $groups = 'whell'
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

Note que esses _matches_ de strings __nao__ sao _case-sensitive_, entao 'CENTOS' tambem funcionaria. Pra finalizar, no bloco `else`, voce vai sinalizar um erro caso o modulo nao suporte o SO.

Com a logica para o grupo (`$groups`) finalizada, crie uma declaracao de recurso `user`. Utilize a variavel `$user_name` definida pelo seu parametro de classe pra atribuir o home e o titulo do usuario, e use a variavel `$groups` para definir o atributo `groups`

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

Pra garantir, que tal seu codigo passar em um `puppet parser validate` antes de continuar? :D

### Tarefa 3

Crie um manifesto de teste `accounts/example/init.pp` e declare o manifesto de contas, com o parametro de nome definido como `dana`.

```
  class {'accounts':
    user_name => 'dana',
  }
```

### Tarefa 4
### Tarefa 5
### Tarefa 6

Agora va em frente e execute um `puppet apply --noop` no seu manifesto de teste antes de definir a variavel de ambiente. Se parecer bom, dispense a _flag_ `--noop` para aplicar o catalogo gerado pelo seu manifesto.

Voce pode usar a ferramenta `puppet resource` para validar os resultados.

### Unless

A declaracao `unless` funciona como o inverso de um `if`. O `unless` recebe uma condicao e um bloco de codigo Puppet. So ira executar __se__ a condicao for __falsa__. Se a condicao for verdadeira, o Puppet nao fara nada e seguira. Nao existe um equivalente de clausulas `elsif` ou `else` para declaracoes `unless`.

### Case

Declaracoes condicionais permitem que voce escreva codigo que retorne valores diferentes ou execute blocos diferentes de codigo dependendo do que voce especificar. Junto ao `Facter`, que disponibiliza os detalhes de uma maquina como _variaveis_, permite que voce escreva um codigo que acomode flexivelmente diferentes plataformas, sistemas operacionais e requisitos funcionais.

### Selector


# Ordenacao de recursos


## Ordem de recurso
### Tarefa 1
### Tarefa 2
### Tarefa 3
### Tarefa 4
### Tarefa 5
### Tarefa 6
### Tarefa 7
### Tarefa 8
### Tarefa 9
## Encadeamento de setas (chaining arrows)
## Autorequires

# Tipos de recurso definidos
## Tipos de recurso definidos
### Tarefa 1
### Tarefa 2
### Tarefa 3
### Tarefa 4
### Paginas HTML publicas
### Tarefa 5
### Tarefa 6
### Parametros
### Tarefa 7
### Tarefa 8
### Tarefa 9

# Instalacao de Agente de no
## Consiga alguns nos
### Conteineres
### Tarefa 1
### Tarefa 2
### Instale o agente do Puppet
### Tarefa 3
### Tarefa 4
### Tarefa 5
### Certificados
### Tarefa 6
### Tarefa 7

# Orquestrador de aplicacao
# O Orquestrador de aplicacao
### Configuracao de no
### Tarefa 1
### Tarefa 2
### Configuracao Master
### Configuracao do client e permissoes
### Tarefa 3
### Token do client
### Tarefa 4
## Aplicacoes Puppetizadas
### Tarefa 6
### Tarefa 7
### Tarefa 8
### Tarefa 9
### Tarefa 10
### Tarefa 11



