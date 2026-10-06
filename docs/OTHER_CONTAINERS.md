# Остальные контейнеры с припасами

Команда `Reports → Export world supplies containers` читает настроенные SUPPLIES-слоты всех editor source открытого мира, всех загруженных subscene и prefab-детей. `New-OtherSupplyContainersReport.ps1` исключает контейнеры, уже сохранённые в проверенном отчёте вместимости баз, и готовит отдельный `OtherContainers.json` / `.md`.

В HQC Everon **1.8.0.13** найдено **568 остальных физических контейнеров** в **129 группах хранилищ / объектов**, вместимость **190700 припасов**. Состав: **387 × 100**, **58 × 500**, **123 × 1000**. Ранее сохранённые **49 физических контейнеров** r0004 исключены после проверки ID, prefab, класса, значений и координат. 129 остальных виртуальных представлений сохранены отдельно и не суммируются. Обе subscene прочитаны; все найденные физические SUPPLIES-слоты этой версии находятся в HQC, слой default, а в Eden дополнительных слотов нет.

[Таблица r0005](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0005/Supplies/OtherContainers.md), [канонический JSON](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/revisions/r0005/Supplies/OtherContainers.json). Корневая [OtherContainers.md](../snapshots/1.8.0.13/worlds/CTI_Campaign_HQC_Eden/Supplies/OtherContainers.md) представляет те же данные.

## Алгоритм и поля

1. Один раз обойти все editor source. Прочитать только `SCR_ResourceComponent`, `Enabled`, `m_aDisabledResourceTypes` и `m_aContainers`. В слотах прочитать четыре поля: `m_eResourceType`, `m_eStorageType`, `m_fResourceValueMax`, `m_fResourceValueCurrent`. Сохранить только SUPPLIES, виртуальные представления и неразрешённые типы / списки, с нужными родителями. Разрешённые другие типы и пустые компоненты исключить.
2. Проверить версию игры и сценарий обоих входов. Сопоставить все ранее сохранённые физические и виртуальные слоты по уникальной комбинации `(sourceId, componentIndex, containerIndex)`, проверить prefab, класс, вместимость, начальное значение и координаты (допуск 0,02 м). Дубликат, изменение или потеря прежнего слота означает отказ до создания результата.
3. Из остальных SUPPLIES сохранить отдельно физический `SCR_ResourceContainer` и виртуальный `SCR_ResourceContainerVirtual`. Последний не прибавлять к вместимости. Неизвестный тип / класс сохранить в unresolvedSlots; неизвестный максимум оставить null / unknown, вместе с известным подытогом.
4. Для физического контейнера сохранить вместимость `m_fResourceValueMax` отдельно от начального количества в конфиге `m_fResourceValueCurrent`, состояние компонента и SUPPLIES, prefab, слой, subscene, мировую позицию и иерархию. Для полей сохранить сырое значение, тип, статус, override и способ чтения; точный ресурс определения унаследованного поля пока unknown.
5. Ближайший предок с prefab даёт групповую подпись состава; если такого предка нет, использовать сам объект. Это не назначение игровой базе. ID группы отличает одинаковые prefab в разных местах. Принадлежность базы по расстоянию не вычислять.
6. Сохранить отдельный OtherContainers.json и построить Markdown из сохранённого JSON. data.json остаётся индексом, world.json хранит дату UTC и SHA-256 нового входа и прежнего отчёта. Каталог результата должен быть свободен; опубликованные ревизии сохраняются.

`OtherContainers` описывает физические контейнеры. Планируемый `Supply Depots / Anothers` относится к базам-источникам, не попавшим в Harbors, и остаётся отдельной задачей.

## CLI

К проверенным `-gproj` и `-addonsDir` из [SOURCE_DIAGNOSTICS.md](SOURCE_DIAGNOSTICS.md) добавить:

```text
-wbModule=WorldEditor -run -exitAfterInit -plugin=ME_CA_WorldSupplyContainersPlugin -ME_CA_World=worlds/MP/CTI_Campaign_HQC_Eden.ent -ME_CA_LogJson=1
```

После завершения именно этого процесса извлечь журнал и сформировать новую ревизию (все выходные пути должны быть свободны):

```powershell
.\tools\Convert-DiagnosticsLog.ps1 `
  -LogPath '<console.log этого запуска>' `
  -OutputPath .\exports\HQC_Eden_WorldSupplyContainers_1.8.0.13.json `
  -ReportKind WorldSupplyContainers

.\tools\New-OtherSupplyContainersReport.ps1 `
  -ReportPath .\exports\HQC_Eden_WorldSupplyContainers_1.8.0.13.json `
  -KnownStorageReportPath .\snapshots\1.8.0.13\worlds\CTI_Campaign_HQC_Eden\revisions\r0004\Supplies\StorageCapacity.json `
  -OutputDirectory .\exports\HQC_Eden_OtherContainers_r0005 `
  -RevisionId r0005 `
  -RevisionReason 'Inventory other configured supplies containers excluding verified base storage' `
  -WorkbenchVersion 1.8.0.13
```

В текущей реализации перенос ревизии в snapshots, дополнение manifest и обновление корневой Markdown-копии выполняются вручную после проверки. Несколько Workbench CLI запускать последовательно, чтобы избежать общего журнала.

## Ограничения и проверки

Это инвентаризация настроенных editor-контейнеров: декоративный ящик без SCR_ResourceComponent не считается. Начальное количество в конфиге не выдаётся за фактический запас в игровой сессии. Runtime-связи ресурсной сети, динамические постройки, создаваемые во время игры объекты и принадлежность отдельно расположенным базам не анализировались.

Отчёт имеет статус partial. Совпадение source ID проверено между выполненными запусками этой версии, но устойчивость этих ID при изменении версии не подтверждена. Пустые списки отфильтрованы; неразрешённые записи сохраняются отдельно и делают полный итог unknown. Прямой FileIO-экспорт из интерактивного меню ещё не проверен; подтверждён CLI через журнал. Подробные выполненные проверки — [VALIDATION.md](VALIDATION.md).
