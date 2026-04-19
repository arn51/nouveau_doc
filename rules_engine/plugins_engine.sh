#############################################
#   PLUGINS ENGINE — Chargement & exécution
#############################################

# Chargement des fichiers plugins (*.sh)
plugins_load_files() {
    [[ -d "$PLUGINS_DIR" ]] || return 0

    for plugin in "$PLUGINS_DIR"/*.sh; do
        [[ -f "$plugin" ]] || continue
        if [[ "$VERBOSE" == true ]]; then
            echo "[PLUGIN] Chargement fichier : $(basename "$plugin")"
        fi
        source "$plugin"
    done
}

# Exécution des plugins dans l’ordre défini
plugins_execute_order() {
    for plugin in "${PLUGIN_ORDER[@]}"; do
        if declare -f "$plugin" >/dev/null; then
            if [[ "$VERBOSE" == true ]]; then
                echo "[PLUGIN] Exécution : $plugin"
            fi
            "$plugin"
        else
            if [[ "$VERBOSE" == true ]]; then
                echo "[PLUGIN] ⚠️ Fonction introuvable : $plugin"
            fi
        fi
    done
}

# Fonction principale
plugins_load() {
    if [[ "$VERBOSE" == true ]]; then
        echo "[PLUGIN] Chargement des plugins…"
    fi

    plugins_load_files
    plugins_execute_order

    if [[ "$VERBOSE" == true ]]; then
        echo "[PLUGIN] Tous les plugins ont été exécutés."
    fi
}
