# DevReady

**Готов ли ваш Windows к разработке? Одна команда — и вы знаете.**

На базе **HomeBase DevShell** — локальная проверка здоровья PowerShell 7 на Windows. Без облака. Без admin. Без угадываний.

🌍 [English](README.md) · **Русский**

[![CI](https://github.com/XKush/homebase-devshell/actions/workflows/ci.yml/badge.svg)](https://github.com/XKush/homebase-devshell/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PowerShell 7](https://img.shields.io/badge/PowerShell-7+-5391FE?logo=powershell&logoColor=white)](https://aka.ms/powershell)

![DevReady — install, devready, Ready to work](docs/assets/devready-demo.gif)

**Проверьте до запуска:** [`install.ps1` @ v2.2.0](https://github.com/XKush/homebase-devshell/blob/v2.2.0/install.ps1) · `devshell init` (dry-run) · [zip + SHA256](packaging/README.md)

---

## Старт за 30 секунд

```powershell
irm https://raw.githubusercontent.com/XKush/homebase-devshell/v2.2.0/install.ps1 | iex
```

Закройте терминал. Откройте снова:

```powershell
devready
```

Видите **`Ready to work`**? Можно работать.

```powershell
devshell doctor -Tier Full   # полная проверка (~75 пунктов)
```

Язык cockpit: `$env:WORKSTATION_LANG='ru'` (по умолчанию в OSS — `en`).

---

## Зачем

| Боль | Ответ DevReady |
|------|----------------|
| Сломанный PATH, профиль, git — тихо до ночи | **`devready`** за секунды |
| Новый ПК | Одна строка install, одна проверка |
| Перед первым коммитом | Зелёное = можно. Нет — чиним |

Всё **только на вашем ПК**.

---

## Команды

| Команда | Действие |
|---------|----------|
| **`devready`** | Проверка здоровья (Core) |
| **`devshell install`** | Первая настройка |
| **`devshell doctor`** | Готов ли я? `-Tier Core` / `Full` |
| **`devshell status`** | Загрузилась ли платформа? |

---

## Документация

| Файл | О чём |
|------|--------|
| [Старт](docs/GETTING-STARTED.md) | Пути, диаграмма |
| [Проблемы](docs/TROUBLESHOOTING.md) | Если doctor падает |
| [Command center](docs/ru/COMMAND-CENTER.md) | `go`, `home`, меню |
| [Бренд](docs/product/BRAND.md) | DevReady vs HomeBase |

Карта репозитория: [REPOSITORY-SURFACE.md](docs/product/REPOSITORY-SURFACE.md)

---

## Безопасно

- Установка **без admin** по умолчанию  
- **`install` можно повторять**  
- Tor/PGP — **opt-in** через `sec`, не нужны для Core  

---

## Не для вас, если

- Нужен macOS/Linux  
- Нужен недельный курс перед использованием  

---

[CONTRIBUTING.md](CONTRIBUTING.md) · [SECURITY.md](SECURITY.md)

**Поделиться:** `irm …/install.ps1 | iex` → **`devready`**

[⭐ Star](https://github.com/XKush/homebase-devshell)
