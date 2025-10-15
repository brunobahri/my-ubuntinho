# my-ubuntinho

Meus scripts e configurações personalizadas para Ubuntu. Este repositório contém scripts utilitários e configurações que tornam minha experiência no Ubuntu mais eficiente e customizável.

## Índice

- [Recursos](#recursos)
- [Instalação](#instalação)
- [Scripts Disponíveis](#scripts-disponíveis)
- [Uso](#uso)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Contribuindo](#contribuindo)

---

## Recursos

### Touchpad
Scripts para configurar e otimizar o touchpad no Ubuntu/GNOME:

- **Desativa tap-and-drag** - Elimina missclicks causados por dois toques rápidos
- **Perfis de aceleração** - Troca fácil entre modos adaptativo, flat e padrão
- **Configuração persistente** - Aplica configurações automaticamente na inicialização

---

## Instalação

### Instalação Rápida

```bash
# Clone o repositório
git clone git@github.com:brunobahri/my-ubuntinho.git
cd my-ubuntinho

# Execute o instalador
chmod +x install.sh
./install.sh
```

O script `install.sh` irá:
1. Criar symlinks em `~/scripts/` apontando para os scripts do projeto
2. Configurar autostart para aplicar configurações na inicialização
3. Tornar todos os scripts executáveis

### Adicionar Aliases ao Shell

Adicione ao seu `~/.zshrc` ou `~/.bashrc`:

```bash
# Touchpad Configuration Aliases
alias tpad-adaptive='~/scripts/touchpad-adaptive.sh'
alias tpad-flat='~/scripts/touchpad-flat.sh'
alias tpad-reset='~/scripts/touchpad-reset.sh'
alias tpad-config='~/scripts/touchpad-accel.sh'
alias tpad-status='gsettings list-recursively org.gnome.desktop.peripherals.touchpad | grep -E "accel|speed|tap-and-drag"'
```

Depois execute:
```bash
source ~/.zshrc  # ou source ~/.bashrc
```

---

## Scripts Disponíveis

### Touchpad

| Script | Descrição | Alias |
|--------|-----------|-------|
| `adaptive.sh` | Ativa perfil adaptativo (movimentos lentos = preciso, rápidos = veloz) | `tpad-adaptive` |
| `flat.sh` | Ativa perfil flat (velocidade constante) | `tpad-flat` |
| `reset.sh` | Reseta para configurações padrão | `tpad-reset` |
| `config.sh` | Menu interativo para configurar touchpad | `tpad-config` |
| `fix-all.sh` | Aplica todas as configurações recomendadas | - |

---

## Uso

### Comandos Rápidos

```bash
# Ativar modo adaptativo (recomendado)
tpad-adaptive

# Modo velocidade constante
tpad-flat

# Voltar ao padrão
tpad-reset

# Configuração interativa
tpad-config

# Ver configurações atuais
tpad-status
```

### Perfis de Aceleração Explicados

#### Adaptive (Recomendado)
- Movimentos **lentos/pequenos** → cursor preciso (fácil fazer ajustes finos)
- Movimentos **rápidos/grandes** → cursor rápido (navegação ágil)
- **Ideal para:** Trabalho geral, edição de texto, design

#### Flat
- Velocidade **constante** em todos os movimentos
- Comportamento totalmente **previsível**
- **Ideal para:** Quem prefere controle total, jogos

#### Default
- Configuração padrão do dispositivo
- Geralmente similar ao flat

---

## Estrutura do Projeto

```
my-ubuntinho/
├── README.md                    # Este arquivo
├── install.sh                   # Script de instalação
├── .gitignore                   # Arquivos ignorados pelo git
├── scripts/
│   └── touchpad/               # Scripts de configuração do touchpad
│       ├── adaptive.sh         # Perfil adaptativo
│       ├── flat.sh             # Perfil flat
│       ├── reset.sh            # Reset para padrão
│       ├── config.sh           # Menu interativo
│       └── fix-all.sh          # Configuração completa
└── autostart/
    └── touchpad-config.desktop # Autostart do GNOME
```

---

## Adicionando Novos Scripts

Este projeto foi estruturado para ser facilmente expansível. Para adicionar novos scripts:

### 1. Criar o script na categoria apropriada

```bash
# Exemplo: adicionar script de rede
nano ~/Documents/Projetos/my-ubuntinho/scripts/network/wifi-toggle.sh
chmod +x ~/Documents/Projetos/my-ubuntinho/scripts/network/wifi-toggle.sh
```

### 2. Atualizar install.sh (se necessário)

Adicione a criação de symlinks para os novos scripts.

### 3. Executar install.sh novamente

```bash
cd ~/Documents/Projetos/my-ubuntinho
./install.sh
```

### 4. Commit e push

```bash
git add scripts/network/wifi-toggle.sh
git commit -m "Add wifi toggle script"
git push
```

---

## Problemas Resolvidos

### Touchpad com Missclicks
**Problema:** Dois toques rápidos no touchpad ativam modo drag, causando missclicks.
**Solução:** Scripts desativam `tap-and-drag` e `tap-and-drag-lock`.

### Touchpad Lento ou Impreciso
**Problema:** Touchpad lento, mas ao aumentar velocidade fica difícil fazer ajustes finos.
**Solução:** Perfil `adaptive` permite movimentos lentos precisos e movimentos rápidos velozes.

---

## Requisitos

- Ubuntu 20.04+ (ou distribuições baseadas em Ubuntu)
- GNOME Desktop Environment
- `gsettings` (geralmente já instalado)
- Git (para clone do repositório)

---

## Licença

MIT License - Sinta-se livre para usar, modificar e distribuir.

---

## Autor

**Bruno Bahri**
GitHub: [@brunobahri](https://github.com/brunobahri)

---

## Changelog

### v1.0.0 (2025-10-15)
- Scripts de configuração do touchpad
- Perfis de aceleração (adaptive, flat, default)
- Desativação de tap-and-drag
- Autostart automático
- Script de instalação
