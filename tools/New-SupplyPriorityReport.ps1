<# Classify configured supplies by source anchors first, then named map locations.
   All spatial links remain proximity observations, not gameplay ownership. #>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$ControlPointsReportPath,
    [Parameter(Mandatory=$true)][string]$SupplyDepotsReportPath,
    [Parameter(Mandatory=$true)][string]$LocationsReportPath,
    [Parameter(Mandatory=$true)][string]$OtherContainersViewPath,
    [Parameter(Mandatory=$true)][string]$HarborsViewPath,
    [Parameter(Mandatory=$true)][string]$WorldContainersReportPath,
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [string]$ControlPointMapLinksPath=(Join-Path $PSScriptRoot 'config/ControlPointMapLinks.json'),
    [ValidateRange(0.001,100000)][double]$RadiusMeters=350,
    [ValidatePattern('^r[0-9]{4}$')][string]$RevisionId='r0023',
    [Parameter(Mandatory=$true)][string]$RevisionReason
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$culture=[Globalization.CultureInfo]::InvariantCulture
function Assert($condition,$message){if(!$condition){throw $message}}
function ReadInput($path){$full=(Resolve-Path -LiteralPath $path).Path;[pscustomobject]@{hash=(Get-FileHash -LiteralPath $full).Hash;value=(Get-Content -LiteralPath $full -Raw -Encoding utf8 | ConvertFrom-Json)}}
function Same($a,$b){($a | ConvertTo-Json -Depth 40 -Compress) -ceq ($b | ConvertTo-Json -Depth 40 -Compress)}
function ValidPosition($p,$status){if($status -cne 'resolved' -or @($p).Count -ne 3){return $false};foreach($v in $p){if($null -eq $v -or [double]::IsNaN([double]$v) -or [double]::IsInfinity([double]$v)){return $false}};$true}
$output=[IO.Path]::GetFullPath($OutputDirectory);Assert (!(Test-Path -LiteralPath $output)) 'Output exists; select a new revision.'
$cpInput=ReadInput $ControlPointsReportPath;$locInput=ReadInput $LocationsReportPath;$otherInput=ReadInput $OtherContainersViewPath;$harborInput=ReadInput $HarborsViewPath
$inventoryInput=ReadInput $WorldContainersReportPath;$inventory=$inventoryInput.value
$cp=$cpInput.value;$oldLocations=$locInput.value;$other=$otherInput.value;$harbors=$harborInput.value
$depotInput=ReadInput $SupplyDepotsReportPath;$depots=$depotInput.value
Assert ($depots.schemaVersion -eq 2 -and $depots.kind -ceq 'campaign-remnants-supply-depots' -and $depots.selection -ceq 'CampaignRemnantsSupplyDepot-prefab' -and $depots.records.Count -eq $depots.recordCount -and $depots.editorEntityCountUnchanged -and $depots.coordinateMismatchCount -eq 0 -and @($depots.records.sourceId | Sort-Object -Unique).Count -eq $depots.recordCount) 'Invalid native supply-depot export.'
Assert ($cp.schemaVersion -eq 2 -and $cp.kind -ceq 'conflict-control-points' -and $cp.selection -ceq 'ConflictControlPoint-prefab' -and $cp.records.Count -eq $cp.recordCount -and $cp.editorEntityCountUnchanged -and $cp.coordinateMismatchCount -eq 0) 'Invalid native control-point export.'
Assert ($oldLocations.kind -ceq 'location-radius-catalog' -and $oldLocations.schemaVersion -eq 2) 'Invalid map/location seed.'
Assert ($other.kind -ceq 'location-grouped-supply-view' -and $other.category -ceq 'other_supply_parent' -and $harbors.kind -ceq 'location-grouped-supply-view' -and $harbors.category -ceq 'supply_source_base') 'Invalid previous supply views.'
$version=$oldLocations.gameVersion;$scenario=$oldLocations.scenarioKey;$snapshotId="$version/$scenario/$RevisionId";$normalizer='supply-priority-architecture-0.5'
Assert ($depots.gameVersion -ceq $version -and $depots.worldPath -ceq $cp.worldPath) 'Supply-depot world/version mismatch.'
$mapLinksInput=ReadInput $ControlPointMapLinksPath
Assert ($mapLinksInput.value.schemaVersion -eq 1 -and $mapLinksInput.value.kind -ceq 'user-confirmed-control-point-map-links') 'Invalid explicit control-point/map links.'
$activeMapLinks=@($mapLinksInput.value.rules | Where-Object {$_.gameVersion -ceq $version -and $_.scenarioKey -ceq $scenario})
Assert ($cp.gameVersion -ceq $version -and $cp.worldPath.EndsWith("/$scenario.ent")) 'Control-point world/version mismatch.'
foreach($view in @($other,$harbors)){Assert ($view.gameVersion -ceq $version -and $view.scenarioKey -ceq $scenario -and $view.inputs.locations.sha256 -ceq $locInput.hash -and $view.records.Count -eq $view.summary.objectCount) 'Supply seed identity/hash mismatch.'}
Assert ($inventory.kind -ceq 'world-supply-containers' -and $inventory.schemaVersion -eq 2 -and $inventory.gameVersion -ceq $version -and $inventory.worldPath -ceq $cp.worldPath -and $inventory.editorEntityCountUnchanged -and $inventory.coordinateMismatchCount -eq 0) 'Invalid supply hierarchy inventory.'
$originalOtherPath=[IO.Path]::GetFullPath((Join-Path (Split-Path -Parent ([IO.Path]::GetFullPath($OtherContainersViewPath))) $other.inputs.supplies.path))
$originalOtherInput=ReadInput $originalOtherPath
Assert ($originalOtherInput.hash -ceq $other.inputs.supplies.sha256 -and $originalOtherInput.value.sourceReportSha256 -ceq $inventoryInput.hash) 'Supply hierarchy differs from original OtherContainers inventory.'
$nodes=@{};foreach($node in $inventory.nodes){Assert (!$nodes.ContainsKey($node.sourceId)) 'Duplicate hierarchy node.';$nodes[$node.sourceId]=$node}
function IsDescendant($sourceId,$ancestorId){$visited=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal);$id=$sourceId;while($id){Assert ($visited.Add($id)) 'Parent cycle in inventory.';if($id -ceq $ancestorId){return $true};Assert ($nodes.ContainsKey($id)) 'Incomplete source parent chain.';$id=$nodes[$id].parentSourceId};$false}
$physicalSlots=@(foreach($resource in $inventory.resources){foreach($slot in $resource.containers){if($slot.className -cne 'SCR_ResourceContainer'){continue};$type=@($slot.fields | Where-Object name -ceq 'm_eResourceType');Assert ($type.Count -eq 1 -and $type[0].status -ceq 'resolved' -and $type[0].enumLabel -ceq 'SUPPLIES') 'Unexpected physical resource type.';[ordered]@{id="$($resource.sourceId)/$($resource.componentIndex)/$($slot.index)";sourceId=$resource.sourceId;componentIndex=$resource.componentIndex;containerIndex=$slot.index;fields=$slot.fields}}})
function RevisionPath($source,$file){Assert ($source.snapshotId -match "^$([regex]::Escape($version))/$([regex]::Escape($scenario))/(r[0-9]{4})$") 'Invalid previous snapshot identity.';"../$($Matches[1])/$file"}
$inputs=[ordered]@{controlPoints=[ordered]@{sha256=$cpInput.hash;capturedAtUTC=$cp.generatedAtUTC;analyzerVersion=$cp.analyzerVersion};locations=[ordered]@{path=(RevisionPath $oldLocations 'Locations.json');sha256=$locInput.hash;capturedAtUTC=$oldLocations.capturedAtUTC};otherContainers=[ordered]@{path=(RevisionPath $other 'Supplies/OtherContainers.json');sha256=$otherInput.hash;originalSupplies=$other.inputs.supplies};harbors=[ordered]@{path=(RevisionPath $harbors 'Supplies/Harbors.json');sha256=$harborInput.hash;originalSupplies=$harbors.inputs.supplies}}
$inputs.worldContainers=[ordered]@{sha256=$inventoryInput.hash;capturedAtUTC=$inventory.generatedAtUTC;originalOtherContainersSnapshot=$originalOtherInput.value.snapshotId;originalOtherContainersPath=(RevisionPath $originalOtherInput.value 'Supplies/OtherContainers.json');originalOtherContainersSha256=$originalOtherInput.hash}
$inputs.controlPointMapLinks=[ordered]@{kind=$mapLinksInput.value.kind;sha256=$mapLinksInput.hash;rules=$activeMapLinks}
$inputs.supplyDepots=[ordered]@{sha256=$depotInput.hash;capturedAtUTC=$depots.generatedAtUTC;analyzerVersion=$depots.analyzerVersion}
function CfgInteger($record,$componentClass,$fieldName){$fields=@($record.components | Where-Object className -ceq $componentClass | ForEach-Object fields | Where-Object name -ceq $fieldName);if($fields.Count -ne 1 -or $fields[0].status -cne 'resolved'){return [ordered]@{value=$null;status='unknown'}};[ordered]@{value=[int]::Parse($fields[0].value,$culture);status='resolved'}}
function CfgValue($record,$componentClass,$fieldName,$type){$fields=@($record.components | Where-Object className -ceq $componentClass | ForEach-Object fields | Where-Object name -ceq $fieldName);if($fields.Count -ne 1 -or $fields[0].status -cne 'resolved'){return [ordered]@{value=$null;status='unknown'}};$value=$(if($type -ceq 'bool'){[bool]::Parse($fields[0].value)}else{[double]::Parse($fields[0].value,$culture)});[ordered]@{value=$value;status='resolved'}}
$controlRecords=@(foreach($record in ($cp.records | Sort-Object displayName,sourceId)){
    Assert ($record.prefab -match '/ConflictControlPoint[^/]*\.et$') 'Unexpected control-point prefab.'
    [ordered]@{objectId="control_point/$($record.sourceId)";sourceId=$record.sourceId;sourceName=$record.sourceName;name=$record.displayName;nameStatus=$record.nameStatus;worldPositionMeters=@($record.worldPositionMeters);positionStatus=$record.positionStatus;prefab=$record.prefab;configuredComponentSupplies=(CfgInteger $record 'SCR_CampaignSuppliesComponent' 'm_iSupplies');configuredComponentSuppliesMax=(CfgInteger $record 'SCR_CampaignSuppliesComponent' 'm_iSuppliesMax');runtimeResourceGridCapacityStatus='not_analyzed';rawName=$record.rawName;nameMethod=$record.nameMethod;language=$cp.language;provenance=$record.components}
})
$depotRecords=@(foreach($record in ($depots.records | Sort-Object sourceId)){
    Assert ($record.prefab -cmatch '/CampaignRemnantsSupplyDepot\.et$') 'Unexpected supply-depot prefab.'
    [ordered]@{objectId="supply_depot/$($record.sourceId)";sourceId=$record.sourceId;sourceName=$record.sourceName;name=$(if($record.sourceName){$record.sourceName}else{[IO.Path]::GetFileNameWithoutExtension($record.prefab)});labelMethod=$(if($record.sourceName){'source_name'}else{'prefab_stem'});worldPositionMeters=@($record.worldPositionMeters);positionStatus=$record.positionStatus;prefab=$record.prefab;subscene=$record.subscene;layer=$record.layer;enabled=(CfgValue $record 'SCR_CampaignSuppliesComponent' 'Enabled' 'bool');configuredComponentSupplies=(CfgInteger $record 'SCR_CampaignSuppliesComponent' 'm_iSupplies');configuredComponentSuppliesMax=(CfgInteger $record 'SCR_CampaignSuppliesComponent' 'm_iSuppliesMax');operationalRadiusMeters=(CfgValue $record 'SCR_CampaignSuppliesComponent' 'm_fOperationalRadius' 'number');standaloneDepot=(CfgValue $record 'SCR_CampaignSuppliesComponent' 'm_bIsStandaloneDepot' 'bool');runtimeResourceGridCapacityStatus='not_analyzed';provenance=$record.components}
})
$objects=[Collections.Generic.List[object]]::new();$objectIds=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach($type in @('control_points','harbors','other_containers','supply_depots')){
    $records=switch($type){'control_points'{$controlRecords} 'harbors'{$harbors.records} 'other_containers'{$other.records} 'supply_depots'{$depotRecords}}
    foreach($record in $records){Assert ($objectIds.Add($record.objectId)) 'Duplicate catalog object.';$objects.Add([pscustomobject][ordered]@{id=$record.objectId;sourceId=$record.sourceId;name=$(if($type -ceq 'control_points'){$record.sourceName}else{$record.name});displayName=$record.name;category=$type;worldPositionMeters=@($record.worldPositionMeters);positionStatus=$record.positionStatus;sourceReport=$(switch($type){'control_points'{'Supplies/ControlPoints.json'} 'harbors'{'Supplies/Harbors.json'} 'supply_depots'{'Supplies/SupplyDepots.json'} default{'Supplies/OtherContainers.json'}})})}
}
$settlementTypes=@('Name City','Name Town','Name Village','Name Settlement');$otherTypes=@('Name Generic','Name Island','Name Hill')
$categories=@('control_points','harbors','supply_depots','settlements','other','unrecognized')
$mapClassificationCategories=@('control_points','harbors','settlements','other')
$groups=[Collections.Generic.List[object]]::new()
function AddGroup($id,$category,$name,$p,$status,$anchorObjectId,$origin){$groups.Add([pscustomobject][ordered]@{id=$id;category=$category;name=$name;worldPositionMeters=@($p);positionStatus=$status;anchorObjectId=$anchorObjectId;origin=$origin;members=@();physicalDescendantContainers=@();mergedMapLocations=@();mergedIntoGroupId=$null})}
foreach($record in $controlRecords){AddGroup "control-point/$($record.sourceId)" 'control_points' $record.name $record.worldPositionMeters $record.positionStatus $record.objectId 'ConflictControlPoint_prefab'}
foreach($record in ($harbors.records | Sort-Object name,sourceId)){AddGroup "harbor/$($record.sourceId)" 'harbors' $record.name $record.worldPositionMeters $record.positionStatus $record.objectId 'supply_source_base'}
foreach($record in $depotRecords){AddGroup "supply-depot/$($record.sourceId)" 'supply_depots' $record.name $record.worldPositionMeters $record.positionStatus $record.objectId 'CampaignRemnantsSupplyDepot_prefab'}
foreach($group in $groups){$sourceId=($objects | Where-Object id -ceq $group.anchorObjectId).sourceId;$group.physicalDescendantContainers=@($physicalSlots | Where-Object {IsDescendant $_.sourceId $sourceId})}
$markerFields=@($oldLocations.locations[0].PSObject.Properties.Name | Where-Object {$_ -notin @('nearbyObjectCount','nearbyObjects','matchingEligible','matchingExclusionReason','matchingTier')})
$mapInventory=@($oldLocations.locations | Select-Object $markerFields)
foreach($marker in $mapInventory){if($marker.descriptorType -in $settlementTypes){AddGroup "map/$($marker.id)" 'settlements' $marker.name $marker.worldPositionMeters $marker.positionStatus $null $marker.descriptorType}elseif($marker.descriptorType -in $otherTypes){AddGroup "map/$($marker.id)" 'other' $marker.name $marker.worldPositionMeters $marker.positionStatus $null $marker.descriptorType}}
$remaining=@($other.records);$stageSummary=[ordered]@{}
foreach($category in $mapClassificationCategories){
    $stageGroups=@($groups | Where-Object category -ceq $category);$next=[Collections.Generic.List[object]]::new();$assigned=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal);$links=0
    $members=@{};foreach($group in $stageGroups){$members[$group.id]=[Collections.Generic.List[object]]::new()}
    foreach($record in $remaining){$matched=$false
        foreach($group in $stageGroups){
            $byHierarchy=$category -in @('control_points','harbors')
            $distance=$null
            if((ValidPosition $record.worldPositionMeters $record.positionStatus) -and (ValidPosition $group.worldPositionMeters $group.positionStatus)){$dx=[double]$record.worldPositionMeters[0]-[double]$group.worldPositionMeters[0];$dz=[double]$record.worldPositionMeters[2]-[double]$group.worldPositionMeters[2];$d2=$dx*$dx+$dz*$dz;$distance=[Math]::Sqrt($d2)}
            $hit=$(if($byHierarchy){$anchorSource=($objects | Where-Object id -ceq $group.anchorObjectId).sourceId;IsDescendant $record.sourceId $anchorSource}else{$null -ne $distance -and $d2 -le $RadiusMeters*$RadiusMeters})
            if($hit){$members[$group.id].Add([ordered]@{objectId=$record.objectId;distanceMeters=$distance;method=$(if($byHierarchy){'source_parent_hierarchy'}else{'horizontal_radius_proximity'});sourceParentEstablished=$byHierarchy;ownershipEstablished=$false});$matched=$true;$links++}
        }
        if($matched){$null=$assigned.Add($record.objectId)}else{$next.Add($record)}
    }
    foreach($group in $stageGroups){$group.members=@($members[$group.id] | Sort-Object distanceMeters,objectId)}
    $stageSummary[$category]=[ordered]@{anchorCount=$stageGroups.Count;assignedParentCount=$assigned.Count;associationCount=$links;populatedGroupCount=@($stageGroups | Where-Object {$_.members.Count -gt 0}).Count}
    $remaining=@($next.ToArray())
}
# Consolidate existing map groups after classification: retain their membership evidence,
# rather than applying a new radius around the control-point source position.
function HorizontalDistance($a,$b){$dx=[double]$a[0]-[double]$b[0];$dz=[double]$a[2]-[double]$b[2];[Math]::Sqrt($dx*$dx+$dz*$dz)}
function NormalizedName($name){([regex]::Replace(([string]$name).Trim(),'\s+',' ')).ToUpperInvariant()}
$mapMerges=[Collections.Generic.List[object]]::new()
$usedMarkers=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach($rule in $activeMapLinks){
    Assert ($rule.approval -ceq 'user_instruction' -and ![string]::IsNullOrWhiteSpace($rule.id)) 'Unconfirmed explicit link.'
    Assert (@($controlRecords | Where-Object {$_.sourceId -ceq $rule.controlPointSourceId -and $_.rawName -ceq $rule.controlPointRawName}).Count -eq 1) 'Explicit link control point is missing or ambiguous.'
    Assert (@($mapInventory | Where-Object id -ceq $rule.mapLocationId).Count -eq 1) 'Explicit link map label is missing or ambiguous.'
}
foreach($control in $controlRecords){
    $target=@($groups | Where-Object anchorObjectId -CEQ $control.objectId)[0]
    $explicitLinks=@($activeMapLinks | Where-Object controlPointSourceId -ceq $control.sourceId)
    Assert ($explicitLinks.Count -le 1) 'Multiple explicit links for one control point.'
    $candidates=@(foreach($marker in $mapInventory){
        if($marker.descriptorType -notin ($settlementTypes+$otherTypes) -or $control.nameStatus -cne 'resolved' -or $marker.nameStatus -cne 'resolved'){continue}
        if(!(ValidPosition $control.worldPositionMeters $control.positionStatus) -or !(ValidPosition $marker.worldPositionMeters $marker.positionStatus)){continue}
        $dx=[double]$control.worldPositionMeters[0]-[double]$marker.worldPositionMeters[0];$dz=[double]$control.worldPositionMeters[2]-[double]$marker.worldPositionMeters[2]
        if($dx*$dx+$dz*$dz -gt $RadiusMeters*$RadiusMeters){continue}
        $method=$null
        if($explicitLinks.Count){if($marker.id -ceq $explicitLinks[0].mapLocationId){$method='user_confirmed_nearby_location'}}
        elseif(![string]::IsNullOrWhiteSpace($control.name) -and (NormalizedName $control.name) -ceq (NormalizedName $marker.name)){$method='normalized_display_name'}
        elseif($control.rawName -cmatch '^#AR-Campaign_MapLocation_(.+)$'){
            $keyIdentity=$Matches[1]
            $prefabIdentity=[regex]::Replace([IO.Path]::GetFileNameWithoutExtension($marker.prefab),'_[0-9]+$','')
            if($keyIdentity -ceq $prefabIdentity){$method='localization_key_prefab_identity'}
        }
        if($method){[pscustomobject]@{marker=$marker;method=$method;distance=[Math]::Sqrt($dx*$dx+$dz*$dz)}}
    })
    Assert ($candidates.Count -le 1) "Ambiguous corresponding map label for $($control.name); review identities before merging."
    Assert (!$explicitLinks.Count -or $candidates.Count -eq 1) 'Explicit link lacks resolved eligible positions/names or exceeds the anchor radius.'
    if(!$candidates.Count){continue}
    $candidate=$candidates[0];$marker=$candidate.marker
    Assert ($usedMarkers.Add($marker.id)) 'One map label corresponds to multiple control points; review before merging.'
    $source=@($groups | Where-Object id -ceq "map/$($marker.id)")[0]
    $transferred=@($source.members)
    $merge=[ordered]@{mapLocationId=$marker.id;sourceGroupId=$source.id;targetGroupId=$target.id;name=$marker.name;descriptorType=$marker.descriptorType;worldPositionMeters=$marker.worldPositionMeters;positionStatus=$marker.positionStatus;correspondenceMethod=$candidate.method;anchorDistanceMeters=$candidate.distance;controlPointRawName=$control.rawName;mapLocationPrefab=$marker.prefab;originalCategory=$source.category;transferredObjectIds=@($transferred | ForEach-Object objectId);sourceParentEstablished=$false;ownershipEstablished=$false}
    if($explicitLinks.Count){$merge.userDecision=$explicitLinks[0]}
    $mapMerges.Add($merge);$target.mergedMapLocations+=@($merge);$source.mergedIntoGroupId=$target.id;$source.members=@()
    foreach($link in $transferred){
        $obj=@($objects | Where-Object id -ceq $link.objectId)[0]
        $distance=$(if((ValidPosition $obj.worldPositionMeters $obj.positionStatus) -and (ValidPosition $target.worldPositionMeters $target.positionStatus)){HorizontalDistance $obj.worldPositionMeters $target.worldPositionMeters}else{$null})
        $target.members+=@([ordered]@{objectId=$link.objectId;distanceMeters=$distance;method='merged_map_location_group';sourceParentEstablished=$false;ownershipEstablished=$false;mapLocationEvidence=[ordered]@{mapLocationId=$marker.id;sourceGroupId=$source.id;distanceMeters=$link.distanceMeters;method=$link.method;originalCategory=$source.category}})
    }
    $target.members=@($target.members | ForEach-Object {[pscustomobject]$_} | Sort-Object distanceMeters,objectId)
}
# A transferred object cannot remain in a lower category, including overlap lists.
$transferredIds=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach($merge in $mapMerges){foreach($id in $merge.transferredObjectIds){$null=$transferredIds.Add($id)}}
foreach($group in ($groups | Where-Object {$_.category -in @('settlements','other')})){$group.members=@($group.members | Where-Object {!$transferredIds.Contains($_.objectId)})}
# Reserve completed control-point and Harbor groups before the approved depot radius.
$protectedIds=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach($group in ($groups | Where-Object {$_.category -in @('control_points','harbors')})){foreach($link in $group.members){$null=$protectedIds.Add($link.objectId)}}
$depotAssignedIds=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach($group in ($groups | Where-Object category -ceq 'supply_depots')){
    $anchorSource=($objects | Where-Object id -ceq $group.anchorObjectId).sourceId
    foreach($record in $other.records){
        if($protectedIds.Contains($record.objectId)){continue}
        $byHierarchy=IsDescendant $record.sourceId $anchorSource
        $distance=$null;$withinRadius=$false
        if((ValidPosition $record.worldPositionMeters $record.positionStatus) -and (ValidPosition $group.worldPositionMeters $group.positionStatus)){
            $dx=[double]$record.worldPositionMeters[0]-[double]$group.worldPositionMeters[0];$dz=[double]$record.worldPositionMeters[2]-[double]$group.worldPositionMeters[2]
            $d2=$dx*$dx+$dz*$dz;$distance=[Math]::Sqrt($d2);$withinRadius=$d2 -le $RadiusMeters*$RadiusMeters
        }
        if($byHierarchy -or $withinRadius){$group.members+=@([pscustomobject][ordered]@{objectId=$record.objectId;distanceMeters=$distance;method=$(if($byHierarchy){'source_parent_hierarchy'}else{'horizontal_radius_proximity'});distanceOrigin='supply_depot_marker';sourceParentEstablished=$byHierarchy;ownershipEstablished=$false});$null=$depotAssignedIds.Add($record.objectId)}
    }
    $group.members=@($group.members | Sort-Object distanceMeters,objectId)
}
foreach($group in ($groups | Where-Object {$_.category -in @('settlements','other')})){$group.members=@($group.members | Where-Object {!$depotAssignedIds.Contains($_.objectId)})}
$remaining=@($remaining | Where-Object {!$depotAssignedIds.Contains($_.objectId)})
$stageSummary=[ordered]@{}
foreach($category in ($categories | Where-Object {$_ -cne 'unrecognized'})){
    $stageGroups=@($groups | Where-Object {$_.category -ceq $category -and !$_.mergedIntoGroupId})
    $members=@(foreach($group in $stageGroups){foreach($member in $group.members){$member}})
    $memberIds=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach($member in $members){$null=$memberIds.Add($member.objectId)}
    $stageSummary[$category]=[ordered]@{anchorCount=$stageGroups.Count;assignedParentCount=$memberIds.Count;associationCount=$members.Count;populatedGroupCount=@($stageGroups | Where-Object {$_.members.Count -gt 0}).Count}
}
$unrecognized=@($remaining | Sort-Object name,sourceId | ForEach-Object {[ordered]@{objectId=$_.objectId;reason=$(if(ValidPosition $_.worldPositionMeters $_.positionStatus){'no_source_anchor_or_map_location_within_radius'}else{'position_unknown_or_invalid'})}})
$stageSummary.unrecognized=[ordered]@{parentCount=$unrecognized.Count}
$visible=@($groups | Where-Object {$_.anchorObjectId -or $_.members.Count})
$policy=[ordered]@{order=$categories;radiusMeters=$RadiusMeters;radiusScope='map_location_stages_only';scope='remaining_other_supply_parents';sourceAnchorRule='confirmed_source_parent_hierarchy';anchorInventoryRule='all_control_points_and_source_bases_are_shown_once_in_their_own_category';withinStage='all_matches';settlementDescriptorTypes=$settlementTypes;otherDescriptorTypes=$otherTypes;otherMapTypes='excluded';ownershipEstablished=$false}
$policy.controlPointMapGroupMerge=[ordered]@{phase='after_source_and_map_classification';correspondenceMethods=@('normalized_display_name','localization_key_prefab_identity','user_confirmed_nearby_location');explicitLinkPriority='before_automatic_identity_matching_for_that_control_point';explicitLinkScope='exact_game_version_scenario_and_source_ids';maximumAnchorDistanceMeters=$RadiusMeters;ambiguousMatch='reject';memberRule='transfer_existing_map_group_members_and_remove_from_lower_categories';radiusOrigin='original_map_label';displayDistanceOrigin='control_point_source';sourceParentEstablished=$false;ownershipEstablished=$false}
$policy.radiusScope='map_location_matching_control_point_label_correspondence_and_supply_depot_matching'
$policy.supplyDepotRule=[ordered]@{selection='CampaignRemnantsSupplyDepot_prefab';protectedCategories=@('control_points','harbors');phase='after_control_point_map_merges_before_lower_map_groups';memberRule='confirmed_source_hierarchy_or_horizontal_radius_proximity';radiusMeters=$RadiusMeters;distanceOrigin='supply_depot_marker';withinStage='all_matches';ownershipEstablished=$false}
$warnings=@('Control points are selected by prefab, source bases by their previous verified catalog; named map labels are a separate source.','Control-point component supplies/max are configured fields, not measured physical capacity or runtime stock.','Control-point and Harbor members require confirmed source hierarchy; the 350 m radius applies only to the remaining map-location stages.','Each remaining OtherContainers root parent belongs only to its first matching category; all matches within that category are retained.','Control-point and Harbor source entities remain inventory anchors in their own category.','Source parenting and map proximity do not establish runtime resource-grid membership; unknown remains unknown.')
$warnings[2]='After hierarchy and map classification, uniquely corresponding map-label groups are merged into their control-point report group. Transferred map neighbors are not confirmed source children.'
$warnings+='Transferred members retain original map-label proximity evidence; displayed distances use the control-point source position and can exceed the map-label radius.'
$warnings+='Supply-depot markers and their component supplies/max are separate from physical storage. Remaining parents match within the approved depot radius; completed control-point and Harbor assignments are protected.'
$catalog=[ordered]@{schemaVersion=3;kind='priority-location-catalog';snapshotId=$snapshotId;status='partial';gameVersion=$version;scenarioKey=$scenario;normalizerVersion=$normalizer;inputs=$inputs;matchingPolicy=$policy;summary=[ordered]@{objectCount=$objects.Count;controlPointCount=$controlRecords.Count;sourceBaseCount=$harbors.records.Count;otherParentCount=$other.records.Count;recognizedParentCount=$other.records.Count-$unrecognized.Count;unrecognizedParentCount=$unrecognized.Count;associationCount=($stageSummary.Values | Where-Object {$_ -is [System.Collections.IDictionary] -and $_.Contains('associationCount')} | ForEach-Object {$_.associationCount} | Measure-Object -Sum).Sum;visibleGroupCount=$visible.Count;stages=$stageSummary};objects=@($objects.ToArray());groups=@($groups.ToArray());unrecognizedObjects=$unrecognized;mapLocationInventory=$mapInventory;warnings=$warnings}
$catalog.mapGroupMerges=@($mapMerges.ToArray())
$catalog.summary.mergedMapLocationCount=$mapMerges.Count
$catalog.summary.transferredParentCount=$transferredIds.Count
$catalog.summary.supplyDepotCount=$depotRecords.Count
$world=[ordered]@{schemaVersion=3;snapshotId=$snapshotId;revisionId=$RevisionId;revisionReason=$RevisionReason;status='partial';gameVersion=$version;scenarioKey=$scenario;worldPath=$cp.worldPath;normalizerVersion=$normalizer;inputs=$inputs;controlPointCapture=$cp;matchingPolicy=$policy;warnings=$warnings}
$world.supplyDepotCapture=$depots
$index=[ordered]@{schemaVersion=3;kind='conflict-world-index';snapshotId=$snapshotId;status='partial';worldMetadata='world.json';sections=[ordered]@{locations=[ordered]@{path='Locations.json';table='Locations.md'};supplies=[ordered]@{catalog='Locations.json';table='Supplies/OtherContainers.md';controlPoints='Supplies/ControlPoints.json';otherContainers='Supplies/OtherContainers.json';harbors='Supplies/Harbors.json';order=$categories};aiGroups=[ordered]@{status='not_analyzed'};startingBases=[ordered]@{status='not_analyzed'};vehicleSpawns=[ordered]@{status='not_analyzed'}}}
$index.sections.supplies.supplyDepots='Supplies/SupplyDepots.json'
$null=New-Item -ItemType Directory -Path (Join-Path $output 'Supplies')
function WriteJson($path,$value){[IO.File]::WriteAllText((Join-Path $output $path),($value | ConvertTo-Json -Depth 45)+"`n",[Text.UTF8Encoding]::new($false))}
WriteJson 'world.json' $world;WriteJson 'data.json' $index;WriteJson 'Locations.json' $catalog
WriteJson 'Supplies/ControlPoints.json' ([ordered]@{schemaVersion=3;kind='control-point-source-settings';snapshotId=$snapshotId;normalizerVersion=$normalizer;sourceSha256=$cpInput.hash;capturedAtUTC=$cp.generatedAtUTC;records=$controlRecords;nativeInventory=$cp})
WriteJson 'Supplies/SupplyDepots.json' ([ordered]@{schemaVersion=3;kind='supply-depot-marker-settings';snapshotId=$snapshotId;normalizerVersion=$normalizer;sourceSha256=$depotInput.hash;capturedAtUTC=$depots.generatedAtUTC;records=$depotRecords;nativeInventory=$depots})
foreach($type in @('OtherContainers','Harbors')){$source=$(if($type -ceq 'OtherContainers'){$other}else{$harbors});WriteJson "Supplies/$type.json" ([ordered]@{schemaVersion=3;kind='supply-settings-view';report=$type;snapshotId=$snapshotId;normalizerVersion=$normalizer;sourceInputs=$source.inputs;sourceSummary=$source.sourceSummary;records=$source.records;classificationCatalog='../Locations.json';warnings=$warnings})}
# Render both documents from the saved canonical graph and settings.
$saved=Get-Content -LiteralPath (Join-Path $output 'Locations.json') -Raw -Encoding utf8 | ConvertFrom-Json
$lookup=@{};foreach($obj in $saved.objects){$lookup[$obj.id]=$obj}
$rows=@{};foreach($type in @('ControlPoints','OtherContainers','Harbors','SupplyDepots')){$settings=Get-Content -LiteralPath (Join-Path $output "Supplies/$type.json") -Raw -Encoding utf8 | ConvertFrom-Json;foreach($row in $settings.records){$rows[$row.objectId]=$row}}
function Text($v){([string]$v).Replace('|','\|').Replace("`r",' ').Replace("`n",' ').Trim()}
function Number($v){if($null -eq $v){return 'unknown'};([double]$v).ToString('0.######',$culture)}
function Position($p,$status){if(!(ValidPosition $p $status)){return 'unknown'};@($p | ForEach-Object {Number $_}) -join ' '}
function Distance($d){if($null -eq $d){return 'unknown'};([double]$d).ToString('0.###',$culture)}
function Value($v,$status){if($status -cne 'resolved'){return 'unknown'};Number $v}
$titles=@{control_points='Контрольные точки';harbors='Harbors';supply_depots='Склады припасов';settlements='Города и деревни';other='Остальные объекты';unrecognized='Нераспознанные'}
function ParentTable($lines,$links,$showDistance){
    $header='| Родитель | Вместимость / Изначально | Состав, припасы | Координаты X Y Z, м |';$separator='| --- | --- | --- | --- |';if($showDistance){$header+=' Расстояние, м |';$separator+=' ---: |'};$lines.Add($header);$lines.Add($separator)
    foreach($link in $links){
        $row=$rows[$link.objectId]
        $composition=@($row.capacityComposition | ForEach-Object {"$($_.containerCount) × $(Number $_.capacitySupplies)"}) -join ' + '
        if(!$composition){$composition='unknown'}
        $capacityAndInitial="$(Value $row.capacitySupplies $row.capacityStatus) / $(Value $row.configuredInitialSupplies $row.configuredInitialStatus)"
        $line="| $(Text $row.name) | $capacityAndInitial | $composition | $(Position $row.worldPositionMeters $row.positionStatus) |"
        if($showDistance){$line+=" $(Distance $link.distanceMeters) |"}
        $lines.Add($line)
    }
    $lines.Add('')
}
foreach($document in @('Locations.md','Supplies/OtherContainers.md')){
    $supply=$document.StartsWith('Supplies/');$lines=[Collections.Generic.List[string]]::new();$lines.Add($(if($supply){'# Припасы по группам мира'}else{'# Объекты по группам мира'}));$lines.Add('');$lines.Add('## Цель');$lines.Add('')
    $lines.Add('Сверять группы объектов в мире и находить разбросанные сущности: контрольные точки ConflictControlPoint, Harbors, склады CampaignRemnantsSupplyDepot, города / деревни, остальные допустимые локации и нераспознанные объекты. Соответствующие подписи карты и их готовые списки объединены с контрольными точками. Подтверждённые source-потомки и перенесённые соседи карты различаются в JSON; runtime-сеть не проверялась.');$lines.Add('');$lines.Add('## Summary');$lines.Add('')
    $lines.Add("Игра **$version**, мир ``$scenario.ent``, ревизия ``$RevisionId``. Радиус для складов, городов / деревень и остальных подписей: **$(Number $RadiusMeters) м** по X/Z включительно. Контрольных точек: **$($saved.summary.controlPointCount)**; Harbors: **$($saved.summary.sourceBaseCount)**; складов припасов: **$($saved.summary.supplyDepotCount)**; остальных корневых родителей: **$($saved.summary.otherParentCount)**. По приоритетам распознано **$($saved.summary.recognizedParentCount)** родителей, нераспознанных — **$($saved.summary.unrecognizedParentCount)**. Статус **partial**.");$lines.Add('')
    $lines.Add('| Категория | Родителей из OtherContainers | Связей |');$lines.Add('| --- | ---: | ---: |');foreach($category in ($categories | Where-Object {$_ -cne 'unrecognized'})){$summary=$saved.summary.stages.$category;$lines.Add("| $($titles[$category]) | $($summary.assignedParentCount) | $($summary.associationCount) |")};$lines.Add('')
    if($supply){$lines.Add("Итоги исходных каталогов по уникальным записям: OtherContainers — **$($other.sourceSummary.physicalContainerCount)** физических контейнеров / **$(Number $other.sourceSummary.capacitySupplies)** вместимости; Harbors — **$(Number $harbors.sourceSummary.physicalContainerCount)** / **$(Number $harbors.sourceSummary.knownCapacitySubtotalSupplies)** известного подытога, **$($harbors.sourceSummary.unknownCapacityBaseCount)** вместимости unknown. Настройки компонентов припасов контрольных точек и складов учитываются отдельно; они не прибавляются к физической вместимости. Повторные строки локаций не суммируются.");$lines.Add('')}
    $lines.Add('## Откуда берутся данные');$lines.Add('')
    $lines.Add('| Данные | Источник |');$lines.Add('| --- | --- |');$lines.Add('| Контрольная точка / название / позиция | Целевой экспорт ConflictControlPoint prefab; m_sBaseName переведено WidgetManager.Translate, координаты source проверены Workbench. |');$lines.Add('| Припасы точки / максимум компонента | SCR_CampaignSuppliesComponent.m_iSupplies / m_iSuppliesMax; это настройки компонента, они учитываются отдельно от физических контейнеров. |');$lines.Add('| Подтверждённые вложенные контейнеры | Родительские ID полного экспорта world-supply-containers; физические SCR_ResourceContainer, SUPPLIES. Виртуальные представления не суммируются. |');$lines.Add('| Склады припасов | CampaignRemnantsSupplyDepot prefab; SCR_CampaignSuppliesComponent (Enabled, m_iSupplies, m_iSuppliesMax, m_fOperationalRadius, m_bIsStandaloneDepot) и SCR_MapDescriptorComponent (DisplayName, MainType, UnitType). Настройки компонента отдельно от физических контейнеров. |');$lines.Add('| Harbors | Настройки и физическая вместимость прежнего каталога баз-источников; интервал в минутах = исходные секунды / 60. |');$lines.Add('| Контейнерные строки | Прежние OtherContainers по ID корневого родителя; состав / вместимость / начальные припасы сохранены. |');$lines.Add('| Разбивка | Сначала подтверждённая source-иерархия контрольных точек / Harbors; затем совпадения оставшихся объектов с городами / деревнями и остальными разрешёнными подписями в радиусе карты. После этого группы соответствующих подписей переносятся к КП; затем оставшиеся родители в радиусе склада переносятся в отдельную категорию после Harbors и исключаются ниже. Внутри одного этапа сохраняются все совпадения. |');$lines.Add('')
    if($supply){$lines.Add('Канонический граф: [Locations.json](../Locations.json); настройки: [ControlPoints](ControlPoints.json), [OtherContainers](OtherContainers.json), [Harbors](Harbors.json), [SupplyDepots](SupplyDepots.json), [метаданные](../world.json).')}else{$lines.Add('Канонический граф: [Locations.json](Locations.json), [метаданные](world.json), [таблица припасов](Supplies/OtherContainers.md).')};$lines.Add('')
    foreach($category in $categories){$lines.Add("## $($titles[$category])");$lines.Add('')
        if($category -ceq 'unrecognized'){if($saved.unrecognizedObjects.Count){if($supply){ParentTable $lines $saved.unrecognizedObjects $false}else{$lines.Add('| Объект | Координаты X Y Z, м |');$lines.Add('| --- | --- |');foreach($link in $saved.unrecognizedObjects){$obj=$lookup[$link.objectId];$lines.Add("| $(Text $obj.name) | $(Position $obj.worldPositionMeters $obj.positionStatus) |")};$lines.Add('')}}else{$lines.Add('Нераспознанных объектов нет.');$lines.Add('')};continue}
        $categoryGroups=@($saved.groups | Where-Object {$_.category -ceq $category -and ($_.anchorObjectId -or $_.members.Count)})
        if(!$categoryGroups.Count){$lines.Add('Объектов этой категории нет.');$lines.Add('');continue}
        foreach($group in $categoryGroups){$lines.Add("### $(Text $group.name) - $(Position $group.worldPositionMeters $group.positionStatus)");$lines.Add('')
            if($group.mergedMapLocations.Count){$lines.Add("Объекты соответствующей подписи карты перенесены в эту группу справочника. Расстояния ниже рассчитаны до контрольной точки; исходные координаты подписи и расстояния сохранены в JSON. Source-родство перенесённых объектов этим не подтверждается.");$lines.Add('')}
            foreach($merge in ($group.mergedMapLocations | Where-Object correspondenceMethod -ceq 'user_confirmed_nearby_location')){$lines.Add("Подпись **$(Text $merge.name)** связана с этой контрольной точкой по указанию пользователя; расстояние между ними — **$(Distance $merge.anchorDistanceMeters) м** по X/Z.");$lines.Add('')}
            if($category -ceq 'supply_depots'){$lines.Add("Контейнеры сопоставляются с маркером склада в радиусе **$(Number $RadiusMeters) м** по X/Z. Объекты контрольных точек и Harbors сохраняют приоритет; source-родство отмечается отдельно от близости.");$lines.Add('')}
            if($group.anchorObjectId){$anchor=$rows[$group.anchorObjectId]
                if($supply -and $category -ceq 'control_points'){$lines.Add('| Source | Припасы компонента в конфиге | Максимум компонента, припасы | Координаты X Y Z, м |');$lines.Add('| --- | ---: | ---: | --- |');$lines.Add("| $(Text $anchor.sourceName) | $(Value $anchor.configuredComponentSupplies.value $anchor.configuredComponentSupplies.status) | $(Value $anchor.configuredComponentSuppliesMax.value $anchor.configuredComponentSuppliesMax.status) | $(Position $anchor.worldPositionMeters $anchor.positionStatus) |");$lines.Add('')}
                elseif($supply -and $category -ceq 'supply_depots'){$lines.Add('| Максимум / Изначально компонента, припасы | Операционный радиус в конфиге, м |');$lines.Add('| --- | ---: |');$lines.Add("| $(Value $anchor.configuredComponentSuppliesMax.value $anchor.configuredComponentSuppliesMax.status) / $(Value $anchor.configuredComponentSupplies.value $anchor.configuredComponentSupplies.status) | $(Value $anchor.operationalRadiusMeters.value $anchor.operationalRadiusMeters.status) |");$lines.Add('');$lines.Add('Это настройки маркера склада; физические контейнеры перечислены отдельно. Операционный радиус компонента отличается от радиуса 350 м для группировки справочника.');$lines.Add('')}
                elseif($supply){$lines.Add('| Название | Пополнение за цикл, припасы | Пополнение, мин. | Вместимость хранилищ, припасы | Координаты X Y Z, м |');$lines.Add('| --- | ---: | ---: | ---: | --- |');$lines.Add("| $(Text $anchor.name) | $(Value $anchor.supplyIncomePerCycle $anchor.valueStatus.supplyIncomePerCycle) | $(Value $anchor.arrivalIntervalMinutes $anchor.valueStatus.arrivalInterval) | $(Value $anchor.capacitySupplies $anchor.capacityStatus) | $(Position $anchor.worldPositionMeters $anchor.positionStatus) |");$lines.Add('')}
                else{$obj=$lookup[$group.anchorObjectId];$lines.Add("Source: **$(Text $obj.name)**; координаты **$(Position $obj.worldPositionMeters $obj.positionStatus)**.");$lines.Add('')}
                $lines.Add("Подтверждённых физических SUPPLIES-контейнеров в source-потомках: **$($group.physicalDescendantContainers.Count)**. Состав и поля контейнеров сохранены в Locations.json; это отдельная проверка от соседства на карте.");$lines.Add('')
            }
            if($group.members.Count){if($supply){ParentTable $lines $group.members $true}else{$lines.Add('| Объект | Расстояние, м | Координаты X Y Z, м |');$lines.Add('| --- | ---: | --- |');foreach($link in $group.members){$obj=$lookup[$link.objectId];$lines.Add("| $(Text $obj.name) | $(Distance $link.distanceMeters) | $(Position $obj.worldPositionMeters $obj.positionStatus) |")};$lines.Add('')}}elseif($supply){$lines.Add('Других корневых родителей в этой группе справочника нет.');$lines.Add('')}
        }
    }
    [IO.File]::WriteAllText((Join-Path $output $document),($lines -join "`n").TrimEnd([char]13,[char]10)+"`n",[Text.UTF8Encoding]::new($false))
}
[IO.File]::WriteAllText((Join-Path $output 'Supplies.md'),"# Припасы по приоритетам`n`n[Единая таблица](Supplies/OtherContainers.md): контрольные точки → Harbors → склады припасов → города / деревни → остальные объекты → нераспознанные. [Справочник объектов](Locations.md), [индекс](data.json), [метаданные](world.json).`n",[Text.UTF8Encoding]::new($false))
$catalog.summary
