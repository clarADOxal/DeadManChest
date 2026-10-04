#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path
)

Clear-Host
write-host -fore red "██████╗░███████╗░█████╗░██████╗░  ███╗░░░███╗░█████╗░███╗░░██╗  ░█████╗░██╗░░██╗███████╗░██████╗████████╗"
write-host -fore red "██╔══██╗██╔════╝██╔══██╗██╔══██╗  ████╗░████║██╔══██╗████╗░██║  ██╔══██╗██║░░██║██╔════╝██╔════╝╚══██╔══╝"
write-host -fore red "██║░░██║█████╗░░███████║██║░░██║  ██╔████╔██║███████║██╔██╗██║  ██║░░╚═╝███████║█████╗░░╚█████╗░░░░██║░░░"
write-host -fore red "██║░░██║██╔══╝░░██╔══██║██║░░██║  ██║╚██╔╝██║██╔══██║██║╚████║  ██║░░██╗██╔══██║██╔══╝░░░╚═══██╗░░░██║░░░"
write-host -fore red "██████╔╝███████╗██║░░██║██████╔╝  ██║░╚═╝░██║██║░░██║██║░╚███║  ╚█████╔╝██║░░██║███████╗██████╔╝░░░██║░░░"
write-host -fore red "╚═════╝░╚══════╝╚═╝░░╚═╝╚═════╝░  ╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝  ░╚════╝░╚═╝░░╚═╝╚══════╝╚═════╝░░░░╚═╝░░░"
write-host "ForensicReport : Report timerange of each EVTX file"
write-host "Version : 0.50"
$Creation_Date = "11:34 04/10/2026"
Write-Host "Usage :" -ForegroundColor Yellow
Write-Host " .\PS_evtx_time_range.ps1 -Path <folder>"
Write-Host " .\PS_evtx_time_range.ps1 -Path <folder> -Verbose"
Write-Host ""




#/////////////////////////////////////////////////////////////////////////////////////////////

$Todo+="export en Xlsx"
$Todo+="export en HTML"
$Todo+="présentation en OGV"
$Todo+="Lecture optimisée par blocs"
$Todo+="Lecture multi-thread"
$Todo+="Date au format yyyy-mm-dd meme en csv"
$Todo+="OK - Retrait des guillemets pour etre utilisé avec TimeLineExplorer"
$Todo+="Utilisable avec EVTX et CSV"
$Todo+="Afficher en console la toute premire date et la dernière"





# --- CONFIGURATION ------------------------------------------------
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
#get-date -displayHint Time

# Si l'utilisateur saisit juste "c:" ou "d:", on ajoute le "\" pour viser la racine
if ($Path -match '^[a-zA-Z]:$') {
    $Path = "$Path\"
}

$FullPath = (Resolve-Path $Path).Path


# Check if path exist
if (-Not (Test-Path $fullPath)) {
    Write-Host "File '$fullPath' doesnt exist." -ForegroundColor Red
	sleep 5
    exit
}

# Check if evtx are into fullPath
 if (((gci $fullpath *.evtx).count) -lt 1 )
	{
	$FullPath = Join-Path $FullPath "Windows\System32\winevt\Logs"
	#write-host -fore blue $fullPath
	#write-host -fore blue (gci $fullpath *.evtx).count
	
	}
write-host "-------------------------"	
Write-host -Fore Green "Input : $fullPath"
write-host "-------------------------"
$inputfolder = $FullPath
#$inputFolder = ".\uploads\auto\C%3A\Windows\System32\winevt\Logs"

$OutputDir = ".\OUT"
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}
$outputFolderFull = (Resolve-Path $outputDir).Path
$outputCsv   = Join-Path -Path $outputFolderFull -ChildPath ("EVTX_Time_Range_" + $timestamp + ".csv")
$outputCsv4TimeLineExpl   = Join-Path -Path $outputFolderFull -ChildPath ("EVTX_Time_Range_" + $timestamp + "_ForTimeLineExplorer.csv")
$outputImage = Join-Path -Path $outputFolderFull -ChildPath ("EVTX_Time_Range_" + $timestamp + ".png")

$totalevtx=(get-childitem $inputFolder *.evtx).Count
$emptycount = 0


Add-Type -AssemblyName System.Drawing

# --- RÉCUPÉRATION DES DONNÉES -------------------------------------
$results = @()
foreach ($file in Get-ChildItem -Path $inputFolder -Filter *.evtx) {
    try {
        $first = Get-WinEvent -Path $file.FullName -MaxEvents 1 -Oldest -ErrorAction SilentlyContinue
        $last  = Get-WinEvent -Path $file.FullName -MaxEvents 1 -ErrorAction SilentlyContinue

	$reader = New-Object System.Diagnostics.Eventing.Reader.EventLogReader($file.FullName, [System.Diagnostics.Eventing.Reader.PathType]::FilePath)
	$count = 0
	while ($reader.ReadEvent()) { $count++ }
	$eventCount = $count




	$fileSizeKB = [math]::Round(($file.Length / 1KB), 2)
	$daysDiff   = [math]::Round((($last.TimeCreated - $first.TimeCreated).TotalDays), 2)


        if (-not $first -or -not $last) { Write-verbose "$($file.Name) ne contient aucun événement."; $emptycount++;continue }

        Write-Verbose "File : $($file.Name)"
#	$results += [PSCustomObject]@{ NomFichier = $file.Name; PremierEvenement = $first.TimeCreated; DernierEvenement = $last.TimeCreated }

	$results += [PSCustomObject]@{
		NomFichier        = $file.Name
		PremierEvenement  = $first.TimeCreated
		DernierEvenement  = $last.TimeCreated
		NombreEvenements  = $eventCount      # <<< ajouté
		PoidsFichierKo    = $fileSizeKB      # <<< ajouté
		#DureeJours        = $daysDiff       # <<< ajouté
		DureeJours = [int][math]::Floor(($last.TimeCreated - $first.TimeCreated).TotalDays)

}

    } catch { Write-verbose "Erreur avec $($file.FullName) : $_" }
}

