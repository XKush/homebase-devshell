# Тексты домашней панели HOME BASE (ru)

function Get-HomeBaseTexts {
    return @{
        Title           = 'HOME BASE — ДОМАШНЯЯ ПАНЕЛЬ УПРАВЛЕНИЯ'
        Subtitle        = 'Ваш терминал · центр управления · обучение'
        Welcome         = 'Добро пожаловать в вашу систему.'
        SectionState    = '● СОСТОЯНИЕ СИСТЕМЫ'
        SectionOk       = '● ЧТО РАБОТАЕТ НОРМАЛЬНО'
        SectionWarn     = '● ТРЕБУЕТ ВНИМАНИЯ'
        SectionBroken   = '● СЛОМАНО — НУЖНО ИСПРАВИТЬ'
        SectionToday    = '● ЧТО МОЖНО СДЕЛАТЬ СЕГОДНЯ'
        SectionChanges  = '● ПОСЛЕДНИЕ ИЗМЕНЕНИЯ'
        SectionGroups   = '● КОМАНДЫ ПО ГРУППАМ (кратко)'
        SectionTrust    = '● РЕЖИМ ДОВЕРИЯ К СИСТЕМЕ'
        ScoreLabel      = 'Оценка здоровья'
        ValidationLabel = 'Проверки валидации'
        WarningsLabel   = 'Предупреждений (live)'
        BrokenCmdLabel  = 'Сломанных команд (live)'
        DiskLabel       = 'Свободно на диске C'
        TrustVerified   = 'ПРОВЕРЕНО — данные получены live, панель не врёт'
        TrustStale      = 'КЭШ — данные устарели ({0} мин.), запустите trustcheck или doctor'
        TrustDegraded   = 'ЧАСТИЧНО — есть замечания, но критических поломок нет'
        TrustBroken     = 'НАРУШЕН — обнаружены сломанные команды, панель показывает правду'
        TrustUnknown    = 'НЕИЗВЕСТНО — выполните trustcheck для проверки'
        NoOkData        = '(нет подтверждённых данных — trustcheck или doctor)'
        FooterMinimal   = 'Команды: home · trustcheck · doctor · komandy'
        FooterNormal    = 'Подробно: komandy · instrumenty · ``команда -help`` · trustcheck'
        NeverAllOk      = 'Нельзя показать «всё идеально» — есть нерешённые проблемы (см. выше).'
    }
}
