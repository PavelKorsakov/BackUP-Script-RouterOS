# Backups e arquivos compactados

[Índice](../README_PT-BR.md)

## Formatos de backup

O script pode salvar a configuração do dispositivo como texto, criar um backup binário ou obter ambos os formatos.
O parâmetro `backup_type` em `option.cfg` seleciona o formato:

| Valor | O que é salvo |
|---|---|
| `configuration` | Configuração do RouterOS em um arquivo `.rsc` |
| `binary` | Backup binário em um arquivo `.backup` |
| `both` | Ambos os formatos: `.rsc` primeiro, depois `.backup` |

O padrão é `both`. Você pode alterá-lo no arquivo de opções, no Editor de Configuração, no BackUP Master ou com `--backup-type`.

### Configuração em texto: .rsc

O parâmetro `export_format` seleciona o formato de exportação. Os valores válidos são `compact`, `terse` e `verbose`; o padrão é `compact`.

O parâmetro `show_sensitive` determina se a exportação inclui dados sensíveis, incluindo senhas. Está ativado por padrão.
Para desativá-lo, adicione isto a `option.cfg`:

```ini
show_sensitive=false
```

### Backup binário: .backup

Você pode criptografar um backup binário. Defina a senha necessária em `encrypt`:

```ini
encrypt=MySuperPassword
```

Com um valor `encrypt=` vazio, o arquivo `.backup` é salvo sem criptografia. Esse é o padrão.

*(N.B. A criptografia AES-SHA256 aplica-se apenas a `.backup`. Não cifra as configurações de texto, os registros ou os arquivos ZIP.)*

Por padrão, o script limpa o cache DNS e o histórico do console do RouterOS antes de criar um backup binário. Se você não precisar dessas operações, desative os parâmetros correspondentes:

```ini
clear_dns_cache=false
clear_console_history=false
```

Essas operações de limpeza não são realizadas quando apenas uma configuração de texto é obtida.

<br />

## Nomes e localizações dos arquivos

Por padrão, os backups são armazenados no diretório `backups` ao lado do script. Defina outro diretório com `BackupRoot` no arquivo de opções.

Em uma execução de um dispositivo, os arquivos são colocados diretamente nesse diretório:

```text
backups/
├── main.log
├── Router-A_YYYY-MM-DD_HH-MM.rsc
├── Router-A_YYYY-MM-DD_HH-MM.backup
└── Router-A_YYYY-MM-DD_HH-MM.log
```

No modo em lote, cada dispositivo tem seu próprio subdiretório:

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

