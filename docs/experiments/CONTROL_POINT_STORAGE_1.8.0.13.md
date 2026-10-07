# Откуда берётся вместимость хранилища контрольной точки

Проверено 07.10.2026 на ресурсах установленной Arma Reforger **1.8.0.13**. Исследуется хранилище командного пункта, создаваемого для контрольной точки Conflict; это отдельное значение от общей вместимости всей связанной ресурсной сети базы.

## Результат

Вместимость **1000 припасов** задаёт действие **SCR_ResourceEncapsulatorActionChangeResourceValue** внутри SCR_ResourceComponent композиции хранилища. Путь к настройке в редакторе:

```text
SCR_ResourceComponent
  m_aEncapsulators
    SCR_ResourceEncapsulator
      m_aActions
        SCR_ResourceEncapsulatorActionChangeResourceValue
          m_bShouldChangeMaximum = 1
          m_fResourceValueMax = 1000
```

Оба поля непосредственно прописаны в следующих ресурсах; позиции в исходном тексте — строки 15 / 16:

| Фракция | Композиция хранилища |
| --- | --- |
| FIA | Prefabs/Compositions/Misc/SubCompositions/Storage/Slotted/Storage_Supplies_FIA_04.et |
| US | Prefabs/Compositions/Misc/SubCompositions/Storage/Slotted/Storage_Supplies_US_02.et |
| USSR | Prefabs/Compositions/Misc/SubCompositions/Storage/Slotted/Storage_Supplies_USSR_02.et |

Значение относится к сумме представляемых контейнеров композиции. В PerformAction действие делит заданный максимум между контейнерами очереди, вызывает SetMaxResourceValue, а остаток учитывает в одном контейнере. Поэтому исходные максимумы отдельных SupplyStack-префабов могут отличаться от вместимости после выполнения этого действия.

## Цепочка ресурсов

1. CTI_Campaign_HQC_Eden содержит ConflictControlPoint.et и CampaignFactionManager.et; это подтверждено прежней source-диагностикой мира.
2. SCR_CampaignMilitaryBaseComponent.OnAllBasesInitialized для типа BASE выбирает SERVICE_HQ и обращается к SCR_CampaignFaction.GetBuildingPrefab. Getter возвращает m_BaseBuildingHQ. Затем запланирован SpawnBuilding; композиция создаётся в игре, без добавления в сохранённую редакторскую иерархию КП. Вариант фракции берётся из её конфигурации; код также содержит fallback к BLUFOR / OPFOR, если ссылка отсутствует.
3. В Configs/Factions/FIA_Campaign.conf (строка 265), US_Campaign.conf и USSR_Campaign.conf (строка 317) поле m_BaseBuildingHQ ссылается на E_Headquarters_S_Conflict_FIA_01.et / US_01.et / USSR_01.et в PrefabsEditable/Auto/Compositions/Slotted/SlotFlatSmall/.
4. Эти editable-ресурсы наследуют Headquarters_S_Conflict_FIA_01.et / US_01.et / USSR_01.et из Prefabs/Compositions/Slotted/SlotFlatSmall/. В них вложены Storage_Supplies_FIA_04 (строка 62), Storage_Supplies_US_02 (71), Storage_Supplies_USSR_02 (43).
5. Композиции хранилищ наследуют SupplyStorage_Empty.et, затем SupplyStorage_Base.et. В базовом префабе есть SCR_ResourceContainerVirtual и SCR_ResourceEncapsulator; композиции переопределяют действие изменения максимума на 1000.

Место реализации действия: scripts/Game/Sandbox/Resources/ContainerQueue/Encapsulator/Actions/SCR_ResourceEncapsulatorActionBase.c, класс начинается со строки 22, PerformAction — 33. В SCR_ResourceEncapsulator.c действия вызываются при регистрации представляемого контейнера (строка 268).

## Почему прежний отчёт этого не показывал

Ревизия r0030 читает сохранённые source-объекты мира и подтверждённую редакторскую иерархию. Создаваемая в игре композиция командного пункта не входит в этот список физических потомков КП. Поля 250 / 500 в SCR_CampaignSuppliesComponent самого ConflictControlPoint — отдельные настройки компонента; они не являются источником найденного целевого максимума 1000.

GetSuppliesMax у SCR_CampaignMilitaryBaseComponent получает агрегированный максимум ресурсного потребителя базы (scripts/Game/Components/Locations/SCR_CampaignMilitaryBaseComponent.c, строки 2028–2046). Общая величина зависит от состава связанной ресурсной сети; исследование конфигов одной композиции не проверяет всю сеть.

Следующий шаг анализатора: разрешать выбранный m_BaseBuildingHQ и его prefab-наследование / дочерние хранилища; экспортировать encapsulator actions с флагом применения, целевым максимумом, scope и provenance. Исходный максимум каждого физического слота и целевой максимум композиции сохранять раздельно; не прибавлять 1000 как ещё один контейнер и не заменять этим числом всю вместимость базы. Эта функция пока не реализована.

## Проверки и границы результата

Скрипты и префабы прочитаны через FileIO.READ в отдельном диагностическом addon Workbench, вне репозитория мода. Каждый из семи запусков завершился COMPLETE; последние запуски явно подтвердили game=1.8.0.13. Исходный мир не открывался, сущности не создавались, игровой режим не запускался. Проверены все три faction → editable HQ → основной HQ → storage связи, флаг применения / максимум 1000 и код распределения максимума. Воспроизведение видимой вместимости в игровой сессии отдельно не выполнялось.

Сырые ресурсы, скрипт пробы и журналы остаются вне Git. В этой работе зафиксировано исследование; снимки r0001–r0030, обычные таблицы / генератор и native-плагины не изменяются. Даты прежних captures не обновляются.

Для навигации по API: [SCR_CampaignMilitaryBaseComponent](https://community.bistudio.com/wikidata/external-data/arma-reforger/ArmaReforgerScriptAPIPublic/interfaceSCR__CampaignMilitaryBaseComponent.html), [SCR_ResourceEncapsulatorActionChangeResourceValue](https://community.bistudio.com/wikidata/external-data/arma-reforger/ArmaReforgerScriptAPIPublic/interfaceSCR__ResourceEncapsulatorActionChangeResourceValue.html). Числа и цепочка выше проверены по локальным ресурсам версии 1.8.0.13, а не взяты из текущего онлайн API или таблиц версии 1.7.0.49.
