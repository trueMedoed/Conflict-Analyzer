<# Save configured physical SUPPLIES slots not already present in a verified base report.
   Never infer base ownership from proximity or add virtual views to capacity. #>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ReportPath,
    [Parameter(Mandatory = $true)][string]$KnownStorageReportPath,
    [Parameter(Mandatory = $true)][string]$OutputDirectory,
    [ValidatePattern('^r[0-9]{4}$')][string]$RevisionId = 'r0005',
    [Parameter(Mandatory = $true)][string]$RevisionReason,
    [string]$WorkbenchVersion
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$culture = [Globalization.CultureInfo]::InvariantCulture
$output = [IO.Path]::GetFullPath($OutputDirectory)
if (Test-Path -LiteralPath $output) { throw 'Output directory already exists; choose a new revision.' }
function Read-Input([string]$Path) {
    $bytes = [IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Path).Path)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $hash = ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '') }
    finally { $sha.Dispose() }
    [pscustomobject]@{ hash = $hash; value = ([Text.Encoding]::UTF8.GetString($bytes)).TrimStart([char]0xFEFF) | ConvertFrom-Json }
}
$inputReport = Read-Input $ReportPath
$inputKnown = Read-Input $KnownStorageReportPath
$native = $inputReport.value
$known = $inputKnown.value
if ($native.schemaVersion -ne 2 -or $native.kind -ne 'world-supply-containers' -or
    $native.selection -ne 'SCR_ResourceComponent-SUPPLIES-and-unresolved-slots' -or
    $native.resources.Count -ne $native.recordCount -or $native.inspectedResourceComponentCount -lt $native.recordCount -or
    !$native.editorEntityCountUnchanged -or $native.editorEntityCountBefore -ne $native.editorEntityCountAfter -or
    $native.gameVersion -notmatch '^\d+(\.\d+)+$' -or
    $native.worldPath -notmatch '/(?<scenario>[A-Za-z0-9_-]+)\.ent$') { throw 'Invalid targeted world container inventory.' }
