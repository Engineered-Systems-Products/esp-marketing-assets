<#
.SYNOPSIS
    Publish a marketing image to the public host and print its URL.

.DESCRIPTION
    Copies an image into images/, normalises the filename for use in a URL, checks it
    against Instagram's publishing limits, commits, pushes, and prints the public URL to
    paste into a post's Public Image URL field.

    Filenames are normalised on purpose: spaces and punctuation in a URL are a common
    cause of Meta failing to fetch an image.

.EXAMPLE
    .\add-image.ps1 -Path "C:\Users\awilliams\Pictures\blower install.jpg"

.EXAMPLE
    .\add-image.ps1 -Path .\backdrop.jpg -Name "tradeshow-backdrop-2026"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    # Override the published filename (extension is kept from the source file).
    [string]$Name,

    # Stage and commit locally but do not push.
    [switch]$NoPush
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$imagesDir = Join-Path $repoRoot "images"
$baseUrl = "https://engineered-systems-products.github.io/esp-marketing-assets/images"

if (-not (Test-Path -LiteralPath $Path)) {
    throw "No such file: $Path"
}
$source = Get-Item -LiteralPath $Path
if ($source.PSIsContainer) {
    throw "$Path is a folder. Pass a single image file."
}
if (-not (Test-Path -LiteralPath $imagesDir)) {
    New-Item -ItemType Directory -Path $imagesDir | Out-Null
}

# ---- filename ---------------------------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($Name)) { $Name = $source.BaseName }
$extension = $source.Extension.ToLowerInvariant()
$slug = ($Name.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
if ([string]::IsNullOrWhiteSpace($slug)) {
    throw "Could not build a usable filename from '$Name' - pass -Name explicitly."
}
$fileName = "$slug$extension"
$destination = Join-Path $imagesDir $fileName

if (Test-Path -LiteralPath $destination) {
    Write-Warning "images/$fileName already exists and will be overwritten. Anyone already"
    Write-Warning "linking that URL will silently get the new image instead."
}

# ---- Instagram limits -------------------------------------------------------------------
# Facebook has none of these constraints; it accepts the file upload directly.
$instagramReady = $true

if ($extension -ne ".jpg" -and $extension -ne ".jpeg") {
    Write-Warning "Instagram only publishes JPEG. '$extension' will work for Facebook but not Instagram."
    $instagramReady = $false
}

if ($source.Length -gt 8MB) {
    $sizeMb = [math]::Round($source.Length / 1MB, 1)
    Write-Warning "$sizeMb MB exceeds Instagram's 8 MB limit."
    $instagramReady = $false
}

try {
    Add-Type -AssemblyName System.Drawing
    $image = [System.Drawing.Image]::FromFile($source.FullName)
    $width = $image.Width
    $height = $image.Height
    $image.Dispose()

    $ratio = [math]::Round($width / $height, 3)
    Write-Host "Dimensions : ${width}x${height} (aspect $ratio)"

    if ($ratio -lt 0.8 -or $ratio -gt 1.91) {
        Write-Warning "Aspect $ratio is outside Instagram's accepted 4:5 (0.8) to 1.91:1 range."
        $instagramReady = $false
    }
}
catch {
    Write-Warning "Could not read image dimensions: $($_.Exception.Message)"
}

# ---- publish ----------------------------------------------------------------------------
Copy-Item -LiteralPath $source.FullName -Destination $destination -Force

Push-Location $repoRoot
try {
    git add -- ".gitattributes" "images/$fileName"
    if ($LASTEXITCODE -ne 0) { throw "git add failed" }

    git diff --cached --quiet
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "No change - images/$fileName is already published and identical."
    }
    else {
        git commit -q -m "Add marketing image $fileName"
        if ($LASTEXITCODE -ne 0) { throw "git commit failed" }

        if ($NoPush) {
            Write-Host ""
            Write-Host "Committed locally. Not pushed (-NoPush), so the URL is not live yet."
        }
        else {
            git push -q
            if ($LASTEXITCODE -ne 0) { throw "git push failed" }
            Write-Host ""
            Write-Host "Pushed. GitHub Pages usually serves it within a minute."
        }
    }
}
finally {
    Pop-Location
}

$publicUrl = "$baseUrl/$fileName"

Write-Host ""
Write-Host "Public URL : $publicUrl"
if ($instagramReady) {
    Write-Host "Instagram  : ready"
}
else {
    Write-Host "Instagram  : NOT ready - see warnings above. Facebook posting is unaffected."
}
Write-Host ""
Write-Host "Paste the URL into the post's Public Image URL field, or leave it blank if the"
Write-Host "filename matches the attached file and Public Image Base URL is configured."
