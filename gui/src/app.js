const { ipcRenderer } = require('electron');

// Estado da aplicação
let currentSection = 'home';
let isRunning = false;

// Inicialização
document.addEventListener('DOMContentLoaded', () => {
    initializeApp();
    loadSection('home');
});

function initializeApp() {
    // Configurar eventos do menu
    const menuItems = document.querySelectorAll('.menu-item');
    menuItems.forEach(item => {
        item.addEventListener('click', () => {
            const section = item.getAttribute('data-section');
            switchSection(section);
        });
    });

    // Log inicial
    writeLog('WinPurus iniciado');
}

function switchSection(section) {
    // Atualizar menu ativo
    document.querySelectorAll('.menu-item').forEach(item => {
        item.classList.remove('active');
    });
    document.querySelector(`[data-section="${section}"]`).classList.add('active');

    // Carregar conteúdo da seção
    loadSection(section);
    currentSection = section;
}

function loadSection(section) {
    const contentArea = document.getElementById('content-area');
    
    switch(section) {
        case 'home':
            contentArea.innerHTML = getHomeContent();
            break;
        case 'optimize':
            contentArea.innerHTML = getOptimizeContent();
            break;
        case 'office':
            contentArea.innerHTML = getOfficeContent();
            break;
        case 'activation':
            contentArea.innerHTML = getActivationContent();
            break;
        case 'printers':
            contentArea.innerHTML = getPrintersContent();
            break;
        case 'repair':
            contentArea.innerHTML = getRepairContent();
            break;
        case 'programs':
            contentArea.innerHTML = getProgramsContent();
            break;
        case 'diagnostic':
            contentArea.innerHTML = getDiagnosticContent();
            break;
        case 'logs':
            contentArea.innerHTML = getLogsContent();
            loadLogs();
            break;
    }
}

function getHomeContent() {
    return `
        <div class="content-header">
            <h2>Bem-vindo ao WinPurus</h2>
            <p>Sua ferramenta completa para manutenção e otimização do Windows</p>
        </div>
        
        <div class="grid">
            <div class="card">
                <h3>⚡ Otimização Rápida</h3>
                <p>Limpe arquivos temporários e otimize o sistema automaticamente.</p>
                <button class="button" onclick="switchSection('optimize')">Otimizar Agora</button>
            </div>
            
            <div class="card">
                <h3>📦 Instalar Office</h3>
                <p>Instale o Microsoft Office usando seus próprios links de download.</p>
                <button class="button" onclick="switchSection('office')">Instalar Office</button>
            </div>
            
            <div class="card">
                <h3>🔑 Ativação Legal</h3>
                <p>Ative o Windows e Office com suas chaves de produto legítimas.</p>
                <button class="button" onclick="switchSection('activation')">Ativar Licenças</button>
            </div>
            
            <div class="card">
                <h3>🛠️ Reparo do Sistema</h3>
                <p>Execute verificações e reparos do sistema Windows.</p>
                <button class="button" onclick="switchSection('repair')">Reparar Sistema</button>
            </div>
        </div>
        
        <div class="card">
            <h3>📋 Instalação via PowerShell</h3>
            <p>Para instalar o WinPurus em outros computadores, use o comando abaixo:</p>
            <div class="irm-command" style="margin: 15px 0; padding: 15px; font-size: 14px;">
                irm "https://winpurus.cc/irm" | iex
            </div>
            <button class="button" onclick="copyIrmCommand()">📋 Copiar Comando</button>
        </div>
    `;
}

