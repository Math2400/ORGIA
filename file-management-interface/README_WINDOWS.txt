SÉLECTEUR DE DOCUMENTS — WINDOWS 11

Cette version utilise uniquement PowerShell et Windows Forms, déjà inclus dans Windows.

1. Téléchargez et décompressez le ZIP.
2. Double-cliquez sur lancer_picker.bat.
3. Le terminal reste caché et l'application tourne en arrière-plan.
4. Appuyez sur Ctrl+M pour afficher la fenêtre au premier plan.
5. Fermez la fenêtre pour la masquer ; elle reste disponible avec Ctrl+M.
6. Cochez vos fichiers, cliquez sur « Copier les fichiers », puis utilisez Ctrl+V.
7. Pour quitter complètement : clic droit sur l'icône File Picker dans la zone de notification, puis « Quitter ».

Dossier initial :
C:\Users\33660\Desktop\Storage\Personnel\NEW VAULT\1. NEW_VAULT

L'arborescence est chargée progressivement lorsque vous ouvrez les dossiers. Les fichiers Markdown, PDF, texte, HTML, images, vidéo, audio, Word, Excel et présentations sont pris en charge.

RÈGLE DE FILTRAGE
Un fichier est ignoré uniquement si son nom sans extension est identique, sans tenir compte des majuscules, au nom de son dossier parent. Exemple : cours\cours.pdf est masqué, mais cours\cours-v2.pdf est affiché.

La copie place de vrais fichiers dans le presse-papiers Windows, pas du texte ni des chemins. Les fichiers source ne sont jamais modifiés.

RACCOURCI AU DÉMARRAGE
Pour lancer automatiquement l'outil avec Windows, appuyez sur Win+R, tapez shell:startup, puis placez-y un raccourci vers lancer_picker.bat.
