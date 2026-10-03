# Linha de comando

[Índice](../README_PT-BR.md)

## Sintaxe

```text
mikrotik-backup.sh [action] [parameters]
```

Parâmetros de linha de comando podem usar uma forma longa: `--parameter value` ou `--parameter=value`.
Eles também podem usar uma forma curta: `-p=value`. No entanto, se o **valor** começar com `-`, somente a forma com `=` será aceita: `--parameter=-value`.

Um parâmetro desconhecido, um argumento posicional ou um valor ausente, explicitamente vazio ou inválido produz o código de erro `12` e interrompe o script.

<br />

## Ações

| Ação | Finalidade |
|---|---|
| `-i` | Menu interativo principal |
| `-b` | BackUP Master |
| `-e` | Editor de Configuração (`option.cfg`) |
| `-h`, `--help` | Ajuda na opção CLI |
| `-v`, `--version` | Versão do script |

O script não permite mais de uma opção de ação por vez. Por exemplo, `mikrotik-backup.sh -i -b` para com o código de erro `12`.

<br />

## Parâmetros

| Parâmetro | Valor | Finalidade |
|---|---|---|
| `--device-name` | Nome | Nome do dispositivo quando `UseIdentityName=false` |
| `--address` | Endereço ou nome DNS | Endereço do dispositivo RouterOS |
| `--user` | Login | Usuário do dispositivo RouterOS |
| `--password` | Senha | Senha do dispositivo RouterOS |
| `--port` | `1`–`65535` | Porta SSH do dispositivo; por padrão `22` |
| `--language` | `auto` ou duas letras ASCII | Idioma da interface e dos registros de scripts atuais |
| `--use-oxidized` | Valor booleano * | Importar a lista de dispositivos de Oxidized |
| `--oxidized-home` | Caminho | Diretório de configuração do Oxidized contendo `config` e `router.db` |
| `--use-identity-name` | Valor booleano * | Obter o nome de identidade do RouterOS |
| `--backup-root` | Caminho | Diretório raiz para armazenamento de backup |
| `--use-net-folder` | Valor booleano * | Verificar a montagem em lote |
| `--monthly-archive` | `false` ou um número de `1` a `28` * | Ativar o arquivamento mensal com base no calendário |
| `--log-level` | `0`, `1`, `2`, `3` | Nível de detalhe para logs e saída de terminal |
| `--main-log-path` | Caminho | Diretório apenas para `main.log` |
| `--backup-type` | `configuration`, `binary`, `both` | Formatos de backup a obter |
| `--export-format` | `compact`, `terse`, `verbose` | Formato de exportação de texto |
| `--show-sensitive` | Valor booleano * | Incluir valores sensíveis na exportação |
| `--encrypt` | Senha não vazia | Criptografar `.backup` com AES-SHA256 |
| `--clear-dns-cache` | Valor booleano * | Limpar o cache DNS antes de um backup binário |
| `--clear-console-history` | Valor booleano * | Limpar o histórico do shell antes de um backup binário |

`*` Os valores booleanos são `true` ou `false`; o script também aceita `yes`/`no`, `1`/`0` e `on`/`off`, sem considerar o caso.
Para `backup-type`, `config` e `conf` também são aceitos como sinônimos de `configuration`.

Formas curtas de conexão:

```text
-a=VALUE    equivale a --address VALUE
-u=VALUE    equivale a --user VALUE
-p=VALUE    equivale a --password VALUE
```

<br />

<a id="execution-mode"> </a>
## Executando o script da linha de comando

