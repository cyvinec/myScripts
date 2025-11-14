#!/usr/bin/env bash
# ============================================================
# Backup Script to a Temporary Mounted Image
# Script de sauvegarde vers une image montée temporairement
#
# Author / Auteur : CY 😊 
# Updated with GPT-5.1 — 14 Nov 2025
# Mis à jour avec GPT-5.1 — 14 nov 2025
# ============================================================

###############################################################
# === Language Selection / Sélection de la langue ============
###############################################################
# Possible: en, fr
LANG_CODE="fr"

# Capture du temps de démarrage
start_time=$(date +%s%3N)

###############################################################
# === Multilingual Message Dictionaries / Dictionnaires ======
###############################################################

# ----- French / Français -----
declare -A MSG_fr=(
    [FATAL]="❌ Erreur fatale"
    [UNKNOWN_OPTION]="⚠️ Option inconnue ignorée"
    [PASS_PROMPT]="😵 Mot de passe : "
    [DECRYPT_OK]="✅ Déchiffrement terminé avec succès"
    [DECRYPT_FAIL]="❌ Erreur dans le déchiffrement"
    [MISSING_SRC]="Répertoire à sauvegarder manquant"
    [MISSING_DEST]="Destination du fichier image manquante"
    [HELP_TITLE]="Script de sauvegarde vers une image montée temporairement"
    [HELP_USAGE]="Deux arguments sont nécessaires"
    [HELP_SRC]="Répertoire à sauvegarder"
    [HELP_DEST]="Destination du fichier image"
    [HELP_OPTIONS]="Options"
    [COPY_BEGIN]="📁 Copie des fichiers…"
    [COPY_OK]="Copie terminée avec succès."
    [COPY_FAIL]="❌ Erreur pendant la copie des fichiers."
    [CALC_SIZE]="📐 Calcul de la taille…"
    [NOT_ENOUGH_SPACE]="❌ Pas assez d’espace disque"
    [IMG_CREATE]="📦 Création de l’image…"
    [IMG_FORMAT_FAIL]="🧱 Erreur lors du formatage de l’image"
    [MOUNT_FAIL]="Impossible de monter l’image"
    [CLEANUP]="🧹 Nettoyage…"
    [CLEANUP_DONE]="🫧 Nettoyage terminé."
    [COMPRESS]="🗜️ Compression de l’image…"
    [COMPRESS_OK]="✅ Image compressée."
    [ENCRYPT]="🔐 Chiffrement de l’image…"
    [ENCRYPT_OK]="✅ Image chiffrée."
    [HMAC_OK]="🔐 Code d’authentification généré."
    [TIME]="⏳ Temps écoulé"
)

# ----- English / Anglais -----
declare -A MSG_en=(
    [FATAL]="❌ Fatal error"
    [UNKNOWN_OPTION]="⚠️ Unknown option ignored"
    [PASS_PROMPT]="😵 Passphrase: "
    [DECRYPT_OK]="✅ Decryption completed successfully"
    [DECRYPT_FAIL]="❌ Error during decryption"
    [MISSING_SRC]="Source directory missing"
    [MISSING_DEST]="Destination image missing"
    [HELP_TITLE]="Backup script to a temporary mounted image"
    [HELP_USAGE]="Two arguments are required"
    [HELP_SRC]="Directory to back up"
    [HELP_DEST]="Destination of the image file"
    [HELP_OPTIONS]="Options"
    [COPY_BEGIN]="📁 Copying files…"
    [COPY_OK]="✅ Copy completed successfully."
    [COPY_FAIL]="❌ Error during file copy."
    [CALC_SIZE]="📐 Calculating size…"
    [NOT_ENOUGH_SPACE]="❌ Not enough disk space"
    [IMG_CREATE]="📦 Creating image…"
    [IMG_FORMAT_FAIL]="🧱 Error while formatting the image"
    [MOUNT_FAIL]="Unable to mount image"
    [CLEANUP]="🧹 Cleaning up…"
    [CLEANUP_DONE]="🫧 Cleanup done."
    [COMPRESS]="🗜️ Compressing image…"
    [COMPRESS_OK]="✅ Image compressed."
    [ENCRYPT]="🔐 Encrypting image…"
    [ENCRYPT_OK]="✅ Image encrypted."
    [HMAC_OK]="🔐 Message authentication code generated."
    [TIME]="⏳ Elapsed time"
)

###############################################################
# === Function to fetch translated messages ==================
###############################################################
msg() {
 
    local key="$1"
    local lang="MSG_${LANG_CODE}"
    declare -n dict="$lang"   # <-- référence vers le bon tableau
    echo -e "${dict[$key]}"

}

###############################################################
# === Colors / Couleurs ======================================
###############################################################
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

trace() {
    echo -e "${!2:-$YELLOW}${1}${RESET}"
}

fatal() {
    echo -e "${RED}[$(msg FATAL)] $*${RESET}" >&2
    exit 1
}

###############################################################
# === Password Handling / Gestion du mot de passe ============
###############################################################
get_pass() {
    if [[ -f "$BPWD" ]]; then
        pass_opt="-pass file:$BPWD"
        key="$(cat "$BPWD")"
    else
        read -s -p "$(msg PASS_PROMPT)" key
        echo
        pass_opt="-pass pass:$key"
    fi
}

