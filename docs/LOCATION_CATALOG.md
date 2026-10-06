# Справочник групп локаций и оставшихся объектов

## Цель

Сверять группы в Workbench и находить разбросанные объекты. В радиусе 300 м первым этапом собрать населённые пункты, острова и холмы на равных условиях; затем обработать только остаток у Name Generic. Оставшиеся объекты показать отдельно для ручного поиска связей. Сейчас включены OtherContainers и Harbors; машины / ИИ планируются позднее.

## Проверенный результат HQC Everon 1.8.0.13

В r0014 допущены 86 подписей из 170 исходных: 34 населённых пункта, 5 Name Island, 17 Name Hill и 30 Name Generic. Первый этап — 55 уникальных объектов, второй — 63; всего 118 объектов / 128 связей у 30 групп. Без группы осталось 24. Прежние связи r0013 сохранены; у CALVARY HILL добавлены 5 объектов из остатка. Совпадения внутри первого этапа могут пересекаться, между этапами и остатком пересечений нет.

FieldHospital_M_FIA_01 в 3469.189941 179.867996 5808.756835 сопоставлен с CALVARY HILL: 38.343 м по X/Z. Это радиус вокруг точечной подписи Name Hill, а не определение границ холма. Île-aux-Saules сохраняет 3 объекта, Airport — 5, Power Plant — 4, SP_T3H_Lancre остаётся у Lancre (63.429 м). Из 17 холмов только CALVARY HILL имеет объекты в текущем радиусе; остальные исходные подписи сохраняются в JSON.

[Группы r0014](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0014/Locations.md), [объекты без группы](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0014/UngroupedObjects.md), [канонический JSON](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0014/Locations.json). Корневые [Locations.md](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/Locations.md) / [UngroupedObjects.md](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/UngroupedObjects.md) представляют эту ревизию.

## Алгоритм

1. Нативная команда Export named world locations читает все именованные MapDescriptor-подписи мира и subscene, включая родительский Eden. Сохраняет DisplayName, MainType, UnitType, исходный ключ, перевод, язык, source-иерархию и проверенную мировую позицию. В проверенной выгрузке — 170 подписей, 1827 исследованных компонентов, 1657 пустых / недоступных DisplayName исключены; язык en_us. Новый запуск Workbench для этой пересборки не выполнялся.
2. По MainType / enumLabel допустить Name City / Name Town / Name Village / Name Settlement / Name Island / Name Hill и Name Generic. Первые шесть — равный приоритет этапа primary; Generic — второй этап generic. Сохранить matchingTier и исходные подписи / причины исключения. Исключены 84 подписи: 24 водоёма и 60 других типов; Name Ridge не включён, неизвестных типов в снимке нет.
3. Проверить версию / сценарий канонических OtherContainers r0006 и Harbors r0004. Взять 124 корневых родителя и 18 source base, сохранив их собственные имена, мировые координаты, ID, исходные ссылки, даты и SHA-256. Контейнерные позиции не подменяют позиции родителей.
4. Для каждого объекта получить все допустимые подписи в радиусе: dx²+dz² <= 300² включительно, до округления, без участия Y. Сначала сохранить все совпадения с населёнными пунктами, островами и холмами, не ранжируя их друг относительно друга. Если совпадений нет, сохранить все Name Generic. Радиус одинаков для обоих этапов; неизвестная позиция не считается нулевой. В ссылке — selectionTier primary / generic, horizontal_radius_proximity и ownershipEstablished=false. Порядок обхода не влияет на результат.
5. Из общего списка оставшихся исключить каждый объект, попавший хотя бы в одну группу выбранного этапа. Объект первого этапа не назначается Generic. Остаток — точное дополнение сгруппированных ID; причина no_primary_or_generic_within_radius либо position_unknown_or_invalid. Не расширять радиус и не назначать другим типам автоматически.
6. Locations.json хранит 142 объекта один раз, списки групп — ссылки / расстояния / этап, unassignedObjects — оставшиеся ID / причины. Locations.md показывает 30 непустых групп с координатами локаций и самих объектов. UngroupedObjects.md показывает 24 оставшихся объекта. Источник обеих таблиц — Locations.json; индекс и манифест сохраняют параметры / полноту.

## Генерация по проверенным входам

```powershell
.\tools\New-LocationCatalogReport.ps1 `
  -LocationsReportPath .\exports\HQC_Eden_NamedLocations_1.8.0.13.json `
  -OtherContainersReportPath .\snapshots\1.8.0.13\worlds\CTI_Campaign_HQC_Eden\revisions\r0006\Supplies\OtherContainers.json `
  -HarborsReportPath .\snapshots\1.8.0.13\worlds\CTI_Campaign_HQC_Eden\revisions\r0004\Supplies\Harbors.json `
  -OutputDirectory .\exports\HQC_Eden_Locations_r0014 `
  -RadiusMeters 300 `
  -RevisionId r0014 `
  -RevisionReason 'Add Name Hill to the first matching stage alongside settlements and islands within 300 meters' `
  -WorkbenchVersion 1.8.0.13
```

По умолчанию RadiusMeters=300. Каталог результата должен быть свободен. Для нового чтения мира использовать проверенные параметры из [SOURCE_DIAGNOSTICS.md](SOURCE_DIAGNOSTICS.md) с -plugin=ME_CA_LocationsPlugin; извлечение журнала через Convert-DiagnosticsLog.ps1 -ReportKind NamedLocations проверяет UTF-8-байты, отвергает неполные / смешанные выгрузки и U+FFFD.

## Данные и ограничения

normalizerVersion location-catalog-0.6, schemaVersion 2, matchingPolicy settlements_islands_and_hills_first_then_generic_within_radius_then_ungrouped. matchingTier / selectionTier первого этапа — primary; счётчик primaryMatchedObjectCount. locationFilter / matchingPriority сохранены в Locations.json / world.json. Все 170 исходных подписей / 142 объекта, прежние ревизии r0001–r0013, даты и SHA-256 входов сохранены.

Группа справочника означает попадание по расстоянию к точечной подписи разрешённого типа, а не фактическую иерархию мира, область локации, игровую базу или ресурсную сеть. Исходный мир не изменяется. Ручное изучение оставшихся объектов — следующий этап, его признаки ещё не выбраны. Source ID предварительные; их устойчивость между версиями и прямой FileIO-экспорт из меню остаются непроверенными. Статус partial. Проверки — [VALIDATION.md](VALIDATION.md).
