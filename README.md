
# Intuito desse repositorio

Comecei a estudar puppet e me encantei pelas possibilidades que se abriram. Como o material da VM de aprendizagem esta em ingles, resolvi compartilhar todas minhas notas e demais itens que forem criados no processo de estudo da mesma. As notas estarao divididas pelas buscas (quests) do material oficial, todo e qualquer artefato estara dividido nessa mesma hierarquia. Alguns termos eu realmente preferi manter no original e citar sua traducao apenas uma vez - como no caso das _quests_, quando for assim manterei a palavra em italico.

Para acompanhar as notas, utilize o _Quest Guide_ e a VM contidas no _.zip_ disponivel via: https://puppet.com/download-learning-vm


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

