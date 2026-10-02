# fetch_bible_assets.ps1
# Fetches pre-structured 66-book Bible JSON datasets (English KJV, Hindi, Telugu)
# into assets/bible/ and validates each payload.
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$dest = Join-Path $root 'assets\bible'
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Write-Host "Destination: $dest"

$files = @(
    @{ Name = 'en_kjv.json';  Url = 'https://raw.githubusercontent.com/thiagobodruk/bible/master/json/en_kjv.json' },
    @{ Name = 'hi_bible.json'; Url = 'https://raw.githubusercontent.com/godlytalias/Bible-Database/master/Hindi/bible.json' },
    @{ Name = 'te_bible.json'; Url = 'https://raw.githubusercontent.com/godlytalias/Bible-Database/master/Telugu/bible.json' }
)

foreach ($f in $files) {
    $out = Join-Path $dest $f.Name
    Write-Host "Fetching $($f.Name) ..."
    curl.exe -sSL -o $out $f.Url
    if ($LASTEXITCODE -ne 0) { throw "curl failed for $($f.Url)" }
    $size = (Get-Item $out).Length
    Write-Host ("  saved {0} ({1:N0} bytes)" -f $f.Name, $size)
}

Write-Host 'Validating JSON payloads ...'
foreach ($f in $files) {
    $out = Join-Path $dest $f.Name
    $text = [System.IO.File]::ReadAllText($out, [System.Text.Encoding]::UTF8)
    $json = $text | ConvertFrom-Json
    if ($json -is [System.Array]) {
        $count = $json.Count
        $shape = 'array[abbrev/chapters]'
    } elseif ($null -ne $json.Book) {
        $count = $json.Book.Count
        $shape = 'object{Book:[]}'
    } else {
        $count = 0
        $shape = 'unknown'
    }
    Write-Host ("  {0}: parsed OK, books = {1}, shape = {2}" -f $f.Name, $count, $shape)
}

Write-Host 'Done.'