###############################################################
# === Arguments ==============================================
###############################################################
SOURCE_DIR="$1"
DEST_DIR="$2"
VERBOSE=false
COMPRESS=false
ENCRYPT=false
SHOW_HELP=false
BPWD='/root/.backup_pass'
DATE=$(date +%A-%d-%m-%Y)
HOSTNAME=$(hostname -s)
BACKUP_TEMP_DIR='/mnt/.tempdir/'
DEBUG_ME=false

# Handle options
if [[ ! $1 == -* ]]; then shift 2; fi

while getopts "dvzehx:" flag; do
    case "${flag}" in
        d) DEBUG_ME=true ;;
        v) VERBOSE=true ;;
        z) COMPRESS=true ;;
        e) ENCRYPT=true ;;
        h) SHOW_HELP=true ;;
        x) DECRYPT=${OPTARG} ;;
        *) trace "$(msg UNKNOWN_OPTION): ${flag}" ;;
    esac
done

if $DEBUG_ME; then set -x; fi

###############################################################
# === Help Screen / Écran d'aide =============================
###############################################################
MESSAGE_COLOR=LIGHTGRAY
if $SHOW_HELP || [ -z "$SOURCE_DIR" ] || [ -z "$DEST_DIR" ]; then
    trace "------------------------------------------------" $MESSAGE_COLOR
    trace "$(msg HELP_TITLE)" $MESSAGE_COLOR
    trace "------------------------------------------------" $MESSAGE_COLOR
    trace "$(msg HELP_USAGE)" $MESSAGE_COLOR
    trace "  1\) $(msg HELP_SRC)" $MESSAGE_COLOR
    trace "  2\) $(msg HELP_DEST)" $MESSAGE_COLOR
    trace "------------------------------------------------" $MESSAGE_COLOR
    trace "$(msg HELP_OPTIONS)" $MESSAGE_COLOR
    trace "  -d Debug" $MESSAGE_COLOR
    trace "  -v Verbose" $MESSAGE_COLOR
    trace "  -z Compression" $MESSAGE_COLOR
    trace "  -e Encryption" $MESSAGE_COLOR
    trace "  -x File   Decrypt" $MESSAGE_COLOR
    exit 0
fi

###############################################################
# === Cleanup / Nettoyage ====================================
###############################################################
cleanup() {
    trace "$(msg CLEANUP)" WHITE
    mountpoint -q "$BACKUP_TEMP_DIR" && umount "$BACKUP_TEMP_DIR"
    rm -rf "$BACKUP_TEMP_DIR"
    trace "$(msg CLEANUP_DONE)" WHITE
}

trap cleanup EXIT

###############################################################
# === Encryption checks / Vérif Encryption ====================
###############################################################
if $ENCRYPT; then
    get_pass
fi

###############################################################
# === Compute size / Calcul taille ===========================
###############################################################
trace "$(msg CALC_SIZE)"
SIZE=$(du -sm "$SOURCE_DIR" | cut -f1)

###############################################################
# === Space check / Vérif espace =============================
###############################################################
AVAIL=$(df -m "$DEST_DIR" | awk 'NR==2 {print $4}')
(( AVAIL < SIZE )) && fatal "$(msg NOT_ENOUGH_SPACE)"

###############################################################
# === Create image file / Création de l’image ================
###############################################################
trace "$(msg IMG_CREATE)"
IMAGE="${DEST_DIR}/${HOSTNAME}-${DATE}.img"
dd if=/dev/zero of="$IMAGE" bs=1M count=$SIZE status=none

mkfs.ext4 -L BACKUP "$IMAGE" > /dev/null 2>&1 || fatal "$(msg IMG_FORMAT_FAIL)"

mkdir -p "$BACKUP_TEMP_DIR"
mount -o loop "$IMAGE" "$BACKUP_TEMP_DIR" || fatal "$(msg MOUNT_FAIL)"

###############################################################
# === File copy / Copie ======================================
###############################################################
trace "$(msg COPY_BEGIN)"
cp -rL "$SOURCE_DIR"* "$BACKUP_TEMP_DIR" || fatal "$(msg COPY_FAIL)"
trace "$(msg COPY_OK)" GREEN

###############################################################
# === Compression ============================================
###############################################################
if $COMPRESS; then
    trace "$(msg COMPRESS)"
    gzip -f -9 "$IMAGE"
    IMAGE="${IMAGE}.gz"
    trace "$(msg COMPRESS_OK)" GREEN
fi

###############################################################
# === Encryption =============================================
###############################################################
if $ENCRYPT; then
    trace "$(msg ENCRYPT)"

    openssl enc -aes-256-ctr -salt -pbkdf2 \
        -in "$IMAGE" -out "${IMAGE}.enc" $pass_opt \
        || fatal "$(msg ENCRYPT_FAIL)"

    openssl dgst -sha256 -hmac "$key" "${IMAGE}.enc" > "${IMAGE}.enc.hmac"
    trace "$(msg HMAC_OK)"

    rm -f "$IMAGE"
    IMAGE="${IMAGE}.enc"

    trace "$(msg ENCRYPT_OK)" GREEN
fi

###############################################################
# === Time / Temps ===========================================
###############################################################
end=$(( $(date +%s%3N) - start_time ))
#trace "$(msg TIME): ${end} ms"

# Affichage du temps total
if (( end > 60000 )); then
    minutes=$((end / 60000))
    seconds=$(((end / 1000) % 60))
    trace "$(msg TIME): $minutes min $seconds s" WHITE
elif (( end > 1000 )); then
    end=$((end / 1000))
    trace "$(msg TIME): $seconds s" WHITE
else
    trace "$(msg TIME): ${end} ms" WHITE
fi

exit 0
