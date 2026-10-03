# Interface interativa

[Índice](../README_PT-BR.md)

## Menu principal

O menu principal permite configurar o script, criar backups, preparar uma lista de dispositivos ou abrir a ajuda integrada. Para abri-lo, execute:

```bash
mikrotik-backup.sh -i
```

| Item | O que abre ou faz |
|---|---|
| `1` | BackUP Master para trabalhar com um único dispositivo |
| `2` | backup em lote usando a lista de dispositivos |
| `3` | Editor de configuração para criar ou alterar `option.cfg` |
| `4` | Referência da opção CLI |
| `5` | Instruções para usar o script |
| `6` | Sair para o console |

O item `2` aparece quando `devicelist.cfg` contém pelo menos um item elegível. Se a lista ainda não existir ou não tiver dispositivos adequados, o item está oculto. Os números dos outros itens não mudam.

Após um backup em lote, o resultado é exibido e o script retorna você para o console.

*(N.B. Executar o script sem opções não abre o menu principal. Se `option.cfg` estiver ausente ou não tiver configurações utilizáveis, o Editor de Configuração será aberto; com as configurações preparadas, o script passará para o backup em lote.)*

<br />

## Controles

Mova-se pelos itens com as teclas **Up** e **Down** e selecione um item com **Enter**. Se uma ação tiver um número ao lado, você também pode escolhê-la com a tecla numérica correspondente.

No editor e no BackUP Master, uma descrição do campo selecionado aparece acima da lista. Se nem todas as linhas couberem na janela do terminal, a lista rolará à medida que você usar as teclas de seta. O cabeçalho e a descrição permanecerão visíveis, e a linha selecionada ficará dentro da janela.

As ações de salvar, executar e sair estão localizadas no final da mesma lista. As linhas ocultas não estão disponíveis sob as configurações selecionadas e são ignoradas durante a navegação.

É necessário um terminal e o utilitário `stty`. Tanto a entrada padrão como a saída padrão devem estar conectadas a um terminal. As telas principais requerem uma largura de pelo menos 46 colunas; as instruções incorporadas requerem 80. Se a janela for muito pequena, o script informa o erro `31`; aumente a janela e execute-a novamente.

<br />

## Editor de Configuração

Abra o editor através do item `3` no menu principal ou diretamente com:

```bash
mikrotik-backup.sh -e
```

Se `option.cfg` já estiver preparado, o formulário é preenchido com as suas configurações. Se o arquivo ainda não existir, os valores padrão são usados.

O editor permite escolher o idioma, a origem da lista de dispositivos e as configurações de backup, armazenamento, arquivamento mensal e logs. As configurações e os valores aceitos estão descritos em [OPTIONS.md](OPTIONS.md).

### Mudar as configurações

Altere os seletores Sim/Não, o tipo de backup, o formato de exportação e o nível de log pressionando **Enter** na linha correspondente. A seleção de um caminho ou do dia do arquivamento mensal abre um campo para inserir o valor.

O campo “Use backups incrementais” (`UseIncremental`) vem imediatamente após o tipo de backup. “Sim” permite comparação; “Não” mantém cada novo backup válido sem compará-lo com o anterior.

Para arquivar mensalmente, insira `false` para desativá-lo ou um número de `1` até `28`. O formulário mostra o estado desativado como “Não” e um estado ativado como o dia selecionado do mês.

Os campos que não se aplicam ao modo escolhido ficam desativados. Por exemplo, quando apenas `.rsc` está selecionado, a criptografia do backup binário e as operações de limpeza que o precedem não estão disponíveis; quando apenas `.backup` está selecionado, as opções de exportação de texto ficam indisponíveis. A mudança de modo redefine as opções inaplicáveis com seus valores padrão.

A senha de criptografia é inserida e exibida como asteriscos.

### Salvando e cancelando

Escolha as configurações necessárias → vá até “Salvar” → pressione **Enter**. As configurações selecionadas são usadas para criar ou substituir `option.cfg`.

