# Solução de problemas

[Índice](../README_PT-BR.md)

## Por onde começar

Se o backup não começou ou terminou com um erro, verifique os logs primeiro. `main.log` contém os estágios gerais da execução, enquanto os detalhes de backup de um determinado dispositivo são gravados no seu log de dispositivo separado.

Procure entradas marcadas com `[ER]` e um código de erro. Os códigos são explicados [abaixo](#result-codes), e os locais dos logs são descritos em [LOGGING.md](LOGGING.md).

Use estes comandos para exibir a versão instalada do script e a referência das opções:

```bash
mikrotik-backup.sh --version
mikrotik-backup.sh --help
```

Para repetir uma execução em lote já configurada com saída detalhada:

```bash
mikrotik-backup.sh --log-level=3
printf 'Exit code: %s\n' "$?"
```

O segundo comando mostra o resultado da execução completada. Não altera o nível de registro em `option.cfg`.

<br />

## O script não inicia um backup

### O editor foi aberto em vez de um backup

Quando o script é iniciado sem opções, isso significa que `option.cfg` não existe na pasta do script ou não contém configurações utilizáveis. Um arquivo vazio, que contenha somente comentários ou apenas parâmetros desconhecidos ou inválidos não altera o resultado.

Abra o Editor de Configuração, escolha as configurações necessárias, salve o arquivo e execute o script novamente:

```bash
mikrotik-backup.sh -e
```

Salvar um dispositivo por meio do BackUP Master cria `devicelist.cfg`, mas não substitui a preparação de `option.cfg`.

*(N.B. Se tal execução for iniciada por um agendador, o editor não poderá abrir e o script sairá com o código `31`. As configurações para uma execução automática devem ser preparadas com antecedência.)*

### Erro de opção, código 12

Verifique os nomes das opções, os seus valores e a combinação de ações. As causas possíveis incluem uma opção desconhecida, um valor vazio, várias ações diferentes solicitadas de uma só vez ou credenciais incompletas para uma conexão de um único dispositivo.

Uma execução de um dispositivo único pela CLI requer um endereço, login e senha. As credenciais ausentes não são preenchidas a partir de `option.cfg`.

As opções de conexão curtas devem usar `=`: `-a=`, `-u=` e `-p=`. Lembre-se que `-p` especifica a senha; use `--port` para a porta SSH.

Todas as opções aceitas e os exemplos estão listados em [CLI.md](CLI.md).

### option.cfg não pode ser lido, código 21

Certifique-se de que `option.cfg` seja um arquivo comum e legível pelo usuário que executa o script. Também é permitido um link simbólico legível para esse arquivo.

Um arquivo ausente e um arquivo ilegível são situações diferentes. Se o arquivo existir mas não puder ser lido, o script não continua com as configurações padrão.

### Falta a dependência, código 30

Verifique os principais utilitários com:

```bash
command -v ssh scp sshpass timeout sleep sha256sum realpath flock
```

A operação em lote com `UseNetFolder=true` também requer `findmnt`. No dia do arquivamento mensal, `zip`, `unzip` e GNU `mv` são necessários. Copiar um comando de console de BackUP Master requer GNU `base64` com suporte `--wrap=0`.

**Ter apenas um utilitário instalado não é suficiente.** O OpenSSH instalado deve suportar as opções em uso e `scp -O`; GNU `timeout` deve suportar `--signal` e `--kill-after`.

A lista completa de dependências e os comandos de instalação estão em [INSTALL.md](INSTALL.md#dependências).

### O menu não abre, código 31

O menu, o editor e o BackUP Master exigem um terminal e o utilitário `stty` funcional. Não os inicie por meio de um pipe nem com a entrada ou a saída padrão redirecionada.

Se a mensagem informar que o terminal é muito pequeno, aumente a janela. As telas principais precisam ter pelo menos 46 colunas de largura, e as instruções integradas precisam de 80. As listas longas do editor e do BackUP Master rolam com as teclas de seta; o formulário inteiro não precisa caber de uma vez na tela.

Os controles de interface são descritos em [INTERACTIVE.md](INTERACTIVE.md).

<br />

## A lista de dispositivos não carrega

### O arquivo `devicelist.cfg`, códigos 22 e 23

Verifique o caminho do arquivo e o acesso a ele. `devicelist.cfg` deve estar ao lado de `mikrotik-backup.sh`, independentemente do diretório do qual você inicia o script.

Os campos são separados por um caractere TAB real, não por espaços. Um dispositivo deve ter um nome, endereço, login, senha e porta SSH válida. As credenciais compartilhadas podem vir de `option.cfg` quando os campos de entrada correspondentes estiverem vazios.

Um item inválido é ignorado com um aviso. Se não restarem dispositivos elegíveis, não há nada para fazer backup e o script sai com um erro de lista.

Verifique também se existem conexões duplicadas e diferentes dispositivos com o mesmo nome. O formato do arquivo, a herança de credencial e as regras de tratamento de duplicatas estão cobertos em [DEVICES.md](DEVICES.md).

### Importação do Oxidized, códigos 24 e 25

O código `24` significa que o arquivo `config` ou `router.db` em `OxidizedHome` não pôde ser lido. O código `25` diz respeito ao conteúdo: esquema incompatível, dados inválidos ou nenhum dispositivo MikroTik elegível.

Verifique o caminho, o acesso a ambos os arquivos, a fonte `csv`, o delimitador, o mapa de colunas e a definição do modelo `routeros`. Os dados são lidos especificamente de `<OxidizedHome>/router.db`; a configuração Oxidized `source.csv.file` não altera esse caminho.

Com `IgnoreOxiAccess=true`, o script poderá continuar com a lista elegível anterior. A falha de importação permanece no resultado da execução. Com `false`, a lista antiga não é usada para essa execução.

A configuração de importação está descrita em [DEVICES.md](DEVICES.md#importação-do-oxidized).

<br />

## Armazenamento e bloqueio

### O bloqueio está ocupado, código 32

Verifique se outra tarefa já está usando o mesmo diretório de backup. Para as execuções do mesmo usuário, um backup em lote entra em conflito com qualquer outro backup que use o mesmo `BackupRoot`. Duas execuções de dispositivo único para o mesmo dispositivo também não podem ser executadas simultaneamente nesse armazenamento.

Espere o trabalho ativo terminar e então execute o script novamente.

**Não exclua os arquivos de bloqueio para “liberar” o armazenamento.** Eles permanecem após o script terminar; o processo em si mantém o bloqueio. A presença de um arquivo em `/tmp/mikrotik-backup-${UID}/` não significa que o bloqueio esteja ocupado.

### Sem acesso ao diretório

Verifique o caminho `BackupRoot`, as permissões do usuário, o espaço livre e a disponibilidade do próprio dispositivo de armazenamento. Um caminho relativo é resolvido a partir da pasta do script. O diretório raiz do sistema de arquivos, `/`, não pode ser usado para armazenar backups.

Se o script foi executado anteriormente como root e agora é executado como **bsmt**, esse usuário pode não ter acesso às pastas e arquivos antigos. A preparação de permissão está coberta em [INSTALL.md](INSTALL.md#executando-o-script-automaticamente).

A operação em lote com `UseNetFolder=true` requer uma montagem separada. Verifique-a com:

```bash
findmnt -T /mnt/backup/mikrotik
findmnt -T /
```

Substitua o primeiro caminho pelo seu próprio. Se ambos os caminhos pertencem ao mesmo item de montagem, uma pasta normal no sistema de arquivos raiz não satisfaz `UseNetFolder=true`. O script não monta o armazenamento em si.

O código `64` indica uma falha no diretório ou arquivo do dispositivo enquanto o armazenamento compartilhado permaneceu disponível. O processamento de outros dispositivos pode continuar. O código `65` significa que o armazenamento compartilhado foi perdido ou seu estado se tornou inválido, e interrompe o restante do lote.

As regras de armazenamento de rede são descritas em [OPTIONS.md](OPTIONS.md#network-storage).

<br />

## Erros ao trabalhar com um dispositivo

### SSH e transferência de arquivos, códigos 40–43

Verifique o endereço do dispositivo, a disponibilidade do serviço SSH, o login, a senha e a porta. Se nenhuma porta for indicada em `devicelist.cfg`, o valor `SshPort` das configurações será usado; seu padrão é `22`.

O usuário RouterOS deve ter permissão para as operações selecionadas: exportar configuração, criar e recuperar backups, excluir arquivos temporários e realizar qualquer operação de limpeza habilitada.

**E existe uma nuance aqui!!!** Uma conexão bem-sucedida com seu comando SSH habitual não significa que o script use as mesmas configurações. Ele usa uma senha e não usa o agente SSH, chaves nem o `~/.ssh/config` normal. Os arquivos são obtidos por meio de `scp -O`.

O código `40` diz respeito à conexão ou transporte SSH/SCP, o `41` à autenticação, o `42` a um comando do RouterOS ou a sua resposta, e o `43` à transferência de arquivos. As configurações de conexão são explicadas em [SECURITY.md](SECURITY.md#conexão-com-o-routeros).

### Erro de nome, códigos 50 e 52

O código `50` significa que o nome do dispositivo final é inválido. Verifique a fonte do nome selecionado e o conteúdo dos parênteses: na versão atual, o primeiro fragmento completo e não vazio entre parênteses é o que é usado como nome.

Após o processamento, o nome deve conter entre 1 e 32 caracteres. Um nome longo não é truncado. Nomes reservados como `CON` e `NUL` também são rejeitados.

O código `52` significa que o nome final duplica outro dispositivo na mesma execução. A comparação é sem distinguir maiúsculas de minúsculas: `Router-A` e `router-a` são considerados idênticos.

A fonte de nome e as regras de processamento são descritas em [DEVICES.md](DEVICES.md#nomes-dos-dispositivos).

### A validação do backup falhou, códigos 51 e 53

O código `51` aplica-se a `.rsc` e o código `53` a `.backup`. A validação do arquivo obtido falhou — por exemplo, ele está vazio ou o seu tamanho não corresponde ao arquivo no dispositivo.

Verifique o estágio em que o erro ocorreu, além do espaço livre e das permissões no host e no RouterOS. Após uma tentativa com falha, o script tenta mais uma vez depois de 2 segundos. As tentativas são separadas para os dois formatos, de modo que um arquivo pode ser obtido com sucesso enquanto o outro falha.

Um aviso sobre a falha de excluir um arquivo temporário RouterOS após um backup ser recuperado com sucesso não significa que o backup local esteja danificado.

<br />

## Não há nenhum backup novo, mas não há erros também

Primeiro, verifique `UseIncremental`. Quando a comparação estiver ativa, um novo backup poderá ser removido como duplicado enquanto o anterior permanece. Para `.rsc`, os conteúdos são comparados sem a data no cabeçalho padrão; para `.backup`, apenas os tamanhos dos arquivos são comparados.

Com `UseIncremental=false`, um novo backup válido é mantido sem esta comparação.

Lembre-se também de que duas execuções do mesmo dispositivo na mesma pasta dentro de um minuto usam o mesmo nome de arquivo. Uma versão separada não é criada para a segunda execução.

Se o arquivamento mensal foi executado nesse dia, verifique também o ZIP. No modo de dispositivo único pela CLI, o novo backup também pode estar dentro dele. Veja [BACKUPS.md](BACKUPS.md).

<br />

<a id="archive-problems"> </a>
## O arquivo mensal não apareceu

Verifique o valor `MonthlyArchive` e a data de execução na hora local do host. `false` desativa o arquivamento; `true` ou `1` seleciona o primeiro dia, enquanto um número de `2` até `28` seleciona esse dia do mês.

No dia selecionado, o tempo de execução não importa. Se esse dia for perdido, uma execução comum posterior não recupera a tentativa perdida. O arquivamento mensal não é realizado através de BackUP Master.

Se não houver nada para arquivar, não é criado nenhum ZIP vazio.

### Onde encontrar o ZIP

O nome do arquivo corresponde ao dia anterior do calendário. Por exemplo, uma execução em 1 de outubro de 2026 cria `30.09.2026.zip`:

| Modo | Caminho |
|---|---|
| Lote | `<BackupRoot>/<DeviceName>/archive/30.09.2026.zip` |
| Dispositivo único pela CLI | `<BackupRoot>/30.09.2026.zip` |

O nome do diretório `archive/` usa letras minúsculas. Outra execução no mesmo dia atualiza o mesmo ZIP.

### O arquivamento terminou com um erro

Para os códigos `70` e `71`, verifique o log do dispositivo, o acesso ao diretório de arquivamento, o espaço livre e o estado de qualquer ZIP existente. É necessário espaço tanto no armazenamento quanto no diretório local `/tmp`.

Num disco local, o diretório `archive/` deve pertencer ao usuário do script e ter o modo `0700`. No modo em lote com armazenamento de rede verificado e `UseNetFolder=true`, um proprietário ou permissões diferentes atribuídas pelo NAS não são, por si só, uma razão para falha. Os erros de armazenamento durante o arquivamento podem também produzir código `64` ou `65`.

Verifique um arquivo existente com o seguinte comando, substituindo seu caminho real:

```bash
unzip -t "/mnt/backup/mikrotik/Router-A/archive/30.09.2026.zip"
```

Os arquivos de origem não são removidos até que um ZIP verificado seja salvo. Se o ZIP for salvo, mas alguns arquivos de origem não puderem ser removidos, tanto o ZIP como os arquivos não apagados permanecem. Um ZIP existente danificado não é automaticamente substituído por um novo.

**Não exclua os backups ou os registros restantes até que tenha verificado o conteúdo do arquivo.** A sequência de arquivamento está descrita em [BACKUPS.md](BACKUPS.md#monthly-archive).

<br />

## Não há logs nem saída na tela

Com `LogLevel=0` e sem erros, não são criados novos logs. Caso contrário, verifique os valores selecionados de `BackupRoot` e `MainLogPath`, além das permissões de gravação.

Um `MainLogPath=` vazio deixa `main.log` em `BackupRoot`. Se for indicada uma pasta separada, ela já deverá existir e ser acessível ao usuário do script. Os registros dos dispositivos não são movidos por esta opção.

Após arquivamento mensal, o histórico anterior do dispositivo está no ZIP. O trabalho posterior é escrito para um novo log ao lado dos backups.

Quando o script é executado por um agendador ou com sua saída redirecionada, o log na tela com seu indicador e marcas coloridas está ausente. O registro em arquivos continua no nível selecionado.

Um erro de escrita de log não para o backup em si, mas aparece no resultado da execução como um aviso. Veja [LOGGING.md](LOGGING.md) para mais detalhes.

<br />

<a id="language-problems"> </a>
## Não foi aplicada uma tradução

Verifique o idioma selecionado e o caminho do arquivo. Por exemplo, `Language=de` exige um arquivo comum legível chamado `de.lang` ao lado de `mikrotik-backup.sh`, e não no diretório `lang/`. Um link simbólico não é usado como arquivo de tradução.

Com `Language=auto`, o ambiente do sistema operacional determina o idioma. Você pode selecioná-lo explicitamente para uma execução, por exemplo, ao visualizar a ajuda:

```bash
mikrotik-backup.sh --language=de --help
```

As mensagens não traduzidas são mostradas em inglês. As linhas malformadas do arquivo são ignoradas. Os arquivos chamados `ru.lang` e `en.lang` não substituem as traduções integradas.

O formato de linha, nomes de chave e regras para carregar uma tradução são descritos em [LOCALIZATION.md](LOCALIZATION.md).

<br />

## Uma configuração não surte efeito

Verifique o nome da configuração, o valor aceito e os itens duplicados em `option.cfg`. Quando uma configuração é repetida, prevalece o último valor utilizável. Os nomes das chaves não diferenciam maiúsculas de minúsculas, mas hífens e sublinhados não são intercambiáveis.

Uma opção CLI substitui o valor correspondente do arquivo. Para as operações simples e em lote normais, a ordem é:

**Valores internos** → **linhas válidas de `option.cfg`** → **CLI**

O BackUP Master preenche o formulário de forma diferente: os campos comuns vêm dos valores internos e da CLI, não do arquivo de opções. `UseIncremental` é a exceção. As configurações de log do arquivo também são respeitadas quando um backup é executado pelo BackUP Master.

As regras de leitura das configurações estão em [OPTIONS.md](OPTIONS.md), e o comportamento do BackUP Master é explicado em [INTERACTIVE.md](INTERACTIVE.md).

<br />

<a id="result-codes"> </a>
## Códigos dos resultados

| Código | Significado |
|---:|---|
| `0` | Sucesso sem erros ou avisos registrados |
| `1` | Concluído com avisos e sem erro de execução gravado |
| `12` | Erro nas opções CLI, seus valores ou sua combinação |
| `21` | Não foi possível ler `option.cfg` |
| `22` | Não foi possível obter a lista de dispositivos |
| `23` | Lista de dispositivos inválida ou nenhum item elegível |
| `24` | Não foi possível ler os arquivos do Oxidized |
| `25` | Esquema incompatível ou dados Oxidized inválidos; nenhum item MikroTik elegível |
| `30` | Falta um utilitário necessário ou ele não oferece os recursos exigidos |
| `31` | Terminal indisponível, erro `stty` ou tamanho insuficiente da janela |
| `32` | O bloqueio requerido é mantido por outra execução |
| `33` | Caminho ou objeto de armazenamento inválido para uma execução de um único dispositivo |
| `34` | Não foi possível criar ou preparar o diretório de execução de um único dispositivo |
| `35` | Erro ao acessar ou validar um objeto de serviço local, incluindo um bloqueio |
| `36` | O armazenamento de uma execução de dispositivo único falhou na verificação de disponibilidade antes da obtenção dos arquivos |
| `37` | Não foi possível gravar ou substituir um arquivo de serviço |
| `40` | Erro de conexão ou transporte SSH/SCP |
| `41` | Erro de autenticação do dispositivo |
| `42` | Erro em um comando do RouterOS ou na resposta esperada |
| `43` | Erro na transferência de arquivos por SCP |
| `50` | Nome do dispositivo final inválido |
| `51` | Falha na validação do arquivo `.rsc` |
| `52` | Nomes finais duplicados dos dispositivos |
| `53` | Falha na validação do arquivo `.backup` |
| `61` | Armazenamento compartilhado não disponível enquanto prepara uma execução em lote |
| `62` | Não foi possível confirmar ou ativar uma montagem separada para `UseNetFolder=true` |
| `63` | Erro ao preparar ou validar o diretório de backup de lote compartilhado |
| `64` | Erro de armazenamento de dispositivo ou arquivo enquanto o armazenamento compartilhado permanece disponível |
| `65` | O armazenamento compartilhado foi perdido ou tornou-se inválido durante a execução; o processamento em lote é interrompido |
| `70` | Erro ao criar ou atualizar um arquivo |
| `71` | Falha na validação do ZIP ou do objeto de arquivo de destino |
| `80` | Erro interno ou requisito do sistema não cumprido, incluindo a capacidade `C.UTF-8` |
| `81` | Erro interno do controlador MikroTik |
| `129` | Terminado pelo sinal HUP |
| `130` | Terminado pelo sinal INT, por exemplo, pressionando Ctrl+C |
| `143` | Terminado pelo sinal TERM |

O código final reflete o primeiro erro de execução gravado. O aviso `1` é substituído pelo primeiro erro, e um sucesso posterior não o limpa. O código final, portanto, não corresponde necessariamente à última mensagem no log.

Se uma nova tentativa de obtenção do arquivo tiver sucesso, o estágio pode terminar com `[OK]`, mesmo que o erro da primeira tentativa permaneça no log. Um código final diferente de zero de uma execução em lote também não significa que cada dispositivo falhou: inspecione cada resultado separadamente.

Para o código `80`, preste atenção aos requisitos do sistema: GNU Bash 4.4 ou posterior e uma configuração regional `C.UTF-8` funcional. [INSTALL.md](INSTALL.md#requisitos-do-host).

<br />

## Se precisar de ajuda

Forneça a versão do script, o sistema operacional e a versão do Bash, como o script foi iniciado, o código de saída e o trecho relevante do log. Para um problema com um dispositivo, inclua o log desse dispositivo; para um erro ao preparar uma execução, comece com `main.log`.

**Não envie senhas reais ou arquivos completos de configuração de trabalho.** Antes de enviar logs, capturas de tela ou comandos, verifique se contêm dados confidenciais. [SECURITY.md](SECURITY.md).

Você pode contatar o autor usando os dados da [descrição do produto](../README_PT-BR.md#contato-com-o-autor).
