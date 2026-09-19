# Define the URL for the latest release
$url = "https://api.github.com/repos/TwilitRealm/dusklight/releases/latest"

# Use Invoke-RestMethod to get the JSON response for the latest release
$json = Invoke-RestMethod -Uri $url

# Find the browser_download_url for the windows zip asset
$download_url = $json.assets |
    Where-Object { $_.name -like "*win32-x86_64.zip*" } |
    Select-Object -ExpandProperty browser_download_url

# Extract the version number from the download URL
$latest_version = $download_url -replace ".*Dusklight-v(.*?)-win32-x86_64.zip", "`$1"

# Define paths
$zipFile = ".\Dusklight-$latest_version-windows.zip"
$extracted_folder = ".\Dusklight-$latest_version"

# Get all Dusklight folders
$Dusklight_items = Get-ChildItem -Directory -Path "." |
    Where-Object { $_.Name -like "Dusklight-*" }

# Check if the latest version already exists
if (Test-Path $extracted_folder) {

    Write-Output "The latest version of Dusklight ($latest_version) is already downloaded and extracted."

} else {

    Write-Output "There is a new version of Dusklight ($latest_version)"

    # Download the zip
    curl.exe -# -L -o $zipFile $download_url

    # Create destination folder
    New-Item -ItemType Directory -Path $extracted_folder | Out-Null

    # Extract into that folder
    Add-Type -Assembly "System.IO.Compression.FileSystem"
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFile, $extracted_folder)

    # Delete the zip
    Remove-Item $zipFile

    Write-Output "Dusklight $latest_version downloaded and extracted"
}

# Refresh Dusklight folders
$Dusklight_items = Get-ChildItem -Directory -Path "." |
    Where-Object { $_.Name -like "Dusklight-*" }

# Ask to delete old versions
foreach ($item in $Dusklight_items) {

    if ($item.Name -eq "Dusklight-$latest_version") {
        continue
    }

    $delete = Read-Host "Do you want to delete the old version $($item.Name)? (y/n)"

    if ($delete -eq "y") {
        Remove-Item $item.FullName -Recurse -Force
        Write-Output "Deleted $($item.Name)"
    }
}

Pause