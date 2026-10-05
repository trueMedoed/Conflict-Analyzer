<# Extract a complete native diagnostic report; reject truncated or mixed runs. #>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$LogPath,
    [Parameter(Mandatory = $true)][string]$OutputPath
)
$ErrorActionPreference = 'Stop'
$lines = Get-Content -LiteralPath $LogPath
$begin = @($lines | Where-Object { $_ -match '\[ME_CA_JSON_BEGIN\] characters=(\d+)\s*$' })
$end = @($lines | Where-Object { $_ -match '\[ME_CA_JSON_END\]\s*$' })
$success = @($lines | Where-Object { $_ -match '\[ME_CA\] status=SUCCESS .*output=console-log\s*$' })
if ($begin.Count -ne 1 -or $end.Count -ne 1 -or $success.Count -ne 1) {
    throw 'Expected one complete, successful JSON diagnostic run in the log.'
}
$null = $begin[0] -match 'characters=(\d+)'
$expectedLength = [int]$Matches[1]
$prefix = '[ME_CA_JSON_CHUNK] '
$chunks = @($lines | Where-Object { $_.Contains($prefix) } | ForEach-Object {
    $_.Substring($_.IndexOf($prefix) + $prefix.Length)
})
$json = $chunks -join ''
if ($json.Length -ne $expectedLength) {
    throw "Incomplete JSON: expected $expectedLength characters, received $($json.Length)."
}
$report = $json | ConvertFrom-Json -ErrorAction Stop
if ($report.schemaVersion -ne 1 -or $report.kind -ne 'editor-source-diagnostics' -or
    !$report.worldPath -or $report.entities.Count -ne $report.diagnosticEntityCount -or
    !$report.editorEntityCountUnchanged) {
    throw 'Diagnostic report metadata or entity counts are inconsistent.'
}
$absoluteOutput = [IO.Path]::GetFullPath($OutputPath)
# CreateNew refuses to overwrite an existing export, including a concurrent one.
$stream = [IO.File]::Open($absoluteOutput, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
$writer = New-Object IO.StreamWriter($stream, (New-Object Text.UTF8Encoding($false)))
try { $writer.Write($json) } finally { $writer.Dispose() }
[pscustomobject]@{
    OutputPath = $absoluteOutput
    GameVersion = $report.gameVersion
    WorldPath = $report.worldPath
    VisitedSources = $report.visitedSourceCount
    DiagnosticEntities = $report.diagnosticEntityCount
    CoordinateMismatches = $report.coordinateMismatchCount
}