Até salvar, as alterações existem apenas na memória. O “Cancelar” deixa o arquivo existente inalterado. Se você tiver mudado alguma coisa, o editor lhe pede para confirmar que deseja descartar essas alterações.

Um editor aberto pelo menu principal retorna a ele. Quando você executa o editor separadamente com `-e`, fechá-lo leva você de volta ao console.

*(N.B. `SshPort`, `IgnoreOxiAccess`, `encrypt_type`, `Login` e `Password` não são mostrados no formulário. As suas configurações e regras de preservação estão cobertas em [OPTIONS.md](OPTIONS.md).)*

### Escolher um idioma

Na linha do idioma, cada pressionamento de **Enter** seleciona a próxima opção:

```text
auto → ru → en → idiomas externos detectados em ordem alfabética → auto
```

O idioma do formulário muda imediatamente para que você possa visualizá-lo. “Salvar” escreve o idioma selecionado para `option.cfg`; cancelar restaura o idioma anterior da interface. Se `--language` foi explicitamente dado na inicialização, essa opção volta a vigorar depois de você deixar o editor.

A configuração de traduções externas está descrita em [LOCALIZATION.md](LOCALIZATION.md).

<br />

## BackUP Master

BackUP Master permite que você preencha as configurações de um dispositivo, crie seus backups, salve o dispositivo na lista ou prepare um comando para ser executado a partir do console.

Escolha o item `1` no menu principal ou execute:

```bash
mikrotik-backup.sh -b
```

Ao contrário do Editor de Configuração, o BackUP Master não preenche seus campos comuns a partir de `option.cfg`. Os valores vêm dos padrões internos e das opções passadas explicitamente pela CLI. `UseIncremental` é a exceção: seu valor vem do arquivo de opções ou assume `true` quando essa opção está ausente.

Os itens existentes de `devicelist.cfg` também não são carregados no formulário. Você preenche o nome, endereço, login e senha do dispositivo que você escolheu.

### Campos do BackUP Master

Os campos aparecem na seguinte ordem. Estes são os seus nomes na interface em inglês:

| Campo | Finalidade |
|---|---|
| Device name | Nome usado na lista de dispositivos e nos backups quando a obtenção da identidade do RouterOS está desativada |
| IP address | Endereço IP do dispositivo ou nome DNS |
| User | Usuário do dispositivo RouterOS |
| Password | Senha do dispositivo RouterOS |
| SSH port | Porta de conexão; `22` por padrão |
| Backup type | `.rsc` configuração, binário `.backup`, ou ambos os formatos |
| Use incremental backups | Comparar um novo backup com o anterior ou mantê-lo sem comparação |
| Export format | `compact`, `terse` ou `verbose` |
| Sensitive data | Incluir valores sensíveis na exportação de texto |
| Encryption password | Criptografar o backup binário; um valor vazio desativa a criptografia |
| Clear DNS cache | Limpar o cache DNS antes de criar um backup binário |
| Clear console history | Limpar o histórico do shell antes de criar um backup binário |
| Backup directory | Pasta em que os arquivos são gravados |
| This is a network directory | Valor `UseNetFolder`; verificação de montagem aplica-se em modo lote |
| Use RouterOS Identity | Recuperar o nome do dispositivo em vez de usar o nome introduzido no formulário |

Os seletores, o tipo de backup e o formato de exportação são alterados com **Enter**; outros valores são inseridos em seus campos. Ambas as senhas são mascaradas com asteriscos.

**Atenção!!!**
Os dados sensíveis na exportação de texto, a limpeza do cache DNS e a limpeza do histórico do shell antes de um backup binário estão ativados por padrão. Escolha as configurações necessárias antes de executar o backup.

O BackUP Master não tem campos para `MonthlyArchive`, `LogLevel` nem `MainLogPath`. O arquivamento mensal é desativado quando um backup é executado pelo BackUP Master, enquanto as configurações de log vêm de `option.cfg` junto com qualquer opção da CLI passada para a execução.

