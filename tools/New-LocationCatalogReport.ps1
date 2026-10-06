<# Build a geographic index for verified OtherContainers parents and Harbors bases.
   Radius proximity allows multiple locations and never establishes gameplay ownership. #>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$LocationsReportPath,
    [Parameter(Mandatory = $true)][string]$OtherContainersReportPath,
    [Parameter(Mandatory = $true)][string]$HarborsReportPath,
    [Parameter(Mandatory = $true)][string]$OutputDirectory,
    [ValidateRange(0.001, 100000)][double]$RadiusMeters = 1000,
    [ValidatePattern('^r[0-9]{4}$')][string]$RevisionId = 'r0008',
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
$locationInput = Read-Input $LocationsReportPath
$otherInput = Read-Input $OtherContainersReportPath
$harborInput = Read-Input $HarborsReportPath
$native = $locationInput.value; $other = $otherInput.value; $harbor = $harborInput.value
if ($native.schemaVersion -ne 2 -or $native.kind -ne 'named-world-locations' -or
    $native.selection -ne 'named-map-descriptor-DisplayName' -or $native.locations.Count -ne $native.recordCount -or
    $native.inspectedDescriptorCount -ne $native.recordCount + $native.unnamedDescriptorCount -or
    !$native.editorEntityCountUnchanged -or $native.editorEntityCountBefore -ne $native.editorEntityCountAfter -or
    $native.gameVersion -notmatch '^\d+(\.\d+)+$' -or
    $native.worldPath -notmatch '/(?<scenario>[A-Za-z0-9_-]+)\.ent$') { throw 'Invalid named location inventory.' }
