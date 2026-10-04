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
write-host "ThreatHunting : List ConsoleHost_History"
write-host "Version : 0.1"
$Creation_Date = "18:37 04/10/2026"
Write-Host "Usage :" -ForegroundColor Yellow
Write-Host " .\PS_Search_ConsoleHostHistory.ps1 -Path <folder>"
Write-Host " .\PS_Search_ConsoleHostHistory.ps1 -Path <folder> -Verbose"
Write-Host ""

# --------------------------------------------------
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
# Si l'utilisateur saisit juste "c:" ou "d:", on ajoute le "\" pour viser la racine
if ($Path -match '^[a-zA-Z]:$') {
    $Path = "$Path\"
}



# Check if path exist
$FullPath = (Resolve-Path $Path).Path
if (-Not (Test-Path $fullPath)) {
    Write-Host "File '$fullPath' doesnt exist." -ForegroundColor Red
    Start-Sleep 5
    exit
}


$OutputDir = ".\OUT"
if (!(Test-Path $OutputDir)) { 
    New-Item -ItemType Directory -Path $OutputDir | Out-Null 
}
$CsvOut = Join-Path -Path $OutputDir -ChildPath ("List_ConsoleHost_History_" + $timestamp + ".csv")

Write-Host "-------------------------"     
Write-Host -Fore Green "Input : $fullPath"
Write-Host "-------------------------"

$UsersRoot = Join-Path $fullPath "\users"

$Results = @()
$compteur=0



## CHECK BY SYSTEM
$SystemProfiles = @(
    @{
        Nom  = "NT AUTHORITY\SYSTEM"
        Path = "Windows\System32\config\systemprofile\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
    }
    @{
        Nom  = "NT AUTHORITY\LOCAL SERVICE"
        Path = "Windows\ServiceProfiles\LocalService\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
    }
    @{
        Nom  = "NT AUTHORITY\NETWORK SERVICE"
        Path = "Windows\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
    }
)
foreach ($SystemProfile in $SystemProfiles) {

    $CHH = Join-Path $fullPath $SystemProfile.Path

    if (Test-Path $CHH) {
        if ((gc $CHH).Count -gt 0) {

            Write-Host $CHH
            Write-Verbose $CHH
            $compteur++

            $Results += [PSCustomObject]@{
                Utilisateur = $SystemProfile.Nom
                Path        = $CHH
            }

            if ($VerbosePreference -ne 'SilentlyContinue') {
                Start-Process Notepad $CHH
            }
        }
    }
}

## CHECK BY USER
Get-ChildItem -LiteralPath $UsersRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object{
    $UserName = $_.Name
    $CHH = Join-Path $_.FullName "\Appdata\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt"
		
    if (Test-Path $CHH)
		{
		if ((gc $CHH).count -gt 0)
			{
			write-host $CHH 
			write-verbose $CHH 	
			$compteur++
			$Results += [PSCustomObject]@{
			Utilisateur = $UserName
			Path   = $CHH
			}
		if ($VerbosePreference -ne 'SilentlyContinue') {Start-Process Notepad $CHH}	
		
		}
	}
}    
# Affichage tableau
	$Results | Format-Table -AutoSize | Out-String | Write-Verbose

	if ($Results.Count -gt 0)
		{
		$Results | Export-Csv $CsvOut -NoTypeInformation -Encoding UTF8
		Write-Host "Ouput : $CsvOut" -ForegroundColor Green
		Write-host "Output: " $compteur
		}
	else 
		{
		Write-Host "No ConsoleHost_History Found." -ForegroundColor Yellow
		}
		
