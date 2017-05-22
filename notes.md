

# Power of Puppet

Para buscar umm modulo:
    
    puppet module search graphite
    puppet module install dwerder-graphite -v 5.16.1
    	--module_repository=https://forge.puppet.com

* Para o puppet, classe e um bloco que serve para agrupar recursos
* Um modulo pode abrigar varias classes, mas geralmente vai ter uma classe main, com o mesmo nome do modulo (como no java)
    - geralmente responsavel por instalar/configurar o componente primario desse modulo
* class + node = classification
* node group: permite classificar nodes baseados no certname e nas informacoes coletadas via facter

    puppet agent -t

Utilizar para disparar atualizacao no Puppet

* O daemon de agente do puppet roda, por padrao, a cada 30min. Pede um catalogo ao master, parseia, gera um catalogo do node e devolve ao agente, o agente entao aplica qualquer change necessaria para estar up-to-date com o catalogo.

    puppet agent --test

Executa manualmente essa sincronia com master

# Resources



