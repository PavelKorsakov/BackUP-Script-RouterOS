# Registro

[Índice](../README_PT-BR.md)

## Registros principais e registros de dispositivos

O script registra seu progresso geral no log principal, `main.log`, enquanto os detalhes do trabalho com cada dispositivo são salvos em um log separado do dispositivo.

Em `main.log`, você pode ver como a lista de dispositivos foi preparada, seguir o processamento em lote e revisar os resultados de dispositivos processados. Erros que ocorrem antes de um determinado dispositivo ter sido identificado também são registrados aqui.

Um log de dispositivo contém informações sobre a obtenção de arquivos `.rsc` e `.backup`, tentativas, comparação de backups e arquivamento. Em outras palavras, se precisar descobrir o que aconteceu durante o backup de determinado dispositivo, consulte o log desse dispositivo. Esses detalhes não são duplicados em `main.log`.

<br />

## Onde os registros são armazenados

Por padrão, o registro principal é armazenado no diretório `backups` ao lado do script. Os registros de dispositivos são armazenados ao lado de seus backups:

| Registro | Caminho |
|---|---|
| Registro principal | `<BackupRoot>/main.log` |
| Dispositivo em modo em lote | `<BackupRoot>/<DeviceName>/<DeviceName>.log` |
| Dispositivo numa execução de um dispositivo único | `<BackupRoot>/<DeviceName>_YYYY-MM-DD_HH-MM.log` |

No modo em lote, novos itens são adicionados ao mesmo log do dispositivo. Para um backup de um único dispositivo, o nome do registro contém a mesma data e hora que os nomes dos arquivos de backup daquela execução.

### Um diretório separado para main.log

Se preferir manter o log principal separado dos backups, especifique o diretório na configuração `MainLogPath` em `option.cfg`:

```ini
MainLogPath=/var/log/mikrotik-backup
```

O log será então gravado em `/var/log/mikrotik-backup/main.log`. Os logs dos dispositivos permanecerão em suas localizações habituais.

Um `MainLogPath=` vazio usa o `BackupRoot` atual. Um caminho relativo, como `MainLogPath=logs`, refere-se a um diretório ao lado do script, não dentro do armazenamento de backup.

*(N.B. `MainLogPath` indica uma pasta, não um nome de arquivo completo. A pasta já deve existir e permitir escrita pelo usuário que executa o script.)*

<br />

## Detalhes do registro

A configuração `LogLevel` controla a quantidade de informação que é mostrada e gravada. O seu valor por padrão é `2`:

| Valor | Progresso no terminal | Entradas em arquivos de log |
|---|---|---|
| `0` | Apenas erros | Apenas erros |
| `1` | Principais etapas e seus resultados | Breve registro |
| `2` | Principais etapas e seus resultados | Registro detalhado |
| `3` | Principais fases e suboperações atuais | Registro detalhado |

**Os erros são registrados em todos os níveis.** Um breve registro contém as etapas principais e seus resultados; um registro detalhado também registra as operações realizadas dentro dessas etapas.

Você pode alterar o nível em `option.cfg` ou através do Editor de Configuração:

```ini
LogLevel=3
```

Para alterá-lo para uma execução de um backup em lote já configurada, use a CLI:

```bash
mikrotik-backup.sh --log-level=3
```

Isto não altera o valor no arquivo de opções. Da mesma forma, o `--main-log-path` pode definir o caminho principal do registro para a execução atual.

BackUP Master não tem campos separados para `LogLevel` ou `MainLogPath`. Ele usa a configuração de registro em vigor para a execução atual.

<br />

## Aparência dos registros

Os registros são arquivos de texto normais. Cada item inclui a data e hora de acordo com o relógio do host que executa o script. As cores e os indicadores de progresso não são escritos no arquivo.

Exemplo de entradas em `main.log`:

```text
[2026-10-01 01:00:00] [PID:12345] Processando dispositivos em lote
[2026-10-01 01:00:15] [PID:12345] [OK] Processando dispositivos em lote
```

O log principal também inclui o processo PID. Isso permite distinguir os itens escritos por várias instâncias de script em execução ao mesmo tempo.

