# Script pour changer l'icône d'un dossier avec la dernière image téléchargée
# Nécessite les droits d'administration pour certaines opérations

param(
    [string]$FolderPath = "C:\Users\33660\Desktop"
)

Write-Host "=== Changement d'icône de dossier ===" -ForegroundColor Cyan
Write-Host ""

# 1. Trouver la dernière image dans les Téléchargements
$downloadsPath = [Environment]::GetFolderPath("UserProfile") + "\Downloads"
Write-Host "Recherche de la dernière image dans: $downloadsPath" -ForegroundColor Yellow

$imageExtensions = @("*.jpg", "*.jpeg", "*.png", "*.bmp", "*.gif", "*.webp")
$latestImage = Get-ChildItem -Path $downloadsPath -Include $imageExtensions -File -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $latestImage) {
    Write-Host "Aucune image trouvée dans les Téléchargements!" -ForegroundColor Red
    exit
}

Write-Host "Image trouvée: $($latestImage.Name)" -ForegroundColor Green
Write-Host "Taille: $([math]::Round($latestImage.Length / 1KB, 2)) KB" -ForegroundColor Gray

# 2. Créer un fichier .ico à partir de l'image
$icoPath = Join-Path $FolderPath "folder_icon.ico"
Write-Host ""
Write-Host "Conversion de l'image en .ico..." -ForegroundColor Yellow

# Utiliser .NET pour convertir l'image
Add-Type -AssemblyName System.Drawing

try {
    $img = [System.Drawing.Image]::FromFile($latestImage.FullName)
    
    # Créer une icône de 256x256 (taille optimale pour Windows)
    $size = New-Object System.Drawing.Size(256, 256)
    $bitmap = New-Object System.Drawing.Bitmap($size.Width, $size.Height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    
    # Redimensionner et dessiner l'image
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.DrawImage($img, 0, 0, $size.Width, $size.Height)
    
    # Sauvegarder comme icône
    $icon = [System.Drawing.Icon]::FromHandle($bitmap.GetHicon())
    $fileStream = [System.IO.FileStream]::new($icoPath, [System.IO.FileMode]::Create)
    $icon.Save($fileStream)
    $fileStream.Close()
    
    # Nettoyer
    $graphics.Dispose()
    $bitmap.Dispose()
    $img.Dispose()
    $icon.Dispose()
    
    Write-Host "Fichier .ico créé: $icoPath" -ForegroundColor Green
    
} catch {
    Write-Host "Erreur lors de la conversion: $_" -ForegroundColor Red
    exit
}

# 3. Créer le fichier desktop.ini pour personnaliser le dossier
Write-Host ""
Write-Host "Configuration de l'icône du dossier..." -ForegroundColor Yellow

$desktopIniPath = Join-Path $FolderPath "desktop.ini"
$desktopIniContent = @"
[.ShellClassInfo]
IconResource=folder_icon.ico,0
[ViewState]
Mode=
Vid=
FolderType=Generic
"@

# Écrire le fichier desktop.ini
Set-Content -Path $desktopIniPath -Value $desktopIniContent -Encoding ASCII -Force

# 4. Appliquer les attributs système et caché
Set-ItemProperty -Path $desktopIniPath -Name Attributes -Value ([System.IO.FileAttributes]::System -bor [System.IO.FileAttributes]::Hidden)
Set-ItemProperty -Path $FolderPath -Name Attributes -Value ([System.IO.FileAttributes]::ReadOnly)

Write-Host "Icône appliquée avec succès!" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT: Pour voir les changements:" -ForegroundColor Cyan
Write-Host "1. Appuyez sur F5 pour rafraîchir l'Explorateur" -ForegroundColor White
Write-Host "2. Ou fermez et rouvrez l'Explorateur de fichiers" -ForegroundColor White
Write-Host ""
Write-Host "Note: Les fichiers 'desktop.ini' et 'folder_icon.ico' sont cachés." -ForegroundColor Gray
Write-Host "Ne les supprimez pas, sinon l'icône disparaîtra." -ForegroundColor Gray
