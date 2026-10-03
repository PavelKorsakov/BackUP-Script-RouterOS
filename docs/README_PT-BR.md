# MikroTik Backup Script

**Faça backup de dispositivos MikroTik RouterOS.**

Este script cria backups de dispositivos rodando RouterOS, manualmente ou automaticamente através de um agendador *(que você configura separadamente)*.
O arquivo `mikrotik-backup.sh` é um script auto-suficiente, embora algumas funcionalidades possam ser configuradas através de `option.cfg`.

<br>

## Recursos do script

| Característica | Como funciona |
|---|---|
| Modo de dispositivo único | Cria um backup de um dispositivo usando as opções CLI |
| Processamento em lote | Processa em sequência os dispositivos listados em DeviceList; pode importar a lista do Oxidized |
| Formatos de backup | Cria `.rsc`, `.backup`, ou ambos os formatos em sequência |
| Modos de backup | Suporta exportações compactas, terse e verbose, além de criptografia de backups binários |
| Backups incrementais | Pode manter backups somente quando uma alteração é detectada |
| Arquivamento mensal | Pode arquivar backups e logs antigos em um limite do calendário |
| Registro | Grava as fases gerais em `main.log` e as operações do dispositivo em `devicename.log` |
| Menu de configuração | Fornece um menu interativo para configuração e operação convenientes |
| Localização | Inclui russo e inglês e aceita arquivos externos de localização |
| Armazenamento de backup | Pode usar qualquer diretório de backup, incluindo um NAS |
| Uso de NAS | Verifica se o armazenamento está disponível antes de criar um backup |

<br>

## Requisitos do sistema e início

