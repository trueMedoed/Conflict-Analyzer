Текущая архитектура — **r0020**: [SUPPLY_PRIORITY.md](SUPPLY_PRIORITY.md). Подтверждённая source-иерархия и перенос соответствующих подписей в группы КП описаны отдельно; нижние группы не дублируются. Описание ниже сохраняет прежние ревизии для воспроизведения.

# Припасы по локациям

Генератор `tools/New-LocationSupplyReports.ps1` формирует единый Supplies/OtherContainers.md: сначала OtherContainers, в самом конце Harbors. Представление HQC Everon 1.8.0.13 находится в r0018; источник групп — Locations r0016, исходные значения и назначения не менялись.

## Результат

| Отчёт | Уникальных объектов | Сгруппировано | Локаций | Связей | Без группы |
| --- | ---: | ---: | ---: | ---: | ---: |
| OtherContainers | 124 | 109 | 25 | 119 | 15 |
| Harbors | 18 | 14 | 15 | 15 | 4 |

[Единый отчёт r0018](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0018/Supplies/OtherContainers.md), [Harbors в конце](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0018/Supplies/OtherContainers.md#harbors). Корневой Supplies/OtherContainers.md представляет эту ревизию; отдельного актуального Harbors.md нет. Старые файлы сохранены в r0017. Общий [Locations r0016](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0016/Locations.md) сохранён.

## Алгоритм

1. Прочитать Locations и соседний world.json, OtherContainers r0006 и Harbors r0004. Проверить schemaVersion / kind, версию, сценарий, уникальность ID и SHA-256 обоих supply-каталогов против Locations.inputs.
2. Проверить соответствие каждой исходной записи объекту Locations: ID, имя, собственные мировые координаты, статус позиции и вместимость. Взять готовые связи по ID; не пересчитывать радиус или ранжирование. В проверенном справочнике оба этапа используют 350 м по X/Z: населённые пункты / острова / холмы наравне, затем Generic только для остатка.
3. Разделить записи / связи / unassignedObjects по категориям other_supply_parent и supply_source_base. Сохранить все совпадения выбранного этапа; в каждом отчёте показать только его непустые группы. Совпадающие названия не объединять, пересечения не терять. Остаток каждого каталога — точное дополнение его сгруппированных ID.
4. Сохранить поля таблиц: OtherContainers — число и состав контейнеров, вместимость, начальный запас и статусы; Harbors — доход, исходные секунды, секунды / 60 в минутах, вместимость и статусы. Значения unknown не превращать в ноль. Полные физические слоты и происхождение полей остаются по ссылкам в прежних каталогах.
5. Сохранить JSON вида location-grouped-supply-view отдельно для каждой категории; из обоих сохранённых JSON построить один OtherContainers.md. Категория OtherContainers идёт первой, Harbors — последней; внутри каждой свои Summary / происхождение / ограничения, локации и остаток. Координаты подписи — в заголовке локации, собственные координаты / расстояния — в строках. Последние подразделы категорий называются OtherContainers без группы и Harbors без группы, с уникальными ссылками. Все столбцы прежних таблиц сохранены.
6. Итоги брать по уникальным source ID из исходного каталога, включая остаток. 568 физических контейнеров / 190700 вместимости OtherContainers; 49 / 40500 известного подытога Harbors, три базы unknown. Повторные строки в пересекающихся локациях не прибавлять к мировому запасу.

Это географическое представление для ручной сверки; source-иерархия, игровая база и ресурсная сеть по близости не устанавливаются. Даты / SHA-256 входов сохраняются; статус partial. Полные JSON исходных каталогов сохраняют прежние форматы, JSON представлений не заменяет их.

## Генерация

```powershell
.\tools\New-LocationSupplyReports.ps1 `
  -LocationsReportPath .\snapshots\1.8.0.13\worlds\CTI_Campaign_HQC_Eden\revisions\r0016\Locations.json `
  -OtherContainersReportPath .\snapshots\1.8.0.13\worlds\CTI_Campaign_HQC_Eden\revisions\r0006\Supplies\OtherContainers.json `
  -HarborsReportPath .\snapshots\1.8.0.13\worlds\CTI_Campaign_HQC_Eden\revisions\r0004\Supplies\Harbors.json `
  -OutputDirectory .\exports\HQC_Eden_SuppliesByLocation_r0018 `
  -RevisionId r0018 `
  -RevisionReason 'Combine supply views in OtherContainers with Harbors as the final section'
```

Выходной каталог должен быть свободен. После проверки перенос в snapshots / обновление корневых Markdown-копий и manifest выполняются вручную. Для следующей обработки выбрать новую ревизию; предыдущие файлы не перезаписывать.

В ревизии шесть файлов: world.json, data.json, Supplies.md, Supplies/OtherContainers.json, Supplies/OtherContainers.md и Supplies/Harbors.json. data.json — индекс: sourceBases.table=Supplies/OtherContainers.md#harbors, ungroupedSection ведёт к #othercontainers-без-группы / #harbors-без-группы в этом же Markdown. world.json хранит происхождение / ограничения; JSON сохраняют свои записи / локации / остаток. Normalizer location-grouped-supplies-0.2. Полный Locations не дублируется, отдельный Harbors.md не создаётся. Подробные проверки — [VALIDATION.md](VALIDATION.md).
