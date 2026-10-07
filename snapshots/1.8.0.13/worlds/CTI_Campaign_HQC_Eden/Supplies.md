# Припасы по приоритетам

Текущая ревизия **r0025**: [единая таблица](Supplies/OtherContainers.md), [объекты](Locations.md), [граф](revisions/r0025/Locations.json), [индекс](revisions/r0025/data.json), [метаданные](revisions/r0025/world.json). Контрольные точки → Harbors → склады припасов → города / деревни → остальные объекты → нераспознанные.

Настройки: [ControlPoints](revisions/r0025/Supplies/ControlPoints.json), [Harbors](revisions/r0025/Supplies/Harbors.json), [SupplyDepots](revisions/r0025/Supplies/SupplyDepots.json), [OtherContainers](revisions/r0025/Supplies/OtherContainers.json). 9 складов / 47 родителей; КП и Harbors сохраняют приоритет, Source ID и индивидуальные поля остаются в JSON. Source-родство / географические связи / компонентные и физические припасы различаются. Остался один нераспознанный StartingPos21.

Harbors — одна таблица из 18 строк: вместимость / состав рядом с названием, затем интервал / количество пополнения и собственные координаты.

Склады показаны по локациям в 350 м: 7 маркеров связаны, 2 в разделе без привязки; внутри каждой локации собственные координаты склада и прежние контейнеры.
