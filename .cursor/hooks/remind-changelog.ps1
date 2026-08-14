$ErrorActionPreference = "Stop"

function Get-AllStrings {
    param([Parameter(ValueFromPipeline = $true)]$Node)
    if ($null -eq $Node) { return @() }
    if ($Node -is [string]) { return @($Node) }
    if ($Node -is [System.Collections.IDictionary]) {
        $out = @()
        foreach ($k in $Node.Keys) { $out += Get-AllStrings $Node[$k] }
        return $out
    }
    if ($Node -is [System.Collections.IEnumerable] -and -not ($Node -is [string])) {
        $out = @()
        foreach ($item in $Node) { $out += Get-AllStrings $item }
        return $out
    }
    return @()
}

try {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) {
        Write-Output '{"additional_context":""}'
        exit 0
    }

    $payload = $raw | ConvertFrom-Json -Depth 32
    $strings = Get-AllStrings $payload

    $patternsGameplay = @(
        "GameManager",
        "UIController",
        "ClientController",
        "SpiritDatabase",
        "WorldSpawner",
        "OtakuHavenBuilder",
        "docs/realm-of-spirits/studio/"
    )

    $gameplayTouched = $false
    $changelogTouched = $false
    foreach ($s in $strings) {
        if ($s -match "docs[\\/]+realm-of-spirits[\\/]+CHANGELOG\.md") {
            $changelogTouched = $true
        }
        foreach ($p in $patternsGameplay) {
            if ($s -like "*$p*") {
                $gameplayTouched = $true
            }
        }
    }

    if ($gameplayTouched -and -not $changelogTouched) {
        $msg = "Напоминание: после изменений игровых скриптов обнови docs/realm-of-spirits/CHANGELOG.md ([Unreleased])."
        $obj = @{ additional_context = $msg }
        $obj | ConvertTo-Json -Compress
    } else {
        Write-Output '{"additional_context":""}'
    }
}
catch {
    # Fail-open to avoid blocking edits.
    Write-Output '{"additional_context":""}'
}
