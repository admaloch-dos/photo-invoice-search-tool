$remaining_ids = @()

# Loop through each file ID
foreach ($currID in $env:located_file_ids.Split(' ')) {
    # Construct the regex pattern
    $regexPattern = "(?!.*\.md5)(?<![a-zA-Z])(?!\d)$currID(?!\d)"

    # Get files matching the regex in $env:PHOTO_MASTERS_DIR
    $matchingFiles = Get-ChildItem -Path $env:PHOTO_MASTERS_DIR | Where-Object { $_.Name -match $regexPattern }

    if ($matchingFiles.Count -gt 0) {
        # Copy matching files to $env:COPIED_IMAGES_DIR
        $matchingFiles | Copy-Item -Destination $env:COPIED_IMAGES_DIR

        # Log that files were located
        Write-Host "Files for ID $currID located and copied."
    }
    else {
        # Log that ID was not found
        Write-Host "ID $currID not found in any files."
        $remaining_ids += $currID
    }
}

# Output the remaining IDs
Write-Host "Remaining IDs: $($remaining_ids -join ' ')"
