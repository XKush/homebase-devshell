# HomeBase DevShell

🌍 **Язык:** [English](README.md) | Русский

**Ваше окружение готово к работе?**

**Установка. Проверка. Готово.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

```powershell
irm https://raw.githubusercontent.com/XKush/homebase-devshell/v2.0.5/install.ps1 | iex
```

Закройте терминал. Откройте снова. Запустите:

```powershell
pwsh -File $HOME\.homebase\devshell\devshell.ps1 doctor
```

Видите **Ready to work**? Всё — можно работать.

---

## Зачем

- Окружение может быть сломано — и вы этого не заметите  
- Новый ПК не должен означать час догадок  
- Не стоит писать код, пока не знаешь, что всё работает  

---

## Что вы увидите

```
✔ Profile OK
✔ Tools OK
✔ Environment OK
✔ Ready to work
```

Зелёные галочки — можно. Иначе — ещё не готово.

---

## Три действия (и всё)

| | |
|---|---|
| **install** | Первая настройка |
| **doctor** | Готов ли я к работе? |
| **status** | Всё загрузилось? (необязательно) |

Те же команды в любой момент:

```powershell
pwsh -File $HOME\.homebase\devshell\devshell.ps1 install
pwsh -File $HOME\.homebase\devshell\devshell.ps1 doctor
pwsh -File $HOME\.homebase\devshell\devshell.ps1 status
```

Без конфигов. Без мастеров. Скопировал — запустил — прочитал ответ.

---

## Когда

- **Новый Windows** — до первого коммита  
- **Что-то сломалось** — одна проверка вместо угадывания  
- **Начало дня** — 10 секунд спокойствия  

---

## Безопасно

- Только **на вашем ПК** — ничего никуда не уходит  
- **Без admin** в стандартной установке  
- **install можно запустить снова** — хуже не станет  

---

## Не для вас, если

- Нужен большой фреймворк, который сначала учить  
- Не Windows + PowerShell 7  
- Нужна замена bash/zsh на Mac/Linux  

---

**Помощь:** [Troubleshooting](docs/TROUBLESHOOTING.md) · [English](README.md) · [Команды в shell](docs/ru/COMMAND-CENTER.md)
