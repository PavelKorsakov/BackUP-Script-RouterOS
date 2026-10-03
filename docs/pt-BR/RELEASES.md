# Versões

[Índice](../README_PT-BR.md)

## Versão 2.3.1

**Uma versão de manutenção e hotfix posterior à versão 2.3.0 publicada.**

A arquitetura de arquivo único e o requisito mínimo de GNU Bash 4.4 permanecem inalterados. `UseIncremental` agora é um ajuste booleano canônico: `false` ignora a comparação após o backup e a etapa de retenção incremental, mantendo cada artefato novo criado e validado com sucesso. Não há uma opção de CLI dedicada para esse ajuste.

A ordem de calendário do arquivamento mensal foi corrigida, e o tratamento de metadados de armazenamento de rede qualificado foi reforçado, mantendo a verificação rigorosa de metadados do sistema de arquivos local. O Editor de configuração e o BackUP Master agora usam uma área de visualização aceita em terminais mais baixos, sem exigir que todas as linhas do formulário caibam na tela ao mesmo tempo.

Russo e inglês continuam integrados. A versão 2.3.1 inclui traduções externas de runtime para alemão, espanhol, letão, polonês e ucraniano (`de`, `es`, `lv`, `pl`, `uk`), além de `en.lang` como modelo de tradução canônico completo, com 245 chaves. A documentação do usuário está disponível em 11 idiomas.

As notificações continuam não implementadas e fora do escopo desta versão.

<br />

Veja [INSTALL.md](INSTALL.md) para instruções sobre a obtenção dos arquivos, verificação de somas de verificação e preparação do script para uso.
