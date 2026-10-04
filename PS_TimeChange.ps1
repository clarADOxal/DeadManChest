#Requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path
)

Clear-Host
write-host -fore red "██████╗░███████╗░█████╗░██████╗░    ███╗░░░███╗░█████╗░███╗░░██╗    ░█████╗░██╗░░██╗███████╗░██████╗████████╗"
write-host -fore red "██╔══██╗██╔════╝██╔══██╗██╔══██╗    ████╗░████║██╔══██╗████╗░██║    ██╔══██╗██║░░██║██╔════╝██╔════╝╚══██╔══╝"
write-host -fore red "██║░░██║█████╗░░███████║██║░░██║    ██╔████╔██║███████║██╔██╗██║    ██║░░╚═╝███████║█████╗░░╚█████╗░░░██║░░░"
write-host -fore red "██║░░██║██╔══╝░░██╔══██║██║░░██║    ██║╚██╔╝██║██╔══██║██║╚████║    ██║░░██╗██╔══██║██╔══╝░░░╚═══██╗░░░██║░░░"
write-host -fore red "██████╔╝███████╗██║░░██║██████╔╝    ██║░╚═╝░██║██║░░██║██║░╚███║    ╚█████╔╝██║░░██║███████╗██████╔╝░░░██║░░░"
write-host -fore red "╚═════╝░╚══════╝╚═╝░░╚═╝╚═════╝     ╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝    ░╚════╝░╚═╝░░╚═╝╚══════╝╚═════╝░░░░╚═╝░░░"
write-host "ThreatHunting : Antiforensic Time change on EVTX"
write-host "Version : 0.9"
$Creation_Date = "15:12 04/10/2026"
Write-Host "Usage :" -ForegroundColor Yellow
Write-Host " .\PS_TimeChange.ps1 -Path <folder>"
Write-Host " .\PS_TimeChange.ps1 -Path <folder> -Verbose"
Write-Host ""

# --------------------------------------------------
# Si l'utilisateur saisit juste "c:" ou "d:", on ajoute le "\" pour viser la racine
if ($Path -match '^[a-zA-Z]:$') {
    $Path = "$Path\"
}

$FullPath = (Resolve-Path $Path).Path

# Check if path exist
if (-Not (Test-Path $fullPath)) {
    Write-Host "File '$fullPath' doesnt exist." -ForegroundColor Red
    Start-Sleep 5
    exit
}

# Check if evtx are into fullPath
if (((Get-ChildItem $fullPath -Filter *.evtx).Count) -lt 1) {
    $FullPath = Join-Path $FullPath "Windows\System32\winevt\Logs"
	$InputPath = $FullPath
}

Write-host -fore blue "EVTX needed :"
Write-host -fore blue "      - Security.evtx"
Write-host -fore blue "      - System.evtx"
Write-host -fore blue "      - Microsoft-Windows-Time-Service%4Operational.evtx"
Write-host ""


Write-Host "-------------------------"     
Write-Host -Fore Green "Input : $fullPath"
Write-Host "-------------------------"
$inputfolder = $FullPath

$Timestamp  = Get-Date -Format "yyyyMMdd_HHmmss"

$OutputPath = ".\OUT"
if (!(Test-Path $OutputPath)) {New-Item -ItemType Directory -Path $OutputPath | Out-Null}
$OutputPath = (Resolve-Path $OutputPath).Path
$OutputFile = Join-Path $OutputPath "Evtx_TimeChange_$Timestamp.txt"

$SeuilSautBruit = 60.0 

if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath | Out-Null }

$WakeMoments = @{}
$SystemFile = Join-Path $InputPath "System.evtx"
if (Test-Path $SystemFile) {
    try {
        $WakeLogs = Get-WinEvent -Path $SystemFile -FilterXPath "*[System[(EventID=107)]]" -ErrorAction SilentlyContinue
        foreach ($w in $WakeLogs) { $WakeMoments[$w.TimeCreated.ToString("yyyyMMddHHmmss")] = $true }
    } catch { }
}

$Results = @()

foreach ($File in Get-ChildItem -Path $InputPath -Filter *.evtx) {
    try {
        $Events = Get-WinEvent -Path $File.FullName -ErrorAction SilentlyContinue
        foreach ($E in $Events) {
            $Entry = ""; $DeltaInfo = ""; $AlerteLabel = ""; $Skip = $false

            if ($E.Id -eq 4616 -or $E.Id -eq 1) {
                $idxOld = if ($E.Id -eq 1) { 0 } else { 4 }
                $idxNew = if ($E.Id -eq 1) { 1 } else { 5 }
                
                $OldT = [datetime]$E.Properties[$idxOld].Value
                $NewT = [datetime]$E.Properties[$idxNew].Value
                $DiffSec = [math]::Abs(($NewT - $OldT).TotalSeconds)
                
                if ($DiffSec -lt $SeuilSautBruit) { $Skip = $true }
                for ($i = -2; $i -le 2; $i++) {
                    if ($WakeMoments.ContainsKey($E.TimeCreated.AddSeconds($i).ToString("yyyyMMddHHmmss"))) { $Skip = $true; break }
                }

                if (-not $Skip) {
                    $AlerteLabel = if ($DiffSec -lt 3600) { "> 1mn" } elseif ($DiffSec -lt 86400) { "> 1h" } else { "> 1j" }
                    
                    
                    $OldStr = $OldT.ToString("yyyy-MM-dd HH:mm:ss")
                    $NewStr = $NewT.ToString("yyyy-MM-dd HH:mm:ss")
                    $DeltaInfo = "Diff: $([math]::Round($DiffSec,0))s ($OldStr -> $NewStr)"
                    
                    $Entry = if ($E.Id -eq 4616) { "[SECURITY] Changement manuel/process" } else { "[SYSTEM] Saut temporel INEXPLIQUÉ" }
                }
            } elseif ($E.Id -eq 20003) {
                $Entry = "[SYSTEM] Changement de FUSEAU HORAIRE"
            }

            if ($Entry -ne "" -and -not $Skip) {
                $Results += [PSCustomObject]@{ Date = $E.TimeCreated; Fichier = $File.Name; Event = $Entry; Alerte = $AlerteLabel; Details = $DeltaInfo }
            }
        }
    } catch { }
}

$Results | Sort-Object Date -Descending | ForEach-Object {
    "$($_.Date.ToString('yyyy-MM-dd HH:mm:ss')) | $($_.Alerte.PadRight(8)) | $($_.Fichier.PadRight(15)) | $($_.Event.PadRight(40)) | $($_.Details)"
} | Out-File -FilePath $OutputFile
Write-Host "[+] Rapport généré avec succès." -ForegroundColor Green