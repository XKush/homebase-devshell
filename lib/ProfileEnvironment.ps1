# Profile environment state — Wave A declarative layer (idempotent, no side effects beyond env)
# lib/ProfileEnvironment.ps1

function Initialize-WorkstationProfileEnvironment {
    if ($script:WorkstationProfileEnvironmentInitialized) {
        return $script:WorkstationRoots
    }
    $script:WorkstationProfileEnvironmentInitialized = $true

    if (-not (Get-Command Get-HomeBasePath -ErrorAction SilentlyContinue)) {
        throw 'Get-HomeBasePath required before Initialize-WorkstationProfileEnvironment'
    }

    $repoRoot = Get-HomeBasePath -Name RepositoryRoot

    $script:WorkstationRoots = @{
        Tools    = Get-HomeBasePath -Name Tools
        Scripts  = Get-HomeBasePath -Name Scripts
        Projects = Get-HomeBasePath -Name Projects
        Logs     = Get-HomeBasePath -Name Logs
        Backups  = Get-HomeBasePath -Name Backups
        Security = Get-HomeBasePath -Name Security
    }
    $global:WorkstationRoots = $script:WorkstationRoots

    $env:WORKSTATION_ROOT = $repoRoot
    $env:WORKSTATION_LOGS = Get-HomeBasePath -Name Logs
    $env:PROJECTS_HOME     = $script:WorkstationRoots.Projects
    $env:NETWORKING_HOME  = Get-HomeBasePath -Name Networking
    $env:CONFIGS_HOME      = Get-HomeBasePath -Name Configs
    $env:TOOLS_HOME       = $script:WorkstationRoots.Tools
    $env:WS_TEMP           = Get-HomeBasePath -Name Temp

    $script:ProfileOmpTheme = Join-Path $repoRoot 'terminal\active-theme.omp.json'
    $env:FASTFETCH_CONFIG   = Join-Path (Get-HomeBasePath -Name Configs) 'fastfetch-config.jsonc'
    if (Test-Path $script:ProfileOmpTheme) {
        $env:POSH_THEME = $script:ProfileOmpTheme
    }

    return $script:WorkstationRoots
}
