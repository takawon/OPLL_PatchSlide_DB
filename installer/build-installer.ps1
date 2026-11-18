[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$DbSourceDirectory,
    [string]$IsccPath = '',
    [string]$OutputDirectory = 'dist'
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$installerRoot = $PSScriptRoot
$repoRoot = Split-Path -Parent $installerRoot
$definition = Get-Content -LiteralPath (Join-Path $installerRoot 'distribution.json') -Raw -Encoding UTF8 | ConvertFrom-Json

function Get-Sha256([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}
function Assert-FileHash([string]$Path, [string]$Expected, [string]$Label) {
    if (-not (Test-Path -LiteralPath $Path)) { throw "Missing file ($Label): $Path" }
    $actual = Get-Sha256 $Path
    if ($actual -ne $Expected.ToLowerInvariant()) {
        throw "Hash mismatch ($Label): $Path expected $Expected actual $actual"
    }
}

# 1. Validate the database source set against the pinned hashes.
$DbSourceDirectory = [IO.Path]::GetFullPath($DbSourceDirectory)
foreach ($name in @('patchslide.sqlite', 'patchslide_search.sqlite', 'manifest.json')) {
    Assert-FileHash (Join-Path $DbSourceDirectory $name) $definition.dbFiles.$name "database $name"
}
$manifest = Get-Content -LiteralPath (Join-Path $DbSourceDirectory 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if ($manifest.physical_packaging.version -ne $definition.dbVersion) {
    throw "manifest physical_packaging.version '$($manifest.physical_packaging.version)' does not match pinned dbVersion '$($definition.dbVersion)'."
}
if ($manifest.candidate_count -ne $definition.candidateCount) {
    throw "manifest candidate_count '$($manifest.candidate_count)' does not match pinned candidateCount '$($definition.candidateCount)'."
}

# 2. Validate the helper and language files shipped in this repository.
Assert-FileHash (Join-Path $installerRoot 'Manage-InstallerData.ps1') $definition.helperSha256 'installer helper'
foreach ($name in @('Default.isl', 'Japanese.isl')) {
    Assert-FileHash (Join-Path $installerRoot "languages\$name") $definition.languageFiles.$name "language $name"
}

# 3. Resolve and validate the pinned Inno Setup compiler.
if (-not $IsccPath) {
    $command = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    if ($command) { $IsccPath = $command.Source }
    $candidates = @(
        (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'),
        (Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe')
    )
    foreach ($candidate in $candidates) {
        if (-not $IsccPath -and (Test-Path -LiteralPath $candidate)) { $IsccPath = $candidate }
    }
    if (-not $IsccPath) { throw 'ISCC.exe not found. Install Inno Setup 6.7.3 or pass -IsccPath.' }
}
$IsccPath = [IO.Path]::GetFullPath($IsccPath)
# Official ISCC has no usable Windows FileVersion; pin the compiler bytes by
# SHA-256 only (same policy as MGSTC's Get-MgstcCompiler).
Assert-FileHash $IsccPath $definition.compilerSha256 'ISCC.exe'

# 4. Stage the payload in the layout the .iss expects.
$output = [IO.Path]::GetFullPath((Join-Path $repoRoot $OutputDirectory))
New-Item -ItemType Directory -Path $output -Force | Out-Null
$stage = Join-Path $output ('.installer-stage-' + [Guid]::NewGuid().ToString('N'))
try {
    foreach ($dir in @('db', 'installer', 'recipe\languages')) {
        New-Item -ItemType Directory -Path (Join-Path $stage $dir) -Force | Out-Null
    }
    foreach ($name in @('patchslide.sqlite', 'patchslide_search.sqlite', 'manifest.json')) {
        Copy-Item -LiteralPath (Join-Path $DbSourceDirectory $name) -Destination (Join-Path $stage "db\$name")
    }
    Copy-Item -LiteralPath (Join-Path $installerRoot 'Manage-InstallerData.ps1') -Destination (Join-Path $stage 'installer\Manage-InstallerData.ps1')
    Copy-Item -LiteralPath (Join-Path $installerRoot 'OPLL_PatchSlide_DB.iss') -Destination (Join-Path $stage 'recipe\OPLL_PatchSlide_DB.iss')
    foreach ($name in @('Default.isl', 'Japanese.isl')) {
        Copy-Item -LiteralPath (Join-Path $installerRoot "languages\$name") -Destination (Join-Path $stage "recipe\languages\$name")
    }
    Copy-Item -LiteralPath (Join-Path $repoRoot 'LICENSE') -Destination (Join-Path $stage 'LICENSE')

    # 5. Compile.
    $setupName = "OPLL_PatchSlide_DB-$($definition.dbVersion)-setup"
    & $IsccPath "/DSourceRoot=$stage" "/DDbVersion=$($definition.dbVersion)" `
        "/DInstallerVersion=$($definition.installerVersion)" "/O$output" "/F$setupName" `
        (Join-Path $stage 'recipe\OPLL_PatchSlide_DB.iss')
    if ($LASTEXITCODE -ne 0) { throw "ISCC failed with exit code $LASTEXITCODE." }
    $artifact = Join-Path $output ($setupName + '.exe')
    if (-not (Test-Path -LiteralPath $artifact)) { throw "Expected artifact missing: $artifact" }
    Write-Output $artifact
    Write-Output ("SHA-256: " + (Get-Sha256 $artifact))
} finally {
    $resolved = [IO.Path]::GetFullPath($stage)
    if ((Split-Path -Parent $resolved) -eq $output -and (Split-Path -Leaf $resolved) -like '.installer-stage-*') {
        Remove-Item -LiteralPath $resolved -Recurse -Force -ErrorAction SilentlyContinue
    }
}
