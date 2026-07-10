@echo off
color 0A
title SYNCHRONISATION GITHUB - CONFIGURATION AVANCEE
echo ====================================================================
echo     SYNCHRONISATION GITHUB - CONFIGURATION INTERACTIVE
echo ====================================================================
echo.

REM === DEMANDER L'URL GITHUB ===
echo [ETAPE 1/5] URL du repository GitHub
echo Exemple: https://github.com/Math2400/ORGIA.git
echo.
set /p GITHUB_URL="Entrez l'URL GitHub: "

if "%GITHUB_URL%"=="" (
    echo.
    color 0C
    echo [ERREUR] URL GitHub non fournie !
    pause
    exit /b 1
)

echo.
echo ====================================================================

REM === DEMANDER LE REPERTOIRE LOCAL ===
echo [ETAPE 2/5] Repertoire local a synchroniser
echo Exemple: C:\Users\33660\Desktop\ORGIA
echo.
set /p LOCAL_DIR="Entrez le chemin complet du repertoire: "

if "%LOCAL_DIR%"=="" (
    echo.
    color 0C
    echo [ERREUR] Repertoire local non fourni !
    pause
    exit /b 1
)

REM === VERIFICATION DU REPERTOIRE ===
if not exist "%LOCAL_DIR%" (
    echo.
    color 0C
    echo [ERREUR] Le repertoire n'existe pas: %LOCAL_DIR%
    pause
    exit /b 1
)

echo.
echo ====================================================================

REM === CHOISIR LE MODE DE SYNCHRONISATION ===
echo [ETAPE 3/5] Mode de synchronisation
echo.
echo 1. INTELLIGENT - Synchronisation bidirectionnelle automatique (recommande)
echo 2. LOCAL ^>^> GITHUB - Toujours ecraser GitHub avec le contenu local
echo 3. GITHUB ^>^> LOCAL - Toujours ecraser le local avec GitHub
echo.
set /p SYNC_MODE="Choisissez le mode (1/2/3): "

if "%SYNC_MODE%"=="" set SYNC_MODE=1

if not "%SYNC_MODE%"=="1" if not "%SYNC_MODE%"=="2" if not "%SYNC_MODE%"=="3" (
    echo.
    color 0C
    echo [ERREUR] Mode invalide ! Valeurs acceptees: 1, 2 ou 3
    pause
    exit /b 1
)

echo.
echo ====================================================================

REM === CHOISIR LE TYPE D'EXECUTION ===
echo [ETAPE 4/5] Type d'execution
echo.
echo 1. UNIQUE - Synchronisation une seule fois puis fin du script
echo 2. PERPETUEL - Synchronisation continue en boucle infinie
echo.
set /p EXEC_TYPE="Choisissez le type (1/2): "

if "%EXEC_TYPE%"=="" set EXEC_TYPE=1

if not "%EXEC_TYPE%"=="1" if not "%EXEC_TYPE%"=="2" (
    echo.
    color 0C
    echo [ERREUR] Type invalide ! Valeurs acceptees: 1 ou 2
    pause
    exit /b 1
)

REM === CONFIGURER LA FREQUENCE SI MODE PERPETUEL ===
set SYNC_INTERVAL=60
if "%EXEC_TYPE%"=="2" (
    echo.
    echo ====================================================================
    echo [ETAPE 5/5] Frequence de synchronisation (mode perpetuel)
    echo.
    echo Combien de secondes attendre entre chaque synchronisation ?
    echo Exemples: 1 (toutes les secondes), 5, 10, 30, 60 (toutes les minutes)
    echo.
    set /p SYNC_INTERVAL="Intervalle en secondes (defaut: 60): "
    
    if "%SYNC_INTERVAL%"=="" set SYNC_INTERVAL=60
    
    REM Verification que c'est un nombre
    echo %SYNC_INTERVAL%| findstr /r "^[0-9][0-9]*$" >nul
    if errorlevel 1 (
        echo.
        color 0C
        echo [ERREUR] Intervalle invalide ! Doit etre un nombre entier positif
        pause
        exit /b 1
    )
) else (
    echo.
    echo [ETAPE 5/5] Configuration terminee (mode unique)
)

