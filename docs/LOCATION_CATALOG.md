# Справочник групп локаций и оставшихся объектов

## Цель

Сверять группы в Workbench и находить разбросанные объекты. В радиусе 300 м первым этапом собрать города, деревни, поселения и острова на равных условиях; затем обработать только остаток у Name Generic. Оставшиеся объекты показать отдельно для ручного поиска связей. Сейчас включены OtherContainers и Harbors; машины / ИИ планируются позднее.

## Проверенный результат HQC Everon 1.8.0.13

В r0013 допущены 69 подписей из 170 исходных: 34 населённых пункта, 5 Name Island и 30 Name Generic. Первый этап содержит 50 уникальных объектов, второй — 63; всего 113 объектов / 123 связи у 29 групп. Осталось 29 из прежних 142 объектов. Прежние групповые связи r0012 сохранены; добавлены 3 объекта из остатка у Île-aux-Saules. Совпадения внутри первого этапа могут пересекаться, между этапами и остатком пересечений нет.

E_LivingArea_S_FIA_01 в 2873.642089 7.061999 2193.677001 сопоставлен с Île-aux-Saules: 265.792 м по X/Z. Это расстояние до точечной подписи Name Island, а не геометрическое определение нахождения на острове. SP_T3H_Lancre остаётся у Lancre (63.429 м), Airport сохраняет 5 объектов, Power Plant — 4. Все 5 островов допускаются по типу, остальные 4 пока не имеют объектов в радиусе.

[Группы r0013](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0013/Locations.md), [объекты без группы](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0013/UngroupedObjects.md), [канонический JSON](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0013/Locations.json). Корневые [Locations.md](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/Locations.md) / [UngroupedObjects.md](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/UngroupedObjects.md) представляют эту ревизию.

## Алгоритм

1. Нативная команда Export named world locations читает все именованные MapDescriptor-подписи мира и subscene, включая родительский Eden. Сохраняет DisplayName, MainType, UnitType, исходный ключ, перевод, язык, source-иерархию и проверенную мировую позицию. В проверенной выгрузке — 170 подписей, 1827 исследованных компонентов, 1657 пустых / недоступных DisplayName исключены; язык en_us. Новый запуск Workbench для этой пересборки не выполнялся.
2. По MainType / enumLabel допустить Name City / Name Town / Name Village / Name Settlement / Name Island и Name Generic. Первые пять имеют равный приоритет в этапе primary; Generic — второй этап generic. Сохранить matchingTier и исходные подписи / причины исключения. Исключена 101 подпись: 24 водоёма и 77 других типов; неизвестных типов в снимке нет.
3. Проверить версию / сценарий канонических OtherContainers r0006 и Harbors r0004. Взять 124 корневых родителя и 18 source base, сохранив их собственные имена, мировые координаты, ID, исходные ссылки, даты и SHA-256. Контейнерные позиции не подменяют позиции родителей.
4. Для каждого объекта получить все допустимые подписи в радиусе: dx²+dz² <= 300² включительно, до округления, без участия Y. Сначала сохранить все совпадения с населёнными пунктами и островами, не ранжируя их друг относительно друга. Если совпадений нет, сохранить все Name Generic. Радиус одинаков для обоих этапов; неизвестная позиция не считается нулевой. В ссылке — selectionTier primary / generic, horizontal_radius_proximity и ownershipEstablished=false. Порядок обхода не влияет на результат.
5. Из общего списка оставшихся исключить каждый объект, попавший хотя бы в одну группу выбранного этапа. Объект первого этапа не назначается Generic. Остаток — точное дополнение сгруппированных ID; причина no_settlement_island_or_generic_within_radius либо position_unknown_or_invalid. Не расширять радиус и не назначать другим типам автоматически.
6. Locations.json хранит 142 объекта один раз, списки групп — ссылки / расстояния / этап, unassignedObjects — оставшиеся ID / причины. Locations.md показывает 29 непустых групп с координатами локаций и самих объектов. UngroupedObjects.md показывает 29 оставшихся объектов с координатами. Индекс и манифест сохраняют параметры / полноту; источник обеих таблиц — Locations.json.

## Генерация по проверенным входам

```powershell
.\tools\New-LocationCatalogReport.ps1 `
  -LocationsReportPath .\exports\HQC_Eden_NamedLocations_1.8.0.13.json `
  -OtherContainersReportPath .\snapshots\1.8.0.13\worlds\CTI_Campaign_HQC_Eden\revisions\r0006\Supplies\OtherContainers.json `
  -HarborsReportPath .\snapshots\1.8.0.13\worlds\CTI_Campaign_HQC_Eden\revisions\r0004\Supplies\Harbors.json `
  -OutputDirectory .\exports\HQC_Eden_Locations_r0013 `
  -RadiusMeters 300 `
  -RevisionId r0013 `
  -RevisionReason 'Add Name Island with equal first-stage priority to settlements within 300 meters' `
  -WorkbenchVersion 1.8.0.13
```

По умолчанию RadiusMeters=300. Каталог результата должен быть свободен. Для нового чтения мира использовать проверенные параметры из [SOURCE_DIAGNOSTICS.md](SOURCE_DIAGNOSTICS.md) с -plugin=ME_CA_LocationsPlugin; извлечение журнала через Convert-DiagnosticsLog.ps1 -ReportKind NamedLocations проверяет UTF-8-байты, отвергает неполные / смешанные выгрузки и U+FFFD.

## Данные и ограничения

normalizerVersion location-catalog-0.5, schemaVersion 2, matchingPolicy settlements_and_islands_first_then_generic_within_radius_then_ungrouped. primaryMatchedObjectCount заменяет имя settlementMatchedObjectCount, так как первый этап теперь включает острова; matchingTier / selectionTier первого этапа — primary. locationFilter / matchingPriority сохранены в Locations.json / world.json. Все 170 исходных подписей, 142 объекта, прежние ревизии r0001–r0012, даты и SHA-256 входов сохранены.

Группа справочника означает попадание по расстоянию к точечной подписи разрешённого типа, а не фактическую иерархию мира, область локации, игровую базу или ресурсную сеть. Исходный мир не изменяется. Ручное изучение оставшихся объектов — следующий этап, его признаки ещё не выбраны. Source ID предварительные; их устойчивость между версиями и прямой FileIO-экспорт из меню остаются непроверенными. Статус partial. Проверки — [VALIDATION.md](VALIDATION.md).