### 1. Executar backup

Preencha o endereço, o login e a senha; confira as configurações de porta e backup → escolha “1. Executar backup”.

Quando a obtenção da identidade do RouterOS estiver ativa, o nome do backup será obtido do dispositivo. Quando estiver desativada, preencha o campo “Nome do dispositivo”.

Um backup de dispositivo único é iniciado. Ao final, o resultado e seu código são apresentados, e o script retorna ao console. Ele não volta ao formulário do BackUP Master, tenha o backup sido bem-sucedido ou não.

Os locais dos arquivos e as regras de retenção estão descritos em [BACKUPS.md](BACKUPS.md); as mensagens de progresso são explicadas em [LOGGING.md](LOGGING.md).

### 2. Salvar dispositivo para devicelist.cfg

O nome, endereço, login, senha e porta SSH do dispositivo são necessários para salvar. Até que todos os campos necessários sejam preenchidos, a ação correspondente permanece indisponível.

BackUP Master cria o arquivo, adiciona um novo item ou atualiza um item existente com o mesmo nome. Se os itens estiverem em conflito ou se a gravação falhar, a lista anterior permanece inalterada. O formulário permanece aberto após a gravação.

**Apenas os dados do dispositivo são salvos em `devicelist.cfg`.** Configurações de backup do formulário não são gravadas em `option.cfg`, e esta ação não inicia um backup.

*(N.B. A porta `22` é salva como um campo vazio. Em uma execução posterior em lote, tal entrada usa `SshPort` da configuração do script. Uma porta não padrão é escrita explicitamente.)*

O formato da lista e as regras de atualização são descritos em [DEVICES.md](DEVICES.md).

### 3. Copiar o comando do console

O BackUP Master cria um comando de execução a partir do formulário preenchido e o envia para a área de transferência. Nenhum backup é iniciado, e o BackUP Master termina retornando ao console.

Este recurso requer GNU `base64` com suporte `--wrap=0` e um terminal que suporta OSC 52. Se você trabalhar por meio de um multiplexador de terminal, ele também deverá repassar o comando. Se a transferência da área de transferência não for suportada, o comando não será exibido em texto claro na tela.

Os parâmetros que correspondem aos valores internos podem ser omitidos do comando. Quando você o executar mais tarde, as configurações de `option.cfg` ainda serão aplicadas; portanto, o resultado poderá diferir da execução do backup diretamente pelo BackUP Master.

A configuração `UseIncremental` não está incluída no comando: não tem a opção CLI dedicada. Quando o comando copiado é executado, o valor vem de `option.cfg` ou dos padrões.

*(N.B. O comando colocado na área de transferência contém senhas. Lembre-se disso ao usar o histórico da área de transferência e ao colar o comando em um shell. Para obter mais detalhes, veja [SECURITY.md](SECURITY.md).)*

### 0. Voltar ao Menu Principal

O resultado depende de como você abriu BackUP Master:

| Como foi aberto | Onde você volta |
|---|---|
| No menu principal com `-i` | Menu principal |
| Como uma execução separada com `-b` | Console |

Os valores do formulário que não foram salvos são descartados. Um item já salvo em `devicelist.cfg` permanece lá.

<br />

## Ajuda e instruções

O item `4` no menu principal abre a referência das opções de linha de comando, enquanto o item `5` abre instruções breves para usar o script.

Se o texto não couber verticalmente, ele será dividido em páginas. Percorra-as com **PageUp / PageDown**; o número da página atual será mostrado na tela.

O item `0` retorna ao menu principal, e o item `6` sai do script. Você pode selecionar estas ações com as teclas de seta e **Enter**, ou com a tecla de número correspondente.

A mesma ajuda da CLI está disponível diretamente no console:

```bash
mikrotik-backup.sh -h
```
