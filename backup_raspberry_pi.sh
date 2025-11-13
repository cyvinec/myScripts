#!/usr/bin/env bash
# ============================================================
# Script de sauvegarde vers une image montée temporairement
# Auteur : CY 😊 
# version corrigée et optimisée avec compression
# Avec l'aide de GPT-5 le 13 nov 2025  
# ============================================================

# Capture du temps de démarrage
start_time=$(date +%s%3N)

# Répertoire temporaire de montage
BACKUP_TEMP_DIR='/mnt/.tempdir'

# Chargement des fonctions utilitaires
#source "$(dirname "$0")/myfunctions.sh"
#
###############################################################
DEBUG_ME=false
MYNAME=$(basename $0)
#
# Define some fancy colors only if connected to a terminal.
# Thus output to file is no more cluttered
#
    [ -t 1 ] && {
            RED=$(tput setaf 1)
            GREEN=$(tput setaf 2)
            YELLOW=$(tput setaf 3)
            BLUE=$(tput setaf 4)
            MAGENTA=$(tput setaf 5)
            CYAN=$(tput setaf 6)
            LIGHTGRAY=$(tput setaf 7)
            GRAY=$(tput setaf 8)
            WHITE=$(tput setaf 15)
            RESET=$(tput setaf 9)
            BOLD=$(tput bold)
            NOATT=$(tput sgr0)
    }||{
            RED=""
            GREEN=""
            YELLOW=""
            BLUE=""
            MAGENTA=""
            CYAN=""
            WHITE=""
            RESET=""
            BOLD=""
            NOATT=""
    }

# Echos traces with yellow text to distinguish from other output
trace () {
    echo -e "${!2:-$YELLOW}${1}${NOATT}"
}


# Echos an error string in red text and exit
fatal() {
    echo "${RED}[FATAL] $@ ${NOATT}" >&2
    exit 1
}


###############################################################
#
# Variables principales
SOURCE_DIR="$1"
DEST_DIR="$2"
VERBOSE=false
COMPRESS=false
ENCRYPT=false
SHOW_HELP=false
DATE=$(date +%A-%d-%m-%Y)
HOSTNAME=$(hostname -s)

# Lecture des options supplémentaires
if [[ $# -ge 2 ]]; then shift 2; SHIFTED=true; fi

while getopts dvzeh flag; do
    case "${flag}" in
        -d|d) DEBUG_ME=true ;;
        -v|v) VERBOSE=true ;;
        -z|z) COMPRESS=true ;;
        -e|e) ENCRYPT=true ;;
        -h|h) SHOW_HELP=true;;
        *) [[ ${SHIFTED:-false} ]] && trace "⚠️ Option inconnue ignorée : $opt" YELLOW ;;
    esac
done

