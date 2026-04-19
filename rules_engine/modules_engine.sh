#!/usr/bin/env bash

# Force bash
if [ -z "$BASH_VERSION" ]; then
    exec /usr/bin/env bash "$0" "$@"
fi

modules_load() {
    local module_dir="$HOME/.local/bin/rules_engine/modules"

    for module in "$module_dir"/*/module.sh; do
        [[ -f "$module" ]] || continue

        source "$module"

        if declare -f module_register >/dev/null; then
            module_register
        else
            echo "[MODULE] ⚠ module '$(basename "$(dirname "$module")")' sans module_register()"
        fi

        # ❌ NE SURTOUT PAS supprimer module_register ici
        # unset -f module_register 2>/dev/null
    done
}


