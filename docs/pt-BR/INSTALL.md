# Instalação

[Índice](../README_PT-BR.md)

## Requisitos do host

O script requer Linux com GNU Bash **4.4 ou posterior** e os utilitários de arquivos GNU padrão.
O script em si não requer compilação, Python, um contêiner, ou um banco de dados.
No entanto, exige os utilitários enumerados em [Dependências](#dependências).

Os nomes dos dispositivos requerem uma configuração regional **`C.UTF-8`** funcional para contar caracteres multibyte, reconhecer letras e alterar entre maiúsculas e minúsculas.
O script verifica estes recursos antes de trabalhar com dispositivos. Este é um requisito do sistema, não um script separado chamado `C.UTF-8`.

Naturalmente, o host já deve ter acesso à rede ao serviço RouterOS SSH e permissão de escrita para o armazenamento selecionado.

**Altamente recomendado!!!**
O script se conecta a dispositivos RouterOS sobre SSH usando autenticação de senha, não autenticação baseada em chaves.
*(Veja [SECURITY.md](SECURITY.md) para a política de transporte exata.)*
Você deve, portanto, criar um usuário dedicado no dispositivo e restringir o login desse usuário pelo endereço IP do host que executa este script.

<br />

## Dependências

### Necessário para backups

**Todos** os utilitários a seguir são necessários para criar backups:

| Utilitários | Finalidade |
|---|---|
| `ssh`, `scp`, `sshpass` | Conectar-se a RouterOS, executar comandos e recuperar arquivos |
| GNU `timeout`, `sleep` | Limitar o tempo de operação e inserir pausas |
| `sha256sum` | Calcular somas de verificação |
| `realpath` | Resolver caminhos absolutos |
| `flock` | Bloqueio que impede o conflito entre execuções simultâneas |

**Se um utilitário necessário estiver faltando, o script reporta dependências insatisfeitas
e interrompe a tentativa de backup.
O código de erro de dependência é `30`. Esse é o comportamento esperado.**

A lista é a mesma para backups de dispositivo único e em lote, independentemente de
o script cria `.rsc`, `.backup`, ou ambos os formatos.

Ter apenas comandos com esses nomes não é suficiente. O OpenSSH instalado deve oferecer suporte às opções usadas pelo script, incluindo o modo SCP legado selecionado por `scp -O`.
GNU `timeout` deve suportar `--signal` e `--kill-after`.
Essas capacidades são verificadas localmente, sem conexão com o roteador.

<br />

### Necessário para recursos específicos

Estas ferramentas não fazem parte da lista geral de requisitos. Elas são necessárias
quando o recurso correspondente é usado.

| Característica | Requisito | O que acontece se estiver ausente |
|---|---|---|
| Modo Lote com `UseNetFolder=true` | `findmnt` | O backup não inicia neste modo; erro de dependência `30` |
| Uma execução em que o arquivamento mensal está previsto | Info-ZIP `zip`, `unzip`, GNU `mv` | A execução para durante a verificação de dependências, antes de qualquer backup; erro `30` |
| Menu interativo, Editor de Configuração e BackUP Master | `stty` e um terminal de entrada e saída padrão | A tela interativa não abre; erro de terminal `31` |
| **Copiar comando do console** em BackUP Master | GNU `base64` com suporte `--wrap=0` | O comando não pode ser copiado; erro `30` |

Por exemplo, um `zip` ausente não impede uma execução de backup normal quando o arquivamento mensal não é devido.
Um `base64` ausente não impede que backups sejam criados.
*(N.B. É necessário quando você escolhe **Copiar o comando do console**.)*

A verificação geral de dependências é executada antes de um backup, não toda vez que o script é aberto.
Consequentemente, ajuda, informações de versão ou o menu podem estar disponíveis mesmo quando utilitários de backup não estão instalados.

<br />

### Ambiente de base Linux

O script também assume que os comandos comuns do sistema para trabalhar com arquivos
e diretórios estão disponíveis, incluindo `date`, `stat`, `mkdir`, `cp`, `ln` e `rm`.

Eles fazem parte do ambiente básico do sistema operacional. A lista de dependências
verificada antecipadamente não inclui todos os comandos externos usados pelo
script. Se um comando do sistema base estiver faltando, a operação correspondente pode falhar
em vez de produzir uma mensagem de dependência não satisfeita.

<br />

### Instalando os pacotes necessários em Debian/Ubuntu

Este exemplo instala as ferramentas necessárias e as ferramentas opcionais listadas acima:
*(N.B. Aqui e abaixo, pressupõe-se que o usuário tenha privilégios de administrador.)*

```bash
sudo apt-get update
sudo apt-get install bash openssh-client sshpass coreutils util-linux zip unzip
```

<br />

## Obtendo os arquivos de script

O método principal de instalação da versão 2.3.1 é o asset completo do GitHub Release `mikrotik-backup-2.3.1.zip`. Ele é extraído diretamente no diretório de instalação, sem um diretório contêiner adicional.
*(N.B. Nos exemplos que colocam arquivos sob `/opt`, execute os comandos com permissão para criar e gravar nesse diretório.)*

### Opção 1: Pacote completo da versão

Baixe `mikrotik-backup-2.3.1.zip` do GitHub Release do MikroTik Backup Script 2.3.1 e execute:

```bash
mkdir -m 700 -- /opt/mikrotik-backup
unzip -q -- mikrotik-backup-2.3.1.zip -d /opt/mikrotik-backup
cd -- /opt/mikrotik-backup
sha256sum --check SHA256SUMS
```

Após a extração, a estrutura pronta para uso será:

```text
mikrotik-backup.sh
SHA256SUMS
README.md
lang/
docs/
```

Se a verificação da soma de verificação falhar, não execute o script até encontrar a causa.

<br />

### Opção 2: Instalação autônoma mínima

Baixe os assets `mikrotik-backup.sh` e `SHA256SUMS` da mesma versão para um diretório protegido, verifique-os e torne o script executável:

```bash
mkdir -m 700 -- /opt/mikrotik-backup
cd -- /opt/mikrotik-backup
# Baixe os dois assets do Release neste diretório.
sha256sum --check SHA256SUMS
chmod 700 -- mikrotik-backup.sh
```

Para um idioma externo de runtime, use o pacote completo ou obtenha o arquivo `.lang` correspondente no código-fonte com tag da mesma versão.

<br />

### Opção avançada: Git ou arquivo do código-fonte

Um clone Git ou o arquivo **Code → Download ZIP** deste repositório também contém a árvore-fonte completa do produto. A estrutura útil na raiz é:

```text
mikrotik-backup.sh
README.md
lang/
docs/
```

`SHA256SUMS` é um asset do Release e pode não existir em um checkout do código-fonte. Para instalação normal, o pacote versionado do Release continua recomendado porque inclui o arquivo de checksum e corresponde exatamente à versão publicada.

<br />

## Arquivos ao lado do script

Depois de extrair o pacote completo do Release, o diretório selecionado conterá o script e os arquivos associados:

```text
mikrotik-backup/
├── mikrotik-backup.sh
├── SHA256SUMS
├── README.md
├── lang/
└── docs/
```

| Arquivo ou diretório | Finalidade |
|---|---|
| mikrotik-backup.sh | O próprio script de backup |
| SHA256SUMS | Somas de verificação usadas para conferir os arquivos baixados |
| README.md | Descrição do produto e links para a documentação detalhada |
| lang/ | Arquivos de localização. Copie o arquivo de idioma necessário desta pasta para a pasta de script. |
| docs/ | Documentação detalhada de instalação, configuração e uso |

Para a execução propriamente dita, somente `mikrotik-backup.sh` é necessário.
Para alterar as configurações, crie **option.cfg** e coloque-o ao lado do script.
Se você pretende consultar e fazer backup de vários dispositivos em sequência, também crie **devicelist.cfg** ao lado do script.
É necessário um arquivo de localização chamado `<xx>.lang` se quiser menus e registros no seu próprio idioma. Coloque-o na mesma pasta que `mikrotik-backup.sh`.
Russo e inglês não requerem arquivos de localização separados porque ambos são incorporados no script.

**No modo interativo, o script pode criar e salvar:**
A lista de dispositivos — **devicelist.cfg** — por meio do BackUP Master.
O arquivo de configuração — **option.cfg** — por meio do Editor de Configuração.
Você também pode prepará-los:
*O formato da lista de dispositivos TSV é descrito em detalhe em [DEVICES.md](DEVICES.md).*
*O formato `Key=value` do arquivo de configuração é descrito em detalhe em [OPTIONS.md](OPTIONS.md).*

<br />

## Preparação de armazenamento e logs

Com as configurações de backup padrão, o script cria um diretório `./backups` ao lado do próprio script e armazena ali os backups dos dispositivos.
A única diferença entre os modos é que uma execução de um único dispositivo coloca os arquivos criados diretamente em `./backups`, enquanto o modo em lote cria um subdiretório com o nome de dispositivo em `./backups` e armazena os backups do dispositivo lá.

O script cria os diretórios de armazenamento necessários com as permissões apropriadas.
*(Ele não altera automaticamente o proprietário nem o modo de acesso de diretórios existentes criados pelo administrador.)*

Por padrão, o log principal do script, `main.log`, é armazenado em `./backups`.
No modo em lote, um registro de dispositivo é armazenado no subdiretório desse dispositivo.

Você também deve saber que, quando seu diretório de backup está no armazenamento de rede,
o script pode verificar a disponibilidade desse diretório durante o processamento em lote. Esta opção está desabilitada por padrão e deve ser configurada antes de ser usada.
*(A forma como a pasta foi montada não importa.)*

Todas estas opções podem ser alteradas definindo os parâmetros necessários em `option.cfg`.
Veja [Configuração](OPTIONS.md) para instruções e sintaxe de parâmetros.

<br />

## Executando o script automaticamente

Antes de ativar um agendamento, prepare as configurações e a lista de dispositivos.
Caso contrário, uma execução automática não pode executar um backup em lote.

Você não precisa criar um usuário separado para executar o script, mas executar operações como estas como **root** é considerado uma prática ruim. O exemplo a seguir cria um usuário dedicado.

Crie o usuário **bsmt** *(você pode escolher outro nome; substitua **bsmt** nos exemplos)* e conceda a ele somente as permissões necessárias:

```bash
(
    set -e

    SCRIPT_DIR="/opt/mikrotik-backup"

    sudo useradd \
        --system \
        --user-group \
        --home-dir "$SCRIPT_DIR" \
        --no-create-home \
        --shell /usr/sbin/nologin \
        bsmt

    sudo chown bsmt:bsmt \
        "$SCRIPT_DIR" \
        "$SCRIPT_DIR/mikrotik-backup.sh"

    sudo chmod 0700 \
        "$SCRIPT_DIR" \
        "$SCRIPT_DIR/mikrotik-backup.sh"

    sudo find "$SCRIPT_DIR" -maxdepth 1 -type f \
        \( -name 'option.cfg' -o -name 'devicelist.cfg' -o -name '*.lang' \) \
        -exec chown bsmt:bsmt {} + \
        -exec chmod 0600 {} +
)
```

<br />

**Se o script já foi executado como root**

*(N.B. Se você executou anteriormente o script como **root**, as pastas, os backups
e os logs criados podem não ser acessíveis para **bsmt**.
Transfira o armazenamento existente para esse usuário antes de habilitar o agendamento.)*

Este exemplo usa o diretório local `/opt/mikrotik-backup/backups`.
O seguinte comando muda o proprietário e o grupo do diretório e tudo o que nele está:

```bash
sudo chown -hR -P -- bsmt:bsmt "/opt/mikrotik-backup/backups"
```

*(N.B. Especifique o diretório de backup deste script, não um diretório compartilhado que também contém dados de outros scripts.
Se o armazenamento ou log principal estiver localizado em outro lugar, configure o acesso a cada um separadamente de acordo com as permissões e configurações do armazenamento selecionado, seguindo o mesmo padrão.)*

Este exemplo abre o Editor de Configuração como **bsmt** depois que o usuário tiver acesso ao diretório e arquivos do script:
*(N.B. Execute o comando como root ou como usuário permitido fazê-lo através do sudo.)*

```bash
sudo -u bsmt /usr/bin/bash /opt/mikrotik-backup/mikrotik-backup.sh -e
```

<br />

**Criando um agendamento para o script**

O exemplo a seguir cria um agendamento com systemd,
mas pode utilizar crontab ou qualquer outro método que prefira.

Criaremos um serviço que executa o script como nosso usuário dedicado e um timer que o inicia conforme o agendamento.
*(O exemplo é executado todos os dias à 1 da manhã, mas o horário é definido por você.)*

```bash
(
    set -e

    sudo tee /etc/systemd/system/mikrotik-backup.service >/dev/null <<'EOF'
[Unit]
Description=MikroTik backup
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
User=bsmt
Group=bsmt
WorkingDirectory=/opt/mikrotik-backup
ExecStart=/usr/bin/bash /opt/mikrotik-backup/mikrotik-backup.sh
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
UMask=0077
NoNewPrivileges=true
Restart=no
TimeoutStartSec=infinity
StandardInput=null
StandardOutput=journal
StandardError=journal
EOF

    sudo tee /etc/systemd/system/mikrotik-backup.timer >/dev/null <<'EOF'
[Unit]
Description=Daily MikroTik backup

[Timer]
OnCalendar=*-*-* 01:00:00
AccuracySec=1s
Persistent=false
Unit=mikrotik-backup.service

[Install]
WantedBy=timers.target
EOF

    sudo chmod 0644 \
        /etc/systemd/system/mikrotik-backup.service \
        /etc/systemd/system/mikrotik-backup.timer

    sudo systemd-analyze verify \
        /etc/systemd/system/mikrotik-backup.service \
        /etc/systemd/system/mikrotik-backup.timer

    sudo systemctl daemon-reload
    sudo systemctl enable --now mikrotik-backup.timer

    systemctl list-timers --all mikrotik-backup.timer
)
```

*`Persistent=false` não permite uma execução de recuperação após um período em que o timer esteve desligado.
`Restart=no` não agenda reinicializações automáticas do serviço após um erro.*
