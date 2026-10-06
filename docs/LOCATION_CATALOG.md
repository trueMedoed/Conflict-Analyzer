# Справочник групп локаций и оставшихся объектов

## Цель

Сверять группы в Workbench и находить разбросанные объекты. В радиусе 300 м сначала собрать группы городов, деревень и поселений, затем обработать только оставшиеся объекты у всех Name Generic. Показать остаток для ручного поиска связей. Сейчас включены только корневые объекты OtherContainers и базы Harbors; точки машин / ИИ добавляются позднее.

## Проверенный результат HQC Everon 1.8.0.13

В r0012 допущены 64 подписи из 170 исходных: 34 населённых пункта и 30 Name Generic. Первый этап сохраняет 47 объектов / 47 связей у 13 населённых пунктов из r0011. Второй добавляет 63 объекта / 73 связи у 15 Name Generic. Всего 110 уникальных объектов, 120 связей и 28 групп; 32 из прежних 142 объектов остаются без группы. Несколько связей одного объекта в одном этапе сохраняются; между этапами и остатком пересечений нет.

SP_T3H_Lancre остаётся у Lancre: 63.429 м, без назначения Name Generic. Base_Airport_FIA_01 входит в Airport (0 м); у Airport всего 5 объектов, у Power Plant — 4. Все 30 Name Generic допускаются по типу, включая общие названия инфраструктуры и местности; не фильтровать их по переводу. Бухты, водоёмы, другие типы и неизвестный тип не участвуют.

[Группы r0012](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0012/Locations.md), [объекты без группы](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0012/UngroupedObjects.md), [канонический JSON](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0012/Locations.json). Корневые [Locations.md](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/Locations.md) / [UngroupedObjects.md](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/UngroupedObjects.md) представляют эту ревизию.

## Алгоритм

1. Нативная команда Export named world locations читает все именованные MapDescriptor-подписи мира и subscene, включая родительский Eden. Сохраняет DisplayName, MainType, UnitType, исходный ключ, перевод, язык, source-иерархию и проверенную мировую позицию. В проверенной выгрузке — 170 подписей, 1827 исследованных компонентов, 1657 пустых / недоступных DisplayName исключены; язык en_us. Новый запуск Workbench для этой пересборки не выполнялся.
2. По MainType / enumLabel допустить Name City / Name Town / Name Village / Name Settlement и Name Generic. Первые четыре — этап settlement, Name Generic — этап generic. Сохранить matchingTier и исходные подписи / причины исключения. Исключены 106 подписей: 24 водоёма и 82 других типов; неизвестных типов в реальном снимке нет.
3. Проверить версию / сценарий канонических OtherContainers r0006 и Harbors r0004. Взять 124 корневых родителя и 18 source base, сохранив их собственные имена, мировые координаты, ID, исходные ссылки, даты и SHA-256. Контейнерные позиции не подменяют позиции родителей.
4. Для каждого объекта получить все допустимые подписи в радиусе: dx²+dz² <= 300² включительно, до округления, без участия Y. Сначала сохранить все совпадения с населёнными пунктами. Если их нет, сохранить все совпадения с Name Generic. Радиус одинаков для обоих этапов; неизвестная позиция не считается нулевой. В ссылках записать selectionTier, horizontal_radius_proximity и ownershipEstablished=false. Порядок обхода не влияет на результат.
5. Из общего списка оставшихся исключить каждый объект, попавший хотя бы в одну группу выбранного этапа. Объект с совпадением на первом этапе не назначается Name Generic. Остаток — точное дополнение к сгруппированным ID; причина no_settlement_or_generic_within_radius либо position_unknown_or_invalid. Не расширять радиус и не назначать другим типам автоматически.
6. Locations.json хранит все 142 объекта один раз, списки групп — ссылки / расстояния / этап, unassignedObjects — оставшиеся ID / причины. Locations.md показывает 28 непустых групп: имя - координаты локации в заголовке; объект, расстояние, собственные координаты в таблице. UngroupedObjects.md строится из того же JSON и показывает 32 оставшихся объекта с координатами. Общий data.json — индекс обеих таблиц; world.json / манифест сохраняют фильтр, matchingPriority и полноту.

## Генерация по проверенным входам

```powershell
.\tools\New-LocationCatalogReport.ps1 `
  -LocationsReportPath .\exports\HQC_Eden_NamedLocations_1.8.0.13.json `
  -OtherContainersReportPath .\snapshots\1.8.0.13\worlds\CTI_Campaign_HQC_Eden\revisions\r0006\Supplies\OtherContainers.json `
  -HarborsReportPath .\snapshots\1.8.0.13\worlds\CTI_Campaign_HQC_Eden\revisions\r0004\Supplies\Harbors.json `
  -OutputDirectory .\exports\HQC_Eden_Locations_r0012 `
  -RadiusMeters 300 `
  -RevisionId r0012 `
  -RevisionReason 'Match settlements first and add Name Generic within 300 meters for remaining objects' `
  -WorkbenchVersion 1.8.0.13
```

По умолчанию RadiusMeters=300. Каталог результата должен быть свободен. Для нового чтения мира использовать проверенные параметры из [SOURCE_DIAGNOSTICS.md](SOURCE_DIAGNOSTICS.md) с -plugin=ME_CA_LocationsPlugin; извлечение журнала через Convert-DiagnosticsLog.ps1 -ReportKind NamedLocations проверяет UTF-8-байты, отвергает неполные / смешанные выгрузки и U+FFFD.

## Данные и ограничения

normalizerVersion location-catalog-0.4, schemaVersion 2, matchingPolicy settlements_first_then_generic_within_radius_then_ungrouped. locationFilter / matchingPriority записаны в Locations.json / world.json; источник приоритета — MainType. Все исходные подписи / объекты сохранены в JSON. Опубликованные r0001–r0011, прежние даты и SHA-256 входов не изменены.

Группа справочника означает попадание по расстоянию к точечной подписи разрешённого типа, а не фактическую иерархию мира, область локации, игровую базу или ресурсную сеть. Исходный мир не изменяется. Ручное изучение оставшихся объектов — следующий этап, его признаки ещё не выбраны. Source ID предварительные; их устойчивость между версиями и прямой FileIO-экспорт из меню остаются непроверенными. Статус partial. Проверки — [VALIDATION.md](VALIDATION.md).
