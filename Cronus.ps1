Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Folder Archiver"
$form.Size = New-Object System.Drawing.Size(550, 300)
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

$labelFolder = New-Object System.Windows.Forms.Label
$labelFolder.Text = "Folder Path:"
$labelFolder.AutoSize = $true
$labelFolder.Location = New-Object System.Drawing.Point(10, 20)

$textboxFolder = New-Object System.Windows.Forms.TextBox
$textboxFolder.Size = New-Object System.Drawing.Size(300, 20)
$textboxFolder.Location = New-Object System.Drawing.Point(120, 20)

$buttonBrowse = New-Object System.Windows.Forms.Button
$buttonBrowse.Text = "Browse..."
$buttonBrowse.AutoSize = $true
$buttonBrowseX = $textboxFolder.Right + 10
$buttonBrowseY = $textboxFolder.Top - 1
$buttonBrowse.Location = New-Object System.Drawing.Point($buttonBrowseX, $buttonBrowseY)
$buttonBrowse.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.RootFolder = [System.Environment+SpecialFolder]::MyComputer
    $folderBrowser.SelectedPath = $textboxFolder.Text
    $result = $folderBrowser.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $textboxFolder.Text = $folderBrowser.SelectedPath
    }
})

$labelZipName = New-Object System.Windows.Forms.Label
$labelZipName.Text = "Output File Name:"
$labelZipName.AutoSize = $true
$labelZipName.Location = New-Object System.Drawing.Point(10, 50)

$textboxZipName = New-Object System.Windows.Forms.TextBox
$textboxZipName.Size = New-Object System.Drawing.Size(300, 20)
$textboxZipName.Location = New-Object System.Drawing.Point(120, 50)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
$progressBar.Value = 0
$progressBar.Size = New-Object System.Drawing.Size(440, 20)
$progressBar.Location = New-Object System.Drawing.Point(10, 110)

$labelChunkSize = New-Object System.Windows.Forms.Label
$labelChunkSize.Text = "Chunk Size (MB):"
$labelChunkSize.AutoSize = $true
$labelChunkSize.Location = New-Object System.Drawing.Point(10, 80)

$dropdownChunkSize = New-Object System.Windows.Forms.ComboBox
$dropdownChunkSize.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$dropdownChunkSize.Size = New-Object System.Drawing.Size(150, 20)
$dropdownChunkSize.Location = New-Object System.Drawing.Point(120, 80)
$dropdownChunkSize.Items.AddRange(@("20M", "100M", "1000M", "650M-CD", "700M-CD", "4092M-FAT", "4480M-DVD", "8128M-DVD DL", "23040M-BD"))
$dropdownChunkSize.SelectedIndex = 0

$buttonCreate = New-Object System.Windows.Forms.Button
$buttonCreate.Text = "Create Archive"
$buttonCreate.Size = New-Object System.Drawing.Size(150, 30)
$buttonCreate.Location = New-Object System.Drawing.Point(10, 150)
$buttonCreate.Add_Click({
    Write-Host "zipPath:"
    Write-Host "zipPath after assignment: $zipPath"

    $sourcePath = $textboxFolder.Text
    $zipPath = $textboxZipName.Text
    Write-Host "zipPath after assignment: $zipPath"

    # Add checks to ensure $zipPath is not empty or null
    if (-not $zipPath) {
        [System.Windows.Forms.MessageBox]::Show("Please enter an output file name.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    if (-not [System.IO.Path]::HasExtension($zipPath)) {
        $zipPath += ".exe" # Change extension to .exe for SFX
    }

    Write-Host "zipPath after extension check: $zipPath"

    # Set the output folder path
    $outputFolder = Join-Path (Get-Location) "Cronus Output"

    # Add debug output to check the value of $outputFolder
    Write-Host "Output folder: $outputFolder"

    # Check if the output folder exists, if not, create it
    if (-not (Test-Path -Path $outputFolder)) {
        try {
            New-Item -Path $outputFolder -ItemType Directory | Out-Null
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Error creating output folder.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }
    }

    $progressBar.Value = 0
    $buttonCreate.Enabled = $false

    # Check if 7zip command is available
    if (-not (Get-Command "7z.exe" -ErrorAction SilentlyContinue)) {
        # 7zip is not in the PATH, check default location
        $sevenZipPath = "C:\Program Files\7-Zip\7z.exe"
        if (Test-Path $sevenZipPath) {
            # 7zip found in default location, add to PATH
            $env:Path += ";C:\Program Files\7-Zip"
        } else {
            # 7zip not found, show error message
            [System.Windows.Forms.MessageBox]::Show("7-Zip not found. Please install 7-Zip or add it to the PATH.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }
    }

    $chunkSize = $dropdownChunkSize.SelectedItem
    Create-Zip -sourcePath $sourcePath -zipPath $zipPath -progressBar $progressBar -chunkSize $chunkSize -outputFolder $outputFolder

    [System.Windows.Forms.MessageBox]::Show("Archive created successfully.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

    $buttonCreate.Enabled = $true
})

$form.Controls.Add($labelFolder)
$form.Controls.Add($textboxFolder)
$form.Controls.Add($buttonBrowse)
$form.Controls.Add($labelZipName)
$form.Controls.Add($textboxZipName)
$form.Controls.Add($progressBar)
$form.Controls.Add($buttonCreate)
$form.Controls.Add($labelChunkSize)
$form.Controls.Add($dropdownChunkSize)

function Create-Zip {
    param (
        [string]$sourcePath,
        [string]$zipPath,
        [System.Windows.Forms.ProgressBar]$progressBar,
        [string]$chunkSize,
        [string]$outputFolder
    )

    $command = "a -sfx -v$chunkSize `"$zipPath`" `"$sourcePath\*`""
    Write-Host "7zip command: $command"

    $process = Start-Process "7z.exe" -ArgumentList $command -NoNewWindow -PassThru -Wait -WorkingDirectory $outputFolder

    if ($process.ExitCode -ne 0) {
        # 7zip command failed, show error message
        [System.Windows.Forms.MessageBox]::Show("Error: $($process.StandardError)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    $progressBar.Value = 100
}

$form.ShowDialog()
