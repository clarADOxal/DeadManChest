#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter(Mandatory = $false)]
    [int]$HourOffset = 2 # Décalage direct en heures (ex: 2 pour UTC+2)
)

cls
write-host -fore red "██████╗░███████╗░█████╗░██████╗░  ███╗░░░███╗░█████╗░███╗░░██╗  ░█████╗░██╗░░██╗███████╗░██████╗████████╗"
write-host -fore red "██╔══██╗██╔════╝██╔══██╗██╔══██╗  ████╗░████║██╔══██╗████╗░██║  ██╔══██╗██║░░██║██╔════╝██╔════╝╚══██╔══╝"
write-host -fore red "██║░░██║█████╗░░███████║██║░░██║  ██╔████╔██║███████║██╔██╗██║  ██║░░╚═╝███████║█████╗░░╚█████╗░░░░██║░░░"
write-host -fore red "██║░░██║██╔══╝░░██╔══██║██║░░██║  ██║╚██╔╝██║██╔══██║██║╚████║  ██║░░██╗██╔══██║██╔══╝░░░╚═══██╗░░░██║░░░"
write-host -fore red "██████╔╝███████╗██║░░██║██████╔╝  ██║░╚═╝░██║██║░░██║██║░╚███║  ╚█████╔╝██║░░██║███████╗██████╔╝░░░██║░░░"
write-host -fore red "╚═════╝░╚══════╝╚═╝░░╚═╝╚═════╝░  ╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝  ░╚════╝░╚═╝░░╚═╝╚══════╝╚═════╝░░░░╚═╝░░░"
write-host "ThreatHunting : Search AnyDesk"
write-host "Version : 0.5"
write-verbose "06:53 12/10/2026"
write-verbose (get-date -displayHint Time)
Write-Host "Usage :" -ForegroundColor Yellow
Write-Host " .\PS_Search_AnyDesk.ps1 -Path <Drive Path ie: d:\collecte\upload\auto\c%3A>"
Write-Host " .\PS_Search_AnyDesk.ps1 -Path <Drive Path ie: d:\collecte\upload\auto\c%3A> -Verbose"
Write-Host " .\PS_Search_AnyDesk.ps1 -Path <Drive Path ie: d:\collecte\upload\auto\c%3A> -HourOffset 2 (To Convert UTC+2 into UTC)"
Write-Host ""

$FullPath = (Resolve-Path $Path).Path
Write-host -Fore Green "Input : File Path : $fullPath"

# Timestamp for unique filenames
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

$in = (Resolve-Path $path).Path
# Check if target directory exists
if (-not (Test-Path -Path $in -PathType Container)) {
    Write-Host "Error: The specified directory does not exist." -ForegroundColor Red
    exit
}

# Create output folder if missing
$outputFolder = ".\OUT"
if (-not (Test-Path $outputFolder)) { 
    New-Item -Path $outputFolder -ItemType Directory | Out-Null
    Write-Host -ForegroundColor Red "Folder OUT Created" 
}
$outputFolderFull = (Resolve-Path $outputFolder).Path
$outputCsv = Join-Path -Path $outputFolderFull -ChildPath ("PS_AnyDesk_" + $timestamp + ".csv")

# ================================================================
# AUDIT ANYDESK CONFIG / TRACES
# ================================================================

$results = @([PSCustomObject]@{
    Profil           = "SYSTEM"
    Chemin           = "$in\Windows\SysWOW64\config\systemprofile\AppData\Roaming\AnyDesk"
    AdTrace          = $false
    ConnectionTrace  = $false
    ServiceConf      = $false
    SystemConf       = $false
    UserConf         = $false
    ChatDir          = $false
})

# Search AnyDesk into User's Profiles
$userPaths = @()
$baseUsers = "$in\Users"
if (Test-Path $baseUsers) {
    $userPaths = Get-ChildItem -Path $baseUsers -Directory -ErrorAction SilentlyContinue | 
                 ForEach-Object { Join-Path $_.FullName "appdata\roaming\AnyDesk" }
}

# Add SystemProfile path
$systemPath = "$in\Windows\SysWOW64\config\systemprofile\AppData\Roaming\AnyDesk"
$allPaths = @($systemPath) + $userPaths