$scenarioKey = $Matches.scenario
if ($known.schemaVersion -ne 2 -or $known.kind -ne 'source-bases-storage-capacity-report' -or
    $known.gameVersion -ne $native.gameVersion -or $known.scenarioKey -ne $scenarioKey -or $known.count -ne $known.bases.Count) {
    throw 'Incompatible known base storage report.'
}
$snapshotId = "$($native.gameVersion)/$scenarioKey/$RevisionId"
$capturedAtUTC = [DateTime]::ParseExact($native.generatedAtUTC, 'yyyy-MM-dd HH:mm:ss', $culture).ToString("yyyy-MM-dd'T'HH:mm:ss'Z'", $culture)
$knownPhysical = @{}
$knownVirtual = @{}
foreach ($base in $known.bases) {
    foreach ($item in $base.containers) {
        if (!$item.id -or $knownPhysical.ContainsKey($item.id)) { throw 'Duplicate known physical slot.' }
        $knownPhysical[$item.id] = $item
    }
    foreach ($item in $base.virtualViews) {
        if (!$item.id -or $knownVirtual.ContainsKey($item.id) -or $knownPhysical.ContainsKey($item.id)) { throw 'Duplicate known virtual slot.' }
        $knownVirtual[$item.id] = $item
    }
}
if ($knownPhysical.Count -ne $known.summary.physicalContainerCount -or $knownVirtual.Count -ne $known.summary.virtualViewCount) { throw 'Known report counts are inconsistent.' }
$nodes = @{}
foreach ($node in $native.nodes) {
    if (!$node.sourceId -or $nodes.ContainsKey($node.sourceId)) { throw 'Missing or duplicate source node.' }
    $nodes[$node.sourceId] = $node
}
function Get-PathNodes([string]$Id) {
    $path = [Collections.Generic.List[object]]::new()
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    while ($Id) {
        if (!$nodes.ContainsKey($Id) -or !$seen.Add($Id) -or $seen.Count -gt 257) { throw 'Missing, cyclic or excessive hierarchy.' }
        $node = $nodes[$Id]
        $path.Insert(0, $node)
        $Id = $node.parentSourceId
    }
    return $path.ToArray()
}
function Get-Label($Node) {
    if ($Node.name) { return $Node.name }
    if ($Node.prefab) { return [IO.Path]::GetFileNameWithoutExtension(($Node.prefab -replace '\\', '/')) }
    return $Node.sourceId
}
function Get-Field($Owner, [string]$Name) {
    $found = @($Owner.fields | Where-Object name -eq $Name)
    if ($found.Count -gt 1) { throw "Ambiguous field: $Name" }
    if ($found.Count -eq 1) { return $found[0] }
    return [pscustomobject]@{ name = $Name; status = 'unknown'; type = ''; value = ''; enumLabel = ''; values = @(); directOverride = $false }
}
function Get-Number($Field) {
    [double]$number = 0
    if ($Field.status -ne 'resolved' -or $Field.type -notin @('SCALAR','INTEGER') -or
        ![double]::TryParse($Field.value, [Globalization.NumberStyles]::Float, $culture, [ref]$number) -or
        [double]::IsNaN($number) -or [double]::IsInfinity($number) -or $number -lt 0) { return $null }
    return $number
}
function Get-Origin($Field, [string]$Path) {
    [ordered]@{
        fieldPath = $Path; field = $Field.name; method = 'BaseContainer.Get'; rawValue = $Field.value; rawType = $Field.type
        fieldStatus = $Field.status; directOverride = [bool]$Field.directOverride
        resolution = $(if ($Field.status -ne 'resolved') { 'unknown' } elseif ($Field.directOverride) { 'override' } else { 'inherited_or_default' })
        definingResource = $null; definingResourceStatus = 'unknown'
    }
}
function Assert-KnownIdentity($Item, $Previous) {
    if ($Item.prefab -cne $Previous.prefab -or $Item.subscene -ne $Previous.subscene -or $Item.layer -cne $Previous.layer -or
        $Item.containerClass -cne $Previous.containerClass -or $Item.resourceType -cne $Previous.resourceType -or
        $Item.capacitySupplies -ne $Previous.capacitySupplies -or $Item.configuredInitialSupplies -ne $Previous.configuredInitialSupplies -or
        $Item.worldPositionMeters.Count -ne $Previous.worldPositionMeters.Count) { throw 'Known slot identity or configuration changed.' }
    for ($axis = 0; $axis -lt $Item.worldPositionMeters.Count; $axis++) {
        if ([Math]::Abs($Item.worldPositionMeters[$axis] - $Previous.worldPositionMeters[$axis]) -gt 0.02) { throw 'Known slot coordinates changed.' }
    }
}
$records = [Collections.Generic.List[object]]::new()
$virtualViews = [Collections.Generic.List[object]]::new()
$unresolved = [Collections.Generic.List[object]]::new()
$unknownLists = [Collections.Generic.List[string]]::new()
$warnings = [Collections.Generic.List[string]]::new()
foreach ($warning in $native.warnings) { $warnings.Add($warning) }
$keys = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$componentKeys = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$matchedPhysical = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$matchedVirtual = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($resource in ($native.resources | Sort-Object sourceId, componentIndex)) {
    $componentKey = "$($resource.sourceId)/$($resource.componentIndex)"
    if (!$componentKeys.Add($componentKey) -or $resource.componentClass -ne 'SCR_ResourceComponent') { throw 'Duplicate or unexpected resource component.' }
    $path = @(Get-PathNodes $resource.sourceId)
    $node = $path[-1]
    # Choose the nearest ancestor prefab for a readable composition label, not base ownership.
    $group = $node
    for ($index = $path.Count - 2; $index -ge 0; $index--) { if ($path[$index].prefab) { $group = $path[$index]; break } }
    $enabledField = Get-Field $resource 'Enabled'
    $enabled = if ($enabledField.status -eq 'resolved' -and $enabledField.value -in @('true','false')) { $enabledField.value -eq 'true' } else { $null }
    $disabledField = Get-Field $resource 'm_aDisabledResourceTypes'
    $suppliesEnabled = if ($disabledField.status -eq 'resolved') { '0' -notin @($disabledField.values) } else { $null }
    if ($resource.containersStatus -ne 'resolved') { $unknownLists.Add($componentKey); $warnings.Add("Unknown container list: $componentKey") }
    foreach ($container in ($resource.containers | Sort-Object index)) {
        $key = "$componentKey/$($container.index)"
        if (!$keys.Add($key)) { throw 'Duplicate container slot.' }
        if (@($container.fields | ForEach-Object { $_.name } | Where-Object { $_ -notin @('m_eResourceType','m_eStorageType','m_fResourceValueMax','m_fResourceValueCurrent') }).Count -gt 0) { throw 'Unexpected container field.' }
        $type = Get-Field $container 'm_eResourceType'
        $storageType = Get-Field $container 'm_eStorageType'
        $max = Get-Field $container 'm_fResourceValueMax'
        $initial = Get-Field $container 'm_fResourceValueCurrent'
        $capacity = Get-Number $max
        $item = [pscustomobject][ordered]@{
            id = $key; groupSourceId = $group.sourceId; groupLabel = (Get-Label $group)
            sourceId = $node.sourceId; parentSourceId = $node.parentSourceId; sourceName = $node.name; label = (Get-Label $node)
            prefab = $node.prefab; subscene = $node.subscene; layer = $node.layer; positionStatus = $node.positionStatus
            worldPositionMeters = @($node.worldPositionMeters); hierarchySourceIds = @($path.sourceId)
            componentIndex = $resource.componentIndex; containerIndex = $container.index; containerClass = $container.className
            resourceType = $(if ($type.status -eq 'resolved') { $type.enumLabel } else { 'unknown' })
            storageType = $(if ($storageType.status -eq 'resolved') { $storageType.enumLabel } else { 'unknown' })
            componentEnabled = $enabled; suppliesEnabled = $suppliesEnabled; capacitySupplies = $capacity
            capacityStatus = $(if ($null -eq $capacity) { 'unknown' } else { 'resolved' })
            configuredInitialSupplies = (Get-Number $initial); baseOwnershipStatus = 'not_resolved'
            provenance = [ordered]@{
                capacity = (Get-Origin $max "SCR_ResourceComponent.m_aContainers[$($container.index)].m_fResourceValueMax")
                configuredInitial = (Get-Origin $initial "SCR_ResourceComponent.m_aContainers[$($container.index)].m_fResourceValueCurrent")
                resourceType = (Get-Origin $type "SCR_ResourceComponent.m_aContainers[$($container.index)].m_eResourceType")
                storageType = (Get-Origin $storageType "SCR_ResourceComponent.m_aContainers[$($container.index)].m_eStorageType")
                componentEnabled = (Get-Origin $enabledField 'SCR_ResourceComponent.Enabled')
                disabledTypes = [ordered]@{ field = $disabledField.name; values = @($disabledField.values); fieldStatus = $disabledField.status; directOverride = $disabledField.directOverride }
                containersDirectOverride = $resource.containersDirectOverride
            }
        }
        if ($type.status -ne 'resolved' -or $type.type -ne 'INTEGER' -or $type.value -ne '0' -or $type.enumLabel -ne 'SUPPLIES') {
            $item | Add-Member -NotePropertyName excludedReason -NotePropertyValue 'not_confirmed_supplies'
            $unresolved.Add($item); $warnings.Add("Unknown or unexpected resource type: $key")
        } elseif ($container.className -eq 'SCR_ResourceContainerVirtual') {
            if ($knownVirtual.ContainsKey($key)) { Assert-KnownIdentity $item $knownVirtual[$key]; $null = $matchedVirtual.Add($key) }
            else { $virtualViews.Add($item) }
        } elseif ($container.className -eq 'SCR_ResourceContainer') {
            if ($knownPhysical.ContainsKey($key)) { Assert-KnownIdentity $item $knownPhysical[$key]; $null = $matchedPhysical.Add($key) }
            else { $records.Add($item); if ($null -eq $capacity) { $warnings.Add("Unknown physical capacity: $key") } }
        } else {
            $item | Add-Member -NotePropertyName excludedReason -NotePropertyValue 'unresolved_container_class'
            $unresolved.Add($item); $warnings.Add("Unknown container class: $key")
        }
    }
}
if ($matchedPhysical.Count -ne $knownPhysical.Count -or $matchedVirtual.Count -ne $knownVirtual.Count) { throw 'Previously reported slots are missing from the fresh world inventory.' }
$groupRecords = @($records | Group-Object groupSourceId | Sort-Object Name | ForEach-Object {
    $members = @($_.Group | Sort-Object id)
    $subtotal = [double]0
    foreach ($item in $members) { if ($null -ne $item.capacitySupplies) { $subtotal += $item.capacitySupplies } }
    $complete = @($members | Where-Object capacityStatus -ne 'resolved').Count -eq 0
    [ordered]@{ sourceId = $_.Name; label = (Get-Label $nodes[$_.Name]); prefab = $nodes[$_.Name].prefab
        physicalContainerCount = $members.Count; knownCapacitySubtotalSupplies = $subtotal
        capacitySupplies = $(if ($complete) { $subtotal } else { $null }); capacityStatus = $(if ($complete) { 'resolved' } else { 'unknown' })
        containerIds = @($members.id) }
})
$knownSubtotal = [double]0
$initialSubtotal = [double]0
foreach ($item in $records) { if ($null -ne $item.capacitySupplies) { $knownSubtotal += $item.capacitySupplies }; if ($null -ne $item.configuredInitialSupplies) { $initialSubtotal += $item.configuredInitialSupplies } }
$capacityComplete = @($records | Where-Object capacityStatus -ne 'resolved').Count -eq 0 -and $unresolved.Count -eq 0 -and $unknownLists.Count -eq 0 -and @($warnings | Where-Object { $_ -like '*depth limit*' }).Count -eq 0
$report = [ordered]@{
    schemaVersion = 2; kind = 'other-supply-containers-report'; snapshotId = $snapshotId; status = 'partial'
    gameVersion = $native.gameVersion; scenarioKey = $scenarioKey; capturedAtUTC = $capturedAtUTC
    analyzerVersion = $native.analyzerVersion; normalizerVersion = 'other-supply-containers-0.1'; sourceReportSha256 = $inputReport.hash
    scope = 'configured_physical_SUPPLIES_slots_except_verified_base_storage'; unit = 'supplies'; count = $records.Count
    previousStorage = [ordered]@{ snapshotId = $known.snapshotId; reportSha256 = $inputKnown.hash; capturedAtUTC = $known.capturedAtUTC; excludedPhysicalSlotCount = $matchedPhysical.Count; excludedVirtualSlotCount = $matchedVirtual.Count }
    summary = [ordered]@{
        storageGroupCount = $groupRecords.Count; physicalContainerCount = $records.Count; virtualViewCount = $virtualViews.Count
        unresolvedSlotCount = $unresolved.Count; unknownContainerListCount = $unknownLists.Count
        capacitySupplies = $(if ($capacityComplete) { $knownSubtotal } else { $null }); capacityStatus = $(if ($capacityComplete) { 'resolved' } else { 'unknown' })
        knownCapacitySubtotalSupplies = $knownSubtotal; knownConfiguredInitialSubtotalSupplies = $initialSubtotal
        inspectedResourceComponentCount = $native.inspectedResourceComponentCount; filteredNonSuppliesSlotCount = $native.filteredNonSuppliesSlotCount
        worldPhysicalSuppliesSlotCount = $matchedPhysical.Count + $records.Count
    }
    storageGroups = $groupRecords; containers = @($records.ToArray()); virtualViews = @($virtualViews.ToArray()); unresolvedSlots = @($unresolved.ToArray())
    unknownContainerLists = @($unknownLists.ToArray()); warnings = @($warnings.ToArray())
}
$world = [ordered]@{
    schemaVersion = 2; snapshotId = $snapshotId; revisionId = $RevisionId; revisionReason = $RevisionReason; status = 'partial'
    gameVersion = $native.gameVersion; scenarioKey = $scenarioKey; worldPath = $native.worldPath; capturedAtUTC = $capturedAtUTC
    worldResourceGuid = $null; worldResourceGuidStatus = 'unknown'; gameChannel = $null; workbenchVersion = $WorkbenchVersion
    workbenchVersionStatus = $(if ($WorkbenchVersion) { 'provided_by_operator' } else { 'unknown' }); analyzerVersion = $native.analyzerVersion
    normalizerVersion = 'other-supply-containers-0.1'; identityStatus = 'provisional_editor_ids'; subscenes = $native.subscenes
    editorEntityCountUnchanged = $native.editorEntityCountUnchanged; addons = [ordered]@{ inventoryStatus = 'unknown'; completeLoadedInventory = $null }
    inputs = [ordered]@{ inventory = [ordered]@{ sha256 = $inputReport.hash; capturedAtUTC = $capturedAtUTC }; previousStorage = $report.previousStorage }
    warnings = $report.warnings
}
$index = [ordered]@{
    schemaVersion = 2; kind = 'conflict-world-index'; snapshotId = $snapshotId; status = 'partial'; worldMetadata = 'world.json'
    sections = [ordered]@{
        supplies = [ordered]@{ status = 'partial'; otherContainers = [ordered]@{ count = $records.Count; path = 'Supplies/OtherContainers.json'; table = 'Supplies/OtherContainers.md' }; knownBaseStorage = [ordered]@{ snapshotId = $known.snapshotId; status = 'previous_verified_revision' } }
        aiGroups = [ordered]@{ status = 'not_analyzed' }; startingBases = [ordered]@{ status = 'not_analyzed' }
        vehicleSpawns = [ordered]@{ status = 'not_analyzed' }; locations = [ordered]@{ status = 'not_analyzed' }
    }
}
$null = New-Item -ItemType Directory -Path (Join-Path $output 'Supplies')
function Write-Json([string]$Path, $Value) { [IO.File]::WriteAllText((Join-Path $output $Path), (($Value | ConvertTo-Json -Depth 40) + "`n"), [Text.UTF8Encoding]::new($false)) }
Write-Json 'world.json' $world; Write-Json 'data.json' $index; Write-Json 'Supplies/OtherContainers.json' $report
# Render only from the canonical JSON that was actually saved.
$saved = Get-Content -LiteralPath (Join-Path $output 'Supplies/OtherContainers.json') -Raw | ConvertFrom-Json
function Number($Value) { if ($null -eq $Value) { return 'unknown' }; return ([double]$Value).ToString('0.######', $culture) }
$lines = [Collections.Generic.List[string]]::new()
$lines.Add('# Остальные контейнеры с припасами'); $lines.Add(''); $lines.Add('## Summary'); $lines.Add('')
$lines.Add("Физических контейнеров: **$($saved.count)**, групп хранилищ / объектов: **$($saved.summary.storageGroupCount)**. Игра **$($saved.gameVersion)**, мир ``$scenarioKey.ent``, ревизия ``$RevisionId``. Статус **partial**.")
$lines.Add(''); $lines.Add("Из выборки исключены **$($saved.previousStorage.excludedPhysicalSlotCount)** физических контейнеров баз, уже сохранённых в ``$($known.snapshotId)``. Остальных виртуальных представлений: **$($saved.summary.virtualViewCount)**; они не входят в таблицу и сумму.")
$lines.Add(''); $lines.Add("Вместимость найденных остальных контейнеров: **$(Number $saved.summary.capacitySupplies) припасов**; известный подытог **$(Number $saved.summary.knownCapacitySubtotalSupplies)**. Неопределённых слотов: **$($saved.summary.unresolvedSlotCount)**, списков: **$($saved.summary.unknownContainerListCount)**.")
$lines.Add(''); $lines.Add('## Откуда берутся данные'); $lines.Add('')
$lines.Add('| Столбец | Источник |'); $lines.Add('| --- | --- |')
$lines.Add('| Хранилище / объект | Ближайший предок с prefab, либо сам объект; подпись по source name или имени prefab. Это группировка состава, не принадлежность игровой базе. |')
$lines.Add('| Контейнер | Source name, либо имя файла prefab физического объекта. |')
$lines.Add('| Вместимость, припасы | `SCR_ResourceComponent.m_aContainers[].m_fResourceValueMax`. |')
$lines.Add('| Начальные припасы в конфиге | `m_fResourceValueCurrent`; это не фактический запас в игровой сессии. |')
$lines.Add('| Координаты X / Y / Z, м | Мировая позиция editor entity, сверенная с преобразованиями родительской иерархии. |')
$lines.Add('| Source ID / компонент / слот | Уникальная комбинация ID source, индекса компонента и индекса контейнера. |')
$lines.Add(''); $lines.Add('## Контейнеры'); $lines.Add('')
$lines.Add('| Хранилище / объект | Контейнер | Вместимость, припасы | Начальные припасы в конфиге | Координаты X / Y / Z, м | Source ID / компонент / слот |')
$lines.Add('| --- | --- | ---: | ---: | --- | --- |')
foreach ($item in ($saved.containers | Sort-Object groupLabel, label, id)) {
    $position = if ($item.worldPositionMeters.Count -eq 3) { ($item.worldPositionMeters | ForEach-Object { Number $_ }) -join ' / ' } else { 'unknown' }
    $lines.Add("| $($item.groupLabel) | $($item.label) | $(Number $item.capacitySupplies) | $(Number $item.configuredInitialSupplies) | $position | $($item.id) |")
}
$lines.Add(''); $lines.Add('## Ограничения'); $lines.Add('')
$lines.Add('Включены настроенные физические `SUPPLIES`-слоты открытого мира и всех загруженных subscene, включая Eden. Декорации без ресурсного контейнера не считаются. Состояния компонента / типа ресурсов сохранены в JSON; настроенная вместимость не равна доступной вместимости во время игры.')
$lines.Add(''); $lines.Add('Рядом расположенные склады не назначаются базе автоматически. Runtime-связи, динамические постройки и создаваемые во время игры контейнеры ещё не анализируются. Виртуальные представления и неопределённые записи сохранены отдельно в JSON; прежние контейнеры исключены после проверки ID, prefab, конфигурации и координат.')
$lines.Add(''); $lines.Add('Данные: [OtherContainers.json](OtherContainers.json). Метаданные и источники: [world.json](../world.json).')
[IO.File]::WriteAllText((Join-Path $output 'Supplies/OtherContainers.md'), (($lines -join "`n") + "`n"), [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $output 'Supplies.md'), "# Припасы`n`nРевизия ``$RevisionId``: [остальные контейнеры](Supplies/OtherContainers.md), физические слоты ранее проверенных баз исключены. Принадлежность отдельных складов ресурсной сети пока не определена.`n", [Text.UTF8Encoding]::new($false))
[pscustomobject]@{ OutputDirectory = $output; PhysicalContainers = $records.Count; StorageGroups = $groupRecords.Count; VirtualViews = $virtualViews.Count; KnownSubtotalSupplies = $knownSubtotal; ExcludedKnownPhysical = $matchedPhysical.Count }
