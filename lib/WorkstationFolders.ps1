# Стандартные папки HOME BASE — одна карта для menu, shell, organize

$pathsLib = Join-Path $PSScriptRoot 'HomeBasePaths.ps1'
if (Test-Path $pathsLib) { . $pathsLib }

function Get-WorkstationStandardFolders {
    if (Get-Command Get-HomeBasePath -ErrorAction SilentlyContinue) {
        return [ordered]@{
            Projects         = Get-HomeBasePath -Name Projects
            Tools            = Get-HomeBasePath -Name Tools
            Scripts          = Get-HomeBasePath -Name Scripts
            Logs             = Get-HomeBasePath -Name Logs
            Security         = Get-HomeBasePath -Name Security
            Backups          = Get-HomeBasePath -Name Backups
            Configs          = Get-HomeBasePath -Name Configs
            Networking       = Get-HomeBasePath -Name Networking
            Temp             = Get-HomeBasePath -Name Temp
            Downloads        = (Join-Path $env:USERPROFILE 'Downloads')
            DownloadsArchive = 'C:\Downloads\Archive'
            Desktop          = [Environment]::GetFolderPath('Desktop')
        }
    }
    return [ordered]@{
        Projects         = 'C:\Projects'
        Tools            = 'C:\Tools'
        Scripts          = 'C:\Scripts'
        Logs             = 'C:\Logs\Workstation'
        Security         = 'C:\Security'
        Backups          = 'C:\Backups\Workstation'
        Configs          = 'C:\Configs\Workstation'
        Networking       = 'C:\Networking'
        Temp             = 'C:\Temp\Scratch'
        Downloads        = (Join-Path $env:USERPROFILE 'Downloads')
        DownloadsArchive = 'C:\Downloads\Archive'
        Desktop          = [Environment]::GetFolderPath('Desktop')
    }
}

function Get-WorkstationFolderStructure {
    return @{
        'C:\Tools'             = @('Portable', 'Scripts')
        'C:\Scripts'           = @('Workstation', 'Networking', 'Maintenance')
        'C:\Projects'          = @('_Templates')
        'C:\Security'          = @('Audits', 'Policies', 'pgp', 'exports')
        'C:\Networking'        = @('Tools', 'Captures', 'Scripts', 'Docs')
        'C:\Logs'              = @('Workstation', 'Networking', 'Maintenance')
        'C:\Backups'           = @('Workstation', 'Configs')
        'C:\Configs'           = @('Workstation', 'Terminal', 'Network')
        'C:\Temp'              = @('Scratch', 'Installers')
        'C:\Downloads\Archive' = @('Installers', 'Old', 'Shortcuts')
    }
}

function Ensure-WorkstationFolderLayout {
    param([switch]$Quiet)

    $created = [System.Collections.Generic.List[string]]::new()
    foreach ($root in (Get-WorkstationFolderStructure).Keys) {
        if (-not (Test-Path $root)) {
            New-Item -ItemType Directory -Force -Path $root | Out-Null
            $created.Add($root)
        }
        foreach ($sub in (Get-WorkstationFolderStructure)[$root]) {
            $p = Join-Path $root $sub
            if (-not (Test-Path $p)) {
                New-Item -ItemType Directory -Force -Path $p | Out-Null
                $created.Add($p)
            }
        }
    }

    if (-not $Quiet -and $created.Count) {
        Write-HackerLine "папки: создано $($created.Count) (go → папки)" -Color DarkGray
    }
    return @($created)
}

function Open-WorkstationFolder {
    param(
        [Parameter(Mandatory)][string]$Path,
        [string]$Label
    )

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
    Set-Location $Path
    $name = if ($Label) { $Label } else { $Path }
    Write-HackerLine "→ $name" -ForegroundColor DarkGreen
    if (Get-Command ll -ErrorAction SilentlyContinue) { ll } else { Get-ChildItem | Select-Object -First 14 }
}
