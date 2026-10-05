# Снимки данных по версиям игры

Утверждённая иерархия: `<game-version>/worlds/<scenario-key>/`.

В каталоге версии находится `manifest.json`, в каталоге сценария — `world.json`, `data.json` и готовые таблицы. Разделы добавляются по мере анализа; отсутствие таблицы не означает отсутствие объектов в мире.

Этот каталог хранится в Git. Первый проверенный снимок **1.8.0.13 / CTI_Campaign_HQC_Eden / r0001** имеет статус **partial**:

- [Манифест версии](1.8.0.13/manifest.json).
- [Метаданные мира](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/world.json) и [нормализованные данные](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/data.json).
- [Припасы — охват раздела](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/Supplies.md).
- [Базы-источники припасов — Harbors](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/Supplies/Harbors.md): 18 точек, количество пополнения за цикл и интервал в минутах.

Вторая проверенная ревизия **r0002 / schemaVersion 2** подготовлена отдельной целевой командой Workbench:

- [Метаданные](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0002/world.json) и [индекс разделов](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0002/data.json).
- [Harbors.json — 18 нормализованных записей](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0002/Supplies/Harbors.json) и [таблица](1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0002/Supplies/Harbors.md).

Широкий дамп для второй ревизии не требуется; записи находятся в JSON своей таблицы, общий `data.json` служит индексом. Склады и вместимость, игровые названия локаций, ИИ, стартовые базы и машины ещё не нормализованы и обозначены `not_analyzed`.

Временная подготовка результатов выполняется в игнорируемом `exports/`. Опубликованные снимки сохраняются: `r0001` находится в корне сценария, исправленные или расширенные снимки — в `revisions/r0002/` и далее. Манифест версии перечисляет ревизии явно.

Правила метаданных, идентификаторов и сравнения: [docs/DATA_LAYOUT.md](../docs/DATA_LAYOUT.md).
