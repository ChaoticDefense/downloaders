# Ship of Harkinian updater/downloader

# Define the GitHub API URL
$url = "https://api.github.com/repos/HarbourMasters/Shipwright/releases/latest"

# File used to track installed version
$version_file = ".\soh-version.txt"

# Get latest release JSON
$json = Invoke-RestMethod -Uri $url

# Find Win64 zip asset
$download_url = $json.assets |
    Where-Object { $_.name -like "*Win64.zip*" } |
    Select-Object -ExpandProperty browser_download_url

# Latest version tag
$latest_version = $json.tag_name

# Zip download path
$zipFile = ".\soh-$latest_version-win64.zip"

# Temp extraction folder
$temp_extract = ".\soh-temp-extract"

# Read installed version if present
$current_version = $null

if (Test-Path $version_file) {
    $current_version = (Get-Content $version_file -Raw).Trim()
}

# Compare versions
if ($current_version -eq $latest_version) {

    Write-Output "Ship of Harkinian is already up to date ($latest_version)."
    Pause
    exit
}

# Display version information
if ($current_version) {
    Write-Output "Installed version: $current_version"
} else {
    Write-Output "No installed version detected."
}

Write-Output "Latest version: $latest_version"

# Ask user before downloading
$proceed = Read-Host "Do you want to download and install this update? (y/n)"

if ($proceed -ne 'y') {
    Write-Output "Update cancelled."
    Pause
    exit
}

# Download release zip
Write-Output "Downloading Ship of Harkinian $latest_version..."

curl.exe -# -L -o $zipFile $download_url

# Clean temp folder if it exists
if (Test-Path $temp_extract) {
    Remove-Item $temp_extract -Recurse -Force
}

# Extract to temp folder (fast native extraction)
Write-Output "Extracting files..."

Add-Type -Assembly "System.IO.Compression.FileSystem"

[System.IO.Compression.ZipFile]::ExtractToDirectory(
    $zipFile,
    $temp_extract
)

# Copy extracted files over current directory (overwrite enabled)
Write-Output "Applying update..."

Copy-Item `
    "$temp_extract\*" `
    "." `
    -Recurse `
    -Force

# Cleanup temp folder
Remove-Item $temp_extract -Recurse -Force

Write-Output "Extraction complete."

# Delete zip after extraction
Remove-Item $zipFile -Force

# Save installed version
Set-Content -Path $version_file -Value $latest_version

Write-Output "Ship of Harkinian updated to $latest_version"

Pause