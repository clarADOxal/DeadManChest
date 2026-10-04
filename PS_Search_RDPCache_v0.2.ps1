#Requires -Version 5.0

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
write-host "ThreatHunting : ListUsr RDPCache"
write-host "Version : 0.2"
$Creation_Date = "18:21 04/10/2026"
Write-Host "Usage :" -ForegroundColor Yellow
Write-Host " .\PS_Search_RDPCache.ps1 -Path <folder>"
Write-Host " .\PS_Search_RDPCache.ps1 -Path <folder> -Verbose"
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

Write-Host "-------------------------"     
Write-Host -Fore Green "Input : $fullPath"
Write-Host "-------------------------"

$UsersRoot = Join-Path $fullPath "\users"

$Results = @()

Get-ChildItem -Path $UsersRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {

    $UserName = $_.Name
    $CachePath = Join-Path $_.FullName "AppData\Local\Microsoft\Terminal Server Client\Cache"

    if (Test-Path $CachePath) {
        $FileCount = (Get-ChildItem -Path $CachePath -File -ErrorAction SilentlyContinue).Count
    }
    else {
        $FileCount = 0
    }

    $Results += [PSCustomObject]@{
        Utilisateur = $UserName
        NbFichiers  = $FileCount
        CachePath   = $CachePath

    }

if ($FileCount -gt 0)
	{
	write-verbose $UserName : $FileCount;
	Write-verbose "Appuyez sur une touche Ouvrir l'explorer"
	pause
	Start-Process explorer.exe $CachePath
	}
}

# Affichage tableau
$Results | Format-Table -AutoSize
