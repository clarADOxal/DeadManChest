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
write-host "Forensic : Tasks list"
write-host "Version : 0.4"
write-verbose "14:53 10/10/2026"
write-verbose (get-date -displayHint Time)
Write-Host "Usage :" -ForegroundColor Yellow
Write-Host " .\PS_Tasks.ps1 -Path <folder> (tasks folder)"
Write-Host " .\PS_Tasks.ps1 -Path <folder> -Verbose"
Write-Host ""

$FullPath = (Resolve-Path $Path).Path
Write-host -Fore Green "Input : File Path : $fullPath"


# TODO   //////////////////////////////////////////////////////////////////////////////////
$Todo+=""
# TODO   //////////////////////////////////////////////////////////////////////////////////
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

$in = (Resolve-Path $path).Path
# Vérifier si le répertoire existe
if (-not (Test-Path -Path $in -PathType Container)) {
    Write-Host "Erreur : Le répertoire spécifié n'existe pas." -ForegroundColor Red
    exit
}


$outputFolder = ".\OUT"
if (-not (Test-Path $outputFolder)) { New-Item -Path $outputFolder -ItemType Directory | Out-Null; Write-Host -ForegroundColor Red "Folder OUT Created" }
$outputFolderFull = (Resolve-Path $outputFolder).Path
$outputCsv   = Join-Path -Path $outputFolderFull -ChildPath ("PS_Tasks_" + $timestamp + ".csv")

#================================================================


# Récupérer TOUS les fichiers du répertoire et des sous-dossiers
$tousLesFichiers = Get-ChildItem -Path $in -File -Recurse

if ($tousLesFichiers.Count -eq 0) {
    Write-Host "Aucun fichier trouvé dans ce répertoire." -ForegroundColor Yellow
    exit
}

Write-Host "Analyse de $($tousLesFichiers.Count) fichier(s)..." -ForegroundColor Cyan

# Liste globale pour stocker toutes les lignes de tous les fichiers
$toutesLesDonnees = [System.Collections.Generic.List[PSCustomObject]]::new()
$fichiersTraites = 0

foreach ($fichier in $tousLesFichiers) {
    try {
        # Tenter de charger le contenu en tant que XML
        [xml]$xml = Get-Content -Path $fichier.FullName -Encoding UTF8 -ErrorAction Stop
        
        # Trouver les nœuds enfants (les tâches/éléments)
        $nodes = $xml.DocumentElement.ChildNodes | Where-Object { $_.NodeType -eq 'Element' }

        if ($nodes) {
            foreach ($node in $nodes) {
                # Utiliser un dictionnaire ordonné pour garder les propriétés
                $properties = [ordered]@{}
                
                # Ajouter en premier le chemin complet du fichier source
                $properties["SourceFilePath"] = $fichier.FullName
                
                # Récupérer les balises enfants du nœud
                foreach ($child in $node.ChildNodes) {
                    if ($child.NodeType -eq 'Element') {
                        $properties[$child.LocalName] = $child.InnerText
                    }
                }
                
                # Ajouter l'objet à notre liste globale
                    $toutesLesDonnees.Add([PSCustomObject]$properties)
            }
            $fichiersTraites++
            Write-verbose "Traité : $($fichier.Name)"
        }
    }
    catch {
        # Ignore les fichiers qui ne sont pas du XML valide
    }
}

# Si on a trouvé des données, on exporte le tout dans UN SEUL fichier CSV
if ($toutesLesDonnees.Count -gt 0) {
   # $cheminCsvFinal = Join-Path -Path $repertoireSortie -ChildPath "toutes_les_taches.csv"
    
    $toutesLesDonnees | Export-Csv -Path $outputCsv  -NoTypeInformation -Encoding utf8
    
    Write-Host "`nTerminé avec succès !" -ForegroundColor Cyan
    Write-Host "$fichiersTraites fichier(s) XML analysé(s)." -ForegroundColor Cyan
    Write-Host "Out : $outputCsv " -ForegroundColor Green
} else {
    Write-Host "`nAucune donnée XML valide n'a pu être extraite." -ForegroundColor Yellow
}
