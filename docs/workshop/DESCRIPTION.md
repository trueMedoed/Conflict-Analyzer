# Conflict Analyzer — Workshop draft (English)

Internal note: unpublished draft. The analysis and export features below are planned, not implemented. Summary and Description blocks use plain text for copying into Workshop. Update the English and Russian versions together after verification.

## Summary

Planned Workbench helper for understanding a Conflict scenario: see which AI groups, supply sources, starting bases and vehicle spawn points are configured in its world. Analysis features are not available in this initial scaffold.

## Description

Conflict Analyzer is planned to help scenario authors collect a readable overview of a Conflict world without maintaining all the tables by hand.

Current status
• Initial addon project and development documentation only.
• No world analysis command or report export is implemented yet.
• This draft does not describe a released or verified analysis tool.

Planned features
• AI spawn points, group types, faction, group composition and soldier counts, with random options and presence probabilities shown separately.
• Supply points and storage counts, initial supplies, capacity, replenishment amount and interval.
• Starting HQ candidates, their locations, starting supplies and supply generation settings.
• Vehicle spawn points, locations, allowed vehicle options and available spawn or respawn settings.
• A readable report with data sources and warnings for incomplete information.

Planned use
1. Open the addon project in Arma Reforger Workbench.
2. Select a Conflict world after the analysis command has been implemented.
3. Export a report to a separate output directory.

The planned root menu category is [ME] Conflict Analyzer. No command is currently provided.

Limitations
• Reading only the .ent file is not sufficient: related layers, parent worlds, prefabs and configuration resources must be resolved.
• Configured candidates and maximum possible counts do not guarantee what will spawn in a particular game session.
• Values depend on the world and game version. Missing resources must be reported as unknown rather than zero.
• Runtime diagnostics and an in-game interface are outside the initial proposed scope.
