# Lista de dispositivos

[Índice](../README_PT-BR.md)

## Dispositivos para fazer backup: o arquivo `devicelist.cfg`

Como o nome sugere, `devicelist.cfg` lista os dispositivos para backups em lote e os dados necessários para se conectar a eles.
Coloque o arquivo diretamente ao lado de `mikrotik-backup.sh`.
Você pode criar `devicelist.cfg` manualmente ou por meio do BackUP Master.
Uma terceira opção é útil quando o Oxidized é executado no mesmo servidor. Depois de adicionar as configurações correspondentes ao arquivo de opções,
o script cria dinamicamente `devicelist.cfg` em cada execução usando os dados necessários dos arquivos de configuração do Oxidized.

<br />

## Criando e editando a lista

Para criar a lista através de BackUP Master, execute:

```bash
mikrotik-backup.sh -b
```

Preencha o nome do dispositivo, endereço, login, senha e porta SSH → selecione **2. Salvar dispositivo em devicelist.cfg**.
O BackUP Master cria o arquivo com a entrada necessária ou adiciona ou atualiza uma entrada no arquivo existente.

Você pode editar a lista pronta em um editor de texto comum. O BackUP Master não carrega as entradas existentes no formulário.

*(N.B. Quando BackUP Master salva a porta `22`, ele grava um campo vazio. Um backup em lote usa `SshPort` da configuração do script para essa entrada. Uma porta não padrão é gravada explicitamente.)*

<br />

## Formato do arquivo

Grave cada dispositivo em uma linha separada. Separe os campos com um caractere **TAB**, não com espaços. Os campos aparecem na seguinte ordem:

| Posição | Campo | Finalidade |
|---|---|---|
| 1 | Nome | Nome do dispositivo; necessário |
| 2 | Endereço | Endereço IP do dispositivo ou nome DNS; requerido |
| 3 | Login | Usuário do dispositivo RouterOS; quando omitido, é herdado de `Login` em `option.cfg` |
| 4 | Senha | Senha do dispositivo RouterOS; quando omitida, é herdada de `Password` em `option.cfg` |
| 5 | Porta | Porta SSH de `1` a `65535`; quando omitida, é herdada de `SshPort`, cujo padrão é `22` |
| 6 | Marcador do dispositivo | `MikroTik`; pode estar vazio. Sem distinção entre maiúsculas e minúsculas |

Os campos a partir do sétimo não são usados. As entradas com um marcador de dispositivo diferente são ignoradas.

### Lista de exemplos

Os campos neste exemplo são separados por caracteres TAB reais:

```text
Router-A	xxx.xxx.xxx.1	UserName	MySuperPassword	1922	MikroTik
Router-B	xxx.xxx.xxx.2	UserName	MySuperPassword		MikroTik
```

A porta é omitida da segunda linha: dois caracteres TAB aparecem entre a senha e `MikroTik`. Substitua os endereços e credenciais por seus próprios.

### Acesso compartilhado, senha e porta

Se todos os seus dispositivos usarem as mesmas credenciais, especifique-as uma vez em `option.cfg`:

```ini
Login=UserName
Password=MySuperPassword
SshPort=22
```

Então `devicelist.cfg` só precisa do nome e endereço de cada dispositivo:

```text
Router-A	xxx.xxx.xxx.1
Router-B	xxx.xxx.xxx.2
```

As credenciais especificadas na entrada de um dispositivo substituem os valores compartilhados.

*(N.B. O arquivo da lista de dispositivos contém senhas. Restrinja o acesso tal como descrito em [SECURITY.md](SECURITY.md).)*

<br />

## Como a lista é lida

Linhas em branco e linhas cujo primeiro caractere não-branco é `#` são ignoradas. Coloque comentários em linhas separadas; um `#` dentro de um campo é parte do seu valor.

Os espaços iniciais e finais são removidos do nome, endereço, porta e marcador. O login e a senha são lidos literalmente, incluindo espaços e aspas. Arquivos com terminações de linha do Windows (CRLF) são aceitos.

Se uma linha — uma entrada de dispositivo — violar a sintaxe necessária, o script a ignora durante a execução e emite um aviso de que a entrada é inválida.

Se uma linha estiver duplicada por qualquer motivo — isto é, se os quatro parâmetros de conexão (**endereço, login, senha e porta**) coincidirem —, o script se conectará ao dispositivo apenas uma vez, usando os dados da última entrada.
Se conexões diferentes tiverem o mesmo nome, a primeira entrada utilizável será usada e a entrada conflitante será ignorada.

