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
write-host "ThreatHunting : Search Lolbas into report's folder"
write-host "Version : 0.4"
Write-Host "Usage :" -ForegroundColor Yellow
Write-Host " .\PS_Search_lolbas.ps1 -Path <folder>"
Write-Host " .\PS_Search_lolbas.ps1 -Path <folder> -Verbose"
Write-Host ""
$FullPath = (Resolve-Path $Path).Path
Write-host -Fore Green "Input : File Path : $fullPath"

# Check if path exist
if (-Not (Test-Path $fullPath)) {
    Write-Host "File '$fullPath' doesnt exist." -ForegroundColor Red
    exit
}


if (-not (Test-Path $Path)) {
    Write-Error "Path not found: $Path"
    exit 1
}

$OutputDir = ".\OUT"

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$OutputCsv = Join-Path $OutputDir "LOLBAS_Hits_$Timestamp.csv"

# LOLBAS List
$LOLBAS = @(
    "findstr.exe",
    "cmd.exe",
    "powershell.exe",
    "pwsh.exe",
    "bitsadmin.exe",
    "certutil.exe",
    "rundll32.exe",
    "regsvr32.exe",
    "mshta.exe",
    "wmic.exe",
    "wscript.exe",
    "cscript.exe",
    "msbuild.exe",
    "installutil.exe",
    "schtasks.exe",
    "reg.exe",
    "regedit.exe",
    "regini.exe",
    "netsh.exe",
    "sc.exe",
    "at.exe",
    "forfiles.exe",
    "hh.exe",
    "ftp.exe",
    "makecab.exe",
    "expand.exe",
    "extrac32.exe",
    "diskshadow.exe",
    "esentutl.exe",
    "dnscmd.exe",
    "cmdkey.exe",
    "cmstp.exe",
    "msiexec.exe",
    "pktmon.exe",
    "vssadmin.exe",
    "wbadmin.exe",
    "mavinject.exe",
    "appinstaller.exe",
    "control.exe",
    "explorer.exe"
)

Write-Host "============================================================"
#Write-Host "[+] Analyzed directory: $Path" -ForegroundColor Cyan

$Files = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue

#Write-Host "[+] Files found: $($Files.Count)" -ForegroundColor Yellow
#Write-Host "============================================================"

$Results = [System.Collections.Generic.List[PSCustomObject]]::new()

foreach ($File in $Files) {
    try {
        $Content = Get-Content $File.FullName -Raw -ErrorAction Stop

        foreach ($LOLBASItem in $LOLBAS) {
            if ($Content -like "*$LOLBASItem*") {
                Write-Verbose "[ALERT] $LOLBASItem detected in: $($File.FullName)"

                $Results.Add(
                    [PSCustomObject]@{
                        LOLBAS       = $LOLBASItem
                        Fichier      = $File.FullName
                        TailleKo     = [Math]::Round($File.Length / 1KB, 2)
                        DernierWrite = $File.LastWriteTime
                    }
                )
            }
        }
    }
    catch {
        Write-Verbose "Unable to read: $($File.FullName)"
    }
}

# Deduplicate for the CSV and summary
$UniqueResults = @($Results | Sort-Object LOLBAS, Fichier -Unique)

# Systematic CSV export
$UniqueResults |
    Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8

#Write-Host ""

if ($UniqueResults.Count -eq 0) {
    Write-Host "[OK] No LOLBAS found." -ForegroundColor Green
} else {
    $UniqueLolbasNames = ($UniqueResults | Select-Object -ExpandProperty LOLBAS -Unique) -join ";"

    Write-Host "[+] Alerts: $($UniqueResults.Count)" -ForegroundColor Red
    Write-Host "[+] $UniqueLolbasNames" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "============================================================"
Write-Host "[+] CSV Report generated: $OutputCsv" -ForegroundColor Green
Write-Host "============================================================"

if ($PSBoundParameters['Verbose'] -and $UniqueResults.Count -gt 0) {
    Write-Host ""
    $UniqueResults | Format-Table -AutoSize
}