function getOptimizeContent() {
    return `
        <div class="content-header">
            <h2>⚡ Otimização do Windows</h2>
            <p>Limpe e otimize seu sistema para melhor performance</p>
        </div>
        
        <div class="card">
            <h3>Limpeza Automática</h3>
            <p>Remove arquivos temporários, cache e outros arquivos desnecessários.</p>
            
            <div class="checkbox-group">
                <div class="checkbox-item">
                    <input type="checkbox" id="temp-files" checked>
                    <label for="temp-files">Arquivos temporários</label>
                </div>
                <div class="checkbox-item">
                    <input type="checkbox" id="cache-files" checked>
                    <label for="cache-files">Cache do sistema</label>
                </div>
                <div class="checkbox-item">
                    <input type="checkbox" id="update-cache" checked>
                    <label for="update-cache">Cache do Windows Update</label>
                </div>
                <div class="checkbox-item">
                    <input type="checkbox" id="recycle-bin" checked>
                    <label for="recycle-bin">Lixeira</label>
                </div>
            </div>
            
            <button class="button" onclick="runOptimization('cleanup')">🧹 Executar Limpeza</button>
        </div>
        
        <div class="card">
            <h3>Remoção de Bloatware</h3>
            <p>Remove aplicativos pré-instalados desnecessários do Windows.</p>
            
            <div class="checkbox-group">
                <div class="checkbox-item">
                    <input type="checkbox" id="xbox-apps">
                    <label for="xbox-apps">Aplicativos Xbox</label>
                </div>
                <div class="checkbox-item">
                    <input type="checkbox" id="cortana">
                    <label for="cortana">Cortana</label>
                </div>
                <div class="checkbox-item">
                    <input type="checkbox" id="onedrive">
                    <label for="onedrive">OneDrive</label>
                </div>
                <div class="checkbox-item">
                    <input type="checkbox" id="edge">
                    <label for="edge">Microsoft Edge (cuidado!)</label>
                </div>
            </div>
            
            <button class="button danger" onclick="runOptimization('debloat')">⚠️ Remover Selecionados</button>
        </div>
        
        <div class="card">
            <h3>Ajustes de Performance</h3>
            <p>Configura o sistema para melhor performance.</p>
            
            <button class="button" onclick="runOptimization('performance')">🚀 Aplicar Ajustes</button>
            <button class="button secondary" onclick="runOptimization('power-plan')">⚡ Plano Ultimate Performance</button>
        </div>
        
        <div id="optimization-progress" class="card hidden">
            <h3>Progresso da Otimização</h3>
            <div class="progress-bar">
                <div class="progress-fill" style="width: 0%"></div>
            </div>
            <div id="optimization-status">Preparando...</div>
        </div>
    `;
}

function getOfficeContent() {
    return `
        <div class="content-header">
            <h2>📦 Instalação do Microsoft Office</h2>
            <p>Instale o Office usando seus próprios links de download</p>
        </div>
        
        <div class="card">
            <h3>Links de Download</h3>
            <p>Cole os links diretos para os instaladores do Office (.exe, .msi ou .iso):</p>
            
            <div class="input-group">
                <label for="office-urls">URLs dos Instaladores (uma por linha):</label>
                <textarea id="office-urls" rows="5" placeholder="https://exemplo.com/office-installer.exe
https://exemplo.com/office-setup.msi"></textarea>
            </div>
            
            <div class="input-group">
                <label for="office-hash">Hash SHA256 (opcional, para verificação):</label>
                <input type="text" id="office-hash" placeholder="abc123def456...">
            </div>
            
            <div class="input-group">
                <label for="install-params">Parâmetros de Instalação:</label>
                <input type="text" id="install-params" value="/quiet /norestart" placeholder="/quiet /norestart">
            </div>
            
            <button class="button" onclick="installOffice()">📦 Baixar e Instalar</button>
            <button class="button secondary" onclick="validateOfficeUrls()">✅ Validar URLs</button>
        </div>
        
        <div class="card">
            <h3>Instalação Personalizada</h3>
            <p>Configure opções específicas para a instalação:</p>
            
            <div class="checkbox-group">
                <div class="checkbox-item">
                    <input type="checkbox" id="office-word" checked>
                    <label for="office-word">Microsoft Word</label>
                </div>
                <div class="checkbox-item">
                    <input type="checkbox" id="office-excel" checked>
                    <label for="office-excel">Microsoft Excel</label>
                </div>
                <div class="checkbox-item">
                    <input type="checkbox" id="office-powerpoint" checked>
                    <label for="office-powerpoint">Microsoft PowerPoint</label>
                </div>
                <div class="checkbox-item">
                    <input type="checkbox" id="office-outlook">
                    <label for="office-outlook">Microsoft Outlook</label>
                </div>
            </div>
        </div>
        
        <div id="office-progress" class="card hidden">
            <h3>Progresso da Instalação</h3>
            <div class="progress-bar">
                <div class="progress-fill" style="width: 0%"></div>
            </div>
            <div id="office-status">Preparando download...</div>
        </div>
    `;
}