**Obrigatório:**
GNU Bash 4.4 ou posterior e os seguintes utilitários instalados: **SSH**, **SCP** e **SSHPass**.
**zip** é necessário apenas para o arquivamento mensal de backup. Todos os utilitários necessários e seus comandos de instalação estão listados em [Dependências](pt-BR/INSTALL.md#dependências).
*(N.B. Se um utilitário necessário estiver faltando, o script termina com um erro. Este é o comportamento esperado.)*

**Opcional:**
**autofs**, **davfs2**, **rclone**, e outras ferramentas para montagem de armazenamento externo.

**Instalação:**
Veja [Instalação](pt-BR/INSTALL.md) para instruções de download e configuração.

Execute os seguintes comandos no diretório que contém os arquivos baixados:

O bloco de comandos abaixo pressupõe arquivos obtidos de um GitHub Release. Um checkout do código-fonte via Git não inclui o `SHA256SUMS` gerado para o Release; nesse caso, comece com `chmod 700 mikrotik-backup.sh` e prossiga com as verificações de versão e ajuda.

```bash
sha256sum -c SHA256SUMS &&
chmod 700 mikrotik-backup.sh &&
./mikrotik-backup.sh --language en --version &&
./mikrotik-backup.sh --language ru --help
```

Se a verificação da soma de verificação falhar, **não execute o arquivo!!!**

<br>

## Formas de executar o script

**Execute o script sem opções adicionais** *(quando `option.cfg` não existe ou não contém configurações válidas)*
Se não houver `option.cfg` ao lado do script, ou se o arquivo estiver vazio, contiver apenas comentários ou tiver somente parâmetros desconhecidos ou inválidos, o Editor de Configuração será aberto para que você possa criar ou editar `option.cfg`.

**Execute o script sem opções adicionais** *(quando existirem arquivos `option.cfg` e `devicelist.cfg` válidos)*
Se as configurações utilizáveis já existirem, o script inicia o processamento em lote.

**Execute o script com uma opção:**

| Tarefa | Comando |
|---|---|
| Abrir o menu interativo | `./mikrotik-backup.sh -i` |
| Abrir BackUP Master | `./mikrotik-backup.sh -b` |
| Criar ou editar `option.cfg` | `./mikrotik-backup.sh -e` |
| Mostrar a ajuda CLI completa | `./mikrotik-backup.sh -h` |
| Executar um backup de um único dispositivo | Forneça os três parâmetros completos da CLI: endereço do dispositivo, usuário e senha |

A opção mais importante aqui é `-i`, que abre o menu interativo. A partir daí você pode:

- usar o BackUP Master para inserir parâmetros do dispositivo, criar seus backups e criar ou ampliar `devicelist.cfg` com os parâmetros selecionados;
- usar o Editor de Configuração para criar ou editar `option.cfg`;
- consultar a ajuda da CLI;
- ler um breve guia dos recursos do script.

Para a referência completa da CLI, incluindo as formas exatas `-a=...`, `-u=...` e `-p=...`, consulte a [referência da linha de comando](pt-BR/CLI.md).

<br>

## Onde estão os resultados, ou “Onde estão meus backups???”

Por padrão, os backups do dispositivo são armazenados no diretório `backups` ao lado do script. Se o diretório não existir, o script o cria.
*(N.B. O caminho relativo `backups` é resolvido a partir do diretório do script, não da pasta de trabalho atual!)*

Em uma execução de um dispositivo, não é criado nenhum subdiretório de dispositivo separado:

```text
backups/
├── main.log
├── Router-A_YYYY-MM-DD_HH-MM.rsc
├── Router-A_YYYY-MM-DD_HH-MM.backup
└── Router-A_YYYY-MM-DD_HH-MM.log
```

No modo em lote, cada dispositivo tem seu próprio diretório:

```text
backups/
├── main.log
└── Router-A/
    ├── Router-A_YYYY-MM-DD_HH-MM.rsc
    ├── Router-A_YYYY-MM-DD_HH-MM.backup
    ├── Router-A.log
    └── archive/
        └── DD.MM.YYYY.zip
```

Estes layouts são exemplos, não uma promessa de que cada arquivo existirá após cada execução.
Um log é criado quando seu primeiro item aplicável é escrito.
A opção `MainLogPath` de `option.cfg` pode mover `main.log` para `/var/log/` ou qualquer outra pasta adequada.
Veja [Configuração](pt-BR/OPTIONS.md) para detalhes sobre a configuração dos diretórios de backup, arquivamento e logs.

<br>

## Arquivamento mensal

Este recurso fica desativado por padrão. Se o script for executado de forma agendada, defina `MonthlyArchive=true|1...28` em `option.cfg` para selecionar o dia do arquivamento mensal.

Nesse dia, uma execução em lote altera sua ordem de trabalho: primeiro arquiva todos os dados elegíveis acumulados no diretório de backup e depois cria backups para a data atual.

O arquivo recebe o nome do dia anterior no calendário. Por exemplo, uma execução em 1 de outubro cria `30.09.YYYY.zip`.

*(N.B. Se o script NÃO for executado diariamente, você deverá criar uma tarefa agendada separada para a data necessária. Nenhuma tarefa separada é necessária quando o script é executado diariamente ou com mais frequência.)*

Uma tentativa mensal perdida, seja qual for o motivo, não é recuperada por execuções diárias posteriores. Não há uma execução adicional do arquivamento mais tarde no mesmo dia ou mês.
A próxima tentativa ocorre somente na data mensal agendada seguinte e reúne em um único arquivo todos os dados antigos elegíveis acumulados, mesmo que o backlog abranja vários meses. `main.log` não é arquivado.

Veja [Arquivamento mensal](pt-BR/BACKUPS.md#monthly-archive) para as regras completas, exemplos e comportamento de falha.

<br>

## Documentação detalhada

| Assunto | Página |
|---|---|
| Requisitos, dependências e colocação de arquivos | [Instalação](pt-BR/INSTALL.md) |
| Parâmetros e seleção de modo | [CLI](pt-BR/CLI.md) |
| Valores padrão e `option.cfg` | [Configuração](pt-BR/OPTIONS.md) |
| DeviceList, nomes e Oxidized | [Dispositivos](pt-BR/DEVICES.md) |
| Formatos, comparação, armazenamento e arquivos ZIP | [Backups](pt-BR/BACKUPS.md) |
| Níveis de registro, caminhos e mensagens | [Registro](pt-BR/LOGGING.md) |
| Menu, editor e BackUP Master | [Interface interativa](pt-BR/INTERACTIVE.md) |
| Seleção de idiomas e arquivos `.lang` | [Localização](pt-BR/LOCALIZATION.md) |
| Credenciais, SSH e permissões de acesso | [Segurança](pt-BR/SECURITY.md) |
| Diagnóstico por sintoma ou código de resultado | [Resolução de Problemas](pt-BR/TROUBLESHOOTING.md) |
| Verificação de versões e atualizações | [Releases](pt-BR/RELEASES.md) |
| História e planos de desenvolvimento | [Roteiro](pt-BR/ROADMAP.md) |

<br>

## Escopo e limitações

O script cria backups, mas não restaura uma configuração de roteador.
A versão atual não envia notificações de e-mail ou messenger e não apaga arquivos ZIP antigos por idade.
O administrador é responsável pelos procedimentos de restauração, retenção externa e monitoramento de resultados.

O perfil SSH usa autenticação de senha e desativa a verificação da chave de host.
Criptografar um arquivo `.backup` não criptografa arquivos `.rsc`, arquivos de configuração ou arquivos ZIP.
Leia o [modelo de segurança](pt-BR/SECURITY.md) antes do uso em produção.

<br>

## Documentação em outros idiomas

[English](../README.md).  
[Русский](README_RU.md).  
[Latviešu](README_LV.md).  
[Українська](README_UK.md).  
[Deutsch](README_DE.md).  
[Bahasa Indonesia](README_ID.md).  
[Português (Brasil)](README_PT-BR.md).  
[Tiếng Việt](README_VI.md).  
[Español](README_ES.md).  
[Polski](README_PL.md).  
[বাংলা](README_BN.md).

## Contato com o autor

Envie sugestões de recursos, relatórios de erros e perguntas sobre o script para [backup-scripts@korsakov.dev](mailto:backup-scripts@korsakov.dev),
ou contate o autor pelo Telegram: [@PavelKorsakoff](https://t.me/PavelKorsakoff).