# Vérification du nombre minimal d’arguments et help
if ( $SHOW_HELP || [ ! "$SOURCE_DIR" ] || [ ! "$DEST_DIR" ]); then
    MESSAGE_COLOR=LIGHTGRAY

    if ( [ ! "$SOURCE_DIR" ] || [ ! "$DEST_DIR" ]); then trace "-------------------------------------------------------------------------" ; fi

    if ( [ ! "$SOURCE_DIR" ] ); then trace "    ⚠️ Répertoire à sauvegarder manquant" RED; fi
    if ( [ ! "$DEST_DIR" ]); then trace "    ⚠️ Destination du fichier image manquant" RED; fi

  
    trace "-------------------------------------------------------------------------" 
    trace "  Script de sauvegarde vers une image montée temporairement" $MESSAGE_COLOR
    trace "  version corrigée et optimisée avec compression avec l'aide de GPT-5" $MESSAGE_COLOR
    trace "-------------------------------------------------------------------------" 
    echo ""      
    trace "         Deux arguments sont nécessaires" $MESSAGE_COLOR
    echo ""
    trace "         1️⃣  Répertoire à sauvegarder" $MESSAGE_COLOR
    trace "         2️⃣  Destination du fichier image" $MESSAGE_COLOR
    echo "" 
    trace "-------------------------------------------------------------------------" 
    echo ""
    trace "  Options" $MESSAGE_COLOR
    trace "    -v, v      details des operations de copie" $MESSAGE_COLOR
    trace "    -z, z      activée la compression" $MESSAGE_COLOR
    trace "    -e, e      activée l'encryption" $MESSAGE_COLOR
    trace "    -h, h      afficher cette aide et quitter" $MESSAGE_COLOR
    trace "               ------------------------------------------------------------"
    trace "               *** ATTENTION pour encryption ***" $MESSAGE_COLOR
    trace "               Pour Cron ou Script, ceci est necessaire" $MESSAGE_COLOR
    trace "               ------------------------------------------------------------"
    trace "               sudo nano /root/.backup_pass" $MESSAGE_COLOR
    trace "               Mets dedans un mot de passe fort, ex. généré ainsi:" $MESSAGE_COLOR
    trace "                   openssl rand -base64 32" $MESSAGE_COLOR
    trace "               sudo chmod 400 /root/.backup_pass" $MESSAGE_COLOR
    trace "               ------------------------------------------------------------"
    trace "               pour déchiffrer automatiquement" $MESSAGE_COLOR
    trace "               ------------------------------------------------------------"
    trace '               openssl enc -aes-256-cbc -d -pbkdf2 \' $MESSAGE_COLOR
    trace '                   -in "${IMAGE}.enc" -out "${IMAGE}" \' $MESSAGE_COLOR
    trace '                   -pass file:/root/.backup_pass' $MESSAGE_COLOR
    echo ""
    trace "-------------------------------------------------------------------------"
    echo ""
    trace "  Exemple : sudo bash $0 /home/$USER /mnt/backup -v -z" $MESSAGE_COLOR
    echo ""
    trace "-------------------------------------------------------------------------"
    exit 0
fi

# Fonction de nettoyage (appelée automatiquement à la fin ou en cas d’erreur)
cleanup() {
    trace '=== 🧹 Nettoyage...' WHITE
    if mountpoint -q "$BACKUP_TEMP_DIR"; then
        umount "$BACKUP_TEMP_DIR"
    fi
    shopt -u dotglob
    if [[ -n "$BACKUP_TEMP_DIR" && -d "$BACKUP_TEMP_DIR" ]]; then
        rm -rf "$BACKUP_TEMP_DIR"
    fi
    trace '=== ✅ Nettoyage terminé.' WHITE
}

# Trap 
trap cleanup EXIT SIGTERM
trap 'echo "${RED}[ERROR] Occurred on line $LINENO: $BASH_COMMAND (exit code: $?)${NOATT}" && exit 1' ERR
if $DEBUG_ME; then trap 'echo "${WHITE}[DEBUG] running: $BASH_COMMAND${NOATT}"' DEBUG; fi

# Verification pour etre sur que le password est disponible
if $ENCRYPT && [[ ! -t 1 && ! -f /root/.backup_pass ]]; then
    ENCRYPT=false
    trace "⚠️ Encryption ignorée, mot de passe non existant" YELLOW
fi

# Définition du chemin final de l’image
[[ "$DEST_DIR" != */ ]] && IMAGE="${DEST_DIR}/${HOSTNAME}-${DATE}.img" || IMAGE="${DEST_DIR}${HOSTNAME}-${DATE}.img"
[[ "$SOURCE_DIR" != */ ]] && SOURCE_DIR="${SOURCE_DIR}/"

# Bloc et arguments de copie
BLOCKSIZE='1M'
[[ "$VERBOSE" == true ]] && CP_ARGS="-rLv" || CP_ARGS="-rL"

