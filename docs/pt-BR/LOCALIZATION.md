# Localização

[Índice](../README_PT-BR.md)

## Idioma da interface e dos registros

O russo (`ru`) e o inglês (`en`) estão integrados ao script. Não são necessários arquivos de tradução separados para eles. A versão 2.3.1 inclui as traduções externas da interface e dos registros `de.lang`, `es.lang`, `lv.lang`, `pl.lang` e `uk.lang`.

O idioma da documentação e a disponibilidade de uma tradução externa em tempo de execução são independentes. Por isso, pode haver documentação em um idioma sem que a distribuição contenha o arquivo `.lang` correspondente.

O idioma selecionado é usado em menus, ajuda, mensagens de script e entradas de registro. Não existe uma configuração de idioma separada para registros.

<br />

## Escolher um idioma

A configuração `Language` em `option.cfg` controla a seleção. O seu valor por padrão é `auto`:

| Valor | Idioma usado |
|---|---|
| `auto` | Determinado pela configuração regional do sistema operacional |
| `ru` | Russo embutido |
| `en` | Inglês embutido |
| Outro código de duas letras, como `de` | Tradução do arquivo correspondente, como por exemplo `de.lang` |

Para selecionar o russo permanentemente, defina isto em `option.cfg`:

```ini
Language=ru
```

Para uma única execução, você pode selecionar o idioma pela CLI:

```bash
mikrotik-backup.sh --language=ru --help
```

A opção `--language` tem precedência sobre a configuração no arquivo de opções, mas não altera o arquivo em si. Use `auto` ou um código de duas letras; não há distinção entre maiúsculas e minúsculas.

### Seleção automática

Com `auto`, o script toma o primeiro valor não vazio de `LC_ALL`, `LC_MESSAGES` e `LANG`, nessa ordem.

Por exemplo, `ru_RU.UTF-8` seleciona o russo, enquanto `de_DE.UTF-8` seleciona a tradução do alemão de `de.lang`. O inglês é usado para `C`, `C.UTF-8`, `POSIX`, ou quando o idioma não pode ser determinado.

As mensagens também permanecem em inglês se a tradução externa selecionada não estiver disponível.

<br />

## Instalando uma tradução externa

O diretório `lang/` contém as traduções externas prontas `de.lang`, `es.lang`, `lv.lang`, `pl.lang` e `uk.lang`, além do modelo canônico `en.lang`. Para usar uma tradução externa, copie o arquivo necessário para o diretório que contém `mikrotik-backup.sh`.

Por exemplo, execute isto no diretório do script para instalar o alemão:

```bash
cp -- lang/de.lang de.lang
```

Em seguida, selecione `de` nas configurações ou especifique-o ao iniciar o script:

```bash
mikrotik-backup.sh --language=de --help
```

O nome do arquivo é composto por duas letras em latim e a extensão `.lang` — por exemplo, `de.lang`. Deve ser um arquivo legível normal, não um link simbólico.

*(N.B. A pasta `lang/` armazena a coleção de traduções. O script não as carrega automaticamente dessa pasta: o arquivo necessário deve ser colocado ao lado do próprio script.)*

O `en.lang` contém todas as 245 chaves da versão 2.3.1 e é o modelo canônico para criar traduções de terceiros. Ele não substitui o inglês integrado nem participa como idioma externo em tempo de execução. Um arquivo `ru.lang`, se criado, também não substitui o russo integrado e será ignorado.

<br />

## Escolher um idioma no Editor de Configuração

Abra o editor com:

```bash
mikrotik-backup.sh -e
```

Vá até a linha de idioma → pressione **Enter** até que o valor necessário apareça → escolha “Salvar.”

As opções percorrem este ciclo:

```text
auto → ru → en → idiomas externos detectados em ordem alfabética → auto
```

O idioma do formulário muda imediatamente. Até que você salve, isso é apenas uma prévia; “Cancelar” restaura o idioma anterior da interface. Se `--language` foi especificado no início, essa opção da CLI volta a vigorar depois que você sai do editor.

Os comentários gravados em `option.cfg` usam o idioma selecionado pelo próprio ajuste `Language`, e não uma opção temporária da CLI. Com `auto`, a configuração regional do sistema operacional também é usada para esses comentários.

Para mais informações sobre o editor, consulte [INTERACTIVE.md](INTERACTIVE.md).

<br />

## Criando e editando uma tradução

Se a tradução que você precisa ainda não existir, você mesmo poderá prepará-la. Use `lang/en.lang` da mesma versão do script e salve uma cópia como `<xx>.lang`, em que `xx` é o código de duas letras do novo idioma. O modelo da versão 2.3.1 contém todas as 245 chaves.

O formato é simples: cada mensagem tem a sua própria linha. Por exemplo, o modelo em inglês contém:

```text
msg_version_en="MikroTik Backup Script"
msg_menu_title_en="Main menu"
```

Cada chave começa com `msg_`, seguida do nome da mensagem (`version`, `menu_title`) e do sufixo do idioma `_en`.

Para um novo idioma, substitua o sufixo `_en` por `_xx` em todas as chaves e traduza apenas os valores entre aspas. Não altere os nomes das mensagens e preserve todos os placeholders exatamente. Para corrigir uma tradução existente, basta alterar o texto necessário à direita de `=`.

Você não precisa traduzir o arquivo inteiro de uma vez: as mensagens que faltarem são mostradas em inglês. O script não usa chaves novas arbitrárias.

### Regras de formato de arquivo

Salve o arquivo como UTF-8. Coloque cada valor entre aspas duplas e não use escapes desnecessários. Não adicione espaços antes de uma chave, ao redor de `=` nem depois da aspas dupla de fechamento.

Use `\"` para uma aspas duplas dentro do texto e `\\` para uma barra invertida. Outras sequências de escape, incluindo `\n` e `\t`, não são suportadas. É permitido um caractere `=` dentro das aspas.

As linhas em branco são ignoradas. O formato `.lang` não aceita comentários; um `#` entre aspas faz parte do texto. Os finais de linha do Windows (CRLF) e um BOM no início do arquivo são suportados.

Uma linha mal formada é ignorada enquanto outras traduções válidas permanecem em uso. Se uma mensagem for especificada mais de uma vez, o último item válido ganha. Os caracteres de controle e os códigos de cor do terminal não são permitidos nas traduções.

*(N.B. Um arquivo de localização é tratado como dados de texto. As variáveis não são expandidas e os comandos de shell não são executados a partir dele.)*

### Marcadores de posição nas mensagens

Algumas strings contêm valores em chaves, por exemplo:

```text
msg_log_batch_device_position_en="Processing device {index} of {total}"
```

No momento da execução, o script substitui `{index}` e `{total}` pelo número do dispositivo e o número total de dispositivos. Não traduza estes marcadores: preserve cada marcador de posição da string de origem exatamente uma vez. Você poderá alterar a sua posição dentro da frase.

Se os marcadores de posição forem inválidos, a mensagem em inglês será usada no lugar dessa string.

Depois de salvar o arquivo, verifique a tradução na ajuda e no menu interativo com esse idioma selecionado. Os motivos pelos quais uma tradução pode não ser carregada estão explicados em [Resolução de Problemas](TROUBLESHOOTING.md#language-problems).