# --- STATISTIQUES GLOBALES (placer ici) --------------------------
if ($results.Count -gt 0) {
    $globalMin  = ($results | Measure-Object -Property PremierEvenement -Minimum).Minimum
    $globalMax  = ($results | Measure-Object -Property DernierEvenement -Maximum).Maximum
    $globalDays = [math]::Floor(($globalMax - $globalMin).TotalDays)

    $totalEvents  = ($results | Measure-Object -Property NombreEvenements -Sum).Sum
    $totalSizeMB  = [math]::Round((($results | Measure-Object -Property PoidsFichierKo -Sum).Sum / 1024),2)

}

# --- EXPORT CSV ---------------------------------------------------
if ($results.Count -eq 0) { 
    Write-Warning "Aucun fichier .evtx valide trouvé. Aucun CSV ne sera généré." 
}
else {

$csvData = $results |
Select-Object `
NomFichier,
@{Name="PremierEvenement";Expression={$_.PremierEvenement.ToString("yyyy-MM-dd HH:mm:ss")}},
@{Name="DernierEvenement";Expression={$_.DernierEvenement.ToString("yyyy-MM-dd HH:mm:ss")}},
NombreEvenements,
PoidsFichierKo,
DureeJours

# CSV normal
$csvData | Export-Csv -Path $outputCsv -NoTypeInformation -Encoding UTF8

# CSV pour TimelineExplorer
$csvData | Export-Csv -Path $outputCsv4TimeLineExpl -NoTypeInformation -Encoding UTF8
(Get-Content $outputCsv4TimeLineExpl) -replace '"' , '' | Set-Content $outputCsv4TimeLineExpl

Write-Host -fore green "Output : $outputCsv4TimeLineExpl"

write-verbose "============================================================"
$validcount = $totalevtx - $emptycount

write-verbose ("EVTX total:{0} | analysés:{1} | vides:{2} | events:{3} | période:{4} jours | volume:{5} MB" -f `
        $totalevtx, $results.Count, $emptycount, $totalEvents, $globalDays, $totalSizeMB)


write-verbose "Première trace globale : $globalMin"
write-verbose "Dernière trace globale : $globalMax"


}

# --- GÉNÉRATION IMAGE ---------------------------------------------
if ($results.Count -eq 0) {
    Write-Warning "Aucun événement valide trouvé. L'image ne sera pas générée."
} else {
    $imgWidth  = 1200
    $imgHeight = 50 + ($results.Count * 40)

    # Supprime l'image existante si nécessaire
    if (Test-Path $outputImage) {
        Remove-Item $outputImage -Force
    }

    # Création du bitmap et des objets graphiques
    $bmp  = New-Object System.Drawing.Bitmap $imgWidth, $imgHeight
    $gfx  = [System.Drawing.Graphics]::FromImage($bmp)
    $gfx.SmoothingMode = "AntiAlias"
    $font = New-Object System.Drawing.Font "Arial", 10
    $brush = [System.Drawing.Brushes]::Black
    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::SkyBlue), 10

    # Fond blanc
    $gfx.Clear([System.Drawing.Color]::White)

    # Dates min/max
    $minDate = ($results | Measure-Object -Property PremierEvenement -Minimum).Minimum
    $maxDate = ($results | Measure-Object -Property DernierEvenement -Maximum).Maximum
    $timespan = ($maxDate - $minDate).TotalSeconds

    # Fonction conversion date ? X
    function Get-X([datetime]$date) {
        $offset = ($date - $minDate).TotalSeconds
        return [int](($offset / $timespan) * ($imgWidth - 200)) + 100
    }

    # Axe horizontal
    $gfx.DrawLine([System.Drawing.Pens]::Gray, 100, 30, $imgWidth - 100, 30)
    $gfx.DrawString($minDate.ToString("yyyy-MM-dd HH:mm"), $font, $brush, 100, 10)
    $gfx.DrawString($maxDate.ToString("yyyy-MM-dd HH:mm"), $font, $brush, $imgWidth - 200, 10)

    # Frise pour chaque fichier
    $i = 0
    foreach ($item in $results) {
        $y = 60 + ($i * 40)
        $xStart = Get-X $item.PremierEvenement
        $xEnd   = Get-X $item.DernierEvenement

        # Ligne représentant la période du fichier
        $gfx.DrawLine($pen, $xStart, $y, $xEnd, $y)

        # Nom du fichier à gauche
        $gfx.DrawString($item.NomFichier, $font, $brush, 10, $y - 7)

        $i++
    }

    # Sauvegarde image via FileStream pour éviter les erreurs GDI+
    try {
        $fs = [System.IO.File]::Open($outputImage, [System.IO.FileMode]::Create)
        $bmp.Save($fs, [System.Drawing.Imaging.ImageFormat]::Png)
        $fs.Close()
	write-verbose "============================================================"
Write-Host -fore green "Output : $outputImage"
    } catch {
        Write-Warning "Impossible de sauvegarder l'image : $_"
    }

    # Libération des ressources graphiques
    $gfx.Dispose()
    $bmp.Dispose()
}