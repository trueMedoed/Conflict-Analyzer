# Conflict Analyzer — Workshop draft (English)

Internal note: unpublished draft. Source diagnostics are implemented; the complete gameplay report is still planned. Summary and Description blocks use plain text for copying into Workshop. Update the English and Russian versions together after verification.

## Summary

Workbench helper for investigating a Conflict world. The first prototype exports partial source diagnostics; complete AI, supply, starting base and vehicle reports are still in development.

## Description

Conflict Analyzer helps scenario authors investigate the configuration of a Conflict world. It is being developed into a tool for collecting readable reports without maintaining all the tables by hand.

Current status
• A World Editor diagnostic command reads selected source entities, component fields, layers, prefab references and world positions into partial JSON.
• Tested on CTI_Campaign_HQC_Eden.ent in Arma Reforger / Workbench 1.8.0.13.
• A repository-side converter builds a partial archived report of 18 supply source bases from the diagnostic JSON, with configured income per cycle, intervals in minutes and field provenance.
• A separate source-base command now exports only the selected component and four fields. Its report builder writes Harbors.json beside the generated table; the shared data.json is a section index.
• Added a selected-base storage inspection command. On Everon airport it resolves two storage compositions and five physical containers, totaling 4000 configured supplies capacity; virtual views are excluded from the sum. The subsequent batch covers all 18 source bases; runtime grid membership remains unverified.
• Added a storage-capacity column for all 18 source bases: 49 unique physical containers, 15 resolved descendant capacities and three unknown ownership cases. Income retains its earlier verified capture; nearby detached caches are not assigned by distance.
• Complete gameplay reports and version comparison are not implemented yet. This is an unpublished prototype.

Planned features
• AI spawn points, group types, faction, group composition and soldier counts, with random options and presence probabilities shown separately.
• Supply points and storage counts, initial supplies, capacity, replenishment amount and interval.
• Starting HQ candidates, their locations, starting supplies and supply generation settings.
• Vehicle spawn points, locations, allowed vehicle options and available spawn or respawn settings.
• A readable report with data sources and warnings for incomplete information.

Current diagnostic use
1. Open the addon project in Arma Reforger Workbench.
2. Open a saved Conflict world in World Editor.
3. Run Export world source diagnostics under [ME] Conflict Analyzer / Diagnostics. The repository also documents a verified CLI route through the Workbench log.

Diagnostics read the current editor state and do not save the source world. File export uses a separate directory; direct FileIO export still needs an interactive check.

Limitations
• Reading only the .ent file is not sufficient: related layers, parent worlds, prefabs and configuration resources must be resolved.
• Configured candidates and maximum possible counts do not guarantee what will spawn in a particular game session.
• Values depend on the world and game version. Missing resources must be reported as unknown rather than zero.
• Complete object-valued configurations and faction catalogs remain unresolved; the selected-base storage command reads only its required container settings. Found components are not gameplay totals or soldier counts.
• Runtime diagnostics and an in-game interface are outside the initial proposed scope.
