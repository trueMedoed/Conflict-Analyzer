# Conflict Analyzer — Workshop changelog draft

Служебная заметка: публикации нет. Английский блок предназначен для Workshop, русский — для сверки. Номер выпуска и дату публикации добавить после фактического выпуска. Unreleased означает подготовку, а не опубликованную версию.

## Unreleased

### English — draft text

• Added an initial addon project depending on the base Arma Reforger game.
• Added README, a development checklist, repository ignore rules and project guidelines.
• Added draft Workshop descriptions in English and Russian.
• Defined planned analysis of AI groups, supply points, starting bases and vehicle spawn points.
• Added a World Editor source diagnostic plugin and checked JSON extraction from the Workbench log.
• Verified source inventory and world coordinates on HQC Everon in game / Workbench 1.8.0.13.
• Added a partial versioned snapshot and generated Harbors report for 18 supply source bases, preserving raw seconds and displaying intervals in minutes.
• Added a targeted source-base export and schemaVersion 2 revision with separate Harbors.json and a shared section index; broad diagnostics remain a separate command.
• Added selected-base physical storage composition and capacity export, verified on SP_A_EveronAirport: 3 × 1000 + 2 × 500 = 4000; virtual containers are retained separately and excluded from totals.
• Extended configured storage inspection to all 18 source bases and added the Harbors capacity column. Archived the original r0001 before updating the current table; three detached-storage ownership cases remain unknown.
• Added a targeted world supplies-container command and separate OtherContainers JSON / Markdown, excluding verified base slots and virtual views from physical totals.
• OtherContainers now groups 568 physical slots into 124 root-parent rows, retaining individual records and separate prefab instances in JSON.
• Added named map locations and lists of OtherContainers / Harbors objects within a 1000 m horizontal radius: 170 labels, 142 objects. Overlapping matches retain distances and do not imply gameplay ownership.
• Simplified Locations Markdown to 150 populated location lists; descriptor types, location IDs and all 170 source labels remain in JSON.
• Locations now supports manual world-group review with location positions in headings and object positions / distances in each list; supply and identifier columns remain in JSON.
• Reduced the default location radius from 1000 to 500 m in r0009: 348 links, 76 populated locations and seven unmatched objects retained; previous published revisions are preserved.
• Complete gameplay reports and version comparison remain in development; diagnostics are marked partial.

### Русский — перевод для сверки

• Добавлен начальный addon-проект с зависимостью от базовой Arma Reforger.
• Добавлены README, план разработки, правила исключений Git и памятка проекта.
• Подготовлены черновики описаний Workshop на английском и русском языках.
• Запланирован анализ групп ИИ, точек с припасами, стартовых баз и точек появления машин.
• Добавлены плагин диагностики source в World Editor и проверяемая сборка JSON из журнала Workbench.
• Инвентаризация источников и мировые координаты проверены на HQC Everon в игре / Workbench 1.8.0.13.
• Добавлены частичный снимок по версии игры и генерируемый отчёт Harbors для 18 баз-источников припасов; исходные секунды сохранены, интервал отображается в минутах.
• Добавлены целевой экспорт баз-источников и ревизия schemaVersion 2 с отдельным Harbors.json и общим индексом разделов; широкая диагностика остаётся отдельной командой.
• Добавлен экспорт состава физических хранилищ и вместимости выбранной базы, проверенный на SP_A_EveronAirport: 3 × 1000 + 2 × 500 = 4000; виртуальные контейнеры сохраняются отдельно и исключаются из итогов.
• Обход настроенных хранилищ расширен на все 18 баз-источников, в Harbors добавлен столбец вместимости. Перед обновлением актуальной таблицы сохранён исходный r0001; три случая принадлежности отдельных складов остаются unknown.
• Добавлены целевая команда контейнеров мира и отдельные OtherContainers JSON / Markdown; проверенные слоты баз и виртуальные представления исключены из физического итога.
• OtherContainers теперь группирует 568 физических слотов в 124 строки корневых родителей; индивидуальные записи и разные экземпляры prefab сохранены в JSON.
• Добавлены именованные локации и списки объектов OtherContainers / Harbors в горизонтальном радиусе 1000 м: 170 подписей, 142 объекта. Перекрывающиеся совпадения сохраняют расстояния и не означают игровую принадлежность.
• Locations Markdown упрощён до 150 списков локаций с объектами; типы, ID локаций и все 170 исходных подписей сохранены в JSON.
• Locations оформлен для ручной сверки групп мира: позиции локаций в заголовках, позиции объектов и расстояния в списках; данные припасов и идентификаторы сохранены в JSON.
• В r0009 радиус локаций по умолчанию уменьшен с 1000 до 500 м: 348 связей, 76 локаций с объектами; семь объектов без совпадений сохранены. Предыдущие опубликованные ревизии сохранены.
• Полные игровые отчёты и сравнение версий ещё разрабатываются; диагностика помечена partial.
