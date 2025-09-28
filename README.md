# WinPurus

**Sistema de Instalação e Manutenção do Windows**

WinPurus é uma ferramenta PowerShell completa e segura para instalação automatizada do Microsoft Office e outras tarefas de manutenção do Windows. Desenvolvido especificamente para o mercado brasileiro, com interface em português e links oficiais da Microsoft em pt-BR.

## 🚀 Características Principais

- **Interface em Português**: Menus interativos e mensagens completamente em pt-BR
- **Instalação Automatizada do Office**: Suporte completo para Office 2013, 2016, 2019, 2021 e 365
- **Links Oficiais da Microsoft**: Todos os downloads são feitos diretamente dos servidores oficiais da Microsoft
- **Segurança Avançada**: Verificação de integridade com SHA256, elevação UAC automática
- **Log Detalhado**: Registro completo de todas as operações em formato JSON
- **Montagem Automática**: Suporte nativo para arquivos .img e .iso
- **Pronto para Corporativo**: Estrutura modular e extensível

## 📋 Requisitos do Sistema

- Windows 10/11 ou Windows Server 2016+
- PowerShell 5.1 ou superior
- Privilégios de administrador
- Conexão com a internet
- Mínimo 5GB de espaço livre em disco

## 🛠️ Instalação

### Instalação Rápida

1. Baixe todos os arquivos do projeto para uma pasta
2. Execute o PowerShell como Administrador
3. Navegue até a pasta do projeto
4. Execute o instalador:

```powershell
.\install_and_register_module.ps1
```

### Instalação Manual

1. Copie os arquivos para o diretório desejado
2. Importe o módulo:

```powershell
Import-Module .\WinPurusHelpers.psm1
```

3. Execute o script principal:

```powershell
.\winpurus.ps1
```

## 🎯 Como Usar

### Execução via Alias (Recomendado)

Após a instalação, você pode executar o WinPurus de qualquer lugar:

```powershell
irmx
```

### Execução Direta

```powershell
.\winpurus.ps1
```

## 📦 Estrutura do Projeto

```
winpurus/
├── winpurus.ps1                    # Script principal com menu interativo
├── WinPurusHelpers.psm1            # Módulo com funções auxiliares
├── install_and_register_module.ps1 # Instalador e configurador de alias
├── README.md                       # Este arquivo
├── LICENSE                         # Licença do projeto
├── .gitignore                      # Arquivos ignorados pelo Git
└── CONTRIBUTING.md                 # Guia para contribuidores
```

## 🏢 Edições do Microsoft Office Suportadas

### Office 2013
- Home and Student, Home and Business, Professional, Professional Plus
- Aplicativos individuais: Word, Excel, PowerPoint, Outlook, Publisher, Access
- Project Standard/Professional, Visio Standard/Professional

### Office 2016
- Home and Student, Home and Business, Professional, Professional Plus
- Aplicativos individuais: Word, Excel, PowerPoint, Outlook, Publisher, Access
- Project Standard/Professional, Visio Standard/Professional

### Office 2019
- Home and Student, Home and Business, Professional, Professional Plus
- Aplicativos individuais: Word, Excel, PowerPoint, Outlook, Publisher, Access
- Project Standard/Professional, Visio Standard/Professional

### Office 2021
- Home and Student, Home and Business, Professional, Professional Plus
- Aplicativos individuais: Word, Excel, PowerPoint, Outlook, Publisher, Access
- Project Standard/Professional, Visio Standard/Professional

### Office 365
- Home Premium, Business, Professional Plus

## 🔧 Funcionalidades

### ✅ Implementadas

1. **Instalação do Microsoft Office**
   - Download automático de links oficiais pt-BR
   - Montagem automática de imagens .img/.iso
   - Verificação de espaço em disco
   - Confirmação do usuário em cada etapa
   - Log detalhado de todas as operações

2. **Sistema de Segurança**
   - Elevação UAC automática
   - Verificação de integridade SHA256 (quando disponível)
   - Validação de conectividade de rede
   - Tratamento robusto de erros

3. **Interface do Usuário**
   - Menus coloridos e intuitivos
   - Mensagens de progresso em tempo real
   - Confirmações explícitas do usuário
   - Instruções claras de fallback

### 🚧 Em Desenvolvimento

2. **Reparos do Windows**
   - SFC (System File Checker)
   - DISM (Deployment Image Servicing)
   - Verificação de integridade do sistema

3. **Rede e Impressoras**
   - Diagnóstico de rede
   - Configuração de impressoras
   - Reset de configurações de rede

## 📊 Sistema de Log

O WinPurus registra todas as operações em `C:\ProgramData\WinPurus\winpurus.log` no formato JSON:

```json
{
  "timestamp": "2024-01-15 14:30:25",
  "level": "INFO",
  "user": "usuario",
  "message": "Download concluído com sucesso",
  "action": "DOWNLOAD_FILE",
  "item": "Office 2021 Professional Plus",
  "url": "https://officecdn.microsoft.com/...",
  "result": "SUCCESS",
  "details": "Tamanho: 3.2GB",
  "computer": "DESKTOP-ABC123"
}
```

## 🔒 Segurança

- **Privilégios Mínimos**: Solicita elevação apenas quando necessário
- **Downloads Seguros**: Apenas de servidores oficiais da Microsoft
- **Verificação de Integridade**: Suporte a validação SHA256
- **Log Auditável**: Registro completo para auditoria corporativa
- **Código Aberto**: Totalmente auditável e modificável

## 🤝 Contribuindo

Consulte [CONTRIBUTING.md](CONTRIBUTING.md) para diretrizes de contribuição.

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - consulte o arquivo [LICENSE](LICENSE) para detalhes.

## 🆘 Suporte e Solução de Problemas

### Problemas Comuns

**Erro de Privilégios**
- Certifique-se de executar o PowerShell como Administrador

**Falha no Download**
- Verifique sua conexão com a internet
- Alguns antivírus podem bloquear downloads grandes

**Erro de Montagem**
- Certifique-se de ter espaço suficiente em disco (mínimo 5GB)
- Verifique se não há outras imagens montadas

**Script não Executa**
- Verifique a política de execução: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

### Logs de Diagnóstico

Para diagnóstico avançado, consulte o arquivo de log:
```
C:\ProgramData\WinPurus\winpurus.log
```

## 🔄 Atualizações

Para atualizar o WinPurus:

1. Baixe a versão mais recente
2. Execute o desinstalador: `.\install_and_register_module.ps1` → Opção 2
3. Execute o instalador novamente: `.\install_and_register_module.ps1` → Opção 1

## 📞 Contato

Para suporte, sugestões ou relatórios de bugs, abra uma issue no repositório do projeto.

---

**WinPurus** - Simplificando a instalação e manutenção do Windows desde 2024.