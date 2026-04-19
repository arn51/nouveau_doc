#############################################
#   HOOKS ENGINE — Système d’événements
#############################################

declare -A HOOKS

#############################################
#   Enregistrer un hook
#############################################
# Usage :
#   hook_register pre_tree "commande"
#   hook_register post_document "commande"

hook_register() {
    local event="$1"
    shift
    local cmd="$*"

    HOOKS["$event"]+="$cmd"$'\n'
}

#############################################
#   Exécuter tous les hooks d’un événement
#############################################

hook_run() {
    local event="$1"
    local script="${HOOKS[$event]}"
    ####echo "[DEBUG HOOK] Running $hook_name from $module_name" >&2
    ####echo "[DEBUG HOOK] POSTFIX before hook: ${POSTFIX[*]}" >&2

    [[ -z "$script" ]] && return 0

    if [[ "$VERBOSE" == true ]]; then
        echo "[HOOK] Exécution des hooks : $event"
    fi

    # Vérifie la syntaxe de tout le bloc
    if ! bash -n <<< "$script"; then
        echo "Erreur de syntaxe dans les hooks de l'événement : $event" >&2
        return 1
    fi

    # Exécute tout le bloc comme un script
    eval "$script"
    ####echo "[DEBUG HOOK] POSTFIX after hook: ${POSTFIX[*]}" >&2
}

#############################################
#   Liste des événements disponibles
#############################################
#   pre_context
#   post_context
#   pre_plugins
#   post_plugins
#   pre_rules
#   post_rules
#   pre_tree
#   post_tree
#   pre_stack
#   post_stack
#   pre_document
#   post_document
#############################################
