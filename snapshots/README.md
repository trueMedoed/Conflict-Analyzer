# Снимки данных по версиям игры

Утверждённая иерархия: `<game-version>/worlds/<scenario-key>/`.

В каталоге версии находится `manifest.json`, в каталоге сценария — `world.json`, `data.json` и готовые таблицы. Разделы добавляются по мере анализа; отсутствие таблицы не означает отсутствие объектов в мире.

Этот каталог хранится в Git. Первый проверенный снимок **1.8.0.13 / CTI_Campaign_HQC_Eden / r0001** имеет статус **partial**:

- [Манифест версии](1.8.0.13/manifest.json).
- [Метаданные мира](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0001/world.json) и [нормализованные данные](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0001/data.json).
- [Припасы — охват раздела](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0001/Supplies.md).
- [Базы-источники припасов — Harbors](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0001/Supplies/Harbors.md): 18 точек, количество пополнения за цикл и интервал в минутах.

Вторая проверенная ревизия **r0002 / schemaVersion 2** подготовлена отдельной целевой командой Workbench:

- [Метаданные](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0002/world.json) и [индекс разделов](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0002/data.json).
- [Harbors.json — 18 нормализованных записей](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0002/Supplies/Harbors.json) и [таблица](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0002/Supplies/Harbors.md).

Широкий дамп для второй ревизии не требуется; записи находятся в JSON своей таблицы, общий `data.json` служит индексом. Склады и вместимость, игровые названия локаций, ИИ, стартовые базы и машины ещё не нормализованы и обозначены `not_analyzed`.

Временная подготовка результатов выполняется в игнорируемом `exports/`. Опубликованные снимки сохраняются: `r0001` сохранён в `revisions/r0001/` после обновления актуальной корневой таблицы по просьбе пользователя; исправленные или расширенные снимки — в `revisions/r0002/` и далее. Манифест версии перечисляет ревизии явно.

Правила метаданных, идентификаторов и сравнения: [docs/DATA_LAYOUT.md](../docs/DATA_LAYOUT.md).

Третья проверенная ревизия **r0003 / schemaVersion 2** исследует только настроенную вместимость вложенных контейнеров `SP_A_EveronAirport`:

- [Хранилища и состав](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0003/Supplies/StorageCapacity.md) и [канонический JSON](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0003/Supplies/StorageCapacity.json): 2 хранилища, 5 физических контейнеров, 4000 припасов; виртуальные представления исключены из суммы.
- [Метаданные](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0003/world.json) и [индекс разделов](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0003/data.json). Доход баз и остальные разделы в этой ревизии не пересобирались; статус `partial`.

Четвёртая ревизия **r0004** добавляет вместимость в [актуальный Harbors](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/Supplies/Harbors.md): 18 точек, у 15 — определённая вместимость вложенных контейнеров, у StPierre / Lamentin / Meaux — unknown. [Каноническая таблица](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0004/Supplies/Harbors.md) и [полный состав контейнеров](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0004/Supplies/StorageCapacity.md) сохранены с JSON рядом. 49 физических контейнеров дают известный подытог 40500 припасов; это не полный подтверждённый итог всех баз. Исходные четыре файла r0001 сохранены без изменения содержания в `revisions/r0001/`.

Пятая ревизия **r0005**: [остальные контейнеры](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0005/Supplies/OtherContainers.md) и [JSON](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0005/Supplies/OtherContainers.json). Сохранены 568 физических SUPPLIES-слотов в 129 группах с настроенной вместимостью 190700, начальным количеством и координатами. 49 физических контейнеров r0004 исключены; 129 остальных виртуальных представлений идут отдельно. Первоначальная таблица сохранена в r0005; старые ревизии сохранены.

Шестая ревизия **r0006**: [родительская таблица](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0006/Supplies/OtherContainers.md) и [JSON с индивидуальным составом](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0006/Supplies/OtherContainers.json). 124 родителя объединяют 568 физических слотов в 129 вложенных хранилищах; вместимость осталась 190700. [Корневая таблица](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/Supplies/OtherContainers.md) представляет r0006. Это повторная обработка прежней выгрузки; старые ревизии сохранены.

Седьмая ревизия **r0007**: [локации и объекты в радиусе 1000 м](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0007/Locations.md), [JSON](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0007/Locations.json). 170 подписей Eden и 142 объекта из OtherContainers r0006 / Harbors r0004, 1084 связи по близости. Первое представление [корневого справочника](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/Locations.md) соответствовало r0007. Прежние даты каталогов припасов сохранены отдельно; несколько списков не означают несколько физических объектов или игровую принадлежность.

Текущее Markdown-представление r0007 показывает 150 локаций с объектами, без типа / ID локации; 20 пустых скрыты. Полный JSON и исходные метаданные сохраняют прежние 170 подписей, 142 объекта и 1084 связи.

Восьмая ревизия **r0008**: [справочник для сверки групп](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0008/Locations.md), [JSON](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0008/Locations.json). Те же 150 видимых локаций, 142 объекта / 1084 связи; позиции локаций в заголовках, позиции объектов в таблицах. Это новое представление прежних данных, группировка пока проверяется вручную. [Корневой справочник](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/Locations.md) ранее представлял r0008; опубликованный r0007 сохранён.

Девятая ревизия **r0009**: [локации в радиусе 500 м](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0009/Locations.md), [JSON](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0009/Locations.json). Из прежних входов получены 348 связей и 76 видимых локаций; 135 из 142 объектов сопоставлены, семь без совпадений сохранены отдельно. Все 170 подписей остаются в JSON, даты сбора не менялись. [Корневой справочник](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/Locations.md) ранее представлял r0009; прежние опубликованные ревизии с радиусом 1000 м сохранены.

Десятая ревизия **r0010**: [локации с исключением водоёмов](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0010/Locations.md), [JSON](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0010/Locations.json). Из прежних 170 подписей исключены 24 подписи типов Name Water Minor / Major; по 146 допустимым локациям получены 288 связей и 66 видимых списков. Из 142 объектов 126 сопоставлены, 16 остаются без совпадений. Исходные подписи / причины исключения, даты и SHA-256 сохранены; радиус остаётся 500 м. [Корневой справочник](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/Locations.md) представляет r0010; опубликованные r0001–r0009 не изменены.
