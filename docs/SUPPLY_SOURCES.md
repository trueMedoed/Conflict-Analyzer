# Целевой экспорт баз-источников припасов

Команда Workbench: `Plugins → [ME] Conflict Analyzer → Reports → Export supply source bases`. Она читает текущую сцену вместе с родительскими мирами и отбирает только `SCR_CampaignSourceBaseComponent`. Несохранённые изменения редактора могут попасть в результат; для воспроизводимого снимка используйте отдельный Workbench на сохранённом мире.

## Что сохраняется

У каждой базы сохраняются ID, имя source, родительский ID, prefab, subscene / слой, мировая позиция и только четыре поля компонента:

| Поле | Назначение |
| --- | --- |
| `Enabled` | Состояние компонента; отключённый источник остаётся в выборке |
| `m_sBaseName` | Исходный ключ названия базы; перевод пока не выполняется |
| `m_iRegularSuppliesIncomeBase` | Настроенное пополнение за цикл |
| `m_iSuppliesArrivalInterval` | Исходный интервал в секундах |

В заголовке сохраняются версия игры, время UTC, путь сценария, имена / пути всех subscene через `BaseWorld.GetSubSceneName`, счётчики чтения и предупреждения. Номер subscene не используется для исключения Eden. Трассировка матриц, все поля сущности, звуки, насекомые и строительные компоненты не сериализуются в этот отчёт. Обход и независимая проверка мировой позиции используют тот же код, что диагностика.

Нативный JSON имеет schemaVersion 2, `kind=supply-source-bases`; значения полей сохраняются с типом, статусом и признаком override. Это частичный отчёт настроек: вместимость, точные ресурсы наследования, локализованные локации и условия дохода ещё не разрешены.

## Проверенный CLI-путь

Используйте параметры запуска из [SOURCE_DIAGNOSTICS.md](SOURCE_DIAGNOSTICS.md), заменив имя плагина на `ME_CA_SupplySourcesPlugin`:

```text
-wbModule=WorldEditor -run -exitAfterInit -plugin=ME_CA_SupplySourcesPlugin -ME_CA_World=worlds/MP/CTI_Campaign_HQC_Eden.ent -ME_CA_LogJson=1
```

После завершения именно этого процесса выберите его `console.log`. Режим журнала не вызывает FileIO из скрипта Workbench. Существующий выходной файл не перезаписывается:

```powershell
.\tools\Convert-DiagnosticsLog.ps1 `
  -LogPath '<console.log этого запуска>' `
  -OutputPath .\exports\HQC_Eden_SupplySources_1.8.0.13.json `
  -ReportKind SupplySources

.\tools\New-SupplySourcesReport.ps1 `
  -ReportPath .\exports\HQC_Eden_SupplySources_1.8.0.13.json `
  -OutputDirectory .\exports\HQC_Eden_SupplySources_r0002 `
  -RevisionId r0002 `
  -RevisionReason 'Targeted source-base export and separate Harbors JSON' `
  -WorkbenchVersion 1.8.0.13
```

Создайте `exports/` до извлечения JSON. Для следующего снимка выберите свободную ревизию и укажите причину. `New-SupplySourcesReport.ps1` отказывается писать в существующий каталог и принимает только целевой отчёт с ожидаемым набором полей. Он не требует широкой диагностики.

Прямой файловый путь команды из меню наследует проверку свободного имени; по умолчанию это `exports/ME_CA_SupplySources_N.json`. Он может потребовать авторизации FileIO и ещё не проверен интерактивно. Проверенный путь выше использует сериализацию в журнал.

## Результат подготовки

`Supplies/Harbors.json` содержит нормализованные записи; `Supplies/Harbors.md` строится из этого файла. `world.json` содержит метаданные, `data.json` — индекс разделов, `Supplies.md` — индекс таблиц припасов. Минуты вычисляются делением секунд на 60 без усечения. Unknown и настройки, требующие анализа fallback, не превращаются в ноль: ячейка показывает `unknown`, исходное поле остаётся в `provenance.rawValue` с предупреждением записи.

Перенос проверенной подготовки в `snapshots/` и обновление манифеста пока ручные. Первая ревизия schemaVersion 1 сохраняется; schemaVersion 2 находится в `revisions/r0002/`. Полный отчёт по остальным категориям ещё не реализован.

Проверено на HQC Everon 1.8.0.13: два нативных прогона, 18 источников / 16 420 байт, значения и позиции совпали с широкой диагностикой. Полные результаты — [VALIDATION.md](VALIDATION.md). Структура ревизий — [DATA_LAYOUT.md](DATA_LAYOUT.md).


Вместимость исследуется отдельной командой [Inspect source base storage capacity](STORAGE_CAPACITY.md); её первая проверенная выборка ограничена аэропортом и хранится в `r0003`. Доход этого отчёта не подменяется вместимостью.