echo.
echo ====================================================================
echo     RECAPITULATIF DE LA CONFIGURATION
echo ====================================================================
echo GitHub URL: %GITHUB_URL%
echo Repertoire local: %LOCAL_DIR%
echo.
if "%SYNC_MODE%"=="1" echo Mode: INTELLIGENT (synchronisation bidirectionnelle)
if "%SYNC_MODE%"=="2" echo Mode: LOCAL ^>^> GITHUB (force push)
if "%SYNC_MODE%"=="3" echo Mode: GITHUB ^>^> LOCAL (force pull)
echo.
if "%EXEC_TYPE%"=="1" echo Type: EXECUTION UNIQUE
if "%EXEC_TYPE%"=="2" echo Type: EXECUTION PERPETUELLE (intervalle: %SYNC_INTERVAL% secondes)
echo ====================================================================
echo.
set /p CONFIRM="Confirmer et demarrer la synchronisation ? (O/N): "

if /i not "%CONFIRM%"=="O" (
    echo.
    echo Operation annulee.
    pause
    exit /b 0
)

echo.
echo ====================================================================
echo     DEMARRAGE DE LA SYNCHRONISATION
echo ====================================================================
if "%EXEC_TYPE%"=="2" (
    echo.
    color 0E
    echo [MODE PERPETUEL] Le terminal restera ouvert et effectuera
    echo des synchronisations toutes les %SYNC_INTERVAL% secondes.
    echo Appuyez sur Ctrl+C pour arreter la synchronisation.
    echo.
    timeout /t 3 /nobreak >nul
)
echo.

REM === COMPTEUR DE SYNCHRONISATIONS ===
set SYNC_COUNT=0

:SYNC_LOOP
set /a SYNC_COUNT+=1

if "%EXEC_TYPE%"=="2" (
    color 0B
    title SYNC GITHUB - Iteration %SYNC_COUNT% - Prochain sync dans %SYNC_INTERVAL%s
    echo.
    echo ====================================================================
    echo     SYNCHRONISATION #%SYNC_COUNT% - %date% %time%
    echo ====================================================================
) else (
    title SYNC GITHUB - Synchronisation en cours
)

cd /d "%LOCAL_DIR%"

REM === VERIFIER SI C'EST UN REPO GIT ===
if not exist ".git" (
    echo.
    echo [INFO] Pas de repository Git detecte. Initialisation...
    git init
    git branch -M main
    git remote add origin %GITHUB_URL%
    echo [OK] Repository Git initialise
    echo.
)

REM === VERIFIER LA REMOTE ===
git remote -v > nul 2>&1
if errorlevel 1 (
    echo [INFO] Configuration de la remote...
    git remote add origin %GITHUB_URL%
) else (
    REM Verifier si origin existe
    git remote get-url origin >nul 2>&1
    if errorlevel 1 (
        git remote add origin %GITHUB_URL%
    ) else (
        echo [INFO] Mise a jour de la remote...
        git remote set-url origin %GITHUB_URL%
    )
)

REM === RENOMMER LA BRANCHE LOCALE EN main SI NECESSAIRE ===
for /f "delims=" %%B in ('git branch --show-current 2^>nul') do set CURRENT_BRANCH=%%B
if /i not "%CURRENT_BRANCH%"=="main" (
    echo [INFO] Renommage de la branche en 'main'...
    git branch -M main
)

echo.

REM === BRANCHEMENT SELON LE MODE CHOISI ===
if "%SYNC_MODE%"=="1" goto MODE_INTELLIGENT
if "%SYNC_MODE%"=="2" goto MODE_FORCE_PUSH
if "%SYNC_MODE%"=="3" goto MODE_FORCE_PULL

