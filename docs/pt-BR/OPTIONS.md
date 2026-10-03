# Configuração

[Índice](../README_PT-BR.md)

## Antes de começar

O arquivo opcional `option.cfg` permite alterar as configurações que o script usa por padrão.
Para o script carregar as configurações listadas neste arquivo durante a execução,
`option.cfg` deve estar próximo de `mikrotik-backup.sh` na mesma pasta.

A estrutura do arquivo é simples: uma lista de itens `Key=value`. Não é um script de shell.
Nenhuma expansão variável ou execução de comando ocorre nela.

## Quando uma configuração é utilizável para uma execução

Mesmo uma linha válida e reconhecida torna a configuração utilizável.
Você não precisa listar todas as configurações: se um valor padrão for adequado, essa opção não precisa aparecer em `option.cfg`.

Se o arquivo estiver vazio ou contiver apenas comentários, chaves desconhecidas ou valores inválidos, o script não tem nenhuma configuração para carregar.
As configurações então permanecem em seus padrões.

**E aqui está o detalhe!!!**
Se você executar o script sem argumentos nesse estado, não iniciará nenhum backup. Em vez disso, o script tentará abrir o Editor de Configuração.
A mesma coisa acontece quando `option.cfg` não existe.
Salve as configurações necessárias e execute o script novamente.
*(N.B. O editor necessita de um terminal. Se o script for executado sem um, por exemplo, por um agendador, ele sai com erro `31`.
Prepare `option.cfg` antes de configurar uma execução automática.)*

**Ordem em que os parâmetros opcionais são lidos:**
O script aplica as fontes de parâmetros na ordem de prioridade. Se `option.cfg` estiver ausente, ele usa os padrões internos do script.
Se o arquivo existir e for lido com sucesso, os parâmetros <mark>válidos</mark> que contém substituem os padrões correspondentes.

E o mais importante!!! Se o mesmo parâmetro for fornecido pela CLI, o valor da CLI tem precedência.
Para uma operação simples ou de lote normal, a prioridade é, portanto:
**Valores internos** → **Linhas válidas de `option.cfg`** → **CLI**

*(N.B. Um arquivo ausente não é o mesmo que um arquivo ilegível.
Se `option.cfg` existir mas o script não conseguir lê-lo, a execução termina com
erro de configuração `21`; não continua com os padrões.)*

## Como o arquivo é lido

Cada linha é dividida no primeiro `=`. Os nomes das chaves não diferenciam maiúsculas de minúsculas, mas hífens e sublinhados não são intercambiáveis.
Linhas em branco e linhas cujo primeiro caractere não-branco é `#` são ignoradas. Uma linha desconhecida ou inválida não invalida as linhas corretas vizinhas.
Quando uma chave aparece mais de uma vez, o último valor válido é usado.

Os espaços iniciais e finais são removidos dos valores comuns.
**Importante:** para `Login`, `Password` e `encrypt`, tudo depois do primeiro `=` é preservado literalmente.
Não adicione aspas para a sintaxe da shell: aspas tornam-se parte do valor.
Não coloque um comentário após uma senha. Use uma linha separada para o comentário.

Um BOM no início do arquivo e terminações de linha CRLF são suportados.
É permitido um link simbólico legível para um arquivo regular.
Um problema de acesso ou um tipo de objeto inadequado não é tratado como um arquivo vazio
e causa um erro de configuração.

## Criação, edição e salvamento de `option.cfg`

A maneira mais fácil de criar o arquivo é executar o script com `-e`:

```bash
./mikrotik-backup.sh -e
```

O Editor de Configuração abre e lista as opções principais.
Se nem todas as linhas couberem na janela do terminal, a lista rolará automaticamente à medida que você subir e descer com as setas.
Os itens **Salvar** e **Cancelar** estão no final da mesma lista.
Percorra o menu, informe as configurações necessárias → selecione **Salvar** → e o arquivo será criado.

Tenha em mente que, enquanto você trabalha no menu interativo, o editor muda as configurações apenas na memória.
Somente depois que você selecionar **Salvar** o editor gravará o arquivo *canônico* completo.

