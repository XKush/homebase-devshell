# HomeBase DevShell

🌍 **Язык:** [English](README.md) | Русский

**Окружение может быть сломано. Вы просто ещё не знаете об этом.**

**Одна установка. Одна проверка. Мгновенный ответ.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

```powershell
irm https://raw.githubusercontent.com/XKush/homebase-devshell/v2.0.0/install.ps1 | iex
```

Перезапустите терминал → **`devshell doctor`** → **Ready to work**.

---

## Зачем это нужно

- **Сломанное окружение не видно сразу** — битые пути, нет инструментов, медленный профиль  
- **Онбординг съедает день** — новый ПК, новая работа, переустановка  
- **Нельзя доверять тому, что не проверил** — «наверное, норм» — не стратегия  
- **Drift убивает продуктивность** — конфиг меняется тихо, пока что-то не упадёт  

HomeBase DevShell решает одну задачу: **понять, готовы ли вы работать — за секунды.**

---

## Увидеть за 3 секунды

```powershell
devshell doctor
```

```
✔ Profile OK
✔ Tools OK
✔ Environment OK
✔ Ready to work

Passed: 71 · Failed: 0 · Profile: 489ms
```

Всё. Без догадок.

---

## Три команды. Весь продукт.

```powershell
devshell install   # настройка (можно запускать снова)
devshell doctor    # pass или fail — готовы ли вы?
devshell status    # быстрая проверка
```

| Команда | Одной строкой |
|---------|----------------|
| **`devshell install`** | Профиль + базовая настройка |
| **`devshell doctor`** | Полная проверка перед кодом |
| **`devshell status`** | Версия и состояние загрузки |

<details>
<summary>Без alias (скопируйте один раз после install)</summary>

```powershell
function devshell { pwsh -NoProfile -File "$HOME\.homebase\devshell\devshell.ps1" @args }
```

</details>

---

## Когда использовать

**Новый ПК** — install → doctor → код  
**Что-то не так** — одна команда найдёт поломку  
**Каждое утро** — 5 секунд перед глубокой работой  

---

## Доверие

- **Fail-safe install** — после setup автоматически запускается `doctor`  
- **Идемпотентность** — `devshell install` можно запускать снова после правок  
- **Без admin по умолчанию** — product install не трогает привилегированные настройки  
- **Только локально** — ничего не уходит с машины  
- **Понятные отчёты** — ошибки в `C:\Logs\Workstation\validation-*.json`  

---

## Чем это **не** является

- ❌ Не фреймворк, который надо учить перед работой  
- ❌ Не замена shell (это PowerShell 7, улучшенный)  
- ❌ Не dev-платформа / экосистема плагинов  
- ❌ Не Linux и не macOS  

Просто: **install → doctor → работа.**

---

## Быстрый старт

```powershell
# 1 — установка
irm https://raw.githubusercontent.com/XKush/homebase-devshell/v2.0.0/install.ps1 | iex

# 2 — новый терминал, проверка
devshell doctor
devshell status
```

**Нужно:** Windows 10/11 · [PowerShell 7+](https://aka.ms/powershell) · Git  

**Проблемы?** [Troubleshooting](docs/TROUBLESHOOTING.md) · [English](README.md) · [Справочник команд](docs/ru/README.md) · [Contributing](CONTRIBUTING.md)
