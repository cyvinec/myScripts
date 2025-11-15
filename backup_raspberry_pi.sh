#!/usr/bin/env bash
# ============================================================
# Backup Script to a Temporary Mounted Image
# Script de sauvegarde vers une image montée temporairement
#
# Author / Auteur : CY 😊 
# Updated with GPT-5.1 — 14 Nov 2025
# Mis à jour avec GPT-5.1 — 14 nov 2025 - Resultat par Email
# Mis à jour avec GPT-5.1 — 15 nov 2025 - Ajouter espagnole
# ============================================================

###############################################################
# === start-up time / temps de démarrage =====================
###############################################################
start_time=$(date +%s%3N)

###############################################################
# === Multilingual Message Dictionaries / Dictionnaires ======
###############################################################

# ----- French / Français -----
declare -A MSG_fr=(
    [FATAL]="❌ Erreur fatale"
    [UNKNOWN_OPTION]="⚠️ Option inconnue ignorée"
    #[PASS_PROMPT]="🗝️ Mot de passe : "
    [PASS_PROMPT]="🗝️ Entrez  \"s\" pour ajouter un mot de passe openssl fort n🗝️ Mot de passe nécessaire : "
    [PASS_PROMPT_GMAIL]="🗝️ Mot de passe Gmail (mot de passe d’application) : "
    [DECRYPT_OK]="✅ Déchiffrement terminé avec succès"
    [DECRYPT_FAIL]="❌ Erreur lors du déchiffrement"
    [MISSING_SRC]="😪 Répertoire à sauvegarder manquant"
    [MISSING_DEST]="😪 Destination du fichier image manquante"
    [HELP_TITLE]="Script de sauvegarde vers une image montée temporairement"
    [HELP_USAGE]="⓶ Deux arguments sont nécessaires"
    [HELP_SRC]="🗂️ Répertoire à sauvegarder"
    [HELP_DEST]="Destination du fichier image"
    [HELP_OPTIONS]="Options"
    [COPY_BEGIN]="📁 Copie des fichiers…"
    [COPY_OK]="✅ Copie terminée avec succès."
    [COPY_FAIL]="❌ Erreur lors de la copie des fichiers."
    [CALC_SIZE]="📐 Taille calculée : "
    [NOT_ENOUGH_SPACE]="❌ Pas assez d’espace disque"
    [IMG_CREATE]="📦 Création de l’image…"
    [IMG_FORMAT_FAIL]="🧱 Erreur lors du formatage de l’image"
    [MOUNT_FAIL]="❌ Impossible de monter l’image"
    [CLEANUP]="🧹 Nettoyage…"
    [CLEANUP_DONE]="🫧 Nettoyage terminé."
    [COMPRESS]="🗜️ Compression de l’image :"
    [COMPRESS_OK]="✅ Image compressée :"
    [ENCRYPT]="🔐 Chiffrement de l’image…"
    [ENCRYPT_OK]="✅ Image chiffrée."
    [HMAC_OK]="🔐 Code d’authentification généré."
    [TIME]="⏳ Temps écoulé"
    [EMAIL_TITLE]="Résultat du script de sauvegarde BASH"
    [EMAIL_ERROR_TITLE]="❌ Erreur dans le script de sauvegarde"
    [SET_PASS_FAIL]="Le fichier de mot de passe existe déjà."
)