Se `option.cfg` ainda não existe, o editor preenche inicialmente seus campos com os valores padrão.
Se o arquivo já existe e você mudou alguns parâmetros, o Editor de Configuração preenche seus campos com seus valores em vez dos padrões.

A segunda maneira de criar `option.cfg` é manualmente. Sim: abra o seu editor de texto favorito manualmente e insira as configurações que você precisa.
Onde encontrar essas configurações?

## Configurações e padrões

| Chave | Padrão | Valor e finalidade |
|---|---|---|
| `Language` | `auto` | `auto` ou duas letras ASCII, tais como `ru`, `en` ou `de` |
| `SshPort` | `22` | Porta `1`–`65535`; escondida no editor, visível em BackUP Master |
| `UseOxidized` | `false` | Importar dispositivos de Oxidized |
| `IgnoreOxiAccess` | `true` | Permitir o DeviceList anterior após uma falha de leitura ou análise do Oxidized; somente no arquivo |
| `OxidizedHome` | Vazio | Diretório contendo `config` e `router.db` |
| `UseIdentityName` | `true` | Usar a identidade atual do RouterOS como nome do dispositivo |
| `backup_type` | `both` | `configuration`, `binary` ou `both` |
| `UseIncremental` | `true` | Compare um novo backup verificado com o anterior; com `false`, mantenha cada novo backup sem compará-lo |
| `export_format` | `compact` | `compact`, `terse` ou `verbose` |
| `show_sensitive` | `true` | Incluir valores sensíveis em `.rsc` |
| `encrypt` | Vazio | Senha usada para criptografar `.backup`; vazio significa que não há criptografia |
| `encrypt_type` | `aes-sha256` | Algoritmo fixo; somente no arquivo |
| `clear_dns_cache` | `true` | Limpar o cache DNS antes de um backup binário |
| `clear_console_history` | `true` | Limpar o histórico do shell antes de um backup binário |
| `BackupRoot` | `backups` | Diretório raiz para armazenamento de backup |
| `UseNetFolder` | `false` | Requer uma montagem separada em modo lote |
| `MonthlyArchive` | `false` | Desativar o arquivamento (`false`) ou definir um dia do mês de `1` a `28` |
| `LogLevel` | `2` | Nível `0`, `1`, `2` ou `3` |
| `MainLogPath` | Vazio | Pasta para `main.log` apenas; vazio significa a `BackupRoot` atual |
| `Login` | Vazio | Login compartilhado, herdado somente por campos vazios da DeviceList; somente no arquivo |
| `Password` | Vazio | Senha compartilhada, herdada somente por campos vazios da DeviceList; somente no arquivo |

Com `Language=auto`, o locale do sistema operacional seleciona a interface e o idioma de log.
Uma tradução externa usa o código de duas letras do idioma da configuração regional: por exemplo, `de_DE.UTF-8` requer `de.lang` ao lado do script.
Se não houver tradução adequada, o inglês é usado.

`MonthlyArchive` segue uma regra ligeiramente diferente: `false`/`no`/`0`/`off` desativam o arquivamento; `true`/`yes`/`1`/`on` significam o primeiro dia do mês; e os valores de `2` a `28` selecionam o dia necessário.

Quando o Editor de Configuração salva o arquivo, ele escreve
`MonthlyArchive=false` ou o número selecionado.

Os parâmetros booleanos aceitam `true`/`false`, `yes`/`no`, `1`/`0` e `on`/`off`
sem considerar o caso. O editor escreve `true`/`false`.

Campos como `IgnoreOxiAccess`, `encrypt_type`, `SshPort`, `Login` e `Password` não aparecem no Editor de Configuração.

Ao salvar o arquivo, o editor escreve `IgnoreOxiAccess`, `encrypt_type` e `SshPort`.
Ele preserva `Login` e `Password` somente se essas linhas já estivessem presentes em `option.cfg`, incluindo linhas com valores vazios.

Os campos `SshPort`, `Login` e `Password` podem ser úteis quando todos os dispositivos usam a mesma porta SSH e as mesmas credenciais. Nesse caso, cada entrada em `devicelist.cfg` precisa de apenas dois valores: o **nome** do dispositivo e seu **endereço IP**.

