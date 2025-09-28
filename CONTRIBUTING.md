# Guia de Contribuição - WinPurus

Obrigado por considerar contribuir com o WinPurus! Este documento fornece diretrizes para contribuir com o projeto.

## 🤝 Como Contribuir

### Reportando Bugs

Antes de reportar um bug, verifique se ele já não foi reportado. Se não encontrar, crie uma nova issue incluindo:

1. **Descrição clara do problema**
2. **Passos para reproduzir**
3. **Comportamento esperado vs. atual**
4. **Informações do sistema**:
   - Versão do Windows
   - Versão do PowerShell
   - Versão do WinPurus
5. **Logs relevantes** (de `C:\ProgramData\WinPurus\winpurus.log`)
6. **Screenshots** (se aplicável)

### Sugerindo Melhorias

Para sugerir melhorias:

1. Verifique se a sugestão já não existe
2. Crie uma issue detalhada explicando:
   - O problema que a melhoria resolve
   - A solução proposta
   - Benefícios esperados
   - Possíveis impactos

### Contribuindo com Código

#### Pré-requisitos

- Conhecimento em PowerShell
- Git instalado
- Editor de código (VS Code recomendado)
- Windows 10/11 para testes

#### Processo de Desenvolvimento

1. **Fork do Repositório**
   ```bash
   git clone https://github.com/seu-usuario/winpurus.git
   cd winpurus
   ```

2. **Criar Branch para Feature/Fix**
   ```bash
   git checkout -b feature/nome-da-feature
   # ou
   git checkout -b fix/nome-do-bug
   ```

3. **Fazer as Alterações**
   - Siga as convenções de código
   - Adicione comentários em português
   - Teste suas alterações

4. **Commit das Alterações**
   ```bash
   git add .
   git commit -m "feat: adiciona nova funcionalidade X"
   ```

5. **Push e Pull Request**
   ```bash
   git push origin feature/nome-da-feature
   ```

## 📝 Convenções de Código

### PowerShell

#### Nomenclatura
- **Funções**: Use PascalCase (`Get-OfficeVersion`)
- **Variáveis**: Use camelCase (`$downloadPath`)
- **Constantes**: Use UPPER_CASE (`$OFFICE_VERSIONS`)
- **Parâmetros**: Use PascalCase (`-FilePath`)

#### Estrutura de Funções
```powershell
<#
.SYNOPSIS
    Breve descrição da função

.DESCRIPTION
    Descrição detalhada do que a função faz

.PARAMETER ParameterName
    Descrição do parâmetro

.EXAMPLE
    Exemplo de uso da função

.NOTES
    Informações adicionais
#>
function Verb-Noun {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RequiredParameter,
        
        [Parameter(Mandatory = $false)]
        [string]$OptionalParameter = "DefaultValue"
    )
    
    try {
        # Lógica da função
        Write-Log -Level "INFO" -Message "Iniciando operação"
        
        # Código principal
        
        Write-Log -Level "INFO" -Message "Operação concluída com sucesso"
        return $result
    }
    catch {
        Write-Log -Level "ERROR" -Message "Erro na operação: $($_.Exception.Message)"
        throw
    }
}
```

#### Tratamento de Erros
- Use `try-catch` para todas as operações críticas
- Registre erros no log com `Write-Log`
- Forneça mensagens de erro claras em português
- Use `throw` para erros críticos

#### Comentários
- Comentários em português brasileiro
- Documente a lógica complexa
- Use comentários de bloco para seções importantes

### Estrutura de Arquivos

#### winpurus.ps1
- Script principal com menu interativo
- Funções de interface do usuário
- Lógica de navegação entre menus

#### WinPurusHelpers.psm1
- Funções auxiliares reutilizáveis
- Operações de sistema (download, montagem, log)
- Validações e verificações

#### install_and_register_module.ps1
- Instalação e configuração do módulo
- Gerenciamento de aliases
- Configuração do ambiente

## 🧪 Testes

### Testes Manuais Obrigatórios

Antes de submeter um PR, teste:

1. **Instalação do Módulo**
   - Instalação limpa
   - Atualização
   - Desinstalação