# ----- English / Anglais -----
declare -A MSG_en=(
    [FATAL]="❌ Fatal error"
    [UNKNOWN_OPTION]="⚠️ Unknown option ignored"
    #[PASS_PROMPT]="🗝️ Passphrase: "
    [PASS_PROMPT]="🗝️ Enter \"s\" to add a strong openssl password\n🗝️ Password needed :"
    [PASS_PROMPT_GMAIL]="🗝️ Gmail app password: "
    [DECRYPT_OK]="✅ Decryption completed successfully"
    [DECRYPT_FAIL]="❌ Error during decryption"
    [MISSING_SRC]="😪 Source directory missing"
    [MISSING_DEST]="😪 Destination image missing"
    [HELP_TITLE]="Backup script to a temporarily mounted image"
    [HELP_USAGE]="⓶ Two arguments are required"
    [HELP_SRC]="🗂️ Directory to back up"
    [HELP_DEST]="Destination image file"
    [HELP_OPTIONS]="Options"
    [COPY_BEGIN]="📁 Copying files…"
    [COPY_OK]="✅ Copy completed successfully."
    [COPY_FAIL]="❌ Error during file copy."
    [CALC_SIZE]="📐 Calculated size: "
    [NOT_ENOUGH_SPACE]="❌ Not enough disk space"
    [IMG_CREATE]="📦 Creating image…"
    [IMG_FORMAT_FAIL]="🧱 Error while formatting the image"
    [MOUNT_FAIL]="❌ Unable to mount image"
    [CLEANUP]="🧹 Cleaning up…"
    [CLEANUP_DONE]="🫧 Cleanup completed."
    [COMPRESS]="🗜️ Compressing image:"
    [COMPRESS_OK]="✅ Image compressed:"
    [ENCRYPT]="🔐 Encrypting image…"
    [ENCRYPT_OK]="✅ Image encrypted."
    [HMAC_OK]="🔐 Message authentication code generated."
    [TIME]="⏳ Elapsed time"
    [EMAIL_TITLE]="BASH backup script result"
    [EMAIL_ERROR_TITLE]="❌ Error in the backup script"
    [SET_PASS_FAIL]="The password file already exists."
)

# ----- Spanish / Español -----
declare -A MSG_es=(
    [FATAL]="❌ Error fatal"
    [UNKNOWN_OPTION]="⚠️ Opción desconocida ignorada"
    #[PASS_PROMPT]="🗝️ Contraseña: "
    [PASS_PROMPT]="🗝️ Introduzca  \"s\" para agregar una contraseña openssl fuerte n🗝️ Contraseña necesaria :"
    [PASS_PROMPT_GMAIL]="🗝️ Contraseña de aplicación de Gmail: "
    [DECRYPT_OK]="✅ Descifrado completado con éxito"
    [DECRYPT_FAIL]="❌ Error durante el descifrado"
    [MISSING_SRC]="😪 Directorio de origen no encontrado"
    [MISSING_DEST]="😪 Destino de la imagen no encontrado"
    [HELP_TITLE]="Script de copia de seguridad a una imagen montada temporalmente"
    [HELP_USAGE]="⓶ Se requieren dos argumentos"
    [HELP_SRC]="🗂️ Directorio a respaldar"
    [HELP_DEST]="Destino del archivo de imagen"
    [HELP_OPTIONS]="Opciones"
    [COPY_BEGIN]="📁 Copiando archivos…"
    [COPY_OK]="✅ Copia completada con éxito."
    [COPY_FAIL]="❌ Error durante la copia de archivos."
    [CALC_SIZE]="📐 Tamaño calculado: "
    [NOT_ENOUGH_SPACE]="❌ No hay suficiente espacio en disco"
    [IMG_CREATE]="📦 Creando imagen…"
    [IMG_FORMAT_FAIL]="🧱 Error al formatear la imagen"
    [MOUNT_FAIL]="❌ No se puede montar la imagen"
    [CLEANUP]="🧹 Limpiando…"
    [CLEANUP_DONE]="🫧 Limpieza completada."
    [COMPRESS]="🗜️ Comprimiendo imagen:"
    [COMPRESS_OK]="✅ Imagen comprimida:"
    [ENCRYPT]="🔐 Cifrando imagen…"
    [ENCRYPT_OK]="✅ Imagen cifrada."
    [HMAC_OK]="🔐 Código de autenticación generado."
    [TIME]="⏳ Tiempo transcurrido"
    [EMAIL_TITLE]="Resultado del script de copia de seguridad en BASH"
    [EMAIL_ERROR_TITLE]="❌ Error en el script de copia de seguridad"
    [SET_PASS_FAIL]="El archivo de contraseña ya existe."
)


###############################################################
# === Function to fetch translated messages ==================
###############################################################
msg() {
     local key="$1"
    local lang="MSG_${LANG_CODE}"
    declare -n dict="$lang"  
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
            LIGHTGRAY=""
            GRAY=""
            WHITE=""
            RESET=""
            BOLD=""
            NOATT=""
    }

###############################################################
# === Logs  ==================================================
###############################################################
trace() {
    echo -e "${!2:-$YELLOW}${1}${RESET}"
    if $EMAIL_RESULT; then RESULT="$RESULT<font color=\"${2:-YELLOW}\">${1}<br>"; fi
}

fatal() {
    echo -e "${RED}[$(msg FATAL)] $*${RESET}" >&2
    [ -t 1 ] || email "$(msg EMAIL_TITLE)" "<h1>[$(msg FATAL)] $*</h1>"
    exit 1
}

###############################################################
# === Sending email / Envoie de email ========================
###############################################################
 email() {
     curl --silent --url 'smtps://smtp.gmail.com:465' --ssl-reqd \
     --mail-from 'from-email@gmail.com' \
     --mail-rcpt 'to-email@icloud.com' \
     --user 'youremail@gmail.com:app_password' \
     -T <(echo -e "From: email@gmail.com
             \nTo: email@icloud.com
             \nSubject: $1
             \nContent-Type: text/html
             \n$2")
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
        if [[ $key = "s" ]]; then
            pass_opt="$(openssl rand -base64 32)"
            trace "🗝️ $pass_opt"
            pass_opt="-pass pass:$pass_opt"
        else
            pass_opt="-pass pass:$key"
        fi
        
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
BGPWD='/root/.backup_gmail_pass'
DATE=$(date +%A-%d-%m-%Y)
HOSTNAME=$(hostname -s)
BACKUP_TEMP_DIR='/mnt/.tempdir/'
DEBUG_ME=false
LANG_CODE="" # Possible: en, fr
EMAIL_RESULT=false
SET_PWD=false
RESULT=""
MAC_IMAGE=false

# Handle options
if [[ ! $1 == -* ]]; then shift 2; fi

while getopts "dvzehrsmx:l:" flag; do
    case "${flag}" in
        d) DEBUG_ME=true ;;
        v) VERBOSE=true ;;
        z) COMPRESS=true ;;
        e) ENCRYPT=true ;;
        h) SHOW_HELP=true ;;
        r) EMAIL_RESULT=true ;;
        s) SET_PWD=true ;;
        m) MAC_IMAGE=true ;;
        x) DECRYPT=${OPTARG} ;;
        l) LANG_CODE=${OPTARG} ;; 
        *) trace "$(msg UNKNOWN_OPTION): ${flag}" ;;
    esac
done

###############################################################
# === Language detection / Detection de la langue ============
###############################################################
if [[ $LANG_CODE = "" ]]; then
    # Extract primary language code system locale
    # Extraction du code de langue principal de la locale système
    syslang=$(locale | grep LANG= | cut -d= -f2 | cut -d. -f1)

    case "$syslang" in
        fr* ) LANG_CODE="fr" ;;
        es* ) LANG_CODE="es" ;;
        *   ) LANG_CODE="en" ;;
    esac
fi

###############################################################
# === Debug activation / Activation du Debug ==================
###############################################################
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
    trace "  1) $(msg HELP_SRC)" $MESSAGE_COLOR
    trace "  2) $(msg HELP_DEST)" $MESSAGE_COLOR
    trace "------------------------------------------------" $MESSAGE_COLOR
    trace "$(msg HELP_OPTIONS)" $MESSAGE_COLOR
    trace "  -d             Debug" $MESSAGE_COLOR
    trace "  -v             Verbose" $MESSAGE_COLOR
    trace "  -z             Compression" $MESSAGE_COLOR
    trace "  -e             Encryption" $MESSAGE_COLOR
    trace "  -r             Email" $MESSAGE_COLOR
    trace "  -s             PWD" $MESSAGE_COLOR
    trace "  -m             Image MAC" $MESSAGE_COLOR
    trace "  -x File        Decrypt" $MESSAGE_COLOR
    trace "  -l en/es/fr    Language" $MESSAGE_COLOR
    exit 0
fi

###############################################################
# === Adding password / Ajout de mot de pass =================
###############################################################
if $SET_PWD; then 
    if [[ ! -f "$BPWD" ]]; then
        echo "$(openssl rand -base64 32)" > "$BPWD"
        chmod 400 "$BPWD"
    else
        fatal "$(msg SET_PASS_FAIL)"
    fi
    if [[ ! -f "$BGPWD" ]]; then
        read -s -p "$(msg PASS_PROMPT_GMAIL)" key1
        echo
        echo "$key1" > "$BGPWD"
        chmod 400 "$BGPWD"
    else
        fatal "GMAIL - $(msg SET_PASS_FAIL)"
    fi
    exit 0
fi

###############################################################
# === Cleanup / Nettoyage ====================================
###############################################################
cleanup() {
    trace "$(msg CLEANUP)" GRAY
    mountpoint -q "$BACKUP_TEMP_DIR" && umount "$BACKUP_TEMP_DIR"
    rm -rf "$BACKUP_TEMP_DIR"
    trace "$(msg CLEANUP_DONE)" GRAY
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
#SIZE=$(du -sm "$SOURCE_DIR" | cut -f1)
SIZE=$(rsync -aL --dry-run --stats ${SOURCE_DIR} ${SOURCE_DIR} | \
        grep "Total transferred file size"   | tr -d ','   | \
        awk '{bytes=$5; mb=bytes/1024/1024; if (mb<1) print 1; else printf "%.0f\n", mb*1.15}')
trace "$(msg CALC_SIZE) $SIZE MB"

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

###############################################################
# === Formating image file / Fromatage de l’image ============
###############################################################
if ! $MAC_IMAGE; then
    mkfs.exfat -n 'BACKUP' -b 1024 "${IMAGE}" > /dev/null 2>&1 || fatal "$(msg IMG_FORMAT_FAIL)"
else
    mkfs.ext4 -L BACKUP "$IMAGE" > /dev/null 2>&1 || fatal "$(msg IMG_FORMAT_FAIL)"
fi

###############################################################
# === Mounting image file / Montage de l’image ============
###############################################################
mkdir -p "$BACKUP_TEMP_DIR"
mount -o loop "$IMAGE" "$BACKUP_TEMP_DIR" || fatal "$(msg MOUNT_FAIL)"

###############################################################
# === File copy / Copie ======================================
###############################################################
trace "$(msg COPY_BEGIN)"
if ! $MAC_IMAGE; then
    # Options pour cp
    cp_opts="-rL"
    $VERBOSE && cp_opts="-rvL"

    cp $cp_opts "$SOURCE_DIR"* "$BACKUP_TEMP_DIR" \
        || fatal "$(msg COPY_FAIL)"

else
    # Options pour rsync
    rsync_opts="-aHAX"
    $VERBOSE && rsync_opts="$rsync_opts -v --info=progress2"

    rsync $rsync_opts "$SOURCE_DIR" "$BACKUP_TEMP_DIR/" \
        || fatal "$(msg COPY_FAIL)"
fi
trace "$(msg COPY_OK)" GREEN

###############################################################
# === Compression ============================================
###############################################################
if $COMPRESS; then
    trace "$(msg COMPRESS) $(du -sh "$IMAGE" | cut -f1)"
    gzip -f -9 "$IMAGE"
    IMAGE="${IMAGE}.gz"
    trace "$(msg COMPRESS_OK) $(du -sh "$IMAGE" | cut -f1)" GREEN
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

# Affichage du temps total
if (( end > 60000 )); then
    minutes=$((end / 60000))
    seconds=$(((end / 1000) % 60))
    trace "$(msg TIME): $minutes min $seconds s" LIGHTGRAY
elif (( end > 1000 )); then
    end=$((end / 1000))
    trace "$(msg TIME): $seconds s" LIGHTGRAY
else
    trace "$(msg TIME): ${end} ms" LIGHTGRAY
fi

###############################################################
# === Email result / Resultat par email ======================
###############################################################
if $EMAIL_RESULT; then email "$(msg EMAIL_TITLE)" "${RESULT} <hr> ${IMAGE}"; fi

exit 0
