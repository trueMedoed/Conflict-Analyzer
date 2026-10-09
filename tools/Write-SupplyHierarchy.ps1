# Called by New-SupplyPriorityReport.ps1 with the validated graph and summary entries.
function WriteSupplyHierarchy($entries,$totals){
    InitializePhysicalSupplyDetails
    InitializeHarborNeighbors
    $folders=[ordered]@{control_points='ControlPoints';harbors='Harbors';supply_depots='SupplyDepots';settlements='Settlements';other='Other'}
    $names=@{control_points='Контрольные точки';harbors='Доки';supply_depots='Склады';settlements='Города';other='Другое'}
    $pages=[Collections.Generic.List[object]]::new()
    foreach($category in $folders.Keys){
        foreach($group in @($saved.groups | Where-Object {$_.category -ceq $category -and ($_.anchorObjectId -or $_.members.Count)})){
            $label=$group.name;$position=$group.worldPositionMeters;$positionStatus=$group.positionStatus
            $harborLocationBinding=$null
            if($category -ceq 'other' -and $group.name -ceq 'harbor'){
                $candidates=@(@(foreach($dock in @($saved.groups | Where-Object category -ceq 'harbors')){
                    if(!(ValidPosition $group.worldPositionMeters $group.positionStatus) -or !(ValidPosition $dock.worldPositionMeters $dock.positionStatus)){continue}
                    $dx=$dock.worldPositionMeters[0]-$group.worldPositionMeters[0];$dz=$dock.worldPositionMeters[2]-$group.worldPositionMeters[2]
                    $distance=[Math]::Sqrt($dx*$dx+$dz*$dz)
                    if($distance -le $RadiusMeters){[pscustomobject]@{dock=$dock;distance=$distance}}
                }) | Sort-Object distance,{$_.dock.id})
                if($candidates.Count -and ($candidates.Count -eq 1 -or [Math]::Abs($candidates[0].distance-$candidates[1].distance) -gt 0.001)){
                    $nearest=$candidates[0]
                    if($nearest.dock.name -cmatch '^SP_(?:A|T[0-9]+H)_(.+)$'){
                        $label=$Matches[1]
                        $harborLocationBinding=[ordered]@{originalMapLabel=$group.name;mapGroupId=$group.id;dockGroupId=$nearest.dock.id;dockName=$nearest.dock.name;locationName=$label;nameSource='dock_source_name_suffix';method='nearest_dock_to_generic_harbor_map_label_horizontal';distanceMeters=$nearest.distance;radiusMeters=$RadiusMeters;ownershipEstablished=$false;replenishmentEstablished=$false}
                    }
                }
            }
            if($category -ceq 'supply_depots'){
                $region=@($saved.depotLocationGrouping.locations | Where-Object {$_.depots.depotGroupId -contains $group.id})
                if($region.Count){$label=$region[0].name;$position=$region[0].worldPositionMeters;$positionStatus=$region[0].positionStatus}
                else{$label="Склад - $(Position $position $positionStatus)"}
            }
            $ids=@($group.members | ForEach-Object {$_.objectId} | Sort-Object -Unique)
            if($category -ceq 'control_points'){$ids+=($group.anchorObjectId+'/command-post')}
            if($category -ceq 'harbors'){$ids+=@($group.physicalDescendantContainers | ForEach-Object {$_.id});$ids+=($group.anchorObjectId+'/unresolved-storage')}
            $pages.Add([pscustomobject]@{id=$group.id;category=$category;label=$label;position=$position;positionStatus=$positionStatus;group=$group;harborLocationBinding=$harborLocationBinding;entryIds=$ids;unrecognized=$false;file='';amount='';known=0.0;unknown=0})
        }
    }
    foreach($member in $saved.unrecognizedObjects){
        $obj=$rows[$member.objectId]
        $pages.Add([pscustomobject]@{id=$member.objectId;category='other';label=$obj.name;position=$obj.worldPositionMeters;positionStatus=$obj.positionStatus;group=[pscustomobject]@{members=@($member)};harborLocationBinding=$null;entryIds=@($member.objectId);unrecognized=$true;file='';amount='';known=0.0;unknown=0})
    }
    $paths=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $labelCounts=@{};foreach($item in $pages){$key=$item.category+'/'+$item.label.ToLowerInvariant();if(!$labelCounts.ContainsKey($key)){$labelCounts[$key]=0};$labelCounts[$key]++}
    foreach($page in $pages){
        $slug=[regex]::Replace($page.label.Normalize([Text.NormalizationForm]::FormD),'\p{Mn}','')
        $slug=[regex]::Replace($slug,'[^\p{L}\p{Nd}_-]+','-').Trim('-')
        if(!$slug){$slug='Object'}
        if($slug -match '^(?i:con|prn|aux|nul|com[0-9]|lpt[0-9]|summary)$'){$slug='Object-'+$slug}
        $duplicate=$labelCounts[$page.category+'/'+$page.label.ToLowerInvariant()] -gt 1
        if($duplicate){
            $hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($page.id))).Substring(0,8).ToLowerInvariant()
            $slug+='-'+$hash;$page.label+=" - $(Position $page.position $page.positionStatus)"
        }
        $pageFolder=if($page.harborLocationBinding){'Harbors'}else{$folders[$page.category]};$page.file="$pageFolder/$slug.md"
        Assert ($paths.Add($page.file)) 'Hierarchy: filename collision.'
        $items=@($entries | Where-Object {$_.id -in $page.entryIds})
        $page.entryIds=@($items | ForEach-Object {$_.id})
        foreach($item in $items){$page.known+=$item.knownInitialSubtotal}
        $page.unknown=@($items | Where-Object {$_.status -cne 'resolved'}).Count
        $page.amount=$(if($page.unknown -and !$page.known){'неизвестно'}elseif($page.unknown){"$(Number $page.known) + неизвестно"}else{Number $page.known})
    }
    function SaveHierarchyPage($relative,$lines){
        $path=Join-Path $output "Supplies/$relative";$null=New-Item -ItemType Directory (Split-Path $path) -Force
        [IO.File]::WriteAllText($path,($lines -join "`n").TrimEnd()+"`n",[Text.UTF8Encoding]::new($false))
    }
    $summaryPath=Join-Path $output 'Supplies/Summary.md'
    $previous=[IO.File]::ReadAllText($summaryPath).Replace("`r`n","`n")
    $start=$previous.IndexOf('## Контрольные точки')
    $end=$previous.IndexOf('Один объект может встречаться',$start)
    Assert ($start -ge 0 -and $end -gt $start) 'Hierarchy: missing summary sections.'
    $main=[Collections.Generic.List[string]]::new()
    foreach($category in $folders.Keys){
        $folder=$folders[$category];$name=$names[$category]
        $total=@($totals | Where-Object {$_.category -ceq $category})[0]
        $categoryPages=@($pages | Where-Object category -ceq $category)
        $main.Add("## [$name]($folder/Summary.md)");$main.Add('');$main.Add('| Название | Припасов изначально |');$main.Add('| --- | ---: |')
        $cat=[Collections.Generic.List[string]]::new();$cat.Add("# $name");$cat.Add('');$cat.Add('[Общая сводка](../Summary.md)');$cat.Add('')
        $cat.Add("Игра **$version**, мир ``$scenario``, ревизия ``$RevisionId``.");$cat.Add('')
        $suffix=$(if($total.unknownEntryCount){' + неизвестно'}else{''})
        $cat.Add("Начальных припасов по конфигам: **$(Number $total.knownInitialSupplies)$suffix**. Итог учитывает каждый объект один раз.");$cat.Add('')
        if($category -ceq 'control_points'){
            $cat.Add('Объекты соответствующих подписей карты перенесены в группы контрольных точек справочника. Расстояния в подробных таблицах рассчитаны до соответствующей контрольной точки; исходные координаты подписей и расстояния сохранены в JSON. Source-родство перенесённых объектов этим не подтверждается.');$cat.Add('')
            $cat.Add('Строка командного пункта отражает его собственное хранилище после действия префаба. Начальные припасы всей сети базы и её runtime-агрегаты отдельно не прибавляются.');$cat.Add('')
        }
        if($category -ceq 'supply_depots'){$cat.Add("Хранилища собираются в **$(Number $DepotRadiusMeters) м** по X/Z от маркера склада; привязка маркера к локации — в **$(Number $RadiusMeters) м**. Расстояния в подробных таблицах отсчитываются от маркера.");$cat.Add('')}
        if($category -ceq 'other'){$cat.Add('Включены остальные локации и нераспознанные объекты. Локации могут пересекаться; их строки нельзя повторно складывать для получения общего итога.');$cat.Add('')}
        if($category -ceq 'harbors'){
            $cat.Add('## Радиус поиска хранилищ и пополнение')
            $cat.Add('')
            $cat.Add('В установленной игре **1.8.0.13** базовый префаб `Prefabs/Systems/MilitaryBase/ConflictSourceBase.et` задаёт **100 м** в поле `SCR_ResourceComponent → m_aGenerators → SCR_ResourceGenerator → m_fStorageRange`. Прочитанные `ConflictSourceBase_T1Harbor.et` и `ConflictSourceBase_T2Harbor.et` наследуют этот префаб и не переопределяют это поле. Это настройка генератора ресурсов; одноимённое по величине `m_iRadius` компонента базы — другое поле.')
            $cat.Add('')
            $cat.Add('`SCR_CampaignSourceBaseComponent` наследует механизм пополнения от `SCR_CampaignMilitaryBaseComponent`: таймер вызывает `AddRegularSupplyPackage`, затем `AddSupplies` обращается к генератору SUPPLIES. `SCR_ResourceGenerator.RequestGeneration` вызывает `RequestAvailability`, которая обновляет список контейнеров через `ResourceGrid.UpdateInteractor`. `GetResourceGridRange` генератора возвращает `m_fStorageRange`.')
            $cat.Add('')
            $cat.Add('Ресурсная сеть ищет контейнеры поблизости и проверяет `CanInteractWith`, `IsInRange` и признак изоляции. Поэтому хранилище **не обязано быть дочерним объектом дока**, чтобы участвовать в пополнении. Вместе с тем одной близости недостаточно: действуют условия подключения, свободная вместимость и условия работы базы. Результаты наблюдения подключения показаны отдельно на страницах доков; факт пополнения за цикл этим не измеряется.')
            $cat.Add('')
            $cat.Add('### Как читать список в справочнике')
            $cat.Add('')
            $cat.Add('- Проверяются отдельно все физические и виртуальные SUPPLIES-контейнеры. Расстояние по X/Y/Z считается от сущности дока до позиции каждого контейнера; 100 м включительно, до округления. Корень композиции больше не служит фильтром, исключающим вложенные ящики.')
            $cat.Add('- Расстояние до корня сохранено для сравнения. Вышедшие за радиус соседи внутри выбранной композиции показаны как диагностика: расхождение с корнем — повод проверить расположение, а не автоматически доказанная ошибка мира.')
            $cat.Add('- Игровой IsInRange проверяет пересечение сферы с AABB сущности (GetBounds), поэтому результат может отличаться от расстояния до её позиции. Изоляция, CanInteractWith и IsInteractorLinked показываются отдельными колонками при наличии runtime-измерения; иначе — «не измерено».')
            $cat.Add('- Виртуальные представления хранилищ показаны отдельно от физических ящиков и не добавляются к суммам. Категории, исходные запасы и принадлежность по source-иерархии не изменяются. Динамически созданные объекты, отсутствующие в editor source, остаются в runtime-отчёте без придуманной привязки.')
            $cat.Add('')
            $cat.Add('')
            $cat.Add('У StPierre, Lamentin и Meaux «неизвестно» означает отсутствие подтверждённых вложенных хранилищ в используемом отчёте, а не нулевой запас и не доказанную остановку пополнения. Припасы отдельно стоящих соседей уже учтены в других категориях.')
            $cat.Add('')
            $cat.Add('## Начальные припасы по докам')
            $cat.Add('')
        }
        $cat.Add('| Название | Припасов изначально |');$cat.Add('| --- | ---: |')
        foreach($page in $categoryPages){
            $filename=if($page.harborLocationBinding){"../$($page.file)"}else{Split-Path $page.file -Leaf}
            $main.Add("| [$(Text $page.label)]($($page.file)) | $($page.amount) |")
            $cat.Add("| [$(Text $page.label)]($filename) | $($page.amount) |")
            $detail=[Collections.Generic.List[string]]::new();$detail.Add("# $(Text $page.label)");$detail.Add('');$detail.Add("[$name — сводка](../$folder/Summary.md) · [Все категории](../Summary.md)");$detail.Add('')
            $detail.Add("Координаты X Y Z: **$(Position $page.position $page.positionStatus)**.");$detail.Add('')
            $detail.Add("Припасов изначально по конфигам: **$($page.amount)**.");$detail.Add('')
            if($page.unrecognized){$detail.Add('Объект пока не отнесён к распознанной группе.');$detail.Add('');ParentTable $detail $page.group.members $false}
            elseif($category -ceq 'harbors'){HarborTable $detail @($page.group) $true}
            elseif($category -ceq 'control_points'){
                ParentTable $detail $page.group.members $true $rows[$page.group.anchorObjectId]
                foreach($merge in @($page.group.mergedMapLocations | Where-Object correspondenceMethod -ceq 'user_confirmed_nearby_location')){$detail.Add("Подпись **$(Text $merge.name)** связана с этой КП по указанию пользователя; расстояние между ними — **$(Distance $merge.anchorDistanceMeters) м**.");$detail.Add('')}
            }else{
                ParentTable $detail $page.group.members $true
                $detail.Add($(if($category -ceq 'supply_depots'){'Расстояния рассчитаны до маркера склада.'}else{'Расстояния рассчитаны до подписи локации.'}));$detail.Add('')
            }
            if($page.harborLocationBinding){
                $binding=$page.harborLocationBinding
                $dockPage=@($pages | Where-Object id -ceq $binding.dockGroupId)[0]
                $detail.Add("Подпись карты ``harbor`` связана для навигации с доком [$(Text $binding.dockName)](../$($dockPage.file)); между подписью и доком **$(Distance $binding.distanceMeters) м** по X/Z. Название файла взято из имени дока. Координаты группы и расстояния в таблице по-прежнему относятся к подписи карты.");$detail.Add('')
                $detail.Add('Это географическая группа хранилищ, а не список пополнения дока. Попадание отдельных физических и виртуальных контейнеров в радиус 100 м и игровые проверки показаны на странице дока.');$detail.Add('')
            }
            if($category -ceq 'harbors'){
                $locations=@($pages | Where-Object {$_.harborLocationBinding -and $_.harborLocationBinding.dockGroupId -ceq $page.id})
                foreach($location in $locations){$detail.Add("Хранилища локации: [$(Text $location.label)](../$($location.file)). В эту географическую группу могут входить объекты вне радиуса пополнения дока.");$detail.Add('')}
            }
            AddPhysicalSupplyDetails $detail $page
            AddHarborNeighbors $detail $page $pages
            $detail.Add('[Состав расчёта](../Summary.json) · [Группы и происхождение](../../Locations.json).')
            SaveHierarchyPage $page.file $detail
        }
        $main.Add('');$cat.Add('');$cat.Add('[Состав расчёта и неизвестные значения](../Summary.json).')
        if($category -ceq 'harbors'){
            $cat.Add('## Хранилища локаций доков');$cat.Add('')
            foreach($location in @($pages | Where-Object {$_.harborLocationBinding})){
                $leaf=Split-Path $location.file -Leaf
                $cat.Add("- [$(Text $location.label)]($leaf)")
            }
            $cat.Add('');$cat.Add('Это географические группы, включая хранилища вне радиуса пополнения. Их суммы пока учитываются в категории «Другое».');$cat.Add('')
        }
        SaveHierarchyPage "$folder/Summary.md" $cat
    }
    $text=$previous.Substring(0,$start)+($main -join "`n")+"`n"+$previous.Substring($end)
    foreach($category in $folders.Keys){$text=$text.Replace("| $($names[$category]) |","| [$($names[$category])]($($folders[$category])/Summary.md) |")}
    [IO.File]::WriteAllText($summaryPath,$text,[Text.UTF8Encoding]::new($false))
    $result=Get-Content -LiteralPath (Join-Path $output 'Supplies/Summary.json') -Raw | ConvertFrom-Json
    $navigation=@($pages | ForEach-Object {[ordered]@{id=$_.id;category=$_.category;name=$_.label;path=$_.file;entryIds=$_.entryIds;knownInitialSupplies=$_.known;unknownEntryCount=$_.unknown;harborLocationBinding=$_.harborLocationBinding}})
    $result | Add-Member -NotePropertyName detailPages -NotePropertyValue $navigation
    WriteJson 'Supplies/Summary.json' $result
    $index.sections.supplies.hierarchy=[ordered]@{categories=@($folders.Keys | ForEach-Object {[ordered]@{category=$_;summary="Supplies/$($folders[$_])/Summary.md"}});pages=@($pages | ForEach-Object {"Supplies/$($_.file)"})}
    WriteJson 'data.json' $index
}