REM ====================================================================
REM    MODE 1: SYNCHRONISATION INTELLIGENTE (BIDIRECTIONNELLE)
REM ====================================================================
:MODE_INTELLIGENT
echo --------------------------------------------------------------------
echo [MODE INTELLIGENT] Synchronisation bidirectionnelle
echo --------------------------------------------------------------------

echo [1/5] Recuperation de l'etat actuel de GitHub...
git fetch origin main 2>nul

if errorlevel 1 (
    echo [WARNING] Branche main inexistante sur GitHub
    echo [ACTION] Premier push vers GitHub...
    goto FIRST_PUSH
)

echo [OK] Etat GitHub recupere

echo.
echo [2/5] Verification des differences...
git status --short

echo.
echo [3/5] Ajout des modifications locales...
git add .
git commit -m "Sync intelligent #%SYNC_COUNT% - %date% %time%" 2>nul

if errorlevel 1 (
    echo [INFO] Aucune modification locale a commiter
) else (
    echo [OK] Modifications locales commitees
)

echo.
echo [4/5] Fusion intelligente avec GitHub...
git pull origin main --no-rebase --allow-unrelated-histories 2>nul

if errorlevel 1 (
    echo.
    color 0E
    echo [CONFLIT DETECTE] Resolution necessaire...
    echo.
    
    REM En mode perpetuel, on applique une strategie automatique
    if "%EXEC_TYPE%"=="2" (
        echo [MODE PERPETUEL] Resolution automatique: version locale conservee
        git checkout --ours .
        git add .
        git commit -m "Resolution conflit auto - version locale - #%SYNC_COUNT%"
        goto PUSH_FORCE_CONFLICT
    )
    
    REM En mode unique, on demande a l'utilisateur
    echo Options de resolution:
    echo 1. Garder la version LOCALE (ecraser GitHub)
    echo 2. Garder la version GITHUB (ecraser local)
    echo 3. Resoudre MANUELLEMENT dans le terminal
    echo.
    set /p CONFLICT_CHOICE="Votre choix (1/2/3): "

    if "%CONFLICT_CHOICE%"=="1" (
        echo [ACTION] Conservation de la version locale...
        git checkout --ours .
        git add .
        git commit -m "Resolution conflit - version locale - #%SYNC_COUNT%"
        goto PUSH_FORCE_CONFLICT
    )

    if "%CONFLICT_CHOICE%"=="2" (
        echo [ACTION] Conservation de la version GitHub...
        git reset --hard origin/main
        git clean -fd
        echo [OK] Local aligne sur GitHub
        goto SYNC_COMPLETE
    )

    if "%CONFLICT_CHOICE%"=="3" (
        echo.
        echo [MODE MANUEL] Resolvez les conflits puis executez:
        echo   git add .
        echo   git commit -m "Resolution manuelle"
        echo   git push origin main
        echo.
        echo Une fois termine, appuyez sur une touche pour continuer...
        pause
        goto SYNC_COMPLETE
    )

    echo [ERREUR] Choix invalide, skip de cette synchronisation
    goto SYNC_COMPLETE
)

echo [OK] Fusion reussie

echo.
echo [5/5] Envoi vers GitHub...
git push origin main 2>nul

if errorlevel 1 (
    color 0C
    echo [ERREUR] Push echoue
    if "%EXEC_TYPE%"=="1" (
        pause
        exit /b 1
    )
    echo [MODE PERPETUEL] Nouvelle tentative au prochain cycle...
    goto SYNC_COMPLETE
)

echo [OK] Push reussi
goto SYNC_COMPLETE

:PUSH_FORCE_CONFLICT
echo.
echo [5/5] Envoi force vers GitHub (resolution conflit)...
git push origin main --force 2>nul

if errorlevel 1 (
    color 0C
    echo [ERREUR] Force push echoue
    if "%EXEC_TYPE%"=="1" (
        pause
        exit /b 1
    )
)

echo [OK] Force push reussi
goto SYNC_COMPLETE