2. **Menu Principal**
   - Navegação entre opções
   - Saída do programa
   - Tratamento de entradas inválidas

3. **Instalação do Office**
   - Pelo menos uma edição de cada versão (2013, 2016, 2019, 2021, 365)
   - Cancelamento durante download
   - Erro de rede simulado
   - Espaço insuficiente em disco

4. **Sistema de Log**
   - Criação do arquivo de log
   - Formato JSON válido
   - Registro de sucessos e erros

### Ambiente de Teste

- Teste em máquina virtual limpa
- Windows 10 e 11
- PowerShell 5.1 e 7.x
- Com e sem privilégios de administrador

## 📋 Checklist para Pull Requests

- [ ] Código segue as convenções estabelecidas
- [ ] Comentários em português brasileiro
- [ ] Funções documentadas com comentários de bloco
- [ ] Tratamento de erros implementado
- [ ] Testes manuais realizados
- [ ] Log de alterações atualizado
- [ ] Sem hardcoding de caminhos ou valores
- [ ] Compatibilidade com Windows 10/11
- [ ] Não quebra funcionalidades existentes

## 🔄 Processo de Review

1. **Revisão Automática**
   - Verificação de sintaxe PowerShell
   - Análise de segurança básica

2. **Revisão Manual**
   - Aderência às convenções
   - Qualidade do código
   - Funcionalidade

3. **Testes de Integração**
   - Teste em ambiente limpo
   - Verificação de compatibilidade

## 🏷️ Convenções de Commit

Use o padrão Conventional Commits:

- `feat:` Nova funcionalidade
- `fix:` Correção de bug
- `docs:` Alterações na documentação
- `style:` Formatação, sem mudança de lógica
- `refactor:` Refatoração de código
- `test:` Adição ou correção de testes
- `chore:` Tarefas de manutenção

Exemplos:
```
feat: adiciona suporte para Office 2024
fix: corrige erro de montagem de imagem ISO
docs: atualiza README com novas instruções
refactor: melhora estrutura do menu principal
```

## 🚀 Roadmap de Funcionalidades

### Próximas Versões

#### v2.0 - Reparos do Windows
- [ ] SFC (System File Checker)
- [ ] DISM (Deployment Image Servicing)
- [ ] Verificação de integridade
- [ ] Limpeza de arquivos temporários

#### v3.0 - Rede e Impressoras
- [ ] Diagnóstico de rede
- [ ] Reset de configurações TCP/IP
- [ ] Instalação de drivers de impressora
- [ ] Configuração de impressoras de rede

#### v4.0 - Melhorias Avançadas
- [ ] Interface gráfica (WPF)
- [ ] Agendamento de tarefas
- [ ] Relatórios detalhados
- [ ] Configuração remota

## 📞 Comunicação

### Canais de Comunicação

- **Issues**: Para bugs e sugestões
- **Discussions**: Para perguntas e discussões gerais
- **Pull Requests**: Para contribuições de código

### Diretrizes de Comunicação

- Use português brasileiro
- Seja respeitoso e construtivo
- Forneça contexto suficiente
- Seja específico em descrições

## 🎯 Prioridades de Desenvolvimento

1. **Alta Prioridade**
   - Correções de segurança
   - Bugs críticos
   - Compatibilidade com novas versões do Windows

2. **Média Prioridade**
   - Novas funcionalidades do roadmap
   - Melhorias de performance
   - Aprimoramentos de UX

3. **Baixa Prioridade**
   - Refatorações não críticas
   - Documentação adicional
   - Funcionalidades experimentais

## 🏆 Reconhecimento

Contribuidores serão reconhecidos:

- Lista de contribuidores no README
- Menção em releases
- Créditos em comentários de código (para contribuições significativas)

## 📚 Recursos Úteis

- [PowerShell Best Practices](https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/cmdlet-development-guidelines)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Git Flow](https://nvie.com/posts/a-successful-git-branching-model/)

---

Obrigado por contribuir com o WinPurus! Juntos, tornamos a instalação e manutenção do Windows mais simples e eficiente.