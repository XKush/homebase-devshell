# Перевод ошибок командного центра на русский

function Translate-WorkstationError {
    param(
        [Parameter(Mandatory)][string]$Message,
        [string]$Command = ''
    )

    $patterns = @(
        @{ Match = 'not found'; Ru = 'не найдена (отсутствует реализация или не загружен модуль)' }
        @{ Match = 'Cannot bind argument'; Ru = 'неверные параметры команды' }
        @{ Match = 'Access is denied'; Ru = 'доступ запрещён (нужны права администратора)' }
        @{ Match = 'Cannot find path'; Ru = 'путь не найден' }
        @{ Match = 'already exists'; Ru = 'уже существует' }
        @{ Match = 'No venv'; Ru = 'виртуальное окружение Python не найдено' }
        @{ Match = 'Sysinternals'; Ru = 'утилита Sysinternals не установлена — запустите Install-NetworkToolkit.ps1' }
    )

    $reason = $Message
    foreach ($p in $patterns) {
        if ($Message -match [regex]::Escape($p.Match) -or $Message -like "*$($p.Match)*") {
            $reason = $p.Ru
            break
        }
    }

    $solution = switch -Regex ($Message) {
        'Show-NetTools|Invoke-ToolCheck|nettools|toolcheck' {
            'Решение: Import-Module KGreen.Workstation -Force или выполните repairterminal'
        }
        'Profile|profile' {
            'Решение: fixprofile или Install-ShellProfile.ps1 -Force'
        }
        'Font|font|OMP|oh-my-posh' {
            'Решение: repairterminal'
        }
        default {
            if ($Command) { "Решение: выполните ``$Command -help`` или doctor" }
            else { 'Решение: выполните doctor или helpme' }
        }
    }

    @(
        "Ошибка: $Message"
        "Причина: $reason"
        $solution
    ) -join "`n"
}
