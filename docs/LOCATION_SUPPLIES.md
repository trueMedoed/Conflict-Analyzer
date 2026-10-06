# Припасы по локациям

Генератор `tools/New-LocationSupplyReports.ps1` строит отдельно OtherContainers и Harbors по готовому справочнику Locations. В HQC Everon 1.8.0.13 представления сохранены в r0017; новые данные мира не считывались.

## Результат

| Отчёт | Уникальных объектов | Сгруппировано | Локаций | Связей | Без группы |
| --- | ---: | ---: | ---: | ---: | ---: |
| OtherContainers | 124 | 109 | 25 | 119 | 15 |
| Harbors | 18 | 14 | 15 | 15 | 4 |

[OtherContainers r0017](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0017/Supplies/OtherContainers.md), [Harbors r0017](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0017/Supplies/Harbors.md). Корневые Markdown-таблицы представляют эти отчёты. Общий [Locations r0016](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0016/Locations.md) сохранён.

## Алгоритм

1. Прочитать Locations и соседний world.json, OtherContainers r0006 и Harbors r0004. Проверить schemaVersion / kind, версию, сценарий, уникальность ID и SHA-256 обоих supply-каталогов против Locations.inputs.
2. Проверить соответствие каждой исходной записи объекту Locations: ID, имя, собственные мировые координаты, статус позиции и вместимость. Взять готовые связи по ID; не пересчитывать радиус или ранжирование. В проверенном справочнике оба этапа используют 350 м по X/Z: населённые пункты / острова / холмы наравне, затем Generic только для остатка.
3. Разделить записи / связи / unassignedObjects по категориям other_supply_parent и supply_source_base. Сохранить все совпадения выбранного этапа; в каждом отчёте показать только его непустые группы. Совпадающие названия не объединять, пересечения не терять. Остаток каждого каталога — точное дополнение его сгруппированных ID.
4. Сохранить поля таблиц: OtherContainers — число и состав контейнеров, вместимость, начальный запас и статусы; Harbors — доход, исходные секунды, секунды / 60 в минутах, вместимость и статусы. Значения unknown не превращать в ноль. Полные физические слоты и происхождение полей остаются по ссылкам в прежних каталогах.
5. Записать JSON вида location-grouped-supply-view отдельно для каждого отчёта; Markdown генерировать из сохранённого JSON. Заголовок группы содержит название и координаты подписи; строки — собственные координаты объектов и расстояние. В конце каждого файла — «Объекты без группы» с его оставшимися записями. Harbors сохраняет пополнение / вместимость, OtherContainers — свой состав / начальный запас / Source ID.
6. Итоги брать по уникальным source ID из исходного каталога, включая остаток. 568 физических контейнеров / 190700 вместимости OtherContainers; 49 / 40500 известного подытога Harbors, три базы unknown. Повторные строки в пересекающихся локациях не прибавлять к мировому запасу.

Это географическое представление для ручной сверки; source-иерархия, игровая база и ресурсная сеть по близости не устанавливаются. Даты / SHA-256 входов сохраняются; статус partial. Полные JSON исходных каталогов сохраняют прежние форматы, JSON представлений не заменяет их.

## Генерация

```powershell
.\tools\New-LocationSupplyReports.ps1 `
  -LocationsReportPath .\snapshots\1.8.0.13\worlds\CTI_Campaign_HQC_Eden\revisions\r0016\Locations.json `
  -OtherContainersReportPath .\snapshots\1.8.0.13\worlds\CTI_Campaign_HQC_Eden\revisions\r0006\Supplies\OtherContainers.json `
  -HarborsReportPath .\snapshots\1.8.0.13\worlds\CTI_Campaign_HQC_Eden\revisions\r0004\Supplies\Harbors.json `
  -OutputDirectory .\exports\HQC_Eden_SuppliesByLocation_r0017 `
  -RevisionId r0017 `
  -RevisionReason 'Present OtherContainers and Harbors separately grouped by the verified Locations snapshot'
```

Выходной каталог должен быть свободен. После проверки перенос в snapshots / обновление корневых Markdown-копий и manifest выполняются вручную. Для следующей обработки выбрать новую ревизию; предыдущие файлы не перезаписывать.

В ревизии семь файлов: world.json, data.json, Supplies.md и две пары Supplies/OtherContainers.json / .md, Supplies/Harbors.json / .md. data.json — индекс, world.json — происхождение / ограничения, в каждом JSON собственные записи / локации / остаток. Полный Locations не дублируется. Подробные проверки — [VALIDATION.md](VALIDATION.md).
