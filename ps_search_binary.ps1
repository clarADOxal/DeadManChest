#Requires -Version 5.1

[CmdletBinding()]
param(
[Parameter(Mandatory = $true)]
[string]$Path
)

cls
write-host -fore red "██████╗░███████╗░█████╗░██████╗░  ███╗░░░███╗░█████╗░███╗░░██╗  ░█████╗░██╗░░██╗███████╗░██████╗████████╗"
write-host -fore red "██╔══██╗██╔════╝██╔══██╗██╔══██╗  ████╗░████║██╔══██╗████╗░██║  ██╔══██╗██║░░██║██╔════╝██╔════╝╚══██╔══╝"
write-host -fore red "██║░░██║█████╗░░███████║██║░░██║  ██╔████╔██║███████║██╔██╗██║  ██║░░╚═╝███████║█████╗░░╚█████╗░░░░██║░░░"
write-host -fore red "██║░░██║██╔══╝░░██╔══██║██║░░██║  ██║╚██╔╝██║██╔══██║██║╚████║  ██║░░██╗██╔══██║██╔══╝░░░╚═══██╗░░░██║░░░"
write-host -fore red "██████╔╝███████╗██║░░██║██████╔╝  ██║░╚═╝░██║██║░░██║██║░╚███║  ╚█████╔╝██║░░██║███████╗██████╔╝░░░██║░░░"
write-host -fore red "╚═════╝░╚══════╝╚═╝░░╚═╝╚═════╝░  ╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝  ░╚════╝░╚═╝░░╚═╝╚══════╝╚═════╝░░░░╚═╝░░░"
write-host "Threat Hunt : Search Binary into a Folder (not recursive)"
write-host "Version : 0.2"
write-verbose "08:08 08/10/2026"
write-verbose (get-date -displayHint Time)
Write-Host "Usage :" -ForegroundColor Yellow
Write-Host " .\PS_Search_Binary.ps1 -Path <folder>"
Write-Host " .\PS_Search_Binary.ps1 -Path <folder> -Verbose"
Write-Host ""
$FullPath = (Resolve-Path $Path).Path
Write-host -Fore Green "Input : File Path : $fullPath"


# TODO   //////////////////////////////////////////////////////////////////////////////////
$Todo+="search in recursive"
# TODO   //////////////////////////////////////////////////////////////////////////////////
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

$in = (Resolve-Path $path).Path



$outputFolder = ".\OUT"
if (-not (Test-Path $outputFolder)) { New-Item -Path $outputFolder -ItemType Directory | Out-Null; Write-Host -ForegroundColor Red "Folder OUT Created" }
$outputFolderFull = (Resolve-Path $outputFolder).Path
$outputCsv   = Join-Path -Path $outputFolderFull -ChildPath ("Search_Binary_" + $timestamp + ".csv")

#Settings 
$total = 0
$binaires = 0
$listeBinaires = @()
$resultats = @()


Get-ChildItem -File -path $in | ForEach-Object {

    $total++

    $bytes = Get-Content $_.FullName -Encoding Byte -TotalCount 2
    $sig = "{0:X2} {1:X2}" -f $bytes[0],$bytes[1]

    $isBinary = ($bytes[0] -eq 77 -and $bytes[1] -eq 90)

    if ($isBinary) {
        $binaires++
        $listeBinaires += $_.FullName
        Write-verbose "$sig  $($_.FullName)"
    }
    else {
        Write-verbose "$sig  $($_.FullName)"
    }

    $resultats += [PSCustomObject]@{
        Signature = $sig
        Binaire   = $isBinary
        Fichier   = $_.FullName
    }
}

Write-Host ""
Write-Host "===== Resume  ====="
Write-Verbose "Count of files analyzed : $total"
Write-Host "Count of Binary (MZ)     : $binaires" -ForegroundColor Red
$listeBinaires | ForEach-Object { Write-Host $_ -ForegroundColor Red }

$listeBinaires | Export-Csv -Path $outputCsv -NoTypeInformation -Encoding UTF8

#$resultats | Out-GridView -Title "Analyze signature files"
