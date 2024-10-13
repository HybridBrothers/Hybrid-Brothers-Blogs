
######################################################
### Made by Cedric Braekevelt (hybridbrothers.com) ###
######################################################

# Define the folder path
$folderPath = "C:\Scripting\HB-Hybrid-Brothers-Site\Backups\MySQL-2023-10-06"

# Define the values to be replaced and their replacements
$replaceValues = @{
    "utf8mb4" = "utf8"
    "utf8_0900_ai_ci" = "utf8_general_ci"
}

# Get all files within the folder
$files = Get-ChildItem -Path $folderPath -File -Recurse

# Iterate through each file and perform the replacements
foreach ($file in $files) {
    # Read the content of the file
    $content = Get-Content -Path $file.FullName -Raw

    # Replace the values
    foreach ($replaceValue in $replaceValues.GetEnumerator()) {
        $content = $content -replace [regex]::Escape($replaceValue.Key), $replaceValue.Value
    }

    # Write the modified content back to the file
    Set-Content -Path $file.FullName -Value $content
}

# Output a message when the replacements are complete
Write-Host "Value replacements complete."