function getActivationContent() {
    return `
        <div class="content-header">
            <h2>🔑 Ativação Legal de Licenças</h2>
            <p>Ative o Windows e Office com suas chaves de produto legítimas</p>
        </div>
        
        <div class="card">
            <h3>⚠️ Aviso Importante</h3>
            <p style="color: #f39c12; font-weight: bold;">
                Este módulo aceita APENAS chaves de produto legítimas. 
                Não utilizamos métodos ilegais de ativação.
            </p>
        </div>
        
        <div class="card">
            <h3>Ativação do Windows</h3>
            <p>Insira sua chave de produto do Windows:</p>
            
            <div class="input-group">
                <label for="windows-key">Chave do Produto Windows:</label>
                <input type="text" id="windows-key" placeholder="XXXXX-XXXXX-XXXXX-XXXXX-XXXXX" maxlength="29">
            </div>
            
            <button class="button" onclick="activateWindows()">🔑 Ativar Windows</button>
            <button class="button secondary" onclick="checkWindowsActivation()">📊 Verificar Status</button>
        </div>
        
        <div class="card">
            <h3>Ativação do Office</h3>
            <p>Insira sua chave de produto do Office:</p>
            
            <div class="input-group">
                <label for="office-key">Chave do Produto Office:</label>
                <input type="text" id="office-key" placeholder="XXXXX-XXXXX-XXXXX-XXXXX-XXXXX" maxlength="29">
            </div>
            
            <div class="input-group">
                <label for="office-version">Versão do Office:</label>
                <select id="office-version" style="width: 100%; padding: 12px; border-radius: 8px; border: 1px solid rgba(255, 255, 255, 0.3); background: rgba(255, 255, 255, 0.1); color: white;">
                    <option value="2019">Office 2019</option>
                    <option value="2021">Office 2021</option>
                    <option value="365">Office 365</option>
                </select>
            </div>
            
            <button class="button" onclick="activateOffice()">🔑 Ativar Office</button>
            <button class="button secondary" onclick="checkOfficeActivation()">📊 Verificar Status</button>
        </div>
        
        <div id="activation-result" class="card hidden">
            <h3>Resultado da Ativação</h3>
            <div id="activation-output"></div>
        </div>
    `;
}

function getPrintersContent() {
    return `
        <div class="content-header">
            <h2>🖨️ Gerenciamento de Impressoras</h2>
            <p>Resolva problemas comuns com impressoras e spooler</p>
        </div>
        
        <div class="card">
            <h3>Problemas do Spooler</h3>
            <p>Reinicia o serviço de spooler de impressão e limpa a fila.</p>
            
            <button class="button" onclick="runPrinterFix('restart-spooler')">🔄 Reiniciar Spooler</button>
            <button class="button" onclick="runPrinterFix('clear-queue')">🗑️ Limpar Fila</button>
        </div>
        
        <div class="card">
            <h3>Drivers de Impressora</h3>
            <p>Reinstala ou atualiza drivers de impressora.</p>
            
            <button class="button" onclick="runPrinterFix('reinstall-drivers')">🔧 Reinstalar Drivers</button>
            <button class="button secondary" onclick="runPrinterFix('list-printers')">📋 Listar Impressoras</button>
        </div>
        
        <div class="card">
            <h3>Diagnóstico Completo</h3>
            <p>Executa um diagnóstico completo do sistema de impressão.</p>
            
            <button class="button" onclick="runPrinterFix('full-diagnostic')">🔍 Diagnóstico Completo</button>
        </div>
        
        <div id="printer-result" class="card hidden">
            <h3>Resultado</h3>
            <div class="log-container" id="printer-output"></div>
        </div>
    `;
}

function getRepairContent() {
    return `
        <div class="content-header">
            <h2>🛠️ Reparo Geral do Sistema</h2>
            <p>Execute verificações e reparos do sistema Windows</p>
        </div>
        
        <div class="card">
            <h3>Verificação de Arquivos do Sistema</h3>
            <p>Executa SFC (System File Checker) para verificar e reparar arquivos corrompidos.</p>
            
            <button class="button" onclick="runRepair('sfc')">🔍 Executar SFC</button>
        </div>
        
        <div class="card">
            <h3>Reparo de Imagem do Windows</h3>
            <p>Executa DISM para reparar a imagem do Windows.</p>
            
            <button class="button" onclick="runRepair('dism')">🔧 Executar DISM</button>
        </div>
        
        <div class="card">
            <h3>Reparo de Componentes</h3>
            <p>Repara .NET Framework e Visual C++ Redistributables.</p>
            
            <button class="button" onclick="runRepair('dotnet')">🔄 Reparar .NET</button>
            <button class="button" onclick="runRepair('vcredist')">📦 Reparar Visual C++</button>
        </div>
        
        <div class="card">
            <h3>Backup do Registro</h3>
            <p>Cria backup do registro antes de fazer alterações.</p>
            
            <button class="button" onclick="runRepair('backup-registry')">💾 Backup Registro</button>
        </div>
        
        <div id="repair-progress" class="card hidden">
            <h3>Progresso do Reparo</h3>
            <div class="progress-bar">
                <div class="progress-fill" style="width: 0%"></div>
            </div>
            <div id="repair-status">Preparando...</div>
            <div class="log-container" id="repair-output"></div>
        </div>
    `;
}

