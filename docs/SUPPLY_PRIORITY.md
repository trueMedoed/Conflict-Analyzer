# Приоритеты групп мира

В r0031 используется один канонический Locations.json (schemaVersion 3, kind=priority-location-catalog). Из него и сохранённых настроек создаются Locations.md и Supplies/OtherContainers.md. Порядок: склады припасов, контрольные точки, Harbors, города / деревни, остальные объекты, нераспознанные.

## Алгоритм

1. Прочитать проверенные каталоги маркеров CampaignRemnantsSupplyDepot, контрольных точек, Harbors, хранилищ и подписей карты. Это чтение исходных фактов; порядок распределения начинается со складов.
2. Определить локацию каждого маркера склада в прежних 350 м по X/Z: Name City / Town / Village / Settlement, затем Name Generic / Island / Hill. Выбрать ближайшую подпись в первом подходящем этапе; равные расстояния — по ID. Водоёмы / неутверждённые типы не добавлять, маркер без подписи сохранить без локации.
3. Для каждого маркера собрать корневые хранилища OtherContainers в отдельном радиусе 100 м (DepotRadiusMeters), включительно до округления координат / расстояний. Используются мировые X/Z родительских агрегатов; Y не влияет. Все совпадения внутри этапа сохраняются, ID назначенных родителей исключаются из последующих этапов. Радиус не расширяется из-за source-родства; здесь отбор географический, sourceParentEstablished=false / ownershipEstablished=false.
4. Оставшиеся родители проверить по подтверждённой parentSourceId-иерархии ConflictControlPoint, затем Harbors. Сами 7 КП / 18 баз сохраняются как якоря. Их физические source-потомки хранятся отдельно как факт иерархии, не как повторное назначение уже отобранного склада.
5. Остаток распределить по населённым пунктам, затем Generic / Island / Hill в прежних 350 м по X/Z; внутри этапа сохранить все совпадения. Соответствующие готовые группы карты объединить с КП по прежним точным именам / prefab-ключам или явному правилу ControlPointMapLinks.json; проверка радиуса 350 м и отказ при неоднозначности сохраняются. Назначенные складам ID сюда не попадают и не переносятся обратно к КП.
6. Несопоставленные родители оставить в Нераспознанные. JSON сохраняет все исходные объекты / подписи / настройки / captures, а Markdown показывает категории в порядке склады → КП → Harbors → города / деревни → остальные → нераспознанные. Координаты маркеров и их компонентные настройки остаются скрыты; позиции локаций / родителей имеют три знака после точки.

## Проверенный результат

Все девять складов имеют хранилища: 49 корневых родителей / 266 физических SUPPLIES-контейнеров / 69600 настроенной вместимости. Régina: пять хранилищ в 12.745–41.627 м от маркера, 31 контейнер / 7100 вместимости; эти пять исключены из контрольной точки Régina.

Остаток: 35 родителей у 7 КП, 0 дополнительных у 18 Harbors, 13 у населённых пунктов, 23 у остальных локаций, 4 нераспознанных. Всего 124 уникальных родителя, 158 объектов, 124 связи, 45 видимых групп. StartingPos21 сохраняется; три прежних складских родителя дальше 100 м добавлены к остатку. Семь точных соответствий КП/map, 49 физических Harbor-слотов / 40500 известной вместимости / три unknown и все исходные значения / capture-даты прежние. Близость не проверяет игровую ресурсную сеть.

## Экспорт КП и генерация

Workbench CLI использует параметры [SOURCE_DIAGNOSTICS.md](SOURCE_DIAGNOSTICS.md), плагин ME_CA_ControlPointsPlugin, -ME_CA_World=worlds/MP/CTI_Campaign_HQC_Eden.ent -ME_CA_LogJson=1. После завершения именно этого процесса извлечь его журнал. Целевой экспорт складов выполнить по [SUPPLY_DEPOTS.md](SUPPLY_DEPOTS.md):

```powershell
.\tools\Convert-DiagnosticsLog.ps1 -LogPath '<console.log этого запуска>' `
  -OutputPath .\exports\HQC_Eden_ControlPoints_1.8.0.13.json -ReportKind ControlPoints

.\tools\New-SupplyPriorityReport.ps1 `
  -ControlPointsReportPath .\exports\HQC_Eden_ControlPoints_1.8.0.13.json `
  -SupplyDepotsReportPath .\exports\HQC_Eden_SupplyDepots_1.8.0.13.json `
  -ControlPointStorageReportPath .\exports\HQC_Eden_CommandPostStorage_1.8.0.13.json `
  -LocationsReportPath .\snapshots\1.8.0.13\worlds\CTI_Campaign_HQC_Eden\revisions\r0016\Locations.json `
  -OtherContainersViewPath .\snapshots\1.8.0.13\worlds\CTI_Campaign_HQC_Eden\revisions\r0018\Supplies\OtherContainers.json `
  -HarborsViewPath .\snapshots\1.8.0.13\worlds\CTI_Campaign_HQC_Eden\revisions\r0018\Supplies\Harbors.json `
  -WorldContainersReportPath .\exports\HQC_Eden_WorldSupplyContainers_1.8.0.13.json `
  -OutputDirectory .\exports\HQC_Eden_SupplyPriority_r0031 `
  -ControlPointMapLinksPath .\tools\config\ControlPointMapLinks.json `
  -RevisionId r0031 `
  -DepotRadiusMeters 100 -RadiusMeters 350 `
  -RevisionReason 'Show common command-post storage capacity with five- and six-container composition variants'