REM ====================================================================
REM    MODE 2: FORCE PUSH (LOCAL >> GITHUB)
REM ====================================================================
:MODE_FORCE_PUSH
echo --------------------------------------------------------------------
echo [MODE FORCE PUSH] Ecrasement de GitHub avec le contenu local
echo --------------------------------------------------------------------

echo [1/3] Ajout de tous les fichiers locaux...
git add .

echo [2/3] Creation du commit...
git commit -m "Force push #%SYNC_COUNT% - %date% %time%" 2>nul

if errorlevel 1 (
    echo [INFO] Aucune modification a commiter
) else (
    echo [OK] Commit cree
)

echo [3/3] Envoi force vers GitHub (ecrasement)...
git push origin main --force 2>nul

if errorlevel 1 (
    color 0C
    echo [ERREUR] Force push echoue
    if "%EXEC_TYPE%"=="1" (
        pause
        exit /b 1
    )
    echo [MODE PERPETUEL] Nouvelle tentative au prochain cycle...
    goto SYNC_COMPLETE
)

echo [OK] GitHub ecrase avec le contenu local
goto SYNC_COMPLETE

REM ====================================================================
REM    MODE 3: FORCE PULL (GITHUB >> LOCAL)
REM ====================================================================
:MODE_FORCE_PULL
echo --------------------------------------------------------------------
echo [MODE FORCE PULL] Ecrasement du local avec le contenu GitHub
echo --------------------------------------------------------------------

echo [1/3] Recuperation de GitHub...
git fetch origin main 2>nul

if errorlevel 1 (
    color 0C
    echo [ERREUR] Fetch echoue
    if "%EXEC_TYPE%"=="1" (
        pause
        exit /b 1
    )
    echo [MODE PERPETUEL] Nouvelle tentative au prochain cycle...
    goto SYNC_COMPLETE
)

echo [OK] Fetch reussi

echo [2/3] Reset du local vers GitHub...
git reset --hard origin/main 2>nul

if errorlevel 1 (
    color 0C
    echo [ERREUR] Reset echoue
    if "%EXEC_TYPE%"=="1" (
        pause
        exit /b 1
    )
    goto SYNC_COMPLETE
)

echo [3/3] Nettoyage des fichiers non suivis...
git clean -fd 2>nul

echo [OK] Local ecrase avec le contenu GitHub
goto SYNC_COMPLETE

REM ====================================================================
REM    PREMIER PUSH (INITIALISATION)
REM ====================================================================
:FIRST_PUSH
echo.
echo --------------------------------------------------------------------
echo [PREMIER PUSH] Initialisation du repository sur GitHub
echo --------------------------------------------------------------------

if not exist "README.md" (
    echo # ORGIA > README.md
    echo Systeme d'orchestration d'agents IA >> README.md
    echo [INFO] README.md cree
)

echo [1/2] Ajout de tous les fichiers...
git add .

echo [2/2] Premier commit et push...
git commit -m "Premier commit ORGIA - %date% %time%" 2>nul
git push -u origin main 2>nul

if errorlevel 1 (
    color 0C
    echo [ERREUR] Premier push echoue
    echo Verifiez vos droits d'acces et la connexion
    if "%EXEC_TYPE%"=="1" (
        pause
        exit /b 1
    )
    goto SYNC_COMPLETE
)

echo [OK] Premier push reussi
goto SYNC_COMPLETE

REM ====================================================================
REM    FIN DE SYNCHRONISATION
REM ====================================================================
:SYNC_COMPLETE
color 0A
echo.
echo ====================================================================
echo     SYNCHRONISATION #%SYNC_COUNT% TERMINEE
echo ====================================================================
echo Heure: %time%
echo ====================================================================

REM === BOUCLE OU FIN ===
if "%EXEC_TYPE%"=="2" (
    echo.
    echo [ATTENTE] Prochaine synchronisation dans %SYNC_INTERVAL% secondes...
    echo Appuyez sur Ctrl+C pour arreter
    echo.
    timeout /t %SYNC_INTERVAL% /nobreak
    goto SYNC_LOOP
) else (
    echo.
    pause
    exit /b 0
)
