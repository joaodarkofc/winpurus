# WinPurus

**Aplicação desktop para manutenção e otimização do Windows**

WinPurus é uma ferramenta completa para otimização, reparo e manutenção do Windows, com interface moderna e translúcida. Inclui funcionalidades para instalação de software, ativação legal de licenças, reparo do sistema e muito mais.

## 🚀 Instalação Rápida

Execute o comando abaixo no PowerShell como Administrador:

```powershell
irm "https://winpurus.cc/irm" | iex
```

## 📋 Funcionalidades

### 🔧 Otimização do Windows
- Limpeza de arquivos temporários e cache
- Remoção de bloatware (opcional)
- Configuração de plano de energia Ultimate Performance
- Desativação da hibernação
- Configuração do Storage Sense

### 📦 Instalação do Office
- Suporte a links personalizados fornecidos pelo usuário
- Validação de URLs e hashes SHA256
- Instalação silenciosa com parâmetros customizáveis

### 🔑 Ativação Legal
- **APENAS chaves legítimas aceitas**
- Suporte ao Windows via `slmgr.vbs`
- Suporte ao Office via `ospp.vbs`
- Validação do status de ativação

### 🖨️ Gerenciamento de Impressoras
- Reset do spooler de impressão
- Reinstalação de drivers
- Diagnóstico de filas de impressão

### 🛠️ Reparo Geral
- SFC (System File Checker)
- DISM (Deployment Image Servicing)
- Reparo de .NET Framework e Visual C++
- Backup automático do registro

### 📊 Diagnóstico e Relatórios
- Relatórios de hardware e software
- Histórico de operações
- Logs detalhados

## 🖥️ Interface

- **Tamanho:** 1200×720px
- **Estilo:** Futurista e translúcido
- **Framework:** React + Electron
- **UX:** Botões grandes, textos claros, confirmações de segurança

## 📁 Estrutura do Projeto

```
WinPurus/
├─ gui/                      # Interface React + Electron
│   ├─ src/
│   │   ├─ App.jsx          # Componente principal
│   │   ├─ index.html       # HTML base
│   │   └─ main.js          # Processo principal Electron
│   ├─ package.json
│   └─ package-lock.json
├─ scripts/                  # Scripts PowerShell
│   ├─ launcher.ps1         # Script de instalação via IRM
│   ├─ install_office.ps1   # Instalação do Office
│   ├─ activation.ps1       # Ativação legal
│   ├─ optimize.ps1         # Otimização do Windows
│   ├─ repair.ps1           # Reparo do sistema
│   └─ printer_fix.ps1      # Correção de impressoras
├─ data/                     # Dados e logs
│   └─ history.db           # Histórico (opcional)
├─ README.md
└─ LICENSE
```

## ⚖️ Aviso Legal

**IMPORTANTE:** Este software é destinado apenas para uso em ambiente de teste e com licenças legítimas. 

- ❌ **NÃO** inclui ativadores ilegais, cracks ou bypass de licenças
- ✅ **APENAS** aceita chaves de produto legítimas
- ✅ Utiliza **SOMENTE** comandos oficiais da Microsoft
- ✅ Todas as operações são registradas em logs

## 🔒 Segurança

- Todas as operações críticas pedem confirmação
- Logs completos em `C:\ProgramData\WinPurus\winpurus.log`
- Modo "dry-run" disponível para testes
- Backup automático do registro antes de alterações

## 🛡️ Requisitos

- Windows 10/11
- PowerShell 5.1 ou superior
- Permissões de Administrador (quando necessário)
- Node.js (para desenvolvimento da GUI)

## 🚀 Desenvolvimento

### Executar a GUI
```bash
cd gui
npm install
npm start
```

### Compilar para produção
```bash
cd gui
npm run build
npm run dist
```

## 📝 Logs

Todos os logs são salvos em:
- `C:\ProgramData\WinPurus\winpurus.log`

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

---

**⚠️ Disclaimer:** Use apenas com chaves de produto legítimas. Este software não promove ou facilita pirataria de software.