# Приоритеты групп мира

В r0027 используется один канонический Locations.json (schemaVersion 3, kind=priority-location-catalog). Из него и сохранённых настроек создаются Locations.md и Supplies/OtherContainers.md. Порядок: контрольные точки, Harbors, склады припасов, города / деревни, остальные объекты, нераспознанные.

## Алгоритм

1. Контрольные точки отбираются отдельным целевым экспортом по prefab ConflictControlPoint. Читаются только Enabled / m_iSupplies / m_iSuppliesMax в SCR_CampaignSuppliesComponent и Enabled / m_sBaseName / m_iRadius в SCR_CampaignMilitaryBaseComponent. Название переводится WidgetManager.Translate; собственные мировые координаты независимо проверяются. Ближайшая prefab-ссылка не раскрывает все возможные варианты наследования; такие варианты остаются для отдельной проверки.
2. Для КП и Harbors проверяется цепочка parentSourceId полного ранее проверенного world-supply-containers. Физические SCR_ResourceContainer SUPPLIES перечислены по уникальному ID слота; виртуальные не суммируются. Source-родство подтверждается отдельно от игровой ресурсной сети. Радиус здесь не используется. Сами 7 КП и 18 Harbors всегда показаны как исходные точки своих категорий.
3. Из ранее агрегированных OtherContainers последовательно отбираются подтверждённые source-потомки КП и Harbors. Остаток проверяется по Name City / Town / Village / Settlement в 350 м X/Z включительно до округления; далее по Name Generic / Island / Hill в том же радиусе. Внутри одного этапа все совпадения сохраняются, между этапами повторов нет. Водоёмы и остальные неутверждённые типы не добавляются автоматически.
4. После распределения проверить явное пользовательское правило из tools/config/ControlPointMapLinks.json для этой версии / мира / source ID и rawName КП. Если правило есть, использовать только указанный mapLocationId; иначе найти соответствующую подпись карты для КП: разрешённый тип, координаты / имя resolved, расстояние между КП и подписью не более 350 м; одинаковое имя после нормализации регистра / пробелов либо точное совпадение суффикса #AR-Campaign_MapLocation_ с именем prefab без конечного _число (например Levie_Base / Levie_Base_01). При нескольких кандидатах генерация останавливается, при отсутствии подписи КП остаётся самостоятельной. Перенести существующий список группы к КП, убрать её нижний раздел и остальные нижние назначения перенесённых объектов. Это не новый поиск вокруг позиции КП и не изменение мира. Подтверждённые source-потомки, отобранные ранее, сохраняют свой приоритет.
5. После готовых КП/map объединений, сохраняя назначенные КП / Harbors ID, проверить оставшиеся OtherContainers у каждого CampaignRemnantsSupplyDepot: подтверждённая source-цепочка либо радиус 350 м X/Z до округления. Перенести совпадения из нижних картографических групп и остатка в категорию складов после Harbors; внутри этой категории сохранить все совпадения. Все девять маркеров остаются отдельными якорями, даже при пустом списке. Настройки компонента не суммируются с физическими контейнерами. [Экспорт / правила](SUPPLY_DEPOTS.md).
6. Остаток сохраняется как unrecognizedObjects и отображается в конце. JSON хранит все 170 прежних подписей, все 158 объектов и происхождение. Контейнерные / базовые значения и даты r0018 сохранены; новые настройки КП имеют собственный целевой экспорт и время чтения. Настройки компонента КП учитываются отдельно от физической вместимости. Unknown остаётся unknown.

## Проверенный результат

