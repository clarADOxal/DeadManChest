# Search Unicode caracters into a file

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
write-host "ThreatHunting : Search Unicode caracters in specified file/folder"
write-host "Version : 0.2"
Write-Host "Usage :" -ForegroundColor Yellow
Write-Host " .\PS_Search_Unicode.ps1 -Path <file|folder>"
Write-Host " .\PS_Search_Unicode.ps1 -Path <file|folder> -Verbose"
Write-Host ""
Write-Host "Verbose mode displays matching lines and Unicode characters."
write-host ""
$FullPath = (Resolve-Path $Path).Path
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
#$content = Get-Content -Raw -Path $fullPath -Encoding UTF8


function Get-UnicodeScript {
 
param(
[char]$Char
)
 
$Code = [int][char]$Char
 
switch ($Code) {
 
{$_ -ge 0x0400 -and $_ -le 0x04FF} { return "Cyrillic" }
{$_ -ge 0x0370 -and $_ -le 0x03FF} { return "Greek" }
{$_ -ge 0x0590 -and $_ -le 0x05FF} { return "Hebrew" }
{$_ -ge 0x0600 -and $_ -le 0x06FF} { return "Arabic" }
{$_ -ge 0x3040 -and $_ -le 0x309F} { return "Hiragana" }
{$_ -ge 0x30A0 -and $_ -le 0x30FF} { return "Katakana" }
{$_ -ge 0x4E00 -and $_ -le 0x9FFF} { return "CJK" }
{$_ -ge 0xAC00 -and $_ -le 0xD7AF} { return "Hangul" }
 
default { return "Other Unicode" }
}
}

$Files = @()
 
if ((Get-Item $FullPath) -is [System.IO.FileInfo])
	{$Files = Get-Item $FullPath}
else 
	{
	$Files = Get-ChildItem `
	-Path $FullPath `
	-File `
	-Recurse `
	-ErrorAction SilentlyContinue
	}

#===================================================================
# Search non-ascii characters
# ===================================================================
 
$GlobalCount = 0
$ScriptStats = @{}
$FileResults = @{}

foreach ($File in $Files) {
$FileResults[$File.FullName] = $false
 
try {
 
$Lines = Get-Content `
-Path $File.FullName `
-Encoding UTF8 `
-ErrorAction Stop
 
for ($i = 0; $i -lt $Lines.Count; $i++) {
 
$Line = $Lines[$i]
$LineNumber = $i + 1
 
$Matches = [System.Text.RegularExpressions.Regex]::Matches(
$Line,
'[^\p{IsBasicLatin}\p{IsLatin-1Supplement}]'
)
 
if ($Matches.Count -eq 0) {
continue
}
$FileResults[$File.FullName] = $true
 
Write-Verbose ""
Write-Verbose "File : $($File.FullName)"
Write-Verbose "Line : $LineNumber"
Write-Verbose $Line
 
foreach ($Match in $Matches) {

 
$Character = $Match.Value
$CodePoint = [int][char]$Character
$Script = Get-UnicodeScript $Character
 
if (-not $ScriptStats.ContainsKey($Script)) {
$ScriptStats[$Script] = 0
}
 
$ScriptStats[$Script]++
 
Write-Verbose (
" -> '{0}' ({1}) [{2}]" -f
$Character,
('U+{0:X4}' -f $CodePoint),
$Script
)
 
$GlobalCount++
}
}
}

catch {
Write-Warning "Unable to read file: $($File.FullName)"
Write-Host $_.Exception.Message -ForegroundColor Red
Write-Host $_.InvocationInfo.PositionMessage -ForegroundColor Yellow
}


}
 
# ===================================================================
# Summary
# ===================================================================
 
Write-Verbose ""
Write-Verbose "================ SUMMARY ================" 
 
if ($GlobalCount -eq 0) {
 
Write-Verbose "No non-ASCII character found." 
}
else {
 
Write-Verbose "Total suspicious characters found : $GlobalCount"
Write-Verbose ""
 
foreach ($Entry in $ScriptStats.GetEnumerator() | Sort-Object Name) {
 
Write-Verbose ("{0,-15} : {1}" -f $Entry.Name,$Entry.Value)
}
}
 
Write-Verbose ""
Write-Verbose ""
Write-Host "================ FILES STATUS ================" -ForegroundColor Yellow
 
foreach ($Entry in $FileResults.GetEnumerator() | Sort-Object Name) {
 
if ($Entry.Value) {
Write-Host "[X] $($Entry.Key)" -ForegroundColor Red
}
else {
Write-Host "[ ] $($Entry.Key)" -ForegroundColor Green
}
}