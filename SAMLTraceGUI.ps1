
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "SAMLTrace GUI"
$form.Size = New-Object System.Drawing.Size(500,300)
$form.StartPosition = "CenterScreen"

# Input Label
$inputLabel = New-Object System.Windows.Forms.Label
$inputLabel.Location = New-Object System.Drawing.Point(10,20)
$inputLabel.Size = New-Object System.Drawing.Size(100,20)
$inputLabel.Text = "Log Folder:"
$form.Controls.Add($inputLabel)

# Input TextBox
$inputBox = New-Object System.Windows.Forms.TextBox
$inputBox.Location = New-Object System.Drawing.Point(120,20)
$inputBox.Size = New-Object System.Drawing.Size(250,20)
$form.Controls.Add($inputBox)

# Browse Button
$browseBtn = New-Object System.Windows.Forms.Button
$browseBtn.Location = New-Object System.Drawing.Point(380,18)
$browseBtn.Size = New-Object System.Drawing.Size(75,23)
$browseBtn.Text = "Browse"
$browseBtn.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($folderBrowser.ShowDialog() -eq "OK") {
        $inputBox.Text = $folderBrowser.SelectedPath
    }
})
$form.Controls.Add($browseBtn)

# Output Label
$outputLabel = New-Object System.Windows.Forms.Label
$outputLabel.Location = New-Object System.Drawing.Point(10,60)
$outputLabel.Size = New-Object System.Drawing.Size(100,20)
$outputLabel.Text = "Output Excel:"
$form.Controls.Add($outputLabel)

# Output TextBox
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Location = New-Object System.Drawing.Point(120,60)
$outputBox.Size = New-Object System.Drawing.Size(250,20)
$form.Controls.Add($outputBox)

# Run Button
$runBtn = New-Object System.Windows.Forms.Button
$runBtn.Location = New-Object System.Drawing.Point(120,100)
$runBtn.Size = New-Object System.Drawing.Size(100,30)
$runBtn.Text = "Run Trace"
$runBtn.Add_Click({
    Import-Module "$PSScriptRoot\SAMLTrace\SAMLTrace.psm1" -Force
    try {
        Get-SAMLTraces -LogPath $inputBox.Text -OutputExcel $outputBox.Text
        [System.Windows.Forms.MessageBox]::Show("Trace completed.", "Success")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error: $_", "Error")
    }
})
$form.Controls.Add($runBtn)

$form.Topmost = $true
$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()
