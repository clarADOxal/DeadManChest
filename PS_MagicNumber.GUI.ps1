Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- CONFIGURATION ET DOSSIERS ---
$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$inDir = Join-Path $baseDir "IN"
$outDir = Join-Path $baseDir "OUT"

if(!(Test-Path $inDir)){New-Item -ItemType Directory -Path $inDir | Out-Null}
if(!(Test-Path $outDir)){New-Item -ItemType Directory -Path $outDir | Out-Null}

$MagicDB = [ordered]@{
    "FFD8FF"           = "jpg"
    "89504E470D0A1A0A" = "png"
    "25504446"         = "pdf"
    "504B0304"         = "zip/docx/xlsx"
    "4D5A"             = "exe/dll"
    "47494638"         = "gif"
    "424D"             = "bmp"
}

# --- FONCTIONS ---

function Get-MagicNumber($filePath) {
    try {
        $stream = [System.IO.File]::OpenRead($filePath)
        $buffer = New-Object byte[] 8
        $null = $stream.Read($buffer, 0, 8)
        $stream.Close()
        return ($buffer | ForEach-Object { $_.ToString("X2") }) -join ""
    } catch { return "" }
}

function Get-MagicExtension($magic) {
    foreach($sig in $MagicDB.Keys) {
        if($magic.StartsWith($sig)) { return $MagicDB[$sig] }
    }
    return "Inconnu"
}

function Generate-HTML($data) {
    # Création d'un nom de fichier unique avec horodatage
    $fileTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $displayTimestamp = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
    $reportName = "Rapport_$fileTimestamp.html"
    $reportPath = Join-Path $outDir $reportName
    
    $css = @"
    <style>
        body { font-family: 'Segoe UI', sans-serif; margin: 30px; background-color: #f8f9fa; color: #333; }
        h1 { color: #2c3e50; margin-bottom: 5px; }
        .timestamp { color: #95a5a6; margin-bottom: 25px; font-size: 0.9em; }
        table { border-collapse: collapse; width: 100%; background: white; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        th { background-color: #34495e; color: white; padding: 15px; text-align: left; text-transform: uppercase; font-size: 0.85em; }
        td { padding: 12px 15px; border-bottom: 1px solid #eee; font-size: 0.9em; vertical-align: middle; }
        tr:last-child td { border-bottom: none; }
        tr:hover { background-color: #f1f4f6; }
        .anomaly { background-color: #fff5f5 !important; color: #e74c3c; font-weight: bold; }
        .status-icon { font-size: 1.2em; margin-right: 8px; }
        .vt-btn { display: inline-block; padding: 5px 10px; background: #3498db; color: white; text-decoration: none; border-radius: 4px; font-size: 0.8em; }
        .vt-btn:hover { background: #2980b9; }
        code { background: #eee; padding: 2px 5px; border-radius: 3px; font-family: Consolas, monospace; }
    </style>
"@

    $tableRows = foreach ($item in $data) {
        $rowClass = if($item.Anomaly) { 'class="anomaly"' } else { '' }
        $statusIcon = if($item.Anomaly) { '<span class="status-icon">??</span>' } else { '<span class="status-icon">?</span>' }
        $vtUrl = "https://www.virustotal.com/gui/file/$($item.SHA256)"
        
        "<tr $rowClass>
            <td>$statusIcon $($item.Name)</td>
            <td>.$($item.Extension)</td>
            <td>$($item.ExpectedExtension)</td>
            <td><code>$($item.Magic)</code></td>
            <td>$($item.MD5)</td>
            <td><a class='vt-btn' href='$vtUrl' target='_blank'>VirusTotal</a></td>
        </tr>"
    }

    $htmlContent = @"
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <title>Analyse du $displayTimestamp</title>
        $css
    </head>
    <body>
        <h1>Analyse de Sécurité des Fichiers</h1>
        <div class="timestamp">Rapport généré le $displayTimestamp</div>
        <table>
            <thead>
                <tr>
                    <th>Fichier</th>
                    <th>Ext. Réelle</th>
                    <th>Format Détecté</th>
                    <th>Signature Hex</th>
                    <th>Hash MD5</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
                $($tableRows -join "`n")
            </tbody>
        </table>
    </body>
    </html>
"@
    $htmlContent | Out-File $reportPath -Encoding utf8
    return $reportPath
}

function Analyze-Files($path) {
    $files = Get-ChildItem $path -File
    $results = New-Object System.Collections.Generic.List[PSCustomObject]

    foreach ($file in $files) {
        $magic = Get-MagicNumber $file.FullName
        $ext = $file.Extension.Replace(".","").ToLower()
        $expected = Get-MagicExtension $magic
        
        $anomaly = $false
        if($expected -ne "Inconnu" -and -not $expected.Contains($ext)) {
            $anomaly = $true
        }

        $results.Add([PSCustomObject]@{
            Name              = $file.Name
            Extension         = $ext
            ExpectedExtension = $expected
            Magic             = $magic
            MD5               = (Get-FileHash $file.FullName -Algorithm MD5).Hash
            SHA256            = (Get-FileHash $file.FullName -Algorithm SHA256).Hash
            Anomaly           = $anomaly
        })
    }
    return $results
}

# --- GUI ---
$form = New-Object Windows.Forms.Form
$form.Text = "File Analyzer Pro"
$form.Size = New-Object Drawing.Size(600,320)
$form.StartPosition = "CenterScreen"
$form.BackColor = "White"

$label = New-Object Windows.Forms.Label
$label.Text = "Sélectionnez le dossier à scanner :"
$label.Location = New-Object Drawing.Point(30,25)
$label.AutoSize = $true
$label.Font = New-Object Drawing.Font("Segoe UI", 10)

$textbox = New-Object Windows.Forms.TextBox
$textbox.Size = New-Object Drawing.Size(400,25)
$textbox.Location = New-Object Drawing.Point(30,55)
$textbox.Text = $inDir

$browse = New-Object Windows.Forms.Button
$browse.Text = "..."
$browse.Location = New-Object Drawing.Point(440,53)
$browse.Size = New-Object Drawing.Size(40,26)

$analyze = New-Object Windows.Forms.Button
$analyze.Text = "LANCER L'ANALYSE"
$analyze.Size = New-Object Drawing.Size(200,45)
$analyze.Location = New-Object Drawing.Point(180,110)
$analyze.FlatStyle = "Flat"
$analyze.BackColor = "#2ecc71"
$analyze.ForeColor = "White"
$analyze.Font = New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)

$linkLabel = New-Object Windows.Forms.LinkLabel
$linkLabel.Location = New-Object Drawing.Point(30,180)
$linkLabel.Size = New-Object Drawing.Size(520,60)
$linkLabel.Font = New-Object Drawing.Font("Segoe UI", 9)
$linkLabel.Visible = $false

$browse.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if($dialog.ShowDialog() -eq "OK"){ $textbox.Text = $dialog.SelectedPath }
})

$analyze.Add_Click({
    if(-not (Test-Path $textbox.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Le dossier spécifié n'existe pas.")
        return
    }

    $data = Analyze-Files $textbox.Text
    $report = Generate-HTML $data
    
    $linkLabel.Text = "Analyse terminée avec succès !`nLe rapport a été sauvegardé ici :`n$report"
    $linkLabel.Tag = $report
    $linkLabel.Visible = $true
})

$linkLabel.Add_LinkClicked({
    Start-Process $this.Tag
})

$form.Controls.AddRange(@($label,$textbox,$browse,$analyze,$linkLabel))
$form.ShowDialog()