## Exemplo sem limpeza ou exportações sensíveis

Este é um exemplo de uma política selecionada, **não uma lista de valores padrão de fábrica**:

```ini
Language=ru
SshPort=22
UseOxidized=false
IgnoreOxiAccess=true
OxidizedHome=
UseIdentityName=true
backup_type=both
UseIncremental=true
export_format=compact
show_sensitive=false
encrypt=
encrypt_type=aes-sha256
clear_dns_cache=false
clear_console_history=false
BackupRoot=backups
UseNetFolder=false
MonthlyArchive=false
LogLevel=2
MainLogPath=
```

As primeiras 19 chaves são mostradas em ordem canônica de escrita.
Todas as linhas `Login` e `Password` compatíveis são preservadas após elas.

As configurações ausentes usam os valores internos, não os valores do exemplo acima.
Por exemplo, um arquivo contendo apenas `Language=ru` não desativa a limpeza e não altera `show_sensitive=true`.

## Caminhos

```ini
BackupRoot=backups
MainLogPath=logs
```

Estas entradas significam os diretórios `backups` e `logs` ao lado do script.
Caminhos absolutos mantêm o seu significado. `$HOME` e `~` não são expandidos
como uma variável ou diretório home.

Um `BackupRoot` ausente é criado durante a execução se as permissões o permitirem.
O diretório raiz do sistema de arquivos, `/`, é proibido como armazenamento.
Para diretórios existentes, o script não corrige automaticamente a propriedade ou permissões.

Um `MainLogPath` não vazio deve identificar um **diretório existente e com escrita**.
A criação do próprio `main.log` é adiada até que a primeira entrada seja gravada;
isso não cria o diretório pai. Se o log não puder ser gravado, o processamento de backups continuará com um aviso. Esta opção não move os logs dos dispositivos.

<a id="network-storage"> </a>
## Rede e armazenamento separado

`UseNetFolder=true` aplica-se ao modo em lote. O caminho deve ser abrangido por uma entrada de montagem diferente da entrada de `/`. O armazenamento separado pode ser um armazenamento de rede,
um disco local ou uma montagem bind; o nome da opção não restringe o tipo do sistema de arquivos.

Um diretório simples no mesmo sistema de arquivos raiz não atende a este requisito.
O script verifica a disponibilidade e montagem, mas não chama `mount`, `umount`,
ou `sudo` e não recorre silenciosamente ao armazenamento local.

## Parâmetros relacionados

Com `UseIncremental=false`, o script não compara um novo backup com o anterior e mantém todos os novos arquivos que foram criados e verificados com sucesso.
Essa configuração não afeta a criação do backup em si nem o arquivamento mensal.
O padrão é `UseIncremental=true`. Se o seu `option.cfg` ainda não contém este parâmetro, a comparação permanece ativa.

`backup_type=configuration` não usa criptografia de backup binário
nem as operações de limpeza que precedem um backup binário. `backup_type=binary` não usa `export_format`
nem `show_sensitive`. `UseOxidized=false` não utiliza `OxidizedHome`.

Com `UseIdentityName=true`, uma falha na leitura da identidade não é substituída
por `--device-name` nem pelo nome da DeviceList. Para usar um nome especificado, desative
`UseIdentityName`: ver [regras de nomeação](DEVICES.md#nomes-dos-dispositivos).

Com `MonthlyArchive=true`, o arquivamento é executado quando o script começa no dia selecionado do mês,
de acordo com a hora local do host; a hora do dia não importa.
Se o script não for executado naquele dia, a tentativa de arquivamento não será recuperada posteriormente.

[BACKUPS.md](BACKUPS.md#monthly-archive) explica quais arquivos entram no arquivo, onde ele é criado e como ele é nomeado.
O período de dados, o ponto de corte e as tentativas perdidas também são definidos em
[BACKUPS.md](BACKUPS.md#monthly-archive).

A configuração pode conter segredos. Restrinja o acesso a ela e não a inclua em um commit
de um repositório público: [SECURITY.md](SECURITY.md).
