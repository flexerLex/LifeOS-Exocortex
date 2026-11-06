param(
    [string]$Root = "C:\Users\ASRock\RiderProjects\LifeOS-Exocortex",
    [string]$Output = "$env:USERPROFILE\Desktop\LifeOS_for_Argon.md",
    [switch]$OnlyMd
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $Root)) {
    Write-Host "Folder not found: $Root" -ForegroundColor Red
    exit 1
}
$Root = (Resolve-Path -LiteralPath $Root).Path.TrimEnd('\')

# File types to include
$mdExt   = @('.md')
$codeExt = @('.cs', '.csproj', '.sln', '.slnx', '.props', '.targets', '.json',
             '.yml', '.yaml', '.xml', '.editorconfig', '.txt', '.http', '.sql', '.sh')
$extensions = if ($OnlyMd) { $mdExt } else { $mdExt + $codeExt }

# Folders to skip
$excludePattern = '\\(bin|obj|\.git|\.vs|\.idea|node_modules|TestResults)(\\|$)'

# Language tags for code fences
$langMap = @{
    '.md' = 'markdown'; '.cs' = 'csharp'; '.csproj' = 'xml'; '.props' = 'xml'
    '.targets' = 'xml'; '.xml' = 'xml'; '.sln' = 'text'; '.slnx' = 'xml'
    '.json' = 'json'; '.yml' = 'yaml'; '.yaml' = 'yaml'; '.sql' = 'sql'
    '.sh' = 'bash'; '.http' = 'http'; '.txt' = 'text'; '.editorconfig' = 'ini'
}

# Paths to skip: the output file itself and this script
$outFull = $null
if (Test-Path -LiteralPath $Output) { $outFull = (Resolve-Path -LiteralPath $Output).Path }
$selfPath = $PSCommandPath

$files = Get-ChildItem -LiteralPath $Root -Recurse -File | Where-Object {
    $rel = '\' + $_.FullName.Substring($Root.Length + 1)
    ($extensions -contains $_.Extension.ToLower()) -and
    ($rel -notmatch $excludePattern) -and
    ($_.FullName -ne $outFull) -and
    ($_.FullName -ne $selfPath)
} | Sort-Object FullName

if ($files.Count -eq 0) {
    Write-Host "No matching files found." -ForegroundColor Yellow
    exit 1
}

# Four backticks, so triple backticks inside files do not break the block
$fence = '````'
$sb = New-Object System.Text.StringBuilder

# Instructions for the model
[void]$sb.AppendLine(@'
# Project context for analysis

Below is the full content of the project: first the file tree, then each file
in its own block with the path in the heading.

## How to answer
- Study the whole architecture and code before proposing changes.
- For every change give the file path and the changed fragment, with enough
  surrounding context to make clear where it goes.
- Give new files in full, with the full path.
- If something could not be verified (build, tests), say so explicitly.
- Do not change anything I did not ask about. First list the problems you
  found, then propose fixes.

'@)

# File tree
[void]$sb.AppendLine("## Project structure")
[void]$sb.AppendLine()
[void]$sb.AppendLine($fence + "text")
foreach ($f in $files) {
    [void]$sb.AppendLine($f.FullName.Substring($Root.Length + 1))
}
[void]$sb.AppendLine($fence)
[void]$sb.AppendLine()

# File contents
[void]$sb.AppendLine("## File contents")
[void]$sb.AppendLine()

foreach ($f in $files) {
    $rel = $f.FullName.Substring($Root.Length + 1)
    $ext = $f.Extension.ToLower()
    $lang = if ($langMap.ContainsKey($ext)) { $langMap[$ext] } else { 'text' }
    $content = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)

    [void]$sb.AppendLine("### FILE: $rel")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine($fence + $lang)
    [void]$sb.AppendLine($content.TrimEnd())
    [void]$sb.AppendLine($fence)
    [void]$sb.AppendLine()
}

# Save as UTF-8 without BOM
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($Output, $sb.ToString(), $utf8NoBom)

$sizeKb = [math]::Round((Get-Item -LiteralPath $Output).Length / 1KB, 1)
$approxTokens = [math]::Round($sb.Length / 3)
Write-Host ""
Write-Host "Done: $Output" -ForegroundColor Green
Write-Host "Files: $($files.Count) | Size: $sizeKb KB | Approx tokens: $approxTokens"