Um nome de arquivo de backup contém o nome do dispositivo e a data e hora do relógio do host que executa o script. Ambos os formatos da mesma operação de backup usam a mesma data e hora.
A construção do nome do dispositivo está descrita em [DEVICES.md](DEVICES.md#nomes-dos-dispositivos).

**Atenção!!!**
Se fizer o backup do mesmo dispositivo para a mesma pasta duas vezes dentro de um minuto, os nomes dos arquivos correspondem. O arquivo com esse nome é substituído; uma versão separada não é criada para a segunda execução.

Você também pode usar uma pasta de rede para armazenamento. No modo em lote, defina `UseNetFolder=true` para verificar esse armazenamento. A preparação do diretório é descrita em [INSTALL.md](INSTALL.md), e a configuração do caminho em [OPTIONS.md](OPTIONS.md#network-storage).

[LOGGING.md](LOGGING.md) explica em detalhe o caminho e o conteúdo dos registros.

<br />

## Backups incrementais

Este recurso evita reter backups duplicados quando nenhuma alteração é detectada. O parâmetro `UseIncremental` controla esse comportamento:

| Valor | Como os backups são retidos |
|---|---|
| `true` (por padrão) | Se o novo backup for identificado como uma duplicata, ele é excluído e o backup anterior permanece |
| `false` | Cada novo backup válido é mantido sem comparação com o anterior |

Quando uma alteração é detectada ou não existe backup anterior, o novo arquivo é retido. Se a comparação não puder ser concluída, o arquivo também é retido, mas o script emite um aviso.

**E aqui está o detalhe!!!**
A comparação difere por formato:

| Formato | O que é comparado |
|---|---|
| `.rsc` | Conteúdo do arquivo. A data e hora no cabeçalho padrão RouterOS são ignoradas |
| `.backup` | Tamanho do arquivo apenas em bytes |

Dois arquivos binários do mesmo tamanho são tratados como duplicados, mesmo quando o seu conteúdo difere. Leve isso em conta ao escolher as configurações de retenção.

O script compara o novo arquivo com o backup mais recente do mesmo dispositivo e formato no diretório desse dispositivo. Os backups já incluídos em um ZIP não participam da comparação.

O script mantém arquivos `.rsc` e `.backup` comuns, e não arquivos de diferenças separados. Desativar `UseIncremental` não desativa a recuperação e verificação de backup, registro ou arquivamento mensal.

<br />

<a id="monthly-archive"> </a>
## Arquivamento mensal

Este recurso está desativado por padrão. Defina `MonthlyArchive` em `option.cfg` para escolher o dia em que os registros e backups acumulados serão arquivados:

| Valor | Comportamento |
|---|---|
| `false` (por padrão) | O arquivamento está desativado |
| `true` ou `1` | O arquivamento é executado no primeiro dia do mês |
| `2` até `28` | O arquivamento é executado no dia indicado do mês |

A hora da execução dentro do dia selecionado não importa. Configure o agendamento separadamente, conforme descrito em [INSTALL.md](INSTALL.md#executando-o-script-automaticamente).

### O que entra no arquivo

No modo em lote, a ordem de trabalho muda naquele dia: o script primeiro coleta os arquivos acumulados do dispositivo em um ZIP e só então cria novos backups. Backups criados pela execução atual permanecem fora do arquivo.

O arquivo inclui arquivos regulares diretamente dentro do diretório do dispositivo, incluindo o registro cumulativo completo do dispositivo. Isto não se limita a `.rsc` e `.backup`: outros arquivos regulares que você coloca no diretório também podem ser arquivados.

Subdiretórios, links simbólicos, arquivos auxiliares para a execução atual e arquivos ZIP criados anteriormente pelo script não são embalados novamente. **O log principal, `main.log`, não é arquivado.**

Após o ZIP ter sido verificado e salvo, os arquivos de origem incluídos nele são excluídos da pasta do dispositivo. Se não houver nada para arquivar, não é criado nenhum ZIP vazio.

### Nome e caminho do arquivo

O ZIP tem o nome do dia anterior no formato `DD.MM.YYYY.zip`. Por exemplo, uma execução em 1 de Outubro de 2026 cria `30.09.2026.zip`; uma execução em 15 de Outubro cria `14.10.2026.zip`.

| Modo | Caminho do arquivo |
|---|---|
| Lote | `<BackupRoot>/<DeviceName>/archive/DD.MM.YYYY.zip` |
| Dispositivo único pela CLI | `<BackupRoot>/DD.MM.YYYY.zip` |

Uma execução repetida no mesmo dia atualiza o arquivo compactado de mesmo nome.

### Modo de dispositivo único e BackUP Master

Em uma execução de um único dispositivo pela CLI, a ordem é invertida: o backup é executado primeiro, seguido pelo arquivamento. Portanto, o novo backup da execução atual também poderá entrar no ZIP.

Nesse modo, os arquivos `.rsc`, `.backup` e `.log` diretamente em `BackupRoot` são arquivados, exceto `main.log`. Se os resultados das execuções de dispositivo único para vários dispositivos compartilharem um diretório, seus arquivos entrarão no mesmo arquivo.

O arquivamento mensal não é executado quando BackUP Master é usado.

### Se uma execução for perdida

Se o script não for executado no dia selecionado, a tentativa mensal perdida não será recuperada mais tarde. A próxima tentativa ocorre somente no dia designado do mês seguinte.

Na próxima tentativa bem-sucedida, todos os arquivos elegíveis acumulados entram em um único arquivo, mesmo que o backlog abranja dois, três ou mais meses. Não são criados arquivos ZIP separados para os meses perdidos.

### Se o arquivo falhar

Os arquivos de origem não são excluídos até que um ZIP verificado seja salvo. Um ZIP existente e danificado também não é substituído por um novo.

Se o ZIP já foi salvo, mas alguns arquivos de origem não podem ser excluídos, o ZIP concluído permanece no lugar, assim como os arquivos que não puderam ser excluídos. Verifique o registro da causa do erro.

*(N.B. O arquivo é montado no diretório local `/tmp` mesmo quando os backups são armazenados em um NAS. Portanto, também é necessário espaço livre fora do armazenamento.)*

<br />

## Se o backup falhar

Após uma tentativa malsucedida de obter um arquivo, o script tenta novamente após 2 segundos. As tentativas para `.rsc` e `.backup` são realizadas separadamente.

Um erro normal ao obter um formato não cancela a tentativa de obter o outro. Se um dispositivo não estiver disponível, o script continua com os dispositivos restantes. Se o armazenamento compartilhado ficar indisponível, o processamento em lote será interrompido.

Mensagens de erro e códigos de resultado estão descritos em [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

<br />

## Retenção e restauração

Os arquivos ZIP antigos não são excluídos por idade ou contagem. Você decide seu período de retenção e política de rotação externa.

O script cria backups, mas não restaura o RouterOS. Teste a restauração separadamente em um dispositivo adequado.

*(N.B. Os backups e arquivos podem conter senhas e outros dados confidenciais. Restrinja o acesso ao armazenamento como descrito em [SECURITY.md](SECURITY.md).)*
