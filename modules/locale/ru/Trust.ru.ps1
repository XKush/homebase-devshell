# Сообщения режима доверия (ru)

function Get-TrustMessages {
    return @{
        SelfCheckFailed  = 'Самопроверка команды не пройдена: {0}'
        PreCheckTitle    = 'Проверка перед запуском'
        PostCheckTitle   = 'Проверка после выполнения'
        ModuleMissing    = 'Модуль KGreen.Workstation не загружен'
        ProfileDrift     = 'Профиль не синхронизирован с эталоном — fixprofile'
        HealthStale      = 'Отчёт command-health.json устарел ({0} мин.)'
        ValidationFail   = 'Валидация: {0} ошибок'
        CommandBroken    = 'Сломано команд: {0}'
        SelfCheckFail    = 'Самопроверки не пройдены: {0}'
        TrustSaved       = 'Отчёт доверия сохранён: {0}'
    }
}

function Get-TrustMessage {
    param(
        [Parameter(Mandatory)][string]$Key,
        [string]$Detail = ''
    )
    $msgs = Get-TrustMessages
    $template = if ($msgs.ContainsKey($Key)) { $msgs[$Key] } else { $Key }
    if ($Detail) { return ($template -f $Detail) }
    return $template
}

function Get-TrustLevelRu {
    param([Parameter(Mandatory)][string]$Level)
    switch ($Level) {
        'VERIFIED'  { return @{ Text = 'ПРОВЕРЕНО (live)'; Color = 'Green' } }
        'DEGRADED'  { return @{ Text = 'ЕСТЬ ЗАМЕЧАНИЯ'; Color = 'Yellow' } }
        'STALE'     { return @{ Text = 'УСТАРЕВШИЕ ДАННЫЕ'; Color = 'Yellow' } }
        'UNTRUSTED' { return @{ Text = 'ДОВЕРИЕ НАРУШЕНО'; Color = 'Red' } }
        default     { return @{ Text = 'НЕИЗВЕСТНО'; Color = 'DarkGray' } }
    }
}
