# Define the URL for the latest release
$url = "https://api.github.com/repos/randovania/randovania/releases/latest"

# Use Invoke-RestMethod to get the JSON response for the latest release
$json = Invoke-RestMethod -Uri $url

# Find the browser_download_url for the windows zip asset
$download_url = $json.assets | Where-Object { $_.name -like "*windows.zip*" } | Select-Object -ExpandProperty browser_download_url

# Extract the version number from the download URL
$latest_version = $download_url -replace ".*randovania-(.*?)-windows.zip", "`$1"

# Define the path to the downloaded .zip file
$zipFile = ".\\randovania-$latest_version-windows.zip"

# Define the path to the extracted folder
$extracted_folder = ".\\randovania-$latest_version"

# Check if the extracted folder already exists
if (Test-Path -Path $extracted_folder) {
    Write-Output "The latest version of Randovania ($latest_version) is already downloaded and extracted."
} else {
    Write-Output "There is a new version of Randovania ($latest_version)"

    # Use curl.exe to download the file
    curl.exe -# -L -o $zipFile $download_url

    # Use .NET API to extract the .zip file
    Add-Type -Assembly "System.IO.Compression.FileSystem"
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFile, ".")

    # Delete the .zip file after extraction
    Remove-Item -Path $zipFile
    Write-Output "Randovania $latest_version downloaded and extracted"
}
    # Get all the Randovania folders
    $randovania_items = Get-ChildItem -Path "." | Where-Object { $_.Name -like "randovania-*" }

    # Loop through the folders
    foreach ($item in $randovania_items) {
        # Skip the latest version
        if ($item.Name -eq "randovania-$latest_version" -or $item.Extension -eq ".ps1" -or $item.Extension -eq ".exe" ) {
            continue
        }

        # Ask the user if they want to delete the folder
        $delete = Read-Host "Do you want to delete the old version $($item.Name)? (y/n)"
        if ($delete -eq 'y') {
            Remove-Item -Path $item.FullName -Recurse -Force
            Write-Output "Deleted the old version $($item.Name)"
        }
    }

    Pause