@echo off
setlocal
cd /d "%~dp0"
set "ROOT=C:\Users\33660\Desktop\Storage\Personnel\NEW VAULT\1. NEW_VAULT"
echo ========================================
echo File Picker - mode diagnostic
echo Dossier : %ROOT%
echo Le terminal restera ouvert pour afficher les erreurs.
echo ========================================
echo.
start "File Picker" /min "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "%~dp0fichier_picker.ps1" -Root "%ROOT%"
endlocal
