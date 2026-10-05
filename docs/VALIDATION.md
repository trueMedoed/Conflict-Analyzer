# Проверки начального каркаса

Дата подготовки: **05.10.2026** (Europe/Moscow). Это дата работы над каркасом, не дата выпуска Workshop.

## Исходные материалы

- Прочитана `Mods/Template/AGENTS.md`.
- Изучены локальные `Conflict/Constants`: AI-Group-Types, AI-Spawn-Points, Locations, SupplyStorages, Names.
- Просмотрены `.ent` и `default.layer` сохранённого HQC Everon версии `1.7.0.33`.
- Структура `addon.gproj` сверена с соседним `Conflict Spawn Helpers`.
- До создания нового репозитория проверено, что каталог `Mods` и его родители не входят в существующий Git-репозиторий.
- GUID `7778354B6C3C4B09` сгенерирован заново и проверен на отсутствие совпадения среди локальных `.gproj` в каталоге `Arma Reforger` до создания проекта.

## Проверки после создания

- Созданы девять исходных файлов: `.gitignore`, `AGENTS.md`, `README.md`, `TODO.md`, `addon.gproj`, этот журнал проверок и три документа Workshop.
- Проверены ID / TITLE, формат GUID, зависимость базовой игры и согласованность названия Conflict Analyzer. Остаточных placeholder и старого рабочего названия нет.
- После создания проверено: среди `.gproj` локального каталога `Arma Reforger` этот GUID встречается только в новом проекте.
- Проверены шесть относительных Markdown-ссылок: все целевые файлы существуют.
- `git check-ignore` подтверждает исключение личных настроек, логов и `exports/`; `.meta` и `resourceDatabase.rdb` не исключены.
- Создан отдельный репозиторий на ветке `main`. Перед первым коммитом список файлов и whitespace проверяются Git; хеш и окончательное состояние сообщаются в итоговом отчёте.

## Нативная загрузка Workbench

Проверено установленным **Arma Reforger Workbench 1.8.0.13** 05.10.2026.

Первый запуск без `-addonsDir` обнаружил новый addon, но остановился: базовая зависимость `58D0FB3206B6F859` не была видна в путях поиска. Запущенный для этой проверки процесс закрыт, затем выполнен повторный запуск с явным каталогом установленной игры. GUID зависимости не менялся.

Команда успешной проверки в этой установке:

```powershell
& 'D:\SteamLibrary\steamapps\common\Arma Reforger Tools\Workbench\ArmaReforgerWorkbenchSteamDiag.exe' `
  -gproj 'C:\Users\Phil\Documents\GitHub\Arma Reforger\Mods\Conflict Analyzer\ME_Conflict_Analyzer\addon.gproj' `
  -addonsDir 'D:\SteamLibrary\steamapps\common\Arma Reforger\addons' `
  -wbModule=ResourceManager -run -exitAfterInit
```

Результаты:

- В журнале присутствуют новый проект с GUID `7778354B6C3C4B09` и базовая Arma Reforger с GUID `58D0FB3206B6F859`.
- ResourceDB просканировал новый addon и его зависимости; Workbench автоматически создал в addon `resourceDatabase.rdb` (81 байт). Он включается в репозиторий без ручной генерации.
- Загружены базовые модули Game (5660 файлов) и WorkbenchGame (170 файлов), далее записано `Game successfully created.`
- Нет `ENGINE (E)` или `SCRIPT (E)`. Предупреждения `SCRIPT (W)` относятся к устаревшим API базовых скриптов.
- После автоматического завершения есть блок `RESOURCES (E): Resource leaks` для 24 UI-ресурсов (25 строк вместе с заголовком). Контрольный запуск только базовой игры с теми же параметрами завершения воспроизводит точно такой же список. Эти сообщения зафиксированы отдельно от успешной загрузки; весь журнал нельзя называть свободным от ошибок.
- Оба успешных проверочных процесса завершились автоматически. Другие Workbench-процессы не закрывались.

Основной журнал: `C:\Users\Phil\Documents\My Games\ArmaReforgerWorkbench\logs\logs_2026-10-05_13-24-12\console.log`.

Контрольный журнал базовой игры: `C:\Users\Phil\Documents\My Games\ArmaReforgerWorkbench\logs\logs_2026-10-05_13-24-51\console.log`.

Логи и личный профиль Workbench не включаются в Git. Проверка загрузки и сканирования не подтверждает анализ конкретного мира, работу будущих скриптов или экспорт.

## Будущий анализатор

Компиляция собственных скриптов анализатора, анализ мира, значения отчёта, экспорт и отсутствие изменений сцены не проверялись: функциональные скрипты ещё не созданы. План проверок находится в `TODO.md`.

## Официальные материалы для реализации и запуска

- [SCR_WorldFilesHelper — файлы мира и каталог слоёв](https://community.bistudio.com/wikidata/external-data/arma-reforger/ArmaReforgerScriptAPIPublic/interfaceSCR__WorldFilesHelper.html).
- [Workbench Plugin Tutorial](https://community.bistudio.com/wiki/Arma_Reforger%3AWorkbench_Plugin_Tutorial).
- [Startup Parameters — открытие проекта и завершение после инициализации](https://community.bistudio.com/wiki/Arma_Reforger%3AStartup_Parameters).

Проверяйте доступность конкретных API и параметров в установленной версии инструментов, прежде чем использовать их в коде.