function getProgramsContent() {
    return `
        <div class="content-header">
            <h2>📋 Instalação de Programas</h2>
            <p>Instale programas essenciais usando winget e chocolatey</p>
        </div>
        
        <div class="card">
            <h3>Programas Essenciais</h3>
            <p>Selecione os programas que deseja instalar:</p>
            
            <div class="checkbox-group">
                <div class="checkbox-item">
                    <input type="checkbox" id="prog-chrome">
                    <label for="prog-chrome">Google Chrome</label>
                </div>
                <div class="checkbox-item">
                    <input type="checkbox" id="prog-firefox">
                    <label for="prog-firefox">Mozilla Firefox</label>
                </div>
                <div class="checkbox-item">
                    <input type="checkbox" id="prog-7zip">
                    <label for="prog-7zip">7-Zip</label>
                </div>
                <div class="checkbox-item">
                    <input type="checkbox" id="prog-vlc">
                    <label for="prog-vlc">VLC Media Player</label>
                </div>
                <div class="checkbox-item">
                    <input type="checkbox" id="prog-vscode">
                    <label for="prog-vscode">Visual Studio Code</label>
                </div>
                <div class="checkbox-item">
                    <input type="checkbox" id="prog-notepad">
                    <label for="prog-notepad">Notepad++</label>
                </div>
            </div>
            
            <button class="button" onclick="installPrograms()">📦 Instalar Selecionados</button>
        </div>
        
        <div class="card">
            <h3>Instalação Personalizada</h3>
            <p>Digite o nome do programa para instalar via winget:</p>
            
            <div class="input-group">
                <label for="custom-program">Nome do Programa:</label>
                <input type="text" id="custom-program" placeholder="Ex: Microsoft.PowerToys">
            </div>
            
            <button class="button" onclick="installCustomProgram()">🔍 Buscar e Instalar</button>
        </div>
        
        <div id="programs-progress" class="card hidden">
            <h3>Progresso da Instalação</h3>
            <div class="progress-bar">
                <div class="progress-fill" style="width: 0%"></div>
            </div>
            <div id="programs-status">Preparando...</div>
            <div class="log-container" id="programs-output"></div>
        </div>
    `;
}

function getDiagnosticContent() {
    return `
        <div class="content-header">
            <h2>📊 Diagnóstico do Sistema</h2>
            <p>Gere relatórios detalhados sobre hardware e software</p>
        </div>
        
        <div class="card">
            <h3>Relatório Rápido</h3>
            <p>Informações básicas do sistema:</p>
            
            <button class="button" onclick="generateReport('quick')">⚡ Relatório Rápido</button>
        </div>
        
        <div class="card">
            <h3>Relatório Completo</h3>
            <p>Análise detalhada de hardware, software e drivers:</p>
            
            <button class="button" onclick="generateReport('full')">📋 Relatório Completo</button>
        </div>
        
        <div class="card">
            <h3>Teste de Performance</h3>
            <p>Executa testes de performance do sistema:</p>
            
            <button class="button" onclick="generateReport('performance')">🚀 Teste de Performance</button>
        </div>
        
        <div id="diagnostic-result" class="card hidden">
            <h3>Resultado do Diagnóstico</h3>
            <div class="log-container" id="diagnostic-output"></div>
            <button class="button secondary" onclick="saveDiagnosticReport()">💾 Salvar Relatório</button>
        </div>
    `;
}

