# WinPurus — PowerShell Edition

**Central de ferramentas Windows (menu interativo em PowerShell)**

> WinPurus é uma ferramenta administrativa leve e segura para Windows. Fornece um menu interativo em PowerShell com opções para instalar/desinstalar apps, reparar impressoras, testar rede, executar scripts remotos com verificação e muito mais — tudo com logs e confirmações para operações críticas.

---

## Principais funcionalidades

* Menu interativo colorido (título, data/hora, opções, mensagens de erro/sucesso).
* Instalar e desinstalar apps via **winget**, **MSIX/Appx** ou instaladores locais.
* Teste e reparo de impressoras (envio de página de teste, limpar/relançar spooler).
* Ferramentas de rede (exibir IP, ping, renovar DHCP, teste DNS).
* Reparos do sistema (SFC, DISM) com opção de execução manual.
* Execução segura de scripts remotos: baixa, mostra, calcula hash, verifica assinatura e só executa com confirmação.
* Registro (log) de ações importantes em `winpurus.log` para auditoria.

---

## Pré-requisitos

* Windows 10/11 com PowerShell 5.1 ou PowerShell 7+.
* Para operações administrativas (instalar/desinstalar apps, reparar serviços), **executar como Administrador**.
* `winget` (Windows Package Manager) recomendado para instalar/desinstalar pacotes via repositório.

---

## Instalação (colocar no GitHub)

1. Crie um repositório no GitHub chamado `WinPurus` (ou use o que preferir).
2. Coloque estes arquivos no repositório: `winpurus.ps1`, `README.md`, `LICENSE`, `CONTRIBUTING.md`, `.gitignore` e `.github/` (templates/workflows).
3. Clone em qualquer máquina:

```powershell
git clone https://github.com/SEU_USUARIO/WinPurus.git
cd WinPurus
```

---

## Como executar

### Ajustar Execution Policy (se necessário)

Abra PowerShell (preferencialmente como Administrador) e execute:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

### Rodar o WinPurus

No diretório do repositório:

```powershell
.\winpurus.ps1
```

> Observação: se você quiser usar sempre como administrador, crie um atalho na área de trabalho apontando para:
>
> ```text
> powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\caminho\para\WinPurus\winpurus.ps1"
> ```
>
> e marque a opção de executar como administrador nas propriedades do atalho.

---

## Fluxo de uso: execução segura de scripts remotos

WinPurus inclui uma opção para baixar e executar scripts remotos **com segurança**. O fluxo padrão é:

1. O usuário fornece a URL.
2. O script baixa o arquivo para uma pasta temporária (sem executar).
3. Exibe as primeiras linhas para inspeção e calcula o hash SHA256.
4. Verifica assinatura Authenticode (se presente).
5. Permite abrir o arquivo no editor (Notepad).
6. Pergunta se deve executar: (a) executar no contexto atual, (b) executar em nova janela elevada (com UAC), (c) cancelar.
7. Registra a ação no log.

**Nunca** usar `Invoke-RestMethod | Invoke-Expression` (`irm ... | iex`) sem inspeção.

---

## Opções do menu (resumo)

* **Instalar Aplicativos** — instala via `winget`, executável local, ou Appx/MSIX.
* **Desinstalar Aplicativos** — remove apps UWP ou via `winget` (com confirmação).
* **Links Rápidos** — abre portais e sites úteis em navegador.
* **Teste de Impressora** — lista impressoras e envia página de teste.
* **Reparo de Impressora** — parar/limpar/reiniciar spooler; remover impressoras problemáticas (confirmado).
* **Rede e Conectividade
