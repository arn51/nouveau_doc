#!/usr/bin/env bash

# Force bash
if [ -z "$BASH_VERSION" ]; then
    exec /usr/bin/env bash "$0" "$@"
fi

modules_load() {
    # Utilise MODULES_DIR si défini, sinon fallback propre
    local module_dir="${MODULES_DIR:-$RULES_ENGINE_DIR/modules}"

    for module in "$module_dir"/*/module.sh; do
        [[ -f "$module" ]] || continue

        source "$module"

        if declare -f module_register >/dev/null; then
            module_register
        else
            echo "[MODULE] ⚠ module '$(basename "$(dirname "$module")")' sans module_register()"
        fi

        # NE PAS supprimer module_register ici
        # unset -f module_register 2>/dev/null
    done
}



