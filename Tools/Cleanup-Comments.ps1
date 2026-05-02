param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromRemainingArguments = $true)]
    [string[]] $Paths,

    [switch] $DryRun
)

$ErrorActionPreference = 'Stop'

$importantMarkers = @('TODO', 'FIXME', 'HACK', 'NOTE', 'IMPORTANT', 'WARNING', 'BUG')
$unityTemplateComments = [System.Collections.Generic.HashSet[string]]::new([string[]]@(
    'Start is called before the first frame update',
    'Update is called once per frame',
    'Awake is called when the script instance is being loaded',
    'OnEnable is called when the object becomes enabled and active',
    'OnDisable is called when the behaviour becomes disabled',
    'FixedUpdate is called at fixed time intervals',
    'LateUpdate is called after all Update functions have been called'
))

$codeishRegex = [regex]::new(@"
^\s*//\s*(
    using\b|
    (public|private|protected|internal|static|sealed|abstract|virtual|override)\b|
    (class|struct|interface|enum|namespace)\b|
    (if|else|for|foreach|while|switch|case|try|catch|finally|return|throw|break|continue)\b|
    (var|int|float|double|decimal|bool|string|char|long|short|byte|void)\b|
    \{|\}|
    \w+\s*\(|
    \w+\s*=>|
    \w+\s*=\s*new\b
)
"@, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace)

function Test-IsSeparatorComment([string] $trimmedLine) {
    if ($trimmedLine -eq '//' -or $trimmedLine -eq '///') { return $true }
    if ($trimmedLine.StartsWith('//') -and $trimmedLine.Length -ge 4) {
        $body = $trimmedLine.Substring(2).Trim()
        if ($body.Length -gt 0) {
            foreach ($ch in $body.ToCharArray()) {
                if ('-=*_#/\.'.IndexOf($ch) -lt 0) { return $false }
            }
            return $true
        }
    }
    return $false
}

function Test-LooksLikeCommentedOutCode([string] $line) {
    if ($line -match 'https?://') { return $false }
    foreach ($m in $importantMarkers) {
        if ($line.Contains($m)) { return $false }
    }
    if ($line.TrimStart().StartsWith('///')) { return $false }
    if ($codeishRegex.IsMatch($line)) { return $true }

    $statementTokens = @(';', '=>', '{', '}', '==', '!=', '+=', '-=', '*=', '/=')
    if ($line.TrimStart().StartsWith('//')) {
        foreach ($tok in $statementTokens) {
            if ($line.Contains($tok)) { return $true }
        }
    }
    return $false
}

function Get-CsFiles([string] $path) {
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        if ([System.IO.Path]::GetExtension($path).ToLowerInvariant() -eq '.cs') { return ,(Get-Item -LiteralPath $path) }
        return @()
    }
    if (-not (Test-Path -LiteralPath $path -PathType Container)) { return @() }
    return Get-ChildItem -LiteralPath $path -Recurse -File -Filter *.cs
}

$touched = 0
$removed = 0

foreach ($p in $Paths) {
    foreach ($file in (Get-CsFiles $p)) {
        $original = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
        $hasFinalNewline = $original.EndsWith("`n")

        $lines = $original -split "`n", 0, 'SimpleMatch'
        $out = New-Object System.Collections.Generic.List[string]
        $fileRemoved = 0

        foreach ($line in $lines) {
            $trimmed = $line.Trim()

            if ($trimmed.StartsWith('//')) {
                $keep = $false

                foreach ($m in $importantMarkers) {
                    if ($trimmed.Contains($m)) { $keep = $true; break }
                }

                if (-not $keep) {
                    $commentBody = $trimmed.Substring(2).Trim()
                    if ($unityTemplateComments.Contains($commentBody)) { $fileRemoved++; continue }
                    if (Test-IsSeparatorComment $trimmed) { $fileRemoved++; continue }
                    if (Test-LooksLikeCommentedOutCode $line) { $fileRemoved++; continue }
                }
            }

            $out.Add($line)
        }

        if ($fileRemoved -le 0) { continue }

        $touched++
        $removed += $fileRemoved

        if (-not $DryRun) {
            $newText = ($out -join "`n")
            if ($hasFinalNewline -and -not $newText.EndsWith("`n")) { $newText += "`n" }
            Set-Content -LiteralPath $file.FullName -Value $newText -Encoding UTF8
        }
    }
}

$mode = if ($DryRun) { 'DRY-RUN' } else { 'APPLIED' }
Write-Output "${mode}: touched_files=$touched, removed_comment_lines=$removed"