<br />

<a id="device-names"> </a>
## Nomes dos dispositivos

O nome é usado nos nomes dos arquivos de backup e, no modo em lote, no subdiretório do dispositivo.
A configuração `UseIdentityName` em `option.cfg` determina de onde vem o nome:

| Valor | Fonte do nome |
|---|---|
| `true` (por padrão) | O valor de identidade no próprio dispositivo RouterOS |
| `false` | O nome de `devicelist.cfg`, o campo BackUP Master, ou `--device-name` em uma execução de um único dispositivo pela CLI |

### Nome entre parênteses

Se o nome original contém parênteses, o script usa o conteúdo do primeiro grupo completo e não vazio. Se não existir tal grupo, ele usa o nome inteiro.

| Nome original | Nome do backup |
|---|---|
| `Филиал (Core East)` | `Core_East` |
| `Branch () (Core)` | `Core` |
| `Филиал (Core (East) West)` | `Core_East_West` |

### Caracteres permitidos

O nome final mantém letras, incluindo letras cirílicas, dígitos, pontos, hífens e sublinhados. Espaços e caracteres inválidos são substituídos por `_`. Sublinhados repetidos, iniciais ou finais são removidos, assim como pontos no início ou no fim do nome.

Por exemplo, `ЦОД Москва №1` torna-se `ЦОД_Москва_1`.

O nome final deve ser **de 1 a 32 caracteres** de comprimento. Um nome longo não é truncado; causa um erro. Os nomes reservados `CON`, `PRN`, `AUX`, `NUL`, `COM1`–`COM9` e `LPT1`–`LPT9` não são permitidos.

Os nomes finais devem ser únicos sem diferenciar maiúsculas de minúsculas: `Router-A` e `router-a` são considerados iguais. Um segundo dispositivo com esse nome é ignorado durante a execução atual.

*(N.B. A alteração do nome final também altera o subdiretório do dispositivo. Os backups antigos não são movidos automaticamente.)*

<br />

## Importação do Oxidized

Se você já mantiver uma lista de dispositivos em Oxidized, o script poderá obtê-la a partir daí. Adicione o seguinte a `option.cfg`:

```ini
UseOxidized=true
OxidizedHome=/var/lib/oxidized
IgnoreOxiAccess=true
```

Defina `OxidizedHome` para a pasta que contém `config` e `router.db`. O script compila `devicelist.cfg` a partir deles. Ele não modifica os arquivos Oxidized.

*(N.B. A importação substitui `devicelist.cfg`; não estende o arquivo. As adições manuais são perdidas da próxima vez que uma atualização Oxidized tiver sucesso.)*

### Configuração da fonte

A configuração Oxidized deve usar a fonte `csv` com um delimitador de um caractere. `source.csv.map` determina a ordem da coluna, com numeração a começar em zero:

| Campo do mapa | Valor utilizado |
|---|---|
| `name` | Nome do dispositivo; coluna exigida |
| `ip` | Endereço do dispositivo; se omitido, o valor `name` é usado |
| `username` | Login; se omitido, o `Login` compartilhado de `option.cfg` é usado |
| `password` | Senha; se omitido, o `Password` compartilhado de `option.cfg` é usado |
| `port` | Porta SSH; se omitido, `SshPort` é usado |
| `model` | Modelo do dispositivo; se a coluna estiver ausente, é usado o parâmetro raiz `model` |

As regras `model_map` são aplicadas até a primeira correspondência. Só são importados os dispositivos cujo modelo final é `routeros`. Se a coluna `model` existir, o parâmetro raiz não substitui os valores vazios nessa coluna.

Os dados são sempre lidos a partir de `<OxidizedHome>/router.db`. O parâmetro Oxidized `source.csv.file` não altera este caminho.

### Se a importação falhar

Se os arquivos do Oxidized não estiverem disponíveis, se o formato não for aceito ou se nenhum dispositivo adequado for encontrado, o `devicelist.cfg` anterior será preservado.

Com `IgnoreOxiAccess=true`, o script poderá usar a lista válida anterior. Com `false`, nenhum backup será feito a partir da lista antiga.

Um erro de importação afeta o resultado da execução, mesmo que o processamento de backup com a lista anterior tenha sucesso.

Veja [Resolução de Problemas](TROUBLESHOOTING.md) para obter mais detalhes sobre a lista e os erros de importação.