7 КП: Calvary Hill, Île-aux-Saules, Military Base Levie, Montignac, Power Plant, Régina, Transformer Station. У каждой в конфиге m_iSupplies=250 и m_iSuppliesMax=500. Поля этого компонента представлены в [официальном Script API](https://community.bistudio.com/wikidata/external-data/arma-reforger/ArmaReforgerScriptAPIPublic/interfaceSCR__CampaignSuppliesComponent.html); значения взяты из локального экспорта версии 1.8.0.13.

Физические source-потомки КП / маркеров складов не найдены; это отдельный факт от групп справочника. Harbors сохраняет 49 подтверждённых физических контейнеров / 40500 известного подытога, три полные вместимости unknown. 124 OtherContainers: **40** у 7 КП, **47** у 9 складов (8 непустых), **13** у 4 населённых пунктов, **23** у 7 остальных локаций, **1** нераспознанный StartingPos21. 127 связей, 45 видимых групп. Все семь КП/map объединений r0021 сохранены; склад рядом с Régina показан без собственного списка, потому что соседние объекты принадлежат более приоритетной группе справочника КП.

## Экспорт КП и генерация

Workbench CLI использует параметры [SOURCE_DIAGNOSTICS.md](SOURCE_DIAGNOSTICS.md), плагин ME_CA_ControlPointsPlugin, -ME_CA_World=worlds/MP/CTI_Campaign_HQC_Eden.ent -ME_CA_LogJson=1. После завершения именно этого процесса извлечь его журнал. Целевой экспорт складов выполнить по [SUPPLY_DEPOTS.md](SUPPLY_DEPOTS.md):

```powershell
.\tools\Convert-DiagnosticsLog.ps1 -LogPath '<console.log этого запуска>' `
  -OutputPath .\exports\HQC_Eden_ControlPoints_1.8.0.13.json -ReportKind ControlPoints

.\tools\New-SupplyPriorityReport.ps1 `
  -ControlPointsReportPath .\exports\HQC_Eden_ControlPoints_1.8.0.13.json `
  -SupplyDepotsReportPath .\exports\HQC_Eden_SupplyDepots_1.8.0.13.json `
  -LocationsReportPath .\snapshots\1.8.0.13\worlds\CTI_Campaign_HQC_Eden\revisions\r0016\Locations.json `
  -OtherContainersViewPath .\snapshots\1.8.0.13\worlds\CTI_Campaign_HQC_Eden\revisions\r0018\Supplies\OtherContainers.json `
  -HarborsViewPath .\snapshots\1.8.0.13\worlds\CTI_Campaign_HQC_Eden\revisions\r0018\Supplies\Harbors.json `
  -WorldContainersReportPath .\exports\HQC_Eden_WorldSupplyContainers_1.8.0.13.json `
  -OutputDirectory .\exports\HQC_Eden_SupplyPriority_r0027 `
  -ControlPointMapLinksPath .\tools\config\ControlPointMapLinks.json `
  -RevisionId r0027 `
  -RevisionReason 'Remove redundant supply depot subheadings and show marker coordinates in tables under locations'
```

Выходные пути должны быть свободны. До переноса проверить данные и обновить manifest; старые ревизии не перезаписывать. Предыдущий New-LocationSupplyReports.ps1 сохраняется для воспроизведения r0017 / r0018.

В ревизии десять файлов: world.json, data.json, Supplies.md, Locations.json / .md, Supplies/ControlPoints.json, Supplies/OtherContainers.json / .md, Supplies/Harbors.json, Supplies/SupplyDepots.json. Native КП и складов сохраняются внутри метаданных и отдельных ControlPoints.json / SupplyDepots.json; полный старый ресурсный экспорт проверяется по SHA-256 исходного OtherContainers r0006. Сравнение версий по editor ID и runtime-принадлежность пока не проверены. [VALIDATION.md](VALIDATION.md).

## Происхождение объединений — r0020

Normalizer supply-priority-architecture-0.2, схема 3. mapGroupMerges и mergedMapLocations сохраняют имя / ID / тип / позицию исходной подписи, метод соответствия, расстояние между якорями, прежнюю категорию и transferredObjectIds. Нижняя группа сохраняет mergedIntoGroupId с пустым members. Каждый перенесённый member имеет method=merged_map_location_group, sourceParentEstablished=false и ownershipEstablished=false; mapLocationEvidence хранит прежний метод / категорию / расстояние до подписи. Основной distanceMeters пересчитан до позиции КП, поэтому сам по себе не проверяется на радиус подписи. PhysicalDescendantContainers сохраняет только фактическую source-иерархию. Старые ревизии, capture-даты и все значения сохранены; нового запуска Workbench для этой перегруппировки не было.

## Явная связь Provins / Transformer Station — r0021

[ControlPointMapLinks.json](../tools/config/ControlPointMapLinks.json) — проверяемый список решений пользователя, а не игровой экспорт. Правило ограничено версией 1.8.0.13 / CTI_Campaign_HQC_Eden и конкретными ID обоих источников; новое имя / близость других локаций не создаёт новые правила. Сохраняются SHA-256 и активные rules в inputs.controlPointMapLinks; mergedMapLocations / mapGroupMerges содержит correspondenceMethod=user_confirmed_nearby_location и userDecision. Явное решение имеет приоритет перед автоматическим соответствием этой КП; тип подписи, resolved-позиции и радиус 350 м всё равно проверяются. Несуществующий / неоднозначный ID вызывает отказ до записи результата. Правило другой версии / сценария не применяется. Расстояние между КП и Provins — 231.365 м; пять объектов теперь в 24.719–83.671 м от КП. Исходные расстояния до Provins остаются в mapLocationEvidence, sourceParentEstablished / ownershipEstablished остаются false. Normalizer supply-priority-architecture-0.3, schemaVersion 3; старые шесть объединений и source-вместимости неизменны.

## Компактные таблицы родителей — r0022

Порядок: Родитель → Вместимость / Изначально → Состав, припасы → Координаты X Y Z, м → Расстояние, м. Последнего столбца нет у нераспознанных. Вместимость / Изначально читается из capacitySupplies / configuredInitialSupplies, значения выводятся как `2000 / 2000`; статусы проверяются независимо, unknown не заменяется нулём. Состав следует после суммы: например `2 × 1000`. Отдельные Source ID и Контейнеров не показываются в Markdown; полные sourceId / physicalContainerCount / capacityComposition остаются в JSON. Настройки компонентов КП и исходных Harbors сохраняют свои отдельные таблицы. Это изменение представления, без пересчёта / переименования JSON-полей или назначения групп; normalizer supply-priority-architecture-0.4, schemaVersion 3.

## Категория складов — r0023

SchemaVersion 3, supply-priority-architecture-0.5. inputs.supplyDepots / world.supplyDepotCapture и отдельный Supplies/SupplyDepots.json сохраняют свежий целевой экспорт и его дату / SHA-256. MatchingPolicy.supplyDepotRule задаёт радиус / защищённые КП-Harbors / source-chain-or-proximity, distanceOrigin=supply_depot_marker. 47 родителей дают 242 контейнера / 68000 вместимости по уникальным ID; настройки маркеров 50000 / 50000 учитываются отдельно, операционный радиус 20 м не заменяет радиус справочника 350 м. [Подробности](SUPPLY_DEPOTS.md).

## Единая таблица Harbors — r0024

В Supplies/OtherContainers.md раздел Harbors содержит одну таблицу из 18 строк: Название → Вместимость хранилищ, припасы → Состав, припасы → Пополнение, мин. → Пополнение за цикл, припасы → Координаты X Y Z, м. Состав вычисляется из сохранённых физических source-потомков в Locations.json по m_fResourceValueMax, с подсчётом уникальных ID слотов и группировкой одинаковой вместимости. Аэропорт: 4000, `2 × 500 + 3 × 1000`, 10 минут, 2000 за цикл. Все 49 слотов / 40500 известной вместимости сохранены; для StPierre / Lamentin / Meaux вместимость и состав unknown, а не ноль. Частично известный состав при неразрешённых слотах помечается unknown. Отдельные заголовки баз и повторные source-пояснения отсутствуют. Locations.md содержит одну географическую таблицу Harbors (имя / собственные координаты), без колонок припасов. JSON, группировка и остальные категории не изменяются; normalizer supply-priority-architecture-0.6, schemaVersion 3.

## Локация → склад → контейнеры — r0025

Привязка самого маркера выполняется отдельно от неизменённой привязки физических родителей к складу. SupplyDepotLocationRule: 350 м X/Z, сначала населённые пункты, затем Name Generic / Island / Hill; ближайший в первом подходящем этапе, равные расстояния — по ID. DepotLocationGrouping содержит locations / unlocatedDepots / associations и всех кандидатов; в каждом новом заголовке — имя / позиция подписи, внутри — позиция маркера и его прежние контейнеры. 7 маркеров связаны с 7 локациями, 2 остаются без привязки. Радиус не увеличен ради Levie / Figari. Все исходные groups / objects / records / captures и приоритеты не меняются. Normalizer supply-priority-architecture-0.7, schemaVersion 3, десять файлов. [Подробности](SUPPLY_DEPOTS.md).

## Координаты для Workbench — r0026

Координаты заголовков и строк обоих текущих справочников отображаются с тремя знаками после точки, разделены пробелами: `4943.125 28.594 11793.299`. Формат 0.000 не зависит от языка системы. Округляется только отображение; JSON хранит исходную точность и используется для расчёта расстояний / радиуса до округления. Интервалы, припасы, расстояния и группы не меняются. Normalizer supply-priority-architecture-0.8, schemaVersion 3; r0001–r0025 сохранены.

## Склады без повторных подзаголовков — r0027

r0027 убирает отдельные подзаголовки «Склад - X Y Z» из Locations.md и Supplies/OtherContainers.md по указанию пользователя. Остаётся заголовок именованной локации с её координатами; собственная позиция маркера показана в таблице «Координаты склада X Y Z, м», в отчёте припасов рядом с прежними настройками компонента. В текущих семи именованных группах по одному складу; отдельные подзаголовки не вводятся. Два маркера без локации показываются последовательными таблицами позиций / настроек и своими прежними списками. Все девять маркеров, пустой список Régina, 47 родителей / 242 контейнера / 68000 вместимости, расстояния и формат 0.000 сохраняются. JSON меняют только revision metadata; normalizer supply-priority-architecture-0.9, schemaVersion 3, десять файлов. Текущие root views r0027; r0001–r0026 неизменны.
