# DevReady: одна команда — и вы знаете, готов ли Windows к разработке

**Теги:** PowerShell, Windows, Open Source, DevOps

---

## TL;DR

**DevReady** — локальная проверка здоровья dev-окружения на Windows + PowerShell 7.  
Установка → `devready` → зелёный **Ready to work** или список того, что починить.  
Ничего не уходит в облако. MIT.

```powershell
irm https://raw.githubusercontent.com/XKush/homebase-devshell/v3.0.0/install.ps1 | iex
devready
```

Не доверяете `irm | iex`? Сначала `devshell init` (dry-run) или скачайте zip + SHA256 с [Releases](https://github.com/XKush/homebase-devshell/releases).

---

## Зачем это нужно

После переустановки Windows или клонирования чужого dotfiles-репозитория обычно непонятно:

- загрузился ли `$PROFILE` без ошибок;
- есть ли git и pwsh в PATH;
- не сломались ли алиасы и модули.

DevReady не «ставит всё подряд через winget». Он **проверяет**, готово ли то, что уже есть.  
Полный стек инструментов — опционально (`-WithTools` / `devshell doctor -Tier Full`).

---

## Как это выглядит

![DevReady demo](https://raw.githubusercontent.com/XKush/homebase-devshell/v3.0.0/docs/assets/devready-demo.gif)

Core-проверка: ~31 тест за секунду — pwsh, git, profile, command-health.

---

## Три способа установки

### 1. Одна строка (быстро)

```powershell
irm https://raw.githubusercontent.com/XKush/homebase-devshell/v3.0.0/install.ps1 | iex
```

Исходник на GitHub: [install.ps1 @ v3.0.0](https://github.com/XKush/homebase-devshell/blob/v3.0.0/install.ps1)

### 2. Dry-run без изменений

```powershell
git clone --branch v3.0.0 --depth 1 https://github.com/XKush/homebase-devshell.git
cd homebase-devshell
pwsh -File devshell.ps1 init
```

Покажет план: куда клонирует, какие env vars, что делает bootstrap — **без winget**.

### 3. Zip + SHA256

С [Releases](https://github.com/XKush/homebase-devshell/releases/tag/v3.0.0):

- `devready-v3.0.0.zip`
- `devready-v3.0.0.sha256.txt`

Распаковать в `%USERPROFILE%\.homebase\devshell`, затем:

```powershell
pwsh -File install.ps1 -SkipClone -SkipTools
devready
```

---

## Что внутри (коротко)

| Команда | Действие |
|---------|----------|
| `devready` | Core health check |
| `devshell doctor -Tier Full` | ~75 проверок (инструменты, меню) |
| `devshell status` | Загрузилась ли платформа |

Репозиторий: https://github.com/XKush/homebase-devshell  
Русский README: в корне `README.ru.md`

---

## Попробовали?

Скриншот PASS (или первой ошибки) — в [Issue #2](https://github.com/XKush/homebase-devshell/issues/2).  
Это помогает следующему человеку решиться.

Обсуждение: [Discussions #4](https://github.com/XKush/homebase-devshell/discussions/4)

---

*HomeBase DevShell · platform spec 1.0.0 LOCKED · продуктовые PR welcome*
