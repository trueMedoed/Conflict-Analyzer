# Приоритеты групп мира

В r0019 используется один канонический Locations.json (schemaVersion 3, kind=priority-location-catalog). Из него и сохранённых настроек создаются Locations.md и Supplies/OtherContainers.md. Порядок: контрольные точки, Harbors, города / деревни, остальные объекты, нераспознанные.

## Алгоритм

1. Контрольные точки отбираются отдельным целевым экспортом по prefab ConflictControlPoint. Читаются только Enabled / m_iSupplies / m_iSuppliesMax в SCR_CampaignSuppliesComponent и Enabled / m_sBaseName / m_iRadius в SCR_CampaignMilitaryBaseComponent. Название переводится WidgetManager.Translate; собственные мировые координаты независимо проверяются. Ближайшая prefab-ссылка не раскрывает все возможные варианты наследования; такие варианты остаются для отдельной проверки.
2. Для КП и Harbors проверяется цепочка parentSourceId полного ранее проверенного world-supply-containers. Физические SCR_ResourceContainer SUPPLIES перечислены по уникальному ID слота; виртуальные не суммируются. Source-родство подтверждается отдельно от игровой ресурсной сети. Радиус здесь не используется. Сами 7 КП и 18 Harbors всегда показаны как исходные точки своих категорий.
3. Из ранее агрегированных OtherContainers последовательно отбираются подтверждённые source-потомки КП и Harbors. Остаток проверяется по Name City / Town / Village / Settlement в 350 м X/Z включительно до округления; далее по Name Generic / Island / Hill в том же радиусе. Внутри одного этапа все совпадения сохраняются, между этапами повторов нет. Водоёмы и остальные неутверждённые типы не добавляются автоматически.
4. Остаток сохраняется как unrecognizedObjects и отображается в конце. JSON хранит все 170 прежних подписей, все 149 объектов и происхождение. Контейнерные / базовые значения и даты r0018 сохранены; новые настройки КП имеют собственный целевой экспорт и время чтения. Настройки компонента КП учитываются отдельно от физической вместимости. Unknown остаётся unknown.

## Проверенный результат

7 КП: Calvary Hill, Île-aux-Saules, Military Base Levie, Montignac, Power Plant, Régina, Transformer Station. У каждой в конфиге m_iSupplies=250 и m_iSuppliesMax=500. Поля этого компонента представлены в [официальном Script API](https://community.bistudio.com/wikidata/external-data/arma-reforger/ArmaReforgerScriptAPIPublic/interfaceSCR__CampaignSuppliesComponent.html); значения взяты из локального экспорта версии 1.8.0.13.

В полном экспорте физических SUPPLIES-потомков КП не найдено; их отдельные соседние ящики поэтому не назначены КП по близости. У Harbors подтверждены прежние 49 физических контейнеров, известный подытог 40500; три полные вместимости остаются unknown. Все 568 / 190700 остальных физических контейнеров сохранены в 124 родителях: 42 у 9 населённых пунктов, 67 у 16 остальных локаций, 15 нераспознанных. 119 географических связей. На каждой базовой точке сохраняются её собственные настройки независимо от наличия совпадений OtherContainers.

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
  -OutputDirectory .\exports\HQC_Eden_SupplyPriority_r0019 `
  -RevisionId r0019 `
  -RevisionReason 'Use confirmed hierarchy for control points and harbors, then 350 m matching for settlements and other map labels'
```

Выходные пути должны быть свободны. До переноса проверить данные и обновить manifest; старые ревизии не перезаписывать. Предыдущий New-LocationSupplyReports.ps1 сохраняется для воспроизведения r0017 / r0018.

В ревизии девять файлов: world.json, data.json, Supplies.md, Locations.json / .md, Supplies/ControlPoints.json, Supplies/OtherContainers.json / .md, Supplies/Harbors.json. Native КП сохранён внутри метаданных и ControlPoints.json; полный старый ресурсный экспорт проверяется по SHA-256 исходного OtherContainers r0006. Сравнение версий по editor ID и runtime-принадлежность пока не проверены. [VALIDATION.md](VALIDATION.md).
