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
write-host "ThreatHunting : Search Antiforensic Timestomp on EVTX"
write-host "Version : 1.5"
$Creation_Date = "12:50 04/10/2026"
Write-Host "Usage :" -ForegroundColor Yellow
Write-Host " .\PS_TimeStomp4616_csv.ps1 -Path <folder>"
Write-Host " .\PS_TimeStomp4616_csv.ps1 -Path <folder> -Verbose"
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





# ─── DOSSIERS ───────────────────────────────────────────────
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

$OutputDir = ".\OUT"
if (!(Test-Path $OutputDir)) {New-Item -ItemType Directory -Path $OutputDir | Out-Null}
$CsvOut = Join-Path $OutputDir "TimeStomp_EVTX_Results.csv"

# ─── DEFINITIONS DES ID CIBLES ──────────────────────────────
$TargetIDs = @(4616, 1, 37, 6013, 35, 134)
$Targets = @{
    4616 = "Heure systeme modifiee";
    1    = "Heure systeme changee (Kernel-General)";
    37   = "Fuseau horaire modifie / Decalage NTP";
    6013 = "Uptime systeme";
    35   = "Synchronisation NTP reussie";
    134  = "Source NTP modifiee"
}

$Results = New-Object System.Collections.ArrayList

# ─── ANALYSE EVTX ───────────────────────────────────────────
# Sélectionner uniquement les journaux pertinents pour éviter de scanner tous les evtx inutilement
$TargetEvtxNames = @("Security.evtx", "System.evtx")
$EvtxFiles = Get-ChildItem $fullPath -Filter *.evtx -ErrorAction SilentlyContinue | Where-Object { $TargetEvtxNames -contains $_.Name }

if ($null -eq $EvtxFiles) {
    Write-Host "Aucun fichier EVTX trouve dans $fullPath" -ForegroundColor Red
    exit
}

foreach ($Evtx in $EvtxFiles) {
    Write-Host "`nAnalyse : $($Evtx.Name)" -ForegroundColor Cyan
    
    try {
        $AllEvents = Get-WinEvent -Path $Evtx.FullName -ErrorAction SilentlyContinue

        if ($null -eq $AllEvents) { continue }

        foreach ($Evt in $AllEvents) {
            # Filtrage manuel par ID
            if ($TargetIDs -contains $Evt.Id) {
                
                $Desc = $Targets[$Evt.Id]
                $Xml = [xml]$Evt.ToXml()
                $OldTime = ""
                $NewTime = ""
                $Delta   = ""

                if ($Evt.Id -eq 4616) {
                    $Nodes = $Xml.Event.EventData.Data
                    foreach ($node in $Nodes) {
                        if ($node.Name -eq "OldTime") { $OldTime = $node."#text" }
                        if ($node.Name -eq "NewTime") { $NewTime = $node."#text" }
                    }
                    if ($OldTime -and $NewTime) {
                        try { 
                            $ts = ([datetime]$NewTime) - ([datetime]$OldTime) 
                            $Delta = [math]::Round($ts.TotalSeconds, 2).ToString() + " sec"
                        } catch { $Delta = "n/a" }
                    }
                }

                $Obj = New-Object PSObject
                $Obj | Add-Member -MemberType NoteProperty -Name "Date"        -Value $Evt.TimeCreated
                $Obj | Add-Member -MemberType NoteProperty -Name "EventID"     -Value $Evt.Id
                $Obj | Add-Member -MemberType NoteProperty -Name "Description" -Value $Desc
                $Obj | Add-Member -MemberType NoteProperty -Name "OldTime"     -Value $OldTime
                $Obj | Add-Member -MemberType NoteProperty -Name "NewTime"     -Value $NewTime
                $Obj | Add-Member -MemberType NoteProperty -Name "Delta"       -Value $Delta
                $Obj | Add-Member -MemberType NoteProperty -Name "Fichier"     -Value $Evtx.Name
                
                $null = $Results.Add($Obj)
            }
        }
    }
    catch {
        Write-Host "Erreur sur $($Evtx.Name) : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ─── EXPORT CSV ─────────────────────────────────────────────
if ($Results.Count -gt 0) {
    $Results | Sort-Object Date | Export-Csv $CsvOut -NoTypeInformation -Encoding UTF8
    Write-Host "`n[OK] $($Results.Count) evenements extraits dans : $CsvOut" -ForegroundColor Green
} else {
    Write-Host "`nAucun evenement detecte avec les IDs cibles." -ForegroundColor Yellow
}
