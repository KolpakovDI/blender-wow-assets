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

function Invoke-PythonScript {
    param(
        [string]$ScriptPath
    )
    if (Get-Command py -ErrorAction SilentlyContinue) {
        return & py -3 $ScriptPath 2>&1
    }
    if (Get-Command python -ErrorAction SilentlyContinue) {
        return & python $ScriptPath 2>&1
    }
    return "Python runtime not found; skipped $ScriptPath"
}

try {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) {
        Write-Output '{"additional_context":""}'
        exit 0
    }

    $payload = $raw | ConvertFrom-Json -Depth 32
    $strings = Get-AllStrings $payload
    $joined = ($strings -join "`n")

    $needSpiritChecks = $joined -match "SpiritDatabase"
    $needBattleChecks = $joined -match "GameManager|UIController|ClientController|Battle"

    $messages = @()
    if ($needSpiritChecks -or $needBattleChecks) {
        $out = Invoke-PythonScript "scripts/quality_gate.py"
        if ($LASTEXITCODE -ne 0) {
            $messages += "Quality gate failed: $($out -join ' | ')"
        } elseif ($out -and ($out -join "`n").Trim() -ne "") {
            # Non-blocking informational line to keep context visible.
            $messages += "Quality gate: $($out -join ' | ')"
        }
    }

    if ($messages.Count -gt 0) {
        $msg = ($messages -join "`n")
        @{ additional_context = $msg } | ConvertTo-Json -Compress
    } else {
        Write-Output '{"additional_context":""}'
    }
}
catch {
    # Fail-open to avoid blocking edits.
    Write-Output '{"additional_context":""}'
}
