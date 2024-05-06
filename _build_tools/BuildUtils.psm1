using namespace System.Collections.Generic

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$WSRoot = $PSScriptRoot | Join-Path -ChildPath .. | Resolve-Path
$IconDir = "$WSRoot/assets/iconoir"
$CssPath = "$IconDir/style.css"

function Get-IconMap() {
    Get-Content $PSScriptRoot/icon-list.txt
    | Where-Object { $_ -notmatch '^\s*#' }
    | ForEach-Object { $_ -match '\s*^(?<Class>.*?)?\s*=\s*(?<Icon>.*)$\s*' ?
        $Matches :
        @{ Class = $_ -replace '\s*^.*/', ''; Icon = $_ }
    }
    | Group-Object Icon -AsHashTable
}

class IconMetadata {
    $InputHash
}

function Build-Css([hashtable] $iconMap, [IconMetadata] $meta) {
    @"
/* $($meta | ConvertTo-Json -Compress) */
/* Generated code; do not edit */

$($iconMap.Values.Class | Sort-Object | ForEach-Object { ".icon-$_::before," }) .inline-icon::before {
    content: '';
    display: inline-block;
    -webkit-mask-image: var(--icon-image);
    -webkit-mask-position: center;
    -webkit-mask-size: cover;
    -webkit-mask-repeat: no-repeat;
    mask-image: var(--icon-image);
    -webkit-alt: var(--icon-title);
    alt: var(--icon-title);
    mask-position: center;
    mask-size: cover;
    mask-repeat: no-repeat;
    width: 1em;
    height: 1em;
    background: currentColor;
    vertical-align: text-bottom;
}

@supports (content: 'a' / 'b') {
    $($iconMap.Values.Class | Sort-Object | ForEach-Object { ".icon-$_::before," }).inline-icon::before {
        content: '' / var(--icon-title, '');
    }
}

$(foreach ($item in $iconMap.Values | Sort-Object) {
    $item.Class | Sort-Object | ForEach-Object { ".icon-$_::before" } | Join-String -Separator ','
    "{
    --icon-image: url('icons/$($item.Icon).svg');
}
" })
"@
}

function hashFiles {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string[]]
        $Path
    )

    begin {
        $paths = [List[string]]::new()
    }

    process {
        $paths.AddRange($Path)
    }

    end {
        $hashes = $paths
        | Get-FileHash -Algorithm MD5
        | Sort-Object Path
        | Select-Object Hash
        | ConvertTo-Csv

        $stream = [System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($hashes))
        (Get-FileHash -InputStream $stream -Algorithm MD5).Hash
    }
}

function Sync-Icons() {
    Write-Host $PSCommandPath
    New-Item $IconDir -ItemType Directory -Force -ErrorAction Ignore | Push-Location

    try {
        if (-not (Test-Path .git)) {
            git clone `
                --depth 1 --no-checkout --filter=blob:none `
                https://github.com/iconoir-icons/iconoir `
                .
        }

        $iconMap = Get-IconMap

        $missingFiles = $iconMap.Keys
        | ForEach-Object { "icons/$_.svg" }
        | Where-Object { !(Test-Path $_) }

        $meta = [IconMetadata] @{
            InputHash = hashFiles $PSScriptRoot/icon-list.txt, $PSCommandPath
        }

        if ($missingFiles) {
            git checkout main -- $missingFiles
        }

        $oldMeta = try {
            [IconMetadata] (
                Get-Content $CssPath
                | Select-Object -First 1
                | ForEach-Object { $_ -replace '^\s*/\*\s*|\s*\*/\s*$', '' }
                | ConvertFrom-Json
            )
        }
        catch { $null }

        if ($meta.InputHash -ne $oldMeta.InputHash) {
            Write-Information "Updating icon stylesheet..."
            Build-Css $iconMap $meta | Out-File -NoNewline $CssPath
        }
        else {
            Write-Information "Stylesheet already up-to-date"
        }
    }
    finally {
        Pop-Location
    }
}
