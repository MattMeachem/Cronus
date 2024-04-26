Add-Type -AssemblyName System.Windows.Forms

# Create a form
$form = New-Object System.Windows.Forms.Form
$form.Text = "7-Zip SFX Creator"
$form.Size = New-Object System.Drawing.Size(400,200)
$form.StartPosition = "CenterScreen"

# Create source directory label and textbox
$labelSource = New-Object System.Windows.Forms.Label
$labelSource.Location = New-Object System.Drawing.Point(10,20)
$labelSource.Size = New-Object System.Drawing.Size(100,20)
$labelSource.Text = "Source Directory:"
$form.Controls.Add($labelSource)

$textboxSource = New-Object System.Windows.Forms.TextBox
$textboxSource.Location = New-Object System.Drawing.Point(120,20)
$textboxSource.Size = New-Object System.Drawing.Size(250,20)
$form.Controls.Add($textboxSource)

# Create button to select source directory
$buttonBrowse = New-Object System.Windows.Forms.Button
$buttonBrowse.Location = New-Object System.Drawing.Point(380,20)
$buttonBrowse.Size = New-Object System.Drawing.Size(75,20)
$buttonBrowse.Text = "Browse..."
$buttonBrowse.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.SelectedPath = $textboxSource.Text
    $result = $folderBrowser.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $textboxSource.Text = $folderBrowser.SelectedPath
    }
})
$form.Controls.Add($buttonBrowse)

# Create button to start compression
$buttonStart = New-Object System.Windows.Forms.Button
$buttonStart.Location = New-Object System.Drawing.Point(150,100)
$buttonStart.Size = New-Object System.Drawing.Size(100,40)
$buttonStart.Text = "Start Compression"
$buttonStart.Add_Click({
    $sourceDir = $textboxSource.Text
    $sfxFile = "output.exe"
    $volumePrefix = "output"
    $maxVolumeSize = 10MB

    # Change to the source directory
    Set-Location $sourceDir

    # Compress files and folders into SFX file with split volumes
    & "C:\Program Files\7-Zip\7z.exe" a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on "-sfx$sfxFile" "-v$maxVolumeSize" "-v$volumePrefix" * -r
    [System.Windows.Forms.MessageBox]::Show("Compression complete!")
})
$form.Controls.Add($buttonStart)

# Show the form
$form.ShowDialog() | Out-Null
