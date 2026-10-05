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
• Полные игровые отчёты и сравнение версий ещё разрабатываются; диагностика помечена partial.