```

Выходные пути должны быть свободны. До переноса проверить данные и обновить manifest; старые ревизии не перезаписывать. Предыдущий New-LocationSupplyReports.ps1 сохраняется для воспроизведения r0017 / r0018.

В ревизии одиннадцать файлов: world.json, data.json, Supplies.md, Locations.json / .md, Supplies/ControlPoints.json, Supplies/OtherContainers.json / .md, Supplies/Harbors.json, Supplies/SupplyDepots.json, Supplies/ControlPointStorage.json. Native КП и складов сохраняются внутри метаданных и отдельных ControlPoints.json / SupplyDepots.json; полный старый ресурсный экспорт проверяется по SHA-256 исходного OtherContainers r0006. Сравнение версий по editor ID и runtime-принадлежность пока не проверены. [VALIDATION.md](VALIDATION.md).

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

## Без координат маркеров складов — r0028

r0028 убирает из обоих текущих Markdown координаты маркеров CampaignRemnantsSupplyDepot по прямому уточнению пользователя. Не переносить их в другие таблицы / строки этих документов. Заголовки локаций и собственные координаты контейнерных родителей остаются, формат 0.000 прежний. Настройки компонентов, расстояния, списки всех складов и остатки сохраняются. Полные позиции всех девяти маркеров остаются в каноническом JSON для расчётов и происхождения; JSON меняют только revision metadata. Десять файлов, schemaVersion 3, supply-priority-architecture-0.10; текущие root views r0028, r0001–r0027 неизменны.

## Без настроек компонентов маркеров — r0029

r0029 убирает таблицы настроек SCR_CampaignSuppliesComponent маркеров складов из Markdown: m_iSuppliesMax / m_iSupplies (50000 / 50000) и m_fOperationalRadius (20 м), а также сопутствующий абзац об операционном радиусе. Отбор маркеров, физические контейнеры, суммы / состав, расстояния и координаты локаций / объектов прежние. Native и все поля / позиции маркеров остаются в JSON; влияние этих настроек на игру не объявлять установленным, исследование отложено как опциональное в TODO. JSON меняют только revision metadata. Десять файлов, schemaVersion 3, supply-priority-architecture-0.11; текущие root views r0029, r0001–r0028 неизменны.

## Склады первым этапом — r0030

r0030 по новому указанию пользователя ставит склады первым этапом. Сначала каждый CampaignRemnantsSupplyDepot связывается с именованной локацией по прежнему радиусу 350 м: поселения, затем Generic / Island / Hill, ближайшая в подходящем этапе. Затем по мировым X/Z корневых родителей OtherContainers собираются все хранилища в отдельном радиусе DepotRadiusMeters=100 м включительно до округления. Их ID исключаются из всех дальнейших КП / Harbor / map этапов и объединений подписей с КП. Source-иерархия / правила соответствия имен для оставшихся объектов прежние; все совпадения внутри этапа сохраняются, proximity не означает source-родство или runtime-сеть. Порядок обработки и отображения: склады → КП → Harbors → города / деревни → остальные → нераспознанные. У всех 9 складов есть списки: 49 родителей / 266 физических контейнеров / 69600 вместимости; Régina — 5 / 31 / 7100, эти 5 удалены из КП Régina. Остальные категории: 35 / 0 / 13 / 23 / 4 родителей; 158 объектов / 124 связи / 45 видимых групп, 7 именованных локаций складов / 2 без локации. Семь соответствий КП/map прежние, transferredParentCount=35. Настройки / позиции маркеров остаются скрыты в Markdown; исходные records / captures / SHA-256 / физическая иерархия неизменны. SchemaVersion 3, десять файлов, supply-priority-architecture-0.12; текущие root views r0030, r0001–r0029 неизменны.

## Хранилище командного пункта — r0031

r0031 показывает у всех 7 КП строку «Командный пункт»: вместимость 1000, состав для 5 контейнеров — 5 × 200, для 6 — 5 × 166 + 1 × 170. Пользователь выбрал общую сумму и оба варианта состава; количество физических контейнеров различается (FIA=5, US=6, USSR=6), виртуальный представитель по одному в каждом варианте исключён. Workbench прочитал наследуемые prefab-источники без создания сущностей / открытия сценария; static slots до действия имеют по 100, целевой максимум 1000 распределяется целочисленно с остатком по установленному коду action. Состав calculated_from_installed_action_code, runtimeMeasured=false, выбранная фракция не назначается. Supplies/ControlPointStorage.json хранит 3 альтернативных prefab-варианта / 17 физических prototype-slots / 3 virtual, флаги / цепочку / происхождение, не мировые объекты. ControlPoints.records.commandPostStorage ссылается на каталог. Старые 250 / 500 и native поля КП остаются в JSON, в основной таблице заменены собственным хранилищем командного пункта; сообщение о нуле editor-source потомков скрыто только здесь. Полная вместимость сети базы / стартовые припасы не измерены; 1000 не прибавляется к сумме мировых каталогов. Все groups / objects / правила / source captures и контейнерные значения r0030 неизменны. Схема 3, supply-priority-architecture-0.13, 11 канонических файлов; текущие root views r0031, r0001–r0030 неизменны.

Новый обязательный вход ControlPointStorageReportPath — проверенный каталог kind=control-point-command-post-storage, schemaVersion 2, с gameVersion / worldPath / точным controlPointPrefab. Он сохранён в Supplies/ControlPointStorage.json.nativeInventory; для повторной генерации извлечь этот nativeInventory в отдельный JSON в exports. Генератор проверяет три варианта FIA / US / USSR, одинаковый resolved максимум, активный флаг действия, число физических слотов и равенство состава установленному правилу целочисленного распределения. Несогласованные данные вызывают отказ до записи файлов. Результат не назначает фракцию и не меняет приоритеты / радиусы.
