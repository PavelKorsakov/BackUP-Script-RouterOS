# Segurança

[Índice](../README_PT-BR.md)

## Contas

O script não necessita de privilégios **root**. Um usuário comum só precisa de acesso aos arquivos de configuração e permissão para gravar no armazenamento e logs selecionados.

A criação de um usuário dedicado **bsmt** e a configuração do script para ser executado nessa conta são explicadas em [INSTALL.md](INSTALL.md#executando-o-script-automaticamente).

No dispositivo RouterOS, é também aconselhável criar um usuário de backup dedicado e restringir o seu login ao endereço IP do host que executa o script. As permissões dessa conta devem permitir as operações selecionadas: recuperar a configuração, criar e baixar backups, excluir arquivos temporários e realizar quaisquer operações de limpeza habilitadas.

<br />

## Conexão com o RouterOS

O script se conecta via SSH usando autenticação por senha. Chaves SSH e o agente não são usados. Os arquivos são recuperados com o protocolo legado SCP, ou seja, `scp -O`.

O script usa suas próprias configurações de conexão. Ele não lê a configuração `~/.ssh/config` do usuário ou do sistema SSH porque o cliente é iniciado com `-F /dev/null`. O agente, X11 e o encaminhamento de porta estão desativados.

**Atenção!!! A verificação da chave do host do servidor está desativada.**

O perfil atual usa estas configurações:

```text
StrictHostKeyChecking=no
UserKnownHostsFile=/dev/null
GlobalKnownHostsFile=/dev/null
CheckHostIP=no
UpdateHostKeys=no
```

Os arquivos `known_hosts` habituais não são lidos nem alterados. Portanto, o script não verifica se o servidor que responde é o dispositivo esperado ou um impostor. Leve isso em conta ao organizar o acesso de rede aos seus roteadores.

<br />

<a id="secrets"> </a>
## Senhas ao iniciar o script

Uma senha passada por `--password` ou `-p=` torna-se parte do comando de execução. Ela pode ficar visível nos argumentos do processo e ser gravada no histórico do shell. O mesmo se aplica a uma senha de criptografia passada por `--encrypt`.

### Inserir senhas através de BackUP Master

Para evitar colocar a senha SSH na linha de comando, inicie BackUP Master:

```bash
mikrotik-backup.sh -b
```

Preencha as credenciais do dispositivo no formulário e escolha a ação necessária. Ambas as senhas são exibidas como asteriscos, e os valores inseridos no formulário não entram no histórico de comandos do shell.

Ao conectar-se, o próprio script passa a senha SSH para `sshpass` através de um descritor de arquivo (`-d`), não através do argumento `sshpass -p` ou da variável ambiente `SSHPASS`.

### A senha de criptografia .backup

A senha de criptografia é incluída no comando do RouterOS passado ao processo filho `ssh`. Portanto, um usuário do host com permissão suficiente para inspecionar os argumentos dos processos pode vê-la enquanto um backup binário é criado.

Inserir a senha pelo BackUP Master ou armazená-la em `option.cfg` não altera a forma como ela é passada. A criptografia do arquivo não protege contra um administrador do próprio host de backup.

### Copiar um comando de console

A ação “Copiar comando do console” em BackUP Master envia um comando contendo as credenciais de conexão – e, se um estiver definido para um backup binário, a senha de criptografia – para a área de transferência.

Tenha isso em mente ao usar o histórico da área de transferência e ao colar o comando em um shell. Mascarar uma senha com asteriscos no formulário não significa que ela esteja mascarada no comando copiado.

<br />

## Arquivos que contêm dados sensíveis

| Arquivo | O que pode conter |
|---|---|
| `devicelist.cfg` | Endereços de dispositivos, logins e senhas SSH em texto simples |
| `option.cfg` | Valores compartilhados de `Login` e `Password` e a senha de criptografia `encrypt` |
| `.rsc` e `.backup` | Configuração do dispositivo, senhas e outros dados sensíveis |
| ZIP mensal | Os mesmos backups e logs coletados em um arquivo |

Não coloque arquivos de configurações de trabalho ou backups em um repositório público ou diretório acessível publicamente.

### Dados sensíveis em arquivos .rsc

Por padrão, `show_sensitive=true`, assim os valores sensíveis estão incluídos na exportação de texto. Para desabilitar isso, defina o seguinte em `option.cfg`:

```ini
show_sensitive=false
```

Mesmo assim, o arquivo ainda é uma configuração do seu dispositivo: endereços, estrutura de rede, comentários e outras strings fornecidas pelo usuário não desaparecem dele.

### Criptografia de backup binário

Por padrão, `encrypt` está vazio e `.backup` é salvo sem criptografia. Para habilitá-lo, defina uma senha no arquivo de opções ou no campo BackUP Master correspondente:

```ini
encrypt=MySuperPassword
```

O algoritmo AES-SHA256 é usado. Ele criptografa **apenas `.backup`**, não `.rsc`, `option.cfg`, a lista de dispositivos, logs ou o ZIP em si. O acesso ao arquivo mensal deve ser restrito tão cuidadosamente quanto o acesso aos arquivos dentro dele.

<br />

## Permissões de arquivo e armazenamento

O script é executado com `umask 077`. Os diretórios de armazenamento locais que ele cria recebem o modo `0700`, enquanto `option.cfg` e `devicelist.cfg` são gravados com o modo `0600` quando salvos pelo programa.

O proprietário e as permissões das pastas de armazenamento existentes criadas pelo administrador não são alteradas automaticamente. Se você preparar uma pasta manualmente, você mesmo deverá configurar o seu acesso.

A pasta local de arquivamento mensal, `archive/`, deve ter o modo `0700` e pertencer ao usuário que executa o script. Esse requisito também se aplica a uma pasta existente. Os arquivos compactados locais criados pelo script têm o modo `0600`.

No modo em lote, quando o armazenamento de rede verificado é usado com `UseNetFolder=true`, o servidor NAS pode determinar os proprietários e permissões de objetos de arquivo. Uma diferença em relação aos valores locais não impede o arquivamento. Configure o acesso ao armazenamento de rede através do seu sistema operacional e NAS.

Exemplos de preparação de diretórios e concessão de acesso ao usuário **bsmt** são fornecidos em [INSTALL.md](INSTALL.md).

*(N.B. O script lê sua configuração, lista de dispositivos, traduções e quaisquer configurações Oxidized que ele usa como dados; ele não os executa como scripts de shell.)*

<br />

## Alterações feitas no dispositivo

Por padrão, o cache DNS e o histórico do console do RouterOS são limpos antes da criação de um backup binário. Se você não precisar dessas ações, desative-as em `option.cfg`:

```ini
clear_dns_cache=false
clear_console_history=false
```

Você pode desativar as mesmas funcionalidades através do Editor de Configuração, BackUP Master, ou as opções CLI correspondentes. Estas operações de limpeza não são executadas quando apenas `.rsc` é recuperado.

<br />

## Registros e compartilhamento de informações de diagnóstico

O nível detalhado `LogLevel=3` adiciona informações sobre as etapas de processamento; ele não registra senhas ou comandos completos de conexão.

Os diagnósticos SSH processados mascaram os valores exatos conhecidos do endereço, login, senha SSH e senha de criptografia. Isso não higieniza o conteúdo do backup nem garante a remoção de todos os segredos de um texto arbitrário.

Os arquivos temporários que contenham diagnósticos não processados podem incluir dados sensíveis. São criados com o modo `0600` e removidos durante a limpeza normal.

Antes de enviar logs, capturas de tela ou saída de comando para outras pessoas, inspecione seu conteúdo. O conteúdo completo de `devicelist.cfg`, uma lista de processos ou conteúdo da área de transferência podem revelar dados ausentes do registro normal.

Para mais informações sobre entradas de log, consulte [LOGGING.md](LOGGING.md); para ajudar a investigar erros, ver [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

<br />

## Execuções simultâneas

Execuções do mesmo usuário que usam o mesmo `BackupRoot` empregam bloqueios:

| Execuções simultâneas | O que acontece? |
|---|---|
| Uma execução em lote e outra execução em lote ou de um único dispositivo | A segunda execução não adquire o bloqueio |
| Duas execuções de um único dispositivo para o mesmo dispositivo | A segunda execução não adquire o bloqueio |
| Execuções de um único dispositivo para dispositivos diferentes | Podem ser executadas simultaneamente |

Se o bloqueio estiver ocupado, o script sai com o código `32`. As raízes de armazenamento diferentes não são coordenadas como uma única área de armazenamento quando uma está aninhada dentro da outra.

Os arquivos de bloqueio são mantidos em `/tmp/mikrotik-backup-${UID}/` e permanecem após o final do script. A sua presença sozinha não significa que o script ainda esteja em execução.

**Não exclua esses arquivos para “limpar um bloqueio obsoleto”.** O bloqueio está associado a um descritor de arquivo aberto pelo processo, e não à mera existência do arquivo. Esses bloqueios também não protegem os dados contra outros programas que os modifiquem diretamente.

<br />

## Testes de restauração

Verificar o checksum do script e recuperar um arquivo de backup com sucesso não são substitutos para testes de restauração.

O script em si não restaura o RouterOS. Você deve verificar separadamente se os backups podem ser usados em um dispositivo adequado e decidir por quanto tempo mantê-los. Para obter mais informações, consulte [BACKUPS.md](BACKUPS.md).