foreach ($targetPath in $allPaths) {
    if (Test-Path -Path $targetPath) {
        # Set Profile Name 
        if ($targetPath -like "*systemprofile*") {
            $profileName = "SYSTEM"
        } else {
            # Set username 
            $profileName = (Get-Item $targetPath).Parent.Parent.Parent.Name
        }

        # Check paths and files
        $exist_adtrace          = (Get-ChildItem -Path $targetPath -Filter "ad.tr*" -ErrorAction SilentlyContinue) -ne $null
        $exist_connectiontrace  = (Get-ChildItem -Path $targetPath -Filter "connection_tr*" -ErrorAction SilentlyContinue) -ne $null
        $exist_serviceconf      = (Get-ChildItem -Path $targetPath -Filter "service*" -ErrorAction SilentlyContinue) -ne $null
        $exist_systemconf       = (Get-ChildItem -Path $targetPath -Filter "system*" -ErrorAction SilentlyContinue) -ne $null
        $exist_userconf         = (Get-ChildItem -Path $targetPath -Filter "user*" -ErrorAction SilentlyContinue) -ne $null
        $exist_chat             = (Get-ChildItem -Path $targetPath -Filter "chat*" -Directory -ErrorAction SilentlyContinue) -ne $null

        $results += [PSCustomObject]@{
            Profil           = $profileName
            Chemin           = $targetPath
            AdTrace          = $exist_adtrace
            ConnectionTrace  = $exist_connectiontrace
            ServiceConf      = $exist_serviceconf
            SystemConf       = $exist_systemconf
            UserConf         = $exist_userconf
            ChatDir          = $exist_chat
        }
    }
}

# Set "X" as exist, and "-" as unexist for console display
$displayTable = $results | ForEach-Object {
    [PSCustomObject]@{
        "Profil"     = $_.Profil
        "AdTrace"    = if ($_.AdTrace) { "X" } else { "-" }
        "ConnTrace"  = if ($_.ConnectionTrace) { "X" } else { "-" }
        "Service"    = if ($_.ServiceConf) { "X" } else { "-" }
        "System"     = if ($_.SystemConf) { "X" } else { "-" }
        "User"       = if ($_.UserConf) { "X" } else { "-" }
        "Chat"       = if ($_.ChatDir) { "X" } else { "-" }
    }
}

# Show table into console
Write-verbose "`n=== RESUME ANYDESK ==="
$resulttable = $displayTable | Format-Table -AutoSize | out-string
write-verbose $resulttable

# Export details in CSV inventory report
$results | Export-Csv -Path $outputCsv -NoTypeInformation -Encoding UTF8
Write-Host "Out : inventory : $outputCsv" -ForegroundColor Green


# ================================================================
# MERGE CONNECTION TRACES (With Hour Offset)
# ================================================================

Write-verbose "`nSearching and merging connection_trace files (applying offset: -$HourOffset h)..." 
$ConnectionFiles = Get-ChildItem -Path $in -Recurse -Filter "connection_trace.txt" -ErrorAction SilentlyContinue
$outputCnxCsv = Join-Path -Path $outputFolderFull -ChildPath ("PS_AnyDesk_Connections_" + $timestamp + ".csv")

$mergedConnections = @()

foreach ($file in $ConnectionFiles) {
    # Extract username safely from parent directory structure
    try {
        $UserName =$file.Directory.Parent.Parent.Parent.Name
    } catch {
        $UserName = "Unknown"
    }

    # Read file handling UTF-16 LE BOM encoding used by AnyDesk
    if (Test-Path $file.FullName) {
        try {
            $Bytes = [System.IO.File]::ReadAllBytes($file.FullName)
            $Lines = [System.Text.Encoding]::Unicode.GetString($Bytes) -split "`r?`n"

            foreach ($line in $Lines) {
                if ($line.Trim() -ne "") {
                    # Remove commas
                    $CleanLine =$line -replace ",", ""
                    # Split line into words/tokens
                    $parts =$CleanLine -split "\s+"

                    if ($parts.Count -ge 3) {$Type = $parts[0]
						$rawDateStr = $parts[1] + " " + $parts[2]
                        
                        $finalDateTime =$rawDateStr

                        # Apply direct hour offset adjustment
						try {
							$parsedDate = [datetime]::Parse($rawDateStr)
							# Subtract the offset hours to go from Local (e.g., UTC+2) to UTC
							$adjustedDate = $parsedDate.AddHours(-$HourOffset)
							$finalDateTime = $adjustedDate.ToString("yyyy-MM-dd HH:mm:ss")
							} catch {
								$finalDateTime = $rawDateStr
							}
						

                        # Create a clean object for proper CSV export compatible with Timeline Explorer
                        $mergedConnections += [PSCustomObject]@{
                            Type           = $Type
                            DateTime       = $finalDateTime
                            ConnexionType  = $parts[3]
                            Session1       = if ($parts.Count -ge 5) {$parts[4] } else { "" }
                            Session2       = if ($parts.Count -ge 6) {$parts[5] } else { "" }
                            ExtraDetails   = if ($parts.Count -gt 6) { $parts[6..($parts.Count-1)] -join " " } else { "" }
                            UserName       = $UserName
                        }
                    }
                }
            }
        } catch {
            Write-Warning "Unable to read file: $($file.FullName)"
        }
    }
}

# Export cleanly using Export-Csv
if ($mergedConnections.Count -gt 0) {
    $mergedConnections | Export-Csv -Path $outputCnxCsv -NoTypeInformation -Encoding UTF8
    Write-Host "Out : Allconnect : $outputCnxCsv" -ForegroundColor Green
} else {
    Write-Host "No connection traces found to merge." -ForegroundColor Yellow
}