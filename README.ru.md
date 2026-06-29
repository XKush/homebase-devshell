# DevReady

**HomeBase DevShell** готовит, проверяет и поддерживает профессиональные рабочие станции Windows.

Набор для **готовности к работе и аудита конфигурации приватности** — для разработчиков и специалистов по безопасности. PowerShell 7 · только локально · без облака.

🌍 [English](README.md) · **Русский**

[![CI](https://github.com/XKush/homebase-devshell/actions/workflows/ci.yml/badge.svg)](https://github.com/XKush/homebase-devshell/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PowerShell 7](https://img.shields.io/badge/PowerShell-7+-5391FE?logo=powershell&logoColor=white)](https://aka.ms/powershell)

![DevReady — install, devshell health, Ready to work](docs/assets/devready-demo.gif)

**Проверьте до запуска:** [`install.ps1` @ v3.0.0](https://github.com/XKush/homebase-devshell/blob/v3.0.0/install.ps1) · `devshell init` (dry-run) · [zip + SHA256](packaging/README.md)

---

## Старт за 30 секунд

```powershell
irm https://raw.githubusercontent.com/XKush/homebase-devshell/v3.0.0/install.ps1 | iex
```

Закройте терминал. Откройте снова:

```powershell
devshell health
```

Единый дашборд: Developer · Privacy Configuration · Browser · Network → **Ready to work.**

Или классическая проверка разработчика:

```powershell
devready
```

<details>
<summary>Три команды (на старте достаточно)</summary>

| Команда | Когда |
|---------|--------|
| **`devshell health`** | Единый дашборд + `-Json` для CI |
| **`devready`** | Только готовность разработчика (`doctor`) |
| **`devshell install`** | Первая настройка (Core) |

</details>

<details>
<summary>После PASS — command center</summary>

Меню и кокпит: [docs/ru/COMMAND-CENTER.md](docs/ru/COMMAND-CENTER.md) — не обязательны для Core.

</details>

---

## Зачем

| Боль | Ответ DevReady |
|------|----------------|
| Сломанный PATH, профиль, git — тихо до ночи | **`devshell health`** за секунды |
| Новый ПК | Одна строка install, одна проверка **`health`** |
| Дрейф конфигурации | **`baseline`** / **`verify`** |

Всё **только на вашем ПК**.

---

## Команды

| Команда | Действие |
|---------|----------|
| **`devshell health`** | Дашборд → **Ready to work**; `-Json` для CI |
| **`devready`** | Только проверка разработчика |
| **`devshell install`** | Core (профиль, папки); `-WithTools` — winget-стек |
| **`devshell baseline`** / **`verify`** | Снимок и сравнение конфигурации |

---

## Документация

| Файл | О чём |
|------|--------|
| [Старт](docs/GETTING-STARTED.md) | Пути, диаграмма |
| [Roadmap](docs/ROADMAP.md) | План v3.x (стабилизация) |
| [Принципы](docs/PROJECT-PRINCIPLES.md) | Правила проекта |
| [Manifesto](docs/MANIFESTO.md) | Зачем проект и чего не делает |
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

**Поделиться:** `irm …/install.ps1 | iex` → **`devshell health`**

[⭐ Star](https://github.com/XKush/homebase-devshell)