function getLogsContent() {
    return `
        <div class="content-header">
            <h2>📝 Logs do Sistema</h2>
            <p>Visualize o histórico de operações do WinPurus</p>
        </div>
        
        <div class="card">
            <h3>Logs Recentes</h3>
            <button class="button" onclick="loadLogs()">🔄 Atualizar</button>
            <button class="button secondary" onclick="clearLogs()">🗑️ Limpar Logs</button>
            <button class="button secondary" onclick="exportLogs()">📤 Exportar</button>
        </div>
        
        <div class="card">
            <div class="log-container" id="logs-output" style="max-height: 400px;">
                Carregando logs...
            </div>
        </div>
    `;
}

// Funções de ação
async function runOptimization(type) {
    if (isRunning) return;
    
    isRunning = true;
    showProgress('optimization');
    
    try {
        const result = await ipcRenderer.invoke('run-powershell', 'optimize.ps1', [type]);
        updateProgress('optimization', 100, 'Otimização concluída!');
        
        await writeLog(`Otimização ${type} executada: ${result.code === 0 ? 'Sucesso' : 'Erro'}`);
        
        if (result.code !== 0) {
            showError('Erro na otimização', result.error);
        } else {
            showSuccess('Otimização concluída com sucesso!');
        }
    } catch (error) {
        showError('Erro ao executar otimização', error.message);
    } finally {
        isRunning = false;
    }
}

async function installOffice() {
    if (isRunning) return;
    
    const urls = document.getElementById('office-urls').value.trim();
    const hash = document.getElementById('office-hash').value.trim();
    const params = document.getElementById('install-params').value.trim();
    
    if (!urls) {
        showError('Erro', 'Por favor, insira pelo menos uma URL de download.');
        return;
    }
    
    isRunning = true;
    showProgress('office');
    
    try {
        const args = [urls.replace(/\n/g, ';'), hash, params];
        const result = await ipcRenderer.invoke('run-powershell', 'install_office.ps1', args);
        
        updateProgress('office', 100, 'Instalação concluída!');
        
        await writeLog(`Instalação do Office: ${result.code === 0 ? 'Sucesso' : 'Erro'}`);
        
        if (result.code !== 0) {
            showError('Erro na instalação', result.error);
        } else {
            showSuccess('Office instalado com sucesso!');
        }
    } catch (error) {
        showError('Erro ao instalar Office', error.message);
    } finally {
        isRunning = false;
    }
}

async function activateWindows() {
    const key = document.getElementById('windows-key').value.trim();
    
    if (!key || key.length !== 29) {
        showError('Erro', 'Por favor, insira uma chave válida do Windows (formato: XXXXX-XXXXX-XXXXX-XXXXX-XXXXX).');
        return;
    }
    
    const confirmed = await confirmAction('Ativar Windows', 'Deseja ativar o Windows com a chave fornecida?');
    if (!confirmed) return;
    
    try {
        const result = await ipcRenderer.invoke('run-powershell', 'activation.ps1', ['windows', key]);
        
        document.getElementById('activation-result').classList.remove('hidden');
        document.getElementById('activation-output').innerHTML = `
            <div class="log-container">${result.output}</div>
            ${result.error ? `<div style="color: #e74c3c; margin-top: 10px;">Erro: ${result.error}</div>` : ''}
        `;
        
        await writeLog(`Ativação do Windows: ${result.code === 0 ? 'Sucesso' : 'Erro'}`);
        
        if (result.code === 0) {
            showSuccess('Windows ativado com sucesso!');
        } else {
            showError('Erro na ativação', result.error);
        }
    } catch (error) {
        showError('Erro ao ativar Windows', error.message);
    }
}

async function activateOffice() {
    const key = document.getElementById('office-key').value.trim();
    const version = document.getElementById('office-version').value;
    
    if (!key || key.length !== 29) {
        showError('Erro', 'Por favor, insira uma chave válida do Office (formato: XXXXX-XXXXX-XXXXX-XXXXX-XXXXX).');
        return;
    }
    
    const confirmed = await confirmAction('Ativar Office', 'Deseja ativar o Office com a chave fornecida?');
    if (!confirmed) return;
    
    try {
        const result = await ipcRenderer.invoke('run-powershell', 'activation.ps1', ['office', key, version]);
        
        document.getElementById('activation-result').classList.remove('hidden');
        document.getElementById('activation-output').innerHTML = `
            <div class="log-container">${result.output}</div>
            ${result.error ? `<div style="color: #e74c3c; margin-top: 10px;">Erro: ${result.error}</div>` : ''}
        `;
        
        await writeLog(`Ativação do Office ${version}: ${result.code === 0 ? 'Sucesso' : 'Erro'}`);
        
        if (result.code === 0) {
            showSuccess('Office ativado com sucesso!');
        } else {
            showError('Erro na ativação', result.error);
        }
    } catch (error) {
        showError('Erro ao ativar Office', error.message);
    }
}