O script pode fazer backup de um único dispositivo, mas requer pelo menos três parâmetros para tal execução:
o **endereço IP**, o **usuário** e a **senha** do dispositivo. Em outras palavras, este comando já é utilizável:

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword
```

Todos os outros parâmetros listados acima são opcionais aqui.
*(N.B. Um ponto muito importante: o script NÃO foi projetado para combinar esse conjunto de três dados de conexão com uma opção de **ação**.)*

**Mais um detalhe!!!**
Para uma execução de dispositivo único, os três parâmetros de conexão devem ser fornecidos pela CLI. O script não obtém de `option.cfg` um usuário ou uma senha que estejam faltando.

<br />

## Ordem de prioridade

Os backups comuns de dispositivo único e em lote usam a ordem descrita em [OPTIONS.md](OPTIONS.md):
**Valores internos**→**Linhas válidas de `option.cfg`**→**CLI**

Se um parâmetro já estiver presente em `option.cfg` mas uma execução em particular necessitar de um valor diferente, passe esse valor pela CLI. Você não precisa reescrever o arquivo de configuração.

Uma execução de um dispositivo não usa a lista de dispositivos ou importação do Oxidized. Outras configurações de `option.cfg` ainda se aplicam a menos que os parâmetros da linha de comando os substituam.

**O BackUP Master tem sua própria ordem de preenchimento do formulário.**
Os campos comuns usam valores internos e parâmetros fornecidos pela CLI, não `option.cfg`. `UseIncremental` é a exceção: seu valor é herdado do arquivo ou assume o padrão.
Os `LogLevel` e `MainLogPath` selecionados são retidos para a execução, enquanto o arquivamento mensal está desativado. Veja [INTERACTIVE.md](INTERACTIVE.md) para obter mais detalhes sobre o próprio BackUP Master.

<br />

## Parâmetros da linha de comando por finalidade

### Conexão e nome do dispositivo

| Opção | Valor | Finalidade |
|---|---|---|
| `--address` | endereço IP ou nome DNS | Endereço do dispositivo RouterOS |
| `--user` | Login | Usuário do dispositivo RouterOS |
| `--password` | Senha | Senha do dispositivo RouterOS |
| `--port` | `1` a `65535` | Porta SSH do dispositivo; por padrão `22` |
| `--device-name` | Nome | Nome do dispositivo quando `UseIdentityName=false` |
| `--use-identity-name` | `true` / `false` | Obter o nome de identidade do RouterOS |

Para usar o seu próprio nome, especifique `--use-identity-name false` e `--device-name NAME` juntos.

<br />

### Formato e conteúdo do backup

| Opção | Valor | Finalidade |
|---|---|---|
| `--backup-type` | `configuration`, `binary`, `both` | Formatos de backup a obter |
| `--export-format` | `compact`, `terse`, `verbose` | Formato de exportação de texto |
| `--show-sensitive` | `true` / `false` | Incluir valores sensíveis na exportação |
| `--encrypt` | Senha não vazia | Criptografar `.backup` com AES-SHA256 |
| `--clear-dns-cache` | `true` / `false` | Limpar o cache DNS antes de um backup binário |
| `--clear-console-history` | `true` / `false` | Limpar o histórico do shell antes de um backup binário |

Para `--backup-type`, `config` e `conf` também significam `configuration`.

*(N.B. `UseIncremental` não tem opção CLI separada. Defina-a em `option.cfg`, o Editor de Configuração, ou BackUP Master. O seu propósito está descrito em [OPTIONS.md](OPTIONS.md).)*

<br />

### Armazenamento, arquivamento e logs

| Opção | Valor | Finalidade |
|---|---|---|
| `--backup-root` | Caminho | Diretório raiz para armazenamento de backup |
| `--use-net-folder` | `true` / `false` | Verificar a montagem em lote |
| `--monthly-archive` | `false` ou um número de `1` a `28` | Ativar o arquivamento mensal com base no calendário |
| `--log-level` | `0`, `1`, `2`, `3` | Nível de detalhe para logs e saída de terminal |
| `--main-log-path` | Caminho da pasta | Diretório apenas para `main.log` |

`--monthly-archive` tem a sua própria regra: `true`/`yes`/`1`/`on` significa o primeiro dia do mês, enquanto `false`/`no`/`0`/`off` desativa o arquivamento. Os valores de `2` até `28` selecionam o dia requerido.

A opção seleciona o dia de arquivamento; ela não executa o arquivamento imediatamente. Veja [BACKUPS.md](BACKUPS.md#monthly-archive) para as regras deste modo.

Para `--main-log-path`, indique uma pasta, não um caminho completo que termine em `main.log`. Esta opção não afeta os registros do dispositivo.

<br />

### Código e idioma da lista de dispositivos

| Opção | Valor | Finalidade |
|---|---|---|
| `--use-oxidized` | `true` / `false` | Importar a lista de dispositivos de Oxidized |
| `--oxidized-home` | Caminho | Diretório de configuração do Oxidized contendo `config` e `router.db` |
| `--language` | `auto` ou um código de duas letras | Idioma da interface e dos registros de scripts atuais |

Com `--language auto`, a localidade do sistema operacional seleciona o idioma. Você pode selecionar um explicitamente, como `ru`, `en` ou `de`. Russo e inglês não requerem arquivos de tradução separados; as demais traduções são carregadas de arquivos ao lado do script. Se não houver uma tradução adequada, o inglês será usado.
Veja [LOCALIZATION.md](LOCALIZATION.md) para mais detalhes.

<br />

## Exemplos

**Atenção!!!**
Por padrão, a exportação de dados sensíveis, a limpeza do cache DNS e a limpeza do histórico do console antes de um backup binário estão habilitadas. Os exemplos de dispositivo único abaixo desabilitam essas limpezas e a exportação de dados sensíveis.

*(N.B. As senhas fornecidas pela CLI podem estar visíveis no histórico do shell e nos argumentos do processo. Isto também se aplica à senha de criptografia `.backup`, que pode estar visível nos argumentos do processo filho `ssh`. Veja [SECURITY.md](SECURITY.md) para mais detalhes.)*

### `.rsc` apenas configuração, sem dados sensíveis

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword --backup-type=configuration --show-sensitive=false
```

### Ambos os formatos, um nome de dispositivo personalizado e nenhuma limpeza

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword --use-identity-name=false --device-name=edge-router --backup-type=both --show-sensitive=false --clear-dns-cache=false --clear-console-history=false
```

### Backup binário criptografado

```bash
mikrotik-backup.sh --address=xxx.xxx.xxx.xxx --user=UserName --password=MySuperPassword --backup-type=binary --encrypt='ENCRYPTION_PASSWORD' --clear-dns-cache=false --clear-console-history=false
```

### Lote executado com um diretório separado e registro detalhado

Este exemplo pressupõe que `option.cfg` e a lista de dispositivos já foram preparados:

```bash
mikrotik-backup.sh --backup-root=/srv/mikrotik-backups --log-level=3
```

As demais configurações desta execução em lote vêm de `option.cfg` e dos valores internos.

<br />

## Se um comando for rejeitado

Uma opção desconhecida, um argumento posicional extra ou um valor ausente ou inválido causa o erro `12`. Nenhum backup é iniciado. Use `-h` para verificar a grafia da opção.

**Valores vazios não podem ser passados pela CLI.**
`--encrypt=''` e `--main-log-path=''` são rejeitados. Defina valores vazios com `encrypt=` e `MainLogPath=` em `option.cfg` ou através do Editor de Configuração.

Os códigos de resultados e os seus significados são enumerados na lista [Resolução de Problemas](TROUBLESHOOTING.md#result-codes).
