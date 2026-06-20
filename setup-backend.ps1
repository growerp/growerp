# setup-backend.ps1
# Clones moqui-runtime (with its component submodules) if not already present,
# then symlinks GrowERP custom components into the moqui runtime component directory.
#
# Run once after cloning growerp and initialising the moqui submodule:
#   git clone https://github.com/growerp/growerp
#   cd growerp
#   git submodule update --init --recursive
#   .\setup-backend.ps1

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$MoquiDir = Join-Path $RepoRoot "moqui"
$RuntimeDir = Join-Path $MoquiDir "runtime"
$CompDir = Join-Path $RuntimeDir "component"

if (-not (Test-Path -Path $MoquiDir -PathType Container)) {
    Write-Host "ERROR: moqui directory does not exist." -ForegroundColor Red
    Write-Host "Run 'git submodule update --init --recursive' first."
    exit 1
}

# moqui-runtime is not a submodule of moqui-framework — clone it if missing
if (-not (Test-Path -Path $RuntimeDir -PathType Container)) {
    Write-Host "Cloning moqui-runtime into $RuntimeDir ..." -ForegroundColor Cyan
    git clone -b growerp https://github.com/growerp/moqui-runtime.git $RuntimeDir
}

# Initialise runtime's own submodules (mantle-udm, mantle-usl, moqui-fop)
$GitModulesPath = Join-Path $RuntimeDir ".gitmodules"
if (Test-Path -Path $GitModulesPath -PathType Leaf) {
    Write-Host "Initialising moqui-runtime submodules ..." -ForegroundColor Cyan
    git -C $RuntimeDir submodule update --init --recursive
}

if (-not (Test-Path -Path $CompDir -PathType Container)) {
    Write-Host "ERROR: component directory still does not exist after cloning runtime." -ForegroundColor Red
    exit 1
}

# Function to create junction points (works without Admin privileges)
function Create-Junction {
    param(
        [string]$LinkName,
        [string]$TargetRelativePath
    )
    $LinkPath = Join-Path $CompDir $LinkName
    
    # Get absolute path of target
    $TargetFullPath = Resolve-Path (Join-Path $CompDir $TargetRelativePath)
    
    if (Test-Path -Path $LinkPath) {
        Remove-Item -Path $LinkPath -Force -Recurse
    }
    
    Write-Host "Linking $LinkName -> $TargetFullPath"
    New-Item -ItemType Junction -Path $LinkPath -Target $TargetFullPath | Out-Null
}

Create-Junction -LinkName "growerp" -TargetRelativePath "..\..\..\backend"
Create-Junction -LinkName "PopRestStore" -TargetRelativePath "..\..\..\pop-rest-store"
Create-Junction -LinkName "mantle-stripe" -TargetRelativePath "..\..\..\mantle-stripe"

Write-Host "`nCustom components successfully linked into $CompDir!" -ForegroundColor Green