O PID não é adicionado a um registro de dispositivos. Aqui está um trecho de um registro detalhado:

```text
[2026-10-01 01:00:05] Obtendo backup binário
[2026-10-01 01:00:06] [1] Limpando o cache DNS
[2026-10-01 01:00:07] [2] Limpando o histórico do console
[2026-10-01 01:00:12] [OK] Obtendo backup binário
```

`[OK]` significa que a operação terminou com sucesso. Um erro é marcado com `[ER]` e inclui o seu código, por exemplo `[53]`. As suboperações estão numeradas `[1]`, `[2]`, e assim por diante, começando de novo dentro de cada estágio principal.

Se uma nova tentativa tiver sucesso após uma tentativa falhada, o log retém tanto o erro anterior quanto o resultado posterior bem-sucedido.

As entradas de log usam o mesmo idioma da interface, selecionado pela configuração `Language`. Para mais informações sobre a escolha de um idioma e o uso de traduções, consulte [LOCALIZATION.md](LOCALIZATION.md).

<br />

## Saída de terminal

Durante uma execução manual, o progresso é visível na tela. Enquanto uma operação está em andamento, um indicador de espera aparece ao lado dela. Quando ela termina, o indicador muda para um verde `[OK]` ou um vermelho `[ER]` com um código de erro.

Os níveis `1` e `2` mostram as fases principais. No nível `3`, a suboperação atual é também mostrada abaixo da fase em execução e muda à medida que o trabalho prossegue. No modo em lote, a tela identifica adicionalmente o dispositivo atualmente em processamento.

*(N.B. Quando o script é executado sem um terminal — por exemplo, por um agendador ou com sua saída redirecionada — essa saída de tela não existe. A gravação nos arquivos de log continua no nível selecionado.)*

<br />

## Acúmulo e arquivamento de logs

Um arquivo de log é criado quando seu primeiro item é gravado. Com `LogLevel=0` e sem erros, não são criados novos arquivos de log, enquanto os existentes permanecem inalterados.

Os logs principais e os logs de dispositivos em modo de lote são adicionados em vez de serem substituídos em cada execução. Uma linha em branco separa as execuções sucessivas.

`main.log` não é arquivado nem removido com base na idade. O administrador deve configurar a rotação.

Quando o arquivo mensal estiver habilitado, o registro acumulado do dispositivo em modo de lote será incluído no ZIP na íntegra, juntamente com os backups desse dispositivo. Uma vez que o arquivo tenha sido salvo com sucesso, o registro arquivado será removido da pasta do dispositivo; o resultado do arquivamento e o trabalho subsequente serão então gravados em um novo arquivo de registro.

Se o mesmo ZIP for atualizado novamente, o histórico dentro dele é estendido em vez de substituído por um novo log. Se o arquivo não puder ser salvo, o log anterior permanece no lugar e o erro é gravado nele.

Os logs das execuções de um único dispositivo pela CLI são arquivados juntamente com backups da pasta compartilhada. Arquivamento em ambos os modos é descrito em [BACKUPS.md](BACKUPS.md#monthly-archive).

<br />

## Se um registro não puder ser escrito

Permissões insuficientes, uma pasta indisponível ou outro erro de gravação no log não interrompem o backup propriamente dito. O script registra um aviso e continua sempre que possível.

Um `main.log` não disponível é informado uma vez por execução, e um log do dispositivo não disponível uma vez enquanto esse dispositivo está sendo processado. Se o log principal estiver disponível, uma falha de gravação do registro do dispositivo é gravada lá.

Se não houver outros erros, a execução sai com o código `1`, indicando que foi concluída com um aviso. Este aviso não substitui um erro da operação de backup propriamente dita.

Para obter códigos de resultado e ajudar a encontrar a causa de um erro, consulte [TROUBLESHOOTING.md](TROUBLESHOOTING.md#result-codes).

*(N.B. O nível detalhado `3` não registra senhas ou comandos de conexão completos. Para obter informações sobre a proteção de credenciais e arquivos de script, consulte [SECURITY.md](SECURITY.md).)*