$scenarioKey = $Matches.scenario
if ($other.schemaVersion -ne 2 -or $other.kind -ne 'other-supply-containers-report' -or $other.grouping -ne 'root_source_ancestor' -or
    $other.gameVersion -ne $native.gameVersion -or $other.scenarioKey -ne $scenarioKey -or
    $other.storageGroups.Count -ne $other.summary.storageGroupCount -or $other.count -ne $other.containers.Count -or
    $harbor.schemaVersion -ne 2 -or $harbor.kind -ne 'supply-source-bases-report' -or
    $harbor.gameVersion -ne $native.gameVersion -or $harbor.scenarioKey -ne $scenarioKey -or $harbor.count -ne $harbor.records.Count) {
    throw 'Incompatible supply catalogs.'
}
$snapshotId = "$($native.gameVersion)/$scenarioKey/$RevisionId"
$capturedAtUTC = [DateTime]::ParseExact($native.generatedAtUTC, 'yyyy-MM-dd HH:mm:ss', $culture).ToString("yyyy-MM-dd'T'HH:mm:ss'Z'", $culture)
function Revision-File($Report, [string]$File) {
    if ($Report.snapshotId -notmatch "^$([regex]::Escape($native.gameVersion))/$([regex]::Escape($scenarioKey))/(r[0-9]{4})$") { throw 'Invalid source snapshot identity.' }
    return "../$($Matches[1])/$File"
}
$otherFile = Revision-File $other 'Supplies/OtherContainers.json'
$harborFile = Revision-File $harbor 'Supplies/Harbors.json'
function Is-Position($Position, [string]$Status) {
    if ($Status -ne 'resolved' -or @($Position).Count -ne 3) { return $false }
    foreach ($axis in $Position) {
        if ($null -eq $axis -or [double]::IsNaN([double]$axis) -or [double]::IsInfinity([double]$axis)) { return $false }
    }
    return $true
}
function Field($Location, [string]$Name) {
    $fields = @($Location.fields | Where-Object name -eq $Name)
    if ($fields.Count -ne 1) { throw "Missing or ambiguous descriptor field: $Name" }
    return $fields[0]
}
$objects = [Collections.Generic.List[object]]::new()
$objectIds = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$sourceIds = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($group in ($other.storageGroups | Sort-Object sourceId)) {
    $id = 'other_supply_parent/' + $group.sourceId
    if (!$group.sourceId -or !$objectIds.Add($id) -or !$sourceIds.Add($group.sourceId)) { throw 'Duplicate catalog object.' }
    $objects.Add([pscustomobject][ordered]@{
        id = $id; category = 'other_supply_parent'; name = $group.label; sourceId = $group.sourceId
        prefab = $group.prefab; subscene = $group.subscene; layer = $group.layer
        worldPositionMeters = @($group.worldPositionMeters); positionStatus = $group.positionStatus
        sourceSnapshotId = $other.snapshotId; sourceReport = $otherFile; sourceRecordId = $group.sourceId
        configuredCapacitySupplies = $group.capacitySupplies; capacityStatus = $group.capacityStatus
        physicalContainerCount = $group.physicalContainerCount
    })
}
foreach ($record in ($harbor.records | Sort-Object name)) {
    $id = 'supply_source_base/' + $record.source.sourceId
    if (!$record.source.sourceId -or !$objectIds.Add($id) -or !$sourceIds.Add($record.source.sourceId)) { throw 'Duplicate catalog object.' }
    $objects.Add([pscustomobject][ordered]@{
        id = $id; category = 'supply_source_base'; name = $record.name; sourceId = $record.source.sourceId
        prefab = $record.source.nearestPrefab; subscene = $record.source.subscene; layer = $record.source.layer
        worldPositionMeters = @($record.source.worldPositionMeters); positionStatus = $record.source.positionStatus
        sourceSnapshotId = $harbor.snapshotId; sourceReport = $harborFile; sourceRecordId = $record.source.sourceId
        configuredCapacitySupplies = $record.storage.capacitySupplies; capacityStatus = $record.storage.capacityStatus
        physicalContainerCount = $record.storage.physicalContainerCount
    })
}
$validObjects = @($objects | Where-Object { Is-Position $_.worldPositionMeters $_.positionStatus })
$unmatched = @{}; foreach ($item in $objects) { $unmatched[$item.id] = $(if (Is-Position $item.worldPositionMeters $item.positionStatus) { 'no_named_location_within_radius' } else { 'position_unknown_or_invalid' }) }
$locations = [Collections.Generic.List[object]]::new()
$locationIds = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$associationCount = 0
foreach ($marker in ($native.locations | Sort-Object displayName,sourceId,componentIndex)) {
    $id = "$($marker.sourceId)/$($marker.componentIndex)"
    if (!$marker.sourceId -or !$locationIds.Add($id) -or !$marker.rawName) { throw 'Missing or duplicate named location.' }
    if (@($marker.fields | ForEach-Object name | Where-Object { $_ -notin @('DisplayName','MainType','UnitType') }).Count) { throw 'Unexpected descriptor field.' }
    $nameField = Field $marker 'DisplayName'; $typeField = Field $marker 'MainType'; $null = Field $marker 'UnitType'
    if ($nameField.status -ne 'resolved' -or $nameField.value -cne $marker.rawName) { throw 'Descriptor name origin is inconsistent.' }
    $nearby = [Collections.Generic.List[object]]::new()
    if (Is-Position $marker.worldPositionMeters $marker.positionStatus) {
        foreach ($item in $validObjects) {
            $dx = [double]$item.worldPositionMeters[0] - [double]$marker.worldPositionMeters[0]
            $dz = [double]$item.worldPositionMeters[2] - [double]$marker.worldPositionMeters[2]
            $squaredDistance = $dx*$dx + $dz*$dz
            # Evaluate the inclusive boundary before rounding display distances.
            if ($squaredDistance -le $RadiusMeters*$RadiusMeters) {
                $nearby.Add([pscustomobject][ordered]@{ objectId = $item.id; distanceMeters = [Math]::Sqrt($squaredDistance); method = 'horizontal_radius_proximity'; ownershipEstablished = $false })
                $unmatched.Remove($item.id); $associationCount++
            }
        }
    }
    $locations.Add([pscustomobject][ordered]@{
        id = $id; name = $marker.displayName; nameStatus = $marker.nameStatus
        localizationKey = $(if ($marker.rawName.StartsWith('#')) { $marker.rawName } else { $null }); rawName = $marker.rawName
        language = $native.language; nameMethod = $marker.nameMethod
        descriptorType = $(if ($typeField.status -eq 'resolved') { $typeField.enumLabel } else { 'unknown' })
        sourceId = $marker.sourceId; parentSourceId = $marker.parentSourceId; sourceName = $marker.sourceName; prefab = $marker.prefab
        subscene = $marker.subscene; layer = $marker.layer; componentIndex = $marker.componentIndex; componentClass = $marker.componentClass
        worldPositionMeters = @($marker.worldPositionMeters); positionStatus = $marker.positionStatus
        nearbyObjectCount = $nearby.Count; nearbyObjects = @($nearby | Sort-Object distanceMeters,objectId)
        provenance = [ordered]@{ fieldPath = "$($marker.componentClass).DisplayName"; method = 'BaseContainer.Get'; rawValue = $nameField.value; fieldStatus = $nameField.status; directOverride = $nameField.directOverride; fields = $marker.fields; definingResource = $null; definingResourceStatus = 'unknown' }
    })
}
$unassigned = @($unmatched.Keys | Sort-Object | ForEach-Object { [ordered]@{ objectId = $_; reason = $unmatched[$_] } })
$warnings = @($native.warnings) + @('Only root parents in OtherContainers and source bases in Harbors are cataloged; AI, vehicles and HQ candidates are not added.', 'All locations within the horizontal radius are retained; a single object may appear in several location lists.', 'Supply coordinates retain their previous verified snapshots and capture times; proximity does not establish gameplay ownership.')
$inputs = [ordered]@{
    locations = [ordered]@{ sha256 = $locationInput.hash; capturedAtUTC = $capturedAtUTC; analyzerVersion = $native.analyzerVersion }
    otherContainers = [ordered]@{ sha256 = $otherInput.hash; snapshotId = $other.snapshotId; capturedAtUTC = $other.capturedAtUTC; path = $otherFile }
    harbors = [ordered]@{ sha256 = $harborInput.hash; snapshotId = $harbor.snapshotId; capturedAtUTC = $harbor.capturedAtUTC; storageCapturedAtUTC = $harbor.storageCapturedAtUTC; path = $harborFile }
}
$report = [ordered]@{
    schemaVersion = 2; kind = 'location-radius-catalog'; status = 'partial'; snapshotId = $snapshotId
    gameVersion = $native.gameVersion; scenarioKey = $scenarioKey; capturedAtUTC = $capturedAtUTC; language = $native.language
    analyzerVersion = $native.analyzerVersion; normalizerVersion = 'location-catalog-0.1'; radiusMeters = $RadiusMeters
    distanceMethod = 'horizontal_euclidean_XZ'; boundaryRule = 'distance_squared_less_than_or_equal_to_radius_squared'
    matchingPolicy = 'all_named_locations_within_radius'; objectScope = @('other_supply_parent','supply_source_base'); inputs = $inputs
    summary = [ordered]@{
        locationCount = $locations.Count; otherSupplyParentCount = $other.storageGroups.Count; supplySourceBaseCount = $harbor.records.Count
        objectCount = $objects.Count; validPositionObjectCount = $validObjects.Count; associatedObjectCount = $objects.Count - $unmatched.Count
        associationCount = $associationCount; unassignedObjectCount = $unmatched.Count
        locationsWithObjectsCount = @($locations | Where-Object nearbyObjectCount -gt 0).Count
        unknownLocationPositionCount = @($locations | Where-Object { !(Is-Position $_.worldPositionMeters $_.positionStatus) }).Count
    }
    objects = @($objects.ToArray()); locations = @($locations.ToArray()); unassignedObjects = $unassigned; warnings = $warnings
}
$world = [ordered]@{
    schemaVersion = 2; snapshotId = $snapshotId; revisionId = $RevisionId; revisionReason = $RevisionReason; status = 'partial'
    gameVersion = $native.gameVersion; scenarioKey = $scenarioKey; worldPath = $native.worldPath; capturedAtUTC = $capturedAtUTC
    analyzerVersion = $native.analyzerVersion; normalizerVersion = 'location-catalog-0.1'; workbenchVersion = $WorkbenchVersion
    workbenchVersionStatus = $(if ($WorkbenchVersion) { 'provided_by_operator' } else { 'unknown' }); language = $native.language
    worldResourceGuid = $null; worldResourceGuidStatus = 'unknown'; gameChannel = $null; identityStatus = 'provisional_editor_ids'
    subscenes = $native.subscenes; editorEntityCountUnchanged = $native.editorEntityCountUnchanged
    addons = [ordered]@{ inventoryStatus = 'unknown'; completeLoadedInventory = $null }; inputs = $inputs; warnings = $warnings
}
$index = [ordered]@{
    schemaVersion = 2; kind = 'conflict-world-index'; snapshotId = $snapshotId; status = 'partial'; worldMetadata = 'world.json'
    sections = [ordered]@{
        locations = [ordered]@{ status = 'partial'; path = 'Locations.json'; table = 'Locations.md'; locationCount = $locations.Count; objectCount = $objects.Count; radiusMeters = $RadiusMeters }
        supplies = [ordered]@{ status = 'previous_verified_revisions'; otherContainers = $otherFile; harbors = $harborFile }
        aiGroups = [ordered]@{ status = 'not_analyzed' }; startingBases = [ordered]@{ status = 'not_analyzed' }; vehicleSpawns = [ordered]@{ status = 'not_analyzed' }
    }
}
# Validation and spatial matching complete before creating the new revision.
$null = New-Item -ItemType Directory -Path $output
function Write-Json([string]$Path, $Value) { [IO.File]::WriteAllText((Join-Path $output $Path), (($Value | ConvertTo-Json -Depth 40) + "`n"), [Text.UTF8Encoding]::new($false)) }
Write-Json 'world.json' $world; Write-Json 'data.json' $index; Write-Json 'Locations.json' $report
$saved = Get-Content -LiteralPath (Join-Path $output 'Locations.json') -Raw | ConvertFrom-Json
$visibleLocations = @($saved.locations | Where-Object nearbyObjectCount -gt 0)
function Number($Value) { if ($null -eq $Value) { return 'unknown' }; return ([double]$Value).ToString('0.###', $culture) }
function Position($Value, [string]$Status) { if (!(Is-Position $Value $Status)) { return 'unknown' }; return ($Value | ForEach-Object { Number $_ }) -join ' ' }
function Label($Location) { if ($Location.nameStatus -eq 'resolved' -and $Location.name) { return $Location.name }; return $Location.rawName + ' (unknown)' }
function Text([string]$Value) { return $Value.Replace('|','\|').Replace("`r",' ').Replace("`n",' ').Trim() }
$savedObjects = @{}; foreach ($item in $saved.objects) { $savedObjects[$item.id] = $item }
$lines = [Collections.Generic.List[string]]::new()
$lines.Add("# Локации и объекты в радиусе $(Number $saved.radiusMeters) м"); $lines.Add('')
$lines.Add('## Цель'); $lines.Add('')
$lines.Add('Сверять, все ли объекты рядом с именованной локацией входят в её группу в мире, и находить объекты, которые разбросаны или находятся вне этой группы. Названия, расстояния и координаты помогают найти каждый объект в Workbench и проверить его место в иерархии.')
$lines.Add(''); $lines.Add('Список в радиусе служит ориентиром для ручной проверки групп. В дальнейшем справочник будет дополнен точками появления машин и групп ИИ; сейчас включены объекты OtherContainers и Harbors.')
$lines.Add(''); $lines.Add('## Summary'); $lines.Add('')
$lines.Add("Локаций с объектами: **$($visibleLocations.Count)**. Всего именованных локаций в JSON: **$($saved.summary.locationCount)**; без объектов скрыто: **$($saved.summary.locationCount - $visibleLocations.Count)**. Объектов справочника: **$($saved.summary.objectCount)** — **$($saved.summary.otherSupplyParentCount)** родителей OtherContainers и **$($saved.summary.supplySourceBaseCount)** баз Harbors. Игра **$($saved.gameVersion)**, мир ``$scenarioKey.ent``, ревизия ``$RevisionId``, язык ``$($saved.language)``. Статус **partial**.")
$lines.Add(''); $lines.Add("Радиус: **$(Number $saved.radiusMeters) м**, включительно. Расстояние по горизонтали X/Z. С локациями сопоставлены **$($saved.summary.associatedObjectCount)** объектов; без сопоставления **$($saved.summary.unassignedObjectCount)**. Всего связей **$($saved.summary.associationCount)**: один объект может находиться в радиусе нескольких подписей.")
$lines.Add(''); $lines.Add('## Откуда берутся данные'); $lines.Add('')
$lines.Add('| Данные | Источник |'); $lines.Add('| --- | --- |')
$lines.Add('| Локация | Именованный MapDescriptor: поле `DisplayName`, исходный ключ / текст и перевод `WidgetManager.Translate`; язык `WidgetManager.GetLanguage`. |')
$lines.Add('| Координаты локации | Мировая позиция source-объекта подписи карты, включая родительский Eden; сверена с преобразованиями родителей. |')
$lines.Add('| Объекты OtherContainers | Корневые родительские строки канонического отчёта r0006; позиции отдельных контейнеров не используются вместо позиции родителя. |')
$lines.Add('| Объекты Harbors | 18 source base из r0004, с сохранёнными собственными именами и мировыми координатами. |')
$lines.Add('| Расстояние | `sqrt((objectX-locationX)^2 + (objectZ-locationZ)^2)`; проверка ≤ радиуса выполняется до округления вывода. |')
$lines.Add(''); $lines.Add("Полные данные: [Locations.json](Locations.json), [метаданные](world.json). Входы: [OtherContainers]($otherFile), [Harbors]($harborFile).")
$lines.Add(''); $lines.Add('## Список локаций'); $lines.Add('')
$lines.Add('| Локация | Координаты X Y Z, м | Объектов в радиусе |')
$lines.Add('| --- | --- | ---: |')
foreach ($location in $visibleLocations) { $lines.Add("| $(Text (Label $location)) | $(Position $location.worldPositionMeters $location.positionStatus) | $($location.nearbyObjectCount) |") }
$lines.Add(''); $lines.Add('## Объекты по локациям'); $lines.Add('')
foreach ($location in $visibleLocations) {
    $lines.Add("### $(Text (Label $location)) - $(Position $location.worldPositionMeters $location.positionStatus)"); $lines.Add('')
    $lines.Add('| Объект | Расстояние, м | Координаты X Y Z, м |')
    $lines.Add('| --- | ---: | --- |')
    foreach ($link in $location.nearbyObjects) {
        $item = $savedObjects[$link.objectId]
        $lines.Add("| $(Text $item.name) | $(Number $link.distanceMeters) | $(Position $item.worldPositionMeters $item.positionStatus) |")
    }
    $lines.Add('')
}
$lines.Add('## Без сопоставления'); $lines.Add('')
if (!$saved.unassignedObjects.Count) { $lines.Add('Все объекты выбранных каталогов входят хотя бы в один радиус.'); $lines.Add('') }
else {
    $lines.Add('| Объект | Причина | ID |'); $lines.Add('| --- | --- | --- |')
    foreach ($item in $saved.unassignedObjects) { $lines.Add("| $(Text $savedObjects[$item.objectId].name) | $($item.reason) | $($item.objectId) |") }
    $lines.Add('')
}
$lines.Add('## Ограничения'); $lines.Add('')
$lines.Add('Это справочник близости к точечной подписи карты: радиус не является областью локации или доказательством принадлежности группе, игровой базе или ресурсной сети. Несколько совпадений сохраняются для проверки в Workbench. Включены только OtherContainers и Harbors; ИИ, машины, HQ-кандидаты и декорации не добавлены.')
$lines.Add(''); $lines.Add('Названия и координаты подписей прочитаны заново; объекты припасов сохраняют прежние проверенные снимки и даты сбора. Пустые подписи не включены; неразрешённые переводы и позиции обозначаются явно. Source ID — предварительные editor-идентификаторы, их устойчивость между версиями ещё не подтверждена.')
$lines.Add(''); $lines.Add('В Markdown показаны только локации с объектами; типы подписей, ID локаций и локации без объектов сохранены в каноническом JSON для проверки и сравнения.')
[IO.File]::WriteAllText((Join-Path $output 'Locations.md'), (($lines -join "`n") + "`n"), [Text.UTF8Encoding]::new($false))
[pscustomobject]@{ OutputDirectory = $output; Locations = $locations.Count; CatalogObjects = $objects.Count; AssociatedObjects = $objects.Count-$unmatched.Count; Associations = $associationCount; UnassignedObjects = $unmatched.Count }