# Taille du dossier à sauvegarder (en Mo)
trace "=== Calcul de la taille de ${SOURCE_DIR} ..."
#SIZE=$(du -smL "$SOURCE_DIR" | cut -f1)
#SIZE=$((SIZE + SIZE / 5)) # marge de 10 %
# Plus fiable que du on va voir
SIZE=$(rsync -aL --dry-run --stats ${SOURCE_DIR} ${SOURCE_DIR} | \
        grep "Total transferred file size"   | tr -d ','   | \
        awk '{bytes=$5; mb=bytes/1024/1024; if (mb<1) print 1; else printf "%.0f\n", mb*1.15}')

# Vérification de l’espace disque disponible
AVAIL=$(df -m "$DEST_DIR" | awk 'NR==2 {print $4}')
if (( AVAIL < SIZE )); then
    fatal "❌ Pas assez d’espace sur $DEST_DIR (disponible: ${AVAIL}M, requis: ${SIZE}M)"
    exit 1
fi

trace "=== 💾 Création de l’image ${IMAGE} (${SIZE} Mo environ)..."

# Création du fichier image
dd if=/dev/zero of="${IMAGE}" bs=${BLOCKSIZE} count=${SIZE} status=none || {
    fatal "Erreur lors de la création de l’image ${IMAGE}"
    exit 1
}

mkfs.vfat -n 'BACKUP' "${IMAGE}" > /dev/null 2>&1 || {
    fatal "Erreur lors du formatage de l’image ${IMAGE}"
    exit 1
}

# Montage temporaire
mkdir -p "$BACKUP_TEMP_DIR"
if ! mount -o loop "${IMAGE}" "$BACKUP_TEMP_DIR"; then
    fatal "Erreur : impossible de monter ${IMAGE}"
    exit 1
fi

# Copie des fichiers
trace "=== 📁 Copie des fichiers depuis ${SOURCE_DIR} ..."
shopt -s dotglob
cp $CP_ARGS "${SOURCE_DIR}"* "$BACKUP_TEMP_DIR"
cp_status=$?
sync

# Vérification de la copie
if [ $cp_status -eq 0 ]; then
    trace "=== ✅ Copie terminée avec succès." GREEN
else
    fatal "=== ❌ Erreur pendant la copie des fichiers."
    exit 1
fi

# Option de compression
if [ "$COMPRESS" = true ]; then
    trace "=== 🌀 Compression de l’image ${IMAGE} ..."
    gzip -f -9 "${IMAGE}"
    if [ $? -eq 0 ]; then
        trace "=== ✅ Image compressée : ${IMAGE}.gz" GREEN
        IMAGE="${IMAGE}.gz"
    else
        fatal "=== ❌ Erreur lors de la compression de ${IMAGE}"
        exit 1
    fi
fi

# Chiffrement (si -e)
if [ "$ENCRYPT" = true ]; then
    trace "=== 🔐 Chiffrement de l’image ${IMAGE} ..."
    openssl enc -aes-256-cbc -salt -pbkdf2 -in "${IMAGE}" -out "${IMAGE}.enc" -pass "file:/root/.backup_pass" || fatal "Erreur de chiffrement"
    rm -f "${IMAGE}"
    IMAGE="${IMAGE}.enc"
    trace "=== ✅ Image chiffrée : ${IMAGE}" GREEN
fi

# Capture du temps de fin
end_time=$(date +%s%3N)
elapsed=$((end_time - start_time))

# Affichage du temps total
if (( elapsed > 60000 )); then
    minutes=$((elapsed / 60000))
    seconds=$(((elapsed / 1000) % 60))
    trace "=== ⏳ Temps écoulé : $minutes min $seconds s" WHITE
elif (( elapsed > 1000 )); then
    seconds=$((elapsed / 1000))
    trace "=== ⏳ Temps écoulé : $seconds s" WHITE
else
    trace "=== ⏳ Temps écoulé : ${elapsed} ms" WHITE
fi

exit 0