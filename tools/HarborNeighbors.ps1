# A spatial inspection overlay only: never changes assignment or summary totals.
function InitializeHarborNeighbors {
    $script:harborNeighbors=@{}
    foreach($group in @($saved.groups | Where-Object category -ceq 'harbors')){
        $near=[Collections.Generic.List[object]]::new()
        foreach($parent in $other.records){
            if(!(ValidPosition $parent.worldPositionMeters $parent.positionStatus) -or !(ValidPosition $group.worldPositionMeters $group.positionStatus)){continue}
            $dx=$parent.worldPositionMeters[0]-$group.worldPositionMeters[0]
            $dy=$parent.worldPositionMeters[1]-$group.worldPositionMeters[1]
            $dz=$parent.worldPositionMeters[2]-$group.worldPositionMeters[2]
            $distance=[Math]::Sqrt($dx*$dx+$dy*$dy+$dz*$dz)
            if($distance -gt 100){continue}
            $near.Add([pscustomobject][ordered]@{objectId=$parent.objectId;sourceId=$parent.sourceId;name=$parent.name;worldPositionMeters=$parent.worldPositionMeters;positionStatus=$parent.positionStatus;distanceMeters=$distance;band='within_100m';configuredInitialSupplies=$parent.configuredInitialSupplies;configuredInitialStatus=$parent.configuredInitialStatus;capacitySupplies=$parent.capacitySupplies;capacityStatus=$parent.capacityStatus;assignedGroupIds=@($saved.groups | Where-Object {$parent.objectId -in @($_.members | ForEach-Object {$_.objectId})} | ForEach-Object {$_.id});includedInHarborTotal=$false;runtimeConnectionStatus='not_measured'})
        }
        $script:harborNeighbors[$group.id]=[ordered]@{groupId=$group.id;anchorObjectId=$group.anchorObjectId;name=$group.name;worldPositionMeters=$group.worldPositionMeters;neighbors=@($near | Sort-Object distanceMeters,objectId)}
    }
    WriteJson 'Supplies/HarborNeighbors.json' ([ordered]@{schemaVersion=1;kind='harbor-neighbor-inspection';snapshotId=$snapshotId;scope='detached_other_container_root_parents_near_harbor_sources';method='three_dimensional_root_position_distance';innerRadiusMeters=100;outerRadiusMeters=100;boundary='inclusive_before_rounding';classificationChanged=$false;runtimeConnectionMeasured=$false;radiusMeaning='Maximum inspection radius; 100m matches the storage range configured in the inspected ConflictSourceBase prefab, not verified per-world runtime container membership.';inputs=$saved.inputs;records=@($script:harborNeighbors.Values | Sort-Object {$_.name})})
}
function AddHarborNeighbors($lines,$page,$pages){
    if($page.category -cne 'harbors'){return}
    $record=$script:harborNeighbors[$page.id]
    $lines.Add('## Хранилища рядом с доком');$lines.Add('')
    $lines.Add('Это отдельный справочный список. Категории не изменены: припасы этих объектов уже учтены в группах по ссылкам ниже и не прибавляются к итогу дока.');$lines.Add('')
    $lines.Add('Расстояние измерено по X/Y/Z от дока до корня хранилища, до округления. Порог 100 м взят из m_fStorageRange базового префаба ConflictSourceBase. Это не проверка фактического подключения: игра проверяет ресурсные контейнеры, условия взаимодействия и их дальность; настройки экземпляра и работа сети здесь не измерялись.');$lines.Add('')
    foreach($band in @('within_100m')){
        $lines.Add('### До 100 м включительно');$lines.Add('')
        $items=@($record.neighbors | Where-Object band -ceq $band)
        if(!$items.Count){$lines.Add('Отдельно стоящих хранилищ в этом диапазоне не найдено.');$lines.Add('');continue}
        $lines.Add('| Хранилище | Вместимость / Изначально | Координаты X Y Z, м | Расстояние, м | Где уже учтено |');$lines.Add('| --- | ---: | --- | ---: | --- |')
        foreach($item in $items){
            $owners=@($pages | Where-Object {$item.objectId -in $_.entryIds})
            Assert ($owners.Count -gt 0) 'Harbor neighbor lacks an existing detail page.'
            $links=@($owners | ForEach-Object {"[$(Text $_.label)](../$($_.file))"}) -join ', '
            $lines.Add("| $(Text $item.name) | $(Value $item.capacitySupplies $item.capacityStatus) / $(Value $item.configuredInitialSupplies $item.configuredInitialStatus) | $(Position $item.worldPositionMeters $item.positionStatus) | $(Distance $item.distanceMeters) | $links |")
        }
        $lines.Add('')
    }
    $lines.Add('[Расстояния и исходные назначения](../HarborNeighbors.json).');$lines.Add('')
}
