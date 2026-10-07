# Приоритеты групп мира

В r0020 используется один канонический Locations.json (schemaVersion 3, kind=priority-location-catalog). Из него и сохранённых настроек создаются Locations.md и Supplies/OtherContainers.md. Порядок: контрольные точки, Harbors, города / деревни, остальные объекты, нераспознанные.

## Алгоритм

1. Контрольные точки отбираются отдельным целевым экспортом по prefab ConflictControlPoint. Читаются только Enabled / m_iSupplies / m_iSuppliesMax в SCR_CampaignSuppliesComponent и Enabled / m_sBaseName / m_iRadius в SCR_CampaignMilitaryBaseComponent. Название переводится WidgetManager.Translate; собственные мировые координаты независимо проверяются. Ближайшая prefab-ссылка не раскрывает все возможные варианты наследования; такие варианты остаются для отдельной проверки.
2. Для КП и Harbors проверяется цепочка parentSourceId полного ранее проверенного world-supply-containers. Физические SCR_ResourceContainer SUPPLIES перечислены по уникальному ID слота; виртуальные не суммируются. Source-родство подтверждается отдельно от игровой ресурсной сети. Радиус здесь не используется. Сами 7 КП и 18 Harbors всегда показаны как исходные точки своих категорий.
3. Из ранее агрегированных OtherContainers последовательно отбираются подтверждённые source-потомки КП и Harbors. Остаток проверяется по Name City / Town / Village / Settlement в 350 м X/Z включительно до округления; далее по Name Generic / Island / Hill в том же радиусе. Внутри одного этапа все совпадения сохраняются, между этапами повторов нет. Водоёмы и остальные неутверждённые типы не добавляются автоматически.
4. После распределения найти соответствующую подпись карты для каждой КП: разрешённый тип, координаты / имя resolved, расстояние между КП и подписью не более 350 м; одинаковое имя после нормализации регистра / пробелов либо точное совпадение суффикса #AR-Campaign_MapLocation_ с именем prefab без конечного _число (например Levie_Base / Levie_Base_01). При нескольких кандидатах генерация останавливается, при отсутствии подписи КП остаётся самостоятельной. Перенести существующий список группы к КП, убрать её нижний раздел и остальные нижние назначения перенесённых объектов. Это не новый поиск вокруг позиции КП и не изменение мира. Подтверждённые source-потомки, отобранные ранее, сохраняют свой приоритет.
5. Остаток сохраняется как unrecognizedObjects и отображается в конце. JSON хранит все 170 прежних подписей, все 149 объектов и происхождение. Контейнерные / базовые значения и даты r0018 сохранены; новые настройки КП имеют собственный целевой экспорт и время чтения. Настройки компонента КП учитываются отдельно от физической вместимости. Unknown остаётся unknown.

## Проверенный результат

7 КП: Calvary Hill, Île-aux-Saules, Military Base Levie, Montignac, Power Plant, Régina, Transformer Station. У каждой в конфиге m_iSupplies=250 и m_iSuppliesMax=500. Поля этого компонента представлены в [официальном Script API](https://community.bistudio.com/wikidata/external-data/arma-reforger/ArmaReforgerScriptAPIPublic/interfaceSCR__CampaignSuppliesComponent.html); значения взяты из локального экспорта версии 1.8.0.13.

В полном экспорте физических SUPPLIES-потомков КП не найдено; это остаётся отдельным фактом от групп справочника. Harbors сохраняет 49 подтверждённых физических контейнеров / 40500 известного подытога, три вместимости unknown. Из 124 OtherContainers (568 контейнеров / 190700 вместимости) **35** перенесены к 6 КП, **27** у 7 населённых пунктов, **47** у 12 остальных локаций, **15** нераспознанных. Всего 119 связей и 44 видимые группы. Calvary Hill содержит все 5 объектов прежней CALVARY HILL; остальные объединения: Montignac — 6, Régina — 9, Power Plant — 4, Île-aux-Saules — 4, Military Base Levie — 7. Для Transformer Station соответствующей подписи нет; соседний Provins не объединяется.

## Экспорт КП и генерация

Workbench CLI использует параметры [SOURCE_DIAGNOSTICS.md](SOURCE_DIAGNOSTICS.md), плагин ME_CA_ControlPointsPlugin, -ME_CA_World=worlds/MP/CTI_Campaign_HQC_Eden.ent -ME_CA_LogJson=1. После завершения именно этого процесса извлечь его журнал:

```powershell
.\tools\Convert-DiagnosticsLog.ps1 -LogPath '<console.log этого запуска>' `
  -OutputPath .\exports\HQC_Eden_ControlPoints_1.8.0.13.json -ReportKind ControlPoints

.\tools\New-SupplyPriorityReport.ps1 `
  -ControlPointsReportPath .\exports\HQC_Eden_ControlPoints_1.8.0.13.json `
  -LocationsReportPath .\snapshots\1.8.0.13\worlds\CTI_Campaign_HQC_Eden\revisions\r0016\Locations.json `
  -OtherContainersViewPath .\snapshots\1.8.0.13\worlds\CTI_Campaign_HQC_Eden\revisions\r0018\Supplies\OtherContainers.json `
  -HarborsViewPath .\snapshots\1.8.0.13\worlds\CTI_Campaign_HQC_Eden\revisions\r0018\Supplies\Harbors.json `
  -WorldContainersReportPath .\exports\HQC_Eden_WorldSupplyContainers_1.8.0.13.json `
  -OutputDirectory .\exports\HQC_Eden_SupplyPriority_r0020 `
  -RevisionId r0020 `
  -RevisionReason 'Merge corresponding map-label groups into control-point catalog groups, preserving proximity provenance'
```

Выходные пути должны быть свободны. До переноса проверить данные и обновить manifest; старые ревизии не перезаписывать. Предыдущий New-LocationSupplyReports.ps1 сохраняется для воспроизведения r0017 / r0018.

В ревизии девять файлов: world.json, data.json, Supplies.md, Locations.json / .md, Supplies/ControlPoints.json, Supplies/OtherContainers.json / .md, Supplies/Harbors.json. Native КП сохранён внутри метаданных и ControlPoints.json; полный старый ресурсный экспорт проверяется по SHA-256 исходного OtherContainers r0006. Сравнение версий по editor ID и runtime-принадлежность пока не проверены. [VALIDATION.md](VALIDATION.md).

## Происхождение объединений — r0020

Normalizer supply-priority-architecture-0.2, схема 3. mapGroupMerges и mergedMapLocations сохраняют имя / ID / тип / позицию исходной подписи, метод соответствия, расстояние между якорями, прежнюю категорию и transferredObjectIds. Нижняя группа сохраняет mergedIntoGroupId с пустым members. Каждый перенесённый member имеет method=merged_map_location_group, sourceParentEstablished=false и ownershipEstablished=false; mapLocationEvidence хранит прежний метод / категорию / расстояние до подписи. Основной distanceMeters пересчитан до позиции КП, поэтому сам по себе не проверяется на радиус подписи. PhysicalDescendantContainers сохраняет только фактическую source-иерархию. Старые ревизии, capture-даты и все значения сохранены; нового запуска Workbench для этой перегруппировки не было.
