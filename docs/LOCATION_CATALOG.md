# Справочник групп населённых пунктов и оставшихся объектов

## Цель

Сверять группировку объектов возле городов, деревень и поселений в Workbench и находить разбросанные объекты. Сначала собрать группы в радиусе 300 м, затем показать оставшиеся объекты для ручного поиска связей. Сейчас включены только корневые объекты OtherContainers и базы Harbors; точки машин и ИИ добавляются позднее.

## Проверенный результат HQC Everon 1.8.0.13

В r0011 из 170 исходных именованных MapDescriptor-подписей допущены 34 населённых пункта: 1 Name City, 4 Name Town, 15 Name Village и 14 Name Settlement. Из 142 объектов к 13 населённым пунктам отнесены 47; остальные 95 показаны без группы. В этом снимке пересечений между списками групп нет: 47 связей с 47 уникальными объектами. В общем случае все попадания в несколько радиусов сохраняются.

SP_T3H_Lancre входит в Lancre: 63.429 м. Бухты, инфраструктура, пруды, реки, ручьи, озёра и другие типы подписи не участвуют в этом этапе. Они сохранены в JSON с причиной исключения; автоматического назначения оставшихся объектов таким локациям нет.

[Группы r0011](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0011/Locations.md), [объекты без группы](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0011/UngroupedObjects.md), [канонический JSON](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0011/Locations.json). Корневые [Locations.md](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/Locations.md) / [UngroupedObjects.md](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/UngroupedObjects.md) представляют эту ревизию.

## Алгоритм

1. Нативная команда Export named world locations читает все именованные MapDescriptor-подписи мира и subscene, включая родительский Eden. Сохраняет DisplayName, MainType, UnitType, исходный ключ, перевод, язык, source-иерархию и проверенную мировую позицию. В проверенной выгрузке — 170 подписей, 1827 исследованных компонентов, 1657 пустых / недоступных DisplayName исключены; язык en_us. Новый запуск Workbench для этой пересборки не выполнялся.
2. По MainType / enumLabel допустить только Name City / Name Town / Name Village / Name Settlement. Не фильтровать по словам в переводе. Неизвестный тип не угадывать. Все 170 исходных подписей сохраняются с matchingEligible / matchingExclusionReason. Исключены 136 подписей: 24 водоёма и 112 других типов; неизвестных типов в этом снимке нет.
3. Проверить версию / сценарий канонических OtherContainers r0006 и Harbors r0004. Взять 124 корневых родителя и 18 source base, сохранив их собственные имена, мировые координаты, ID, исходные ссылки, даты и SHA-256. Контейнерные позиции не подменяют позиции родителей.
4. Для каждого допустимого населённого пункта проверить все объекты. Условие dx²+dz² <= 300² включительно применяется к исходным координатам до округления. Высота Y не участвует; неизвестная позиция не считается нулевой. Сохранить все подходящие пары как horizontal_radius_proximity, ownershipEstablished=false. При пересечении радиусов объект может попасть в несколько групп; результат не должен зависеть от порядка обхода.
5. Из общего списка оставшихся исключить каждый объект, найденный хотя бы в одной группе. Сохранить точное дополнение к множеству сгруппированных объектов: причина no_settlement_within_radius либо position_unknown_or_invalid. Не расширять радиус и не назначать объекты другим локациям автоматически.
6. Locations.json хранит 142 объекта один раз, списки групп содержат ссылки по ID, unassignedObjects — оставшиеся ID / причины. Locations.md показывает только населённые пункты с объектами: название и координаты в заголовке; объект, расстояние, координаты в таблице. UngroupedObjects.md строится из того же JSON и показывает названия / собственные координаты оставшихся объектов. Сгруппированные объекты в нём отсутствуют. Общий data.json — индекс обеих таблиц; world.json / манифест сохраняют параметры и полноту.

## Генерация по проверенным входам

```powershell
.\tools\New-LocationCatalogReport.ps1 `
  -LocationsReportPath .\exports\HQC_Eden_NamedLocations_1.8.0.13.json `
  -OtherContainersReportPath .\snapshots\1.8.0.13\worlds\CTI_Campaign_HQC_Eden\revisions\r0006\Supplies\OtherContainers.json `
  -HarborsReportPath .\snapshots\1.8.0.13\worlds\CTI_Campaign_HQC_Eden\revisions\r0004\Supplies\Harbors.json `
  -OutputDirectory .\exports\HQC_Eden_Locations_r0011 `
  -RadiusMeters 300 `
  -RevisionId r0011 `
  -RevisionReason 'Group objects around settlements within 300 meters and list all remaining objects for manual review' `
  -WorkbenchVersion 1.8.0.13
```

По умолчанию RadiusMeters=300. Каталог результата должен быть свободен. Для нового чтения мира использовать проверенные параметры из [SOURCE_DIAGNOSTICS.md](SOURCE_DIAGNOSTICS.md) с -plugin=ME_CA_LocationsPlugin; извлечение журнала через Convert-DiagnosticsLog.ps1 -ReportKind NamedLocations проверяет UTF-8-байты, отвергает неполные / смешанные выгрузки и U+FFFD.

## Данные и ограничения

normalizerVersion location-catalog-0.3, schemaVersion 2, matchingPolicy all_settlements_within_radius_then_ungrouped. Фильтр allowedDescriptorTypes записан в Locations.json / world.json. Остальные исходные записи остаются в JSON для проверки. Опубликованные r0001–r0010, прежние даты и SHA-256 входов не изменены.

Группа справочника означает попадание по расстоянию к точечной подписи, а не фактическую иерархию мира, область локации, игровую базу или ресурсную сеть. Исходный мир не изменяется. Ручное изучение оставшихся объектов — следующий этап, его признаки ещё не выбраны. Source ID предварительные; их устойчивость между версиями и прямой FileIO-экспорт из меню остаются непроверенными. Статус partial. Проверки — [VALIDATION.md](VALIDATION.md).
