# Search Cyrillics caracters into a file

#Requires -Version 5.1


param(
    [Parameter(Mandatory = $true)]
    [string]$Path  # Chemin du fichier à analyser
)

cls
write-host -fore red "██████╗░███████╗░█████╗░██████╗░  ███╗░░░███╗░█████╗░███╗░░██╗  ░█████╗░██╗░░██╗███████╗░██████╗████████╗"
write-host -fore red "██╔══██╗██╔════╝██╔══██╗██╔══██╗  ████╗░████║██╔══██╗████╗░██║  ██╔══██╗██║░░██║██╔════╝██╔════╝╚══██╔══╝"
write-host -fore red "██║░░██║█████╗░░███████║██║░░██║  ██╔████╔██║███████║██╔██╗██║  ██║░░╚═╝███████║█████╗░░╚█████╗░░░░██║░░░"
write-host -fore red "██║░░██║██╔══╝░░██╔══██║██║░░██║  ██║╚██╔╝██║██╔══██║██║╚████║  ██║░░██╗██╔══██║██╔══╝░░░╚═══██╗░░░██║░░░"
write-host -fore red "██████╔╝███████╗██║░░██║██████╔╝  ██║░╚═╝░██║██║░░██║██║░╚███║  ╚█████╔╝██║░░██║███████╗██████╔╝░░░██║░░░"
write-host -fore red "╚═════╝░╚══════╝╚═╝░░╚═╝╚═════╝░  ╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝  ░╚════╝░╚═╝░░╚═╝╚══════╝╚═════╝░░░░╚═╝░░░"
write-host "ThreatHunting : Search Cyrillics caracters in specified file"
write-host "Version : 0.1"
write-host ""
$fullPath = (Get-Item $Path).FullName
Write-host -Fore Green "Input : File Path : $fullPath"

#Todo
#====
#Add option to search into folder in recursive
#Add option to search another alphabet


# Check if path exist
if (-Not (Test-Path $fullPath)) {
    Write-Host "File '$fullPath' doesnt exist." -ForegroundColor Red
    exit
}

# Read File content
$content = Get-Content -Raw -Path $fullPath -Encoding UTF8

# Regex to search cyrilic (Unicode U+0400 à U+04FF)
$pattern = '[\u0400-\u04FF]'

if ($content -match $pattern) {
    Write-Host  -ForegroundColor red "Results : FIND cyrillic alphabet into $fullPath "
    # Show lines found
    Get-Content -Path $Path -Encoding UTF8 | Select-String -Pattern $pattern | ForEach-Object {
        Write-Host ("Ligne {0}: {1}" -f $_.LineNumber, $_.Line) -ForegroundColor Cyan
    }
} else {
    Write-Host -fore red "Results : Not FIND cyrillic alphabet into $fullPath."
}
