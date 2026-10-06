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
• Excluded ponds, rivers, streams and lakes from matching by descriptor type in r0010: 24 excluded labels, 288 links and 16 unmatched objects; all original labels and objects remain in JSON.
• r0011 groups objects only around settlements within 300 m: 47 matched objects and a separate UngroupedObjects list of 95 remaining objects with world positions; geographic fallback is not performed.
• r0012 adds Name Generic as a second matching stage for objects outside settlement groups, using the same 300 m radius: 63 additional objects grouped, 32 remaining, and all 47 previous settlement assignments preserved.
• r0013 adds Name Island with equal settlement priority within 300 m: three previously ungrouped objects matched to Île-aux-Saules, 29 remain; earlier settlement and Generic assignments are preserved.
• r0014 adds Name Hill to the first stage within 300 m: five previously ungrouped objects matched to CALVARY HILL, 24 remain; previous settlement, island and Generic assignments are preserved.
• r0015 increases both matching-stage radii from 300 to 350 m: five additional objects grouped, two move from Generic to settlements, and one receives another Generic link. There are 31 populated groups and 19 ungrouped objects; earlier revisions and source data are preserved.
• r0016 combines grouped and ungrouped objects in one Locations report, with the ungrouped category at the end; matching data and earlier revisions are preserved.
• r0017 adds separate location-grouped OtherContainers and Harbors views using existing Locations links, preserving supply values, unknown capacities and earlier snapshots.
• r0018 combines supply tables into OtherContainers with Harbors as the final category; all values, locations, separate JSON catalogs and earlier revisions are preserved.
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
• В r0010 пруды, реки, ручьи и озёра исключены из сопоставления по типу подписи: 24 исключённые локации, 288 связей, 16 объектов без совпадений; все исходные подписи и объекты сохранены в JSON.
• r0011 собирает объекты только у населённых пунктов в радиусе 300 м: 47 сгруппированных объектов и отдельный UngroupedObjects со списком 95 оставшихся и их координатами; автоматического назначения другим локациям нет.
• r0012 добавляет Name Generic вторым этапом для остатка после населённых пунктов в том же радиусе 300 м: ещё 63 объекта сгруппированы, 32 остались, все 47 прежних назначений у населённых пунктов сохранены.
• r0013 добавляет Name Island наравне с населёнными пунктами в радиусе 300 м: три объекта из остатка отнесены к Île-aux-Saules, осталось 29; прежние назначения населённых пунктов / Generic сохранены.
• r0014 добавляет Name Hill в первый этап в радиусе 300 м: пять объектов из остатка отнесены к CALVARY HILL, осталось 24; прежние назначения населённых пунктов / островов / Generic сохранены.
• r0015 повышает радиус обоих этапов с 300 до 350 м: ещё пять объектов сгруппированы, два переходят от Generic к населённым пунктам, один получает дополнительную связь Generic. 31 непустая группа и 19 объектов без группы; прежние ревизии и исходные данные сохранены.
• r0016 объединяет группы и объекты без группы в одном Locations, с категорией без группы в конце; данные сопоставления и прежние ревизии сохранены.
• r0017 добавляет отдельные представления OtherContainers и Harbors по готовым связям Locations; значения припасов, неизвестные вместимости и прежние снимки сохранены.
• r0018 объединяет таблицы припасов в OtherContainers, Harbors идёт последней категорией; значения, локации, раздельные JSON-каталоги и прежние ревизии сохранены.
• Полные игровые отчёты и сравнение версий ещё разрабатываются; диагностика помечена partial.
