# Справочник групп локаций и оставшихся объектов

## Цель

Сверять группы в Workbench и находить разбросанные объекты. В радиусе 350 м первым этапом собрать населённые пункты, острова и холмы на равных условиях; затем обработать только остаток у Name Generic. Оставшиеся объекты показать отдельно для ручного поиска связей. Сейчас включены OtherContainers и Harbors; машины / ИИ планируются позднее.

## Проверенный результат HQC Everon 1.8.0.13

В r0015 допущены прежние 86 подписей из 170 исходных: 34 населённых пункта, 5 Name Island, 17 Name Hill и 30 Name Generic. Радиус обоих этапов повышен с 300 до 350 м. Первый этап — 62 уникальных объекта, второй — 61; всего 123 объекта / 134 связи у 31 группы. Без группы осталось 19 вместо 24. Из остатка добавлены 5 объектов, 2 прежних объекта Generic перешли к населённым пунктам, один получил ещё одну связь Generic. Совпадения внутри выбранного этапа сохраняются, между этапами и остатком пересечений нет.

SP_T3H_Gravette в 3817.628 5.025 7733.588 теперь входит в Gravette: 309.533 м по X/Z. SP_T3H_Thollevast в 3145.991 3.885 2141.905 входит в Île-aux-Saules: 309.332 м. У острова теперь 5 объектов, Airport сохраняет 5, Power Plant — 4, CALVARY HILL — 5, SP_T3H_Lancre остаётся у Lancre (63.429 м). Из 17 холмов только CALVARY HILL имеет объекты в текущем радиусе. Подписи используются как точки, геометрические границы локаций не определяются; Name Local, включая близкую подпись Thollevast, остаётся исключён.

[Группы r0015](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0015/Locations.md), [объекты без группы](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0015/UngroupedObjects.md), [канонический JSON](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0015/Locations.json). Корневые [Locations.md](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/Locations.md) / [UngroupedObjects.md](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/UngroupedObjects.md) представляют эту ревизию.

## Алгоритм

1. Нативная команда Export named world locations читает все именованные MapDescriptor-подписи мира и subscene, включая родительский Eden. Сохраняет DisplayName, MainType, UnitType, исходный ключ, перевод, язык, source-иерархию и проверенную мировую позицию. В проверенной выгрузке — 170 подписей, 1827 исследованных компонентов, 1657 пустых / недоступных DisplayName исключены; язык en_us. Новый запуск Workbench для этой пересборки не выполнялся.
2. По MainType / enumLabel допустить Name City / Name Town / Name Village / Name Settlement / Name Island / Name Hill и Name Generic. Первые шесть — равный приоритет этапа primary; Generic — второй этап generic. Сохранить matchingTier и исходные подписи / причины исключения. Исключены 84 подписи: 24 водоёма и 60 других типов; Name Ridge не включён, неизвестных типов в снимке нет.
3. Проверить версию / сценарий канонических OtherContainers r0006 и Harbors r0004. Взять 124 корневых родителя и 18 source base, сохранив их собственные имена, мировые координаты, ID, исходные ссылки, даты и SHA-256. Контейнерные позиции не подменяют позиции родителей.
4. Для каждого объекта получить все допустимые подписи в радиусе: dx²+dz² <= 350² включительно, до округления, без участия Y. Сначала сохранить все совпадения с населёнными пунктами, островами и холмами, не ранжируя их друг относительно друга. Если совпадений нет, сохранить все Name Generic. Радиус одинаков для обоих этапов; неизвестная позиция не считается нулевой. В ссылке — selectionTier primary / generic, horizontal_radius_proximity и ownershipEstablished=false. Порядок обхода не влияет на результат.
5. Из общего списка оставшихся исключить каждый объект, попавший хотя бы в одну группу выбранного этапа. Объект первого этапа не назначается Generic. Остаток — точное дополнение сгруппированных ID; причина no_primary_or_generic_within_radius либо position_unknown_or_invalid. Не расширять радиус и не назначать другим типам автоматически.
6. Locations.json хранит 142 объекта один раз, списки групп — ссылки / расстояния / этап, unassignedObjects — оставшиеся ID / причины. Locations.md показывает 31 непустую группу с координатами локаций и самих объектов. UngroupedObjects.md показывает 19 оставшихся объектов. Источник обеих таблиц — Locations.json; индекс и манифест сохраняют параметры / полноту.

## Генерация по проверенным входам

```powershell
.\tools\New-LocationCatalogReport.ps1 `
  -LocationsReportPath .\exports\HQC_Eden_NamedLocations_1.8.0.13.json `
  -OtherContainersReportPath .\snapshots\1.8.0.13\worlds\CTI_Campaign_HQC_Eden\revisions\r0006\Supplies\OtherContainers.json `
  -HarborsReportPath .\snapshots\1.8.0.13\worlds\CTI_Campaign_HQC_Eden\revisions\r0004\Supplies\Harbors.json `
  -OutputDirectory .\exports\HQC_Eden_Locations_r0015 `
  -RadiusMeters 350 `
  -RevisionId r0015 `
  -RevisionReason 'Increase both matching-stage radii from 300 to 350 meters' `
  -WorkbenchVersion 1.8.0.13
```

По умолчанию RadiusMeters=350. Каталог результата должен быть свободен. Для нового чтения мира использовать проверенные параметры из [SOURCE_DIAGNOSTICS.md](SOURCE_DIAGNOSTICS.md) с -plugin=ME_CA_LocationsPlugin; извлечение журнала через Convert-DiagnosticsLog.ps1 -ReportKind NamedLocations проверяет UTF-8-байты, отвергает неполные / смешанные выгрузки и U+FFFD.

## Данные и ограничения

normalizerVersion location-catalog-0.7, schemaVersion 2, matchingPolicy settlements_islands_and_hills_first_then_generic_within_radius_then_ungrouped. matchingTier / selectionTier первого этапа — primary; счётчик primaryMatchedObjectCount. locationFilter / matchingPriority сохранены в Locations.json / world.json. Все 170 исходных подписей / 142 объекта, прежние ревизии r0001–r0014, даты и SHA-256 входов сохранены.

Группа справочника означает попадание по расстоянию к точечной подписи разрешённого типа, а не фактическую иерархию мира, область локации, игровую базу или ресурсную сеть. Исходный мир не изменяется. Ручное изучение оставшихся объектов — следующий этап, его признаки ещё не выбраны. Source ID предварительные; их устойчивость между версиями и прямой FileIO-экспорт из меню остаются непроверенными. Статус partial. Проверки — [VALIDATION.md](VALIDATION.md).
