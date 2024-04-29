Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Folder Archiver"
$form.Size = New-Object System.Drawing.Size(550, 250)
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

$labelFolder = New-Object System.Windows.Forms.Label
$labelFolder.Text = "Folder Path:"
$labelFolder.AutoSize = $true
$labelFolder.Location = New-Object System.Drawing.Point(10, 20)

$textboxFolder = New-Object System.Windows.Forms.TextBox
$textboxFolder.Size = New-Object System.Drawing.Size(300, 20)
$textboxFolder.Location = New-Object System.Drawing.Point(100, 20)

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
$labelZipName.Text = "Zip File Name:"
$labelZipName.AutoSize = $true
$labelZipName.Location = New-Object System.Drawing.Point(10, 50)

$textboxZipName = New-Object System.Windows.Forms.TextBox
$textboxZipName.Size = New-Object System.Drawing.Size(300, 20)
$textboxZipName.Location = New-Object System.Drawing.Point(100, 50)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
$progressBar.Value = 0
$progressBar.Size = New-Object System.Drawing.Size(440, 20)
$progressBar.Location = New-Object System.Drawing.Point(10, 110)

$buttonCreate = New-Object System.Windows.Forms.Button
$buttonCreate.Text = "Create Archive"
$buttonCreate.Size = New-Object System.Drawing.Size(150, 30)
$buttonCreate.Location = New-Object System.Drawing.Point(10, 150)
$buttonCreate.Add_Click({
    $sourcePath = $textboxFolder.Text
    $zipPath = $textboxZipName.Text

    if (-not (Test-Path -Path $sourcePath -PathType Container)) {
        [System.Windows.Forms.MessageBox]::Show("Folder not found.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    if (-not [System.IO.Path]::HasExtension($zipPath)) {
        $zipPath += ".zip"
    }

    $progressBar.Value = 0
    $buttonCreate.Enabled = $false # Disable the button during archiving

    Create-Zip -sourcePath $sourcePath -zipPath $zipPath -progressBar $progressBar

    $chunkSize = 10MB
    Split-Zip -zipPath $zipPath -chunkSize $chunkSize

    [System.Windows.Forms.MessageBox]::Show("Archive created successfully.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

    $buttonCreate.Enabled = $true # Re-enable the button after archiving
})

$form.Controls.Add($labelFolder)
$form.Controls.Add($textboxFolder)
$form.Controls.Add($buttonBrowse)
$form.Controls.Add($labelZipName)
$form.Controls.Add($textboxZipName)
$form.Controls.Add($progressBar)
$form.Controls.Add($buttonCreate)

function Create-Zip {
    param (
        [string]$sourcePath,
        [string]$zipPath,
        [System.Windows.Forms.ProgressBar]$progressBar
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $files = Get-ChildItem -Path $sourcePath -Recurse -File
    $totalFiles = $files.Count
    $processedFiles = 0

    $archive = [System.IO.Compression.ZipFile]::Open($zipPath, 'Create')
    
    foreach ($file in $files) {
        $progress = [int](($processedFiles / $totalFiles) * 100)
        $progressBar.Value = $progress

        $relativePath = $file.FullName.Substring($sourcePath.Length + 1)
        $entry = $archive.CreateEntry($relativePath)

        $stream = $entry.Open()
        $fileStream = [System.IO.File]::OpenRead($file.FullName)
        $fileStream.CopyTo($stream)
        $stream.Close()
        $fileStream.Close()

        $processedFiles++
    }

    $archive.Dispose()
}



function Split-Zip {
    param (
        [string]$zipPath,
        [int]$chunkSize
    )

    $buffer = New-Object byte[] $chunkSize

    $fileIndex = 1
    $fileStream = New-Object System.IO.FileStream($zipPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
    
    try {
        while ($fileStream.Position -lt $fileStream.Length) {
            $chunkPath = "{0}.{1:000}" -f $zipPath, $fileIndex
            $fileIndex++
            
            $chunkStream = New-Object System.IO.FileStream($chunkPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
            try {
                $bytesRead = $fileStream.Read($buffer, 0, $buffer.Length)
                $chunkStream.Write($buffer, 0, $bytesRead)
            }
            finally {
                $chunkStream.Close()
            }
        }
    }
    finally {
        $fileStream.Close()
    }
}

$form.ShowDialog() | Out-Null
