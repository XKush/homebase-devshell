# HomeBase DevShell

🌍 **Язык:** [English](README.md) | Русский

**Хватит гадать, сломано ли окружение. Одна команда — и вы знаете.**

Чистое PowerShell-окружение для Windows: за секунды показывает, готова ли машина к работе.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

```powershell
irm https://raw.githubusercontent.com/XKush/homebase-devshell/v2.0.0/install.ps1 | iex
```

Перезапустите терминал и выполните **`devshell doctor`**. Когда увидите **Ready to work** — можно работать.

---

## Зачем это нужно

Оболочка может быть сломана — и вы не узнаете об этом, пока задача не упадёт посередине.

Битые пути, отсутствующие инструменты, профиль, который грузится слишком долго, конфиг, который «уплыл» с прошлой недели. Всё выглядит нормально — пока не перестаёт.

**`devshell doctor`** ловит этот drift *до* того, как испортит день: один pass/fail-тест, чтобы доверять окружению до того, как писать код.

---

## Момент доказательства

```powershell
devshell doctor
```

Когда всё в порядке:

```
✔ Profile OK
✔ Tools OK
✔ Environment OK
✔ Ready to work

Profile load: 489ms
Passed: 71 · Failed: 0
```

Без догадок. Без «наверное, норм». Вы знаете.

<details>
<summary>Полный отчёт (когда нужны детали)</summary>

```
═══════════════════ VALIDATION REPORT ═══════════════════
Passed:   71
Failed:   0
Warnings: 0
Profile load: 489ms <= 600ms
Report: C:\Logs\Workstation\validation-20260629-030000.json
═══════════════════════════════════════════════════════
```

Если **`Failed` > 0** — откройте JSON-отчёт, исправьте пункты из списка, снова запустите `devshell doctor`.

</details>

---

## Быстрый старт (60 секунд)

**1. Установка**

```powershell
irm https://raw.githubusercontent.com/XKush/homebase-devshell/v2.0.0/install.ps1 | iex
```

**2. Перезапуск** Windows Terminal (или новое окно PowerShell 7).

**3. Проверка**

```powershell
pwsh -File $HOME\.homebase\devshell\devshell.ps1 doctor
```

**4. Статус**

```powershell
pwsh -File $HOME\.homebase\devshell\devshell.ps1 status
```

**По желанию — короткий alias для каждый день:**

```powershell
function devshell { pwsh -NoProfile -File "$HOME\.homebase\devshell\devshell.ps1" @args }
```

Дальше только: `devshell install` · `devshell doctor` · `devshell status` — весь продукт на этом.

---

## Три команды

Больше ничего не обязательно.

| Команда | Что делает |
|---------|------------|
| **`devshell install`** | Папки, профиль PowerShell, базовая настройка |
| **`devshell doctor`** | Проверка здоровья — ловит сломанную оболочку, пути и инструменты |
| **`devshell status`** | Версия и факт, что окружение загрузилось корректно |

```powershell
devshell install
devshell doctor
devshell status
```

Без alias:

```powershell
pwsh -File $HOME\.homebase\devshell\devshell.ps1 doctor
```

---

## Реальные сценарии

**Новая Windows**  
Установка → doctor → работа. Оболочка проверена до клонирования проектов.

**«Что-то не так»**  
Окружение может быть сломано, а вы ещё не знаете. Doctor находит drift за один прогон.

**Второй ПК или переустановка**  
Тот же URL установки, тот же pass/fail — меньше «у меня работает».

**Ежедневная оболочка**  
Быстрый профиль с `home`, `go` и shortcuts — без ручного `$PROFILE` на 500 строк.

---

## Если что-то пошло не так

Подробнее: [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) (на английском) или таблица ниже.

| Проблема | Решение |
|----------|---------|
| **Нужен PowerShell 7+** | Установите с [aka.ms/powershell](https://aka.ms/powershell), откройте терминал заново |
| **git not found** при remote install | [Git for Windows](https://git-scm.com/download/win), повторите строку установки |
| **`devshell doctor` не проходит** | `C:\Logs\Workstation\validation-*.json` → исправить → doctor снова |
| **Команды не находятся** | Перезапуск терминала; полный путь или alias выше |
| **Переустановить безопасно** | `devshell install` идемпотентен — можно запускать после правок |

---

## Требования

- Windows 10 или 11  
- [PowerShell 7+](https://aka.ms/powershell)  
- Git (для установки одной строкой)  
- По желанию: Windows Terminal, Python (проверяет doctor)

---

## Чем это **не** является

- Не облачный сервис — всё локально на вашей машине  
- Не фреймворк, который нужно изучать перед работой  
- Не Linux/macOS (только Windows + PowerShell 7)  

Минимальная поверхность. Честная проверка. Если это вам нужно — вы по адресу.

---

## Ещё

- [Getting started](docs/GETTING-STARTED.md) · [Troubleshooting](docs/TROUBLESHOOTING.md) · [Contributing](CONTRIBUTING.md)  
- [CHANGELOG](CHANGELOG.md) · [License MIT](LICENSE)  
- **Команды и меню (RU):** [docs/ru/README.md](docs/ru/README.md) · [COMMANDS.md](docs/ru/COMMANDS.md)