async function runPrinterFix(action) {
    if (isRunning) return;
    
    isRunning = true;
    
    try {
        const result = await ipcRenderer.invoke('run-powershell', 'printer_fix.ps1', [action]);
        
        document.getElementById('printer-result').classList.remove('hidden');
        document.getElementById('printer-output').textContent = result.output;
        
        await writeLog(`Correção de impressora (${action}): ${result.code === 0 ? 'Sucesso' : 'Erro'}`);
        
        if (result.code === 0) {
            showSuccess('Operação concluída com sucesso!');
        } else {
            showError('Erro na operação', result.error);
        }
    } catch (error) {
        showError('Erro ao executar correção', error.message);
    } finally {
        isRunning = false;
    }
}

async function runRepair(type) {
    if (isRunning) return;
    
    isRunning = true;
    showProgress('repair');
    
    try {
        const result = await ipcRenderer.invoke('run-powershell', 'repair.ps1', [type]);
        
        updateProgress('repair', 100, 'Reparo concluído!');
        document.getElementById('repair-output').textContent = result.output;
        
        await writeLog(`Reparo ${type}: ${result.code === 0 ? 'Sucesso' : 'Erro'}`);
        
        if (result.code === 0) {
            showSuccess('Reparo concluído com sucesso!');
        } else {
            showError('Erro no reparo', result.error);
        }
    } catch (error) {
        showError('Erro ao executar reparo', error.message);
    } finally {
        isRunning = false;
    }
}

async function generateReport(type) {
    if (isRunning) return;
    
    isRunning = true;
    
    try {
        const result = await ipcRenderer.invoke('run-powershell', 'diagnostic.ps1', [type]);
        
        document.getElementById('diagnostic-result').classList.remove('hidden');
        document.getElementById('diagnostic-output').textContent = result.output;
        
        await writeLog(`Diagnóstico ${type}: ${result.code === 0 ? 'Sucesso' : 'Erro'}`);
        
        if (result.code === 0) {
            showSuccess('Relatório gerado com sucesso!');
        } else {
            showError('Erro ao gerar relatório', result.error);
        }
    } catch (error) {
        showError('Erro ao gerar relatório', error.message);
    } finally {
        isRunning = false;
    }
}

async function loadLogs() {
    try {
        const logs = await ipcRenderer.invoke('read-logs');
        document.getElementById('logs-output').textContent = logs || 'Nenhum log encontrado.';
    } catch (error) {
        document.getElementById('logs-output').textContent = 'Erro ao carregar logs: ' + error.message;
    }
}

// Funções utilitárias
function showProgress(type) {
    const progressElement = document.getElementById(`${type}-progress`);
    if (progressElement) {
        progressElement.classList.remove('hidden');
        updateProgress(type, 0, 'Iniciando...');
    }
}

function updateProgress(type, percent, status) {
    const fillElement = document.querySelector(`#${type}-progress .progress-fill`);
    const statusElement = document.getElementById(`${type}-status`);
    
    if (fillElement) fillElement.style.width = `${percent}%`;
    if (statusElement) statusElement.textContent = status;
}

async function confirmAction(title, message) {
    const result = await ipcRenderer.invoke('show-message-box', {
        type: 'question',
        buttons: ['Sim', 'Não'],
        defaultId: 1,
        title: title,
        message: message
    });
    
    return result.response === 0;
}

function showSuccess(message) {
    // Implementar notificação de sucesso
    console.log('Sucesso:', message);
}

function showError(title, message) {
    ipcRenderer.invoke('show-message-box', {
        type: 'error',
        title: title,
        message: message
    });
}

async function writeLog(message) {
    try {
        await ipcRenderer.invoke('write-log', message);
    } catch (error) {
        console.error('Erro ao escrever log:', error);
    }
}

async function copyIrmCommand() {
    const command = 'irm "https://winpurus.cc/irm" | iex';
    await ipcRenderer.invoke('copy-to-clipboard', command);
    showSuccess('Comando copiado para a área de transferência!');
}