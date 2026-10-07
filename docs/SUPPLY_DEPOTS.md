# Склады припасов CampaignRemnantsSupplyDepot

В r0023 отдельная категория **«Склады припасов»** стоит после Harbors в Locations.md и Supplies/OtherContainers.md. В HQC Eden 1.8.0.13 целевой экспорт нашёл **9** экземпляров CampaignRemnantsSupplyDepot. Их SCR_MapDescriptorComponent имеет MainType=87 / Icon (generic), DisplayName пустой: эти маркеры не входят в прежние 170 именованных подписей.

## Что читается

Команда World Editor: `Plugins → [ME] Conflict Analyzer → Reports → Export campaign supply depots`, класс ME_CA_SupplyDepotsPlugin.

Отбор по ближайшей prefab-ссылке, оканчивающейся на `/CampaignRemnantsSupplyDepot.et`; обход обеих subscene и source-потомков. Сохраняются source ID / parent ID, имя, prefab, слой / subscene и мировая позиция, независимо проверенная общим Describe. Неименованный source обозначается stem prefab; суффиксы редактора не придумываются.

| Компонент | Поля |
| --- | --- |
| SCR_CampaignSuppliesComponent | Enabled, m_iSupplies, m_iSuppliesMax, m_fOperationalRadius, m_bIsStandaloneDepot |
| SCR_MapDescriptorComponent | DisplayName, MainType, UnitType |

Все девять в проверенном экспорте включены, standaloneDepot=true; настроено 50000 / 50000 для m_iSuppliesMax / m_iSupplies и операционный радиус 20 м. Это поля компонента маркера, которые не суммируются с физическими контейнерами и не являются runtime-замером.

## Связи с контейнерами

Пользователь выбрал маркеры вместе с контейнерами в радиусе **350 м**, сохраняя приоритет КП и Harbors. Поэтому сначала формируются их подтверждённые source-группы и ранее принятые объединения подписей с КП. Среди остальных корневых родителей OtherContainers проверяются source-цепочки и горизонтальный радиус X/Z вокруг каждого маркера склада, включительно до округления. Подходящие объекты исключаются из городов / деревень, остальных подписей и остатка; все совпадения внутри категории складов сохраняются.

Политика в matchingPolicy.supplyDepotRule; расстояние отсчитывается до позиции маркера, distanceOrigin=supply_depot_marker. В проверенном мире физических source-потомков этих маркеров нет: все 47 назначений — horizontal_radius_proximity, sourceParentEstablished=false, ownershipEstablished=false. Близость в справочнике не подтверждает игровую ресурсную сеть. Радиус 350 м для справочника отличается от m_fOperationalRadius=20 в конфиге компонента.

Итог: **47** уникальных родителей / **242** физических контейнера / **68000** припасов настроенной вместимости из прежнего OtherContainers. **14** объектов добавлены из прежних 15 нераспознанных; остался StartingPos21. Маркер рядом с Régina сохранён без отдельного списка родителей: соседние объекты уже находятся у КП. Все девять маркеров показаны, даже при пустом списке.

## Запуск и сохранение

Для отдельного Workbench CLI использовать [SOURCE_DIAGNOSTICS.md](SOURCE_DIAGNOSTICS.md) с `-plugin=ME_CA_SupplyDepotsPlugin -ME_CA_World=worlds/MP/CTI_Campaign_HQC_Eden.ent -ME_CA_LogJson=1`. Не сохранять сцену. После завершения конкретного процесса извлечь его журнал:

```powershell
.\tools\Convert-DiagnosticsLog.ps1 -LogPath '<console.log этого запуска>' `
  -OutputPath .\exports\HQC_Eden_SupplyDepots_1.8.0.13.json -ReportKind SupplyDepots
```

Конвертер требует полный успешный отчёт, проверяет UTF-8-байты, уникальные source ID / точный prefab / счётчики и не перезаписывает существующий файл. Генерация шести категорий — [SUPPLY_PRIORITY.md](SUPPLY_PRIORITY.md); новый параметр SupplyDepotsReportPath обязателен.

Supplies/SupplyDepots.json сохраняет выбранные настройки и полный узкий native-экспорт девяти маркеров, world.json — его метаданные. inputs.supplyDepots хранит отдельную capture-дату / SHA-256; даты контейнеров / Harbors / КП / подписей сохраняются прежними. В r0023 десять файлов, schemaVersion 3, normalizer supply-priority-architecture-0.5; старые ревизии неизменны. Статус partial, runtime-сеть и сравнение версий остаются для проверки. [VALIDATION.md](VALIDATION.md).
