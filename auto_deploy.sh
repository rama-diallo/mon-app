#!/bin/bash

# ============================================================
#  auto_deploy.sh — Script de déploiement automatique
#  TP DevOps — UCAD Département Informatique 2025-2026
# ============================================================

# ---------- Couleurs ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ---------- Fichier de log ----------
LOG_FILE="deploy_$(date +%Y%m%d).log"

# ---------------------------------------------------------------
# AMÉLIORATION 2 : Fonction de log avec horodatage
# Usage : log "INFO" "message"  /  log "ERROR" "message"
# ---------------------------------------------------------------
log() {
    local LEVEL="$1"
    local MESSAGE="$2"
    local TIMESTAMP
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    local ENTRY="[$TIMESTAMP] [$LEVEL] $MESSAGE"

    # Affichage coloré dans le terminal
    case "$LEVEL" in
        INFO)  echo -e "${GREEN}${ENTRY}${NC}" ;;
        WARN)  echo -e "${YELLOW}${ENTRY}${NC}" ;;
        ERROR) echo -e "${RED}${ENTRY}${NC}" ;;
        STEP)  echo -e "${BLUE}${ENTRY}${NC}" ;;
        *)     echo -e "${ENTRY}" ;;
    esac

    # Écriture dans le fichier de log
    echo "$ENTRY" >> "$LOG_FILE"
}

# ---------------------------------------------------------------
# AMÉLIORATION 1 : Accepter l'URL du dépôt en paramètre
# Usage : ./auto_deploy.sh <REPO_URL> [NOM_DOSSIER]
# ---------------------------------------------------------------
if [ -z "$1" ]; then
    log "ERROR" "Usage : $0 <URL_du_depot> [nom_dossier]"
    log "ERROR" "Exemple : $0 https://github.com/rama-diallo/mon-app.git mon_app"
    exit 1
fi

REPO_URL="$1"
PROJECT_DIR="${2:-mon_app}"   # Nom par défaut si non fourni

# ---------------------------------------------------------------
# Début du déploiement
# ---------------------------------------------------------------
echo ""
log "STEP" "=== Déploiement automatique ==="
log "INFO" "Dépôt    : $REPO_URL"
log "INFO" "Dossier  : $PROJECT_DIR"
log "INFO" "Log      : $LOG_FILE"
echo ""

# ---------------------------------------------------------------
# Étape 1 : Vérification des dépendances
# ---------------------------------------------------------------
log "STEP" "--- Étape 1 : Vérification des dépendances ---"

check_command() {
    local CMD="$1"
    if command -v "$CMD" > /dev/null 2>&1; then
        log "INFO" "$CMD est installé ($(command -v $CMD))"
    else
        log "ERROR" "$CMD est requis mais non installé. Abandon."
        exit 1
    fi
}

check_command git
check_command node
check_command npm

# ---------------------------------------------------------------
# Étape 2 : Clonage ou mise à jour du dépôt
# ---------------------------------------------------------------
log "STEP" "--- Étape 2 : Récupération du code source ---"

if [ -d "$PROJECT_DIR" ]; then
    log "WARN" "Le dossier '$PROJECT_DIR' existe déjà. Mise à jour (git pull)..."
    cd "$PROJECT_DIR" || { log "ERROR" "Impossible d'entrer dans $PROJECT_DIR"; exit 1; }
    git pull >> "../$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then
        log "ERROR" "Échec du git pull."
        exit 1
    fi
    log "INFO" "Mise à jour réussie."
else
    log "INFO" "Clonage du dépôt..."
    git clone "$REPO_URL" "$PROJECT_DIR" >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then
        log "ERROR" "Échec du clonage. Vérifiez l'URL : $REPO_URL"
        exit 1
    fi
    cd "$PROJECT_DIR" || { log "ERROR" "Impossible d'entrer dans $PROJECT_DIR"; exit 1; }
    log "INFO" "Clonage réussi."
fi

# ---------------------------------------------------------------
# Étape 3 : Installation des dépendances
# ---------------------------------------------------------------
log "STEP" "--- Étape 3 : Installation des dépendances ---"
npm install >> "../$LOG_FILE" 2>&1
if [ $? -ne 0 ]; then
    log "ERROR" "Échec de npm install."
    exit 1
fi
log "INFO" "Dépendances installées avec succès."

# ---------------------------------------------------------------
# Étape 4 : Lancement des tests
# ---------------------------------------------------------------
log "STEP" "--- Étape 4 : Lancement des tests unitaires ---"
npm test >> "../$LOG_FILE" 2>&1

if [ $? -eq 0 ]; then
    log "INFO" "Tous les tests sont passés ✔"
else
    log "ERROR" "Échec des tests. Déploiement interrompu."
    exit 1
fi

# ---------------------------------------------------------------
# AMÉLIORATION 3 : Lancer l'application en arrière-plan + sauvegarder le PID
# ---------------------------------------------------------------
log "STEP" "--- Étape 5 : Démarrage de l'application en arrière-plan ---"

PID_FILE="../${PROJECT_DIR}.pid"

# Si une instance tourne déjà, on l'arrête proprement
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        log "WARN" "Instance déjà en cours (PID $OLD_PID). Arrêt..."
        kill "$OLD_PID"
        sleep 1
    fi
    rm -f "$PID_FILE"
fi

# Démarrage en arrière-plan, stdout/stderr redirigés vers le log
npm start >> "../$LOG_FILE" 2>&1 &
APP_PID=$!

# Sauvegarde du PID
echo "$APP_PID" > "$PID_FILE"
log "INFO" "Application démarrée en arrière-plan (PID : $APP_PID)"
log "INFO" "PID sauvegardé dans : $PID_FILE"

echo ""
log "STEP" "=== Déploiement terminé avec succès ! ==="
log "INFO" "Consultez '$LOG_FILE' pour l'historique complet."
echo ""