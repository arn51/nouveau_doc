#############################################
#   CONTEXT ENGINE — Contexte utilisateur
#############################################

context_reset() {
    unset PROFILE CATEGORY TEMPLATE DEST_DIR
    unset ZONE_HEADER ZONE_BODY ZONE_FOOTER ZONE_SIDEBAR
    unset CURRENT_SECTION CURRENT_SECTION_VALUE

    CURRENT_SECTION="global"
    CURRENT_SECTION_VALUE=""
}

context_load_user_files() {
    [[ -f "$CONFIG_DIR/user.conf" ]]       && source "$CONFIG_DIR/user.conf"
    [[ -f "$CONFIG_DIR/categories.conf" ]] && source "$CONFIG_DIR/categories.conf"
    [[ -f "$CONFIG_DIR/templates.conf" ]]  && source "$CONFIG_DIR/templates.conf"
}

context_load_profile() {
    local profile="$1"
    local file="$PROFILES_DIR/$profile.conf"

    [[ -f "$file" ]] && source "$file"
}

context_init() {
    # Réinitialisation propre
    context_reset

    # Chargement des fichiers utilisateur
    context_load_user_files

    # Chargement du profil (si défini)
    if [[ -n "${PROFILE:-}" ]]; then
        context_load_profile "$PROFILE"
    fi
}
