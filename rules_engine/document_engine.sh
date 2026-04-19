#############################################
#   DOCUMENT ENGINE — Génération du fichier
#############################################

DEST_DIR="$HOME/Documents/nouveau_doc"
MASTER_TEMPLATE="$CONFIG_DIR/templates/default.md"

# Nettoyage du titre (déjà utilisé dans cli_engine)
clean_title() {
    local raw="$1"
    local cleaned

    cleaned="$(sed -E 's/@[a-zA-Z0-9_\/?=,-]+//g' <<< "$raw")"
    cleaned="$(sed -E 's/[[:space:]]+/ /g' <<< "$cleaned")"
    cleaned="$(sed -E 's/^ +//; s/ +$//' <<< "$cleaned")"

    echo "$cleaned"
}

#############################################
#   1) Génération du slug
#############################################

document_slugify() {
    local title="$1"
    local slug

    slug="$(echo "$title" \
        | tr '[:upper:]' '[:lower:]' \
        | sed -E 's/[^a-z0-9]+/-/g' \
        | sed -E 's/^-+|-+$//g')"

    echo "$slug"
}

#############################################
#   2) Chargement du template
#############################################

document_load_template() {
    local template="$1"
    local path="$CONFIG_DIR/templates/${template}.md"

    if [[ ! -f "$path" ]]; then
        echo "Erreur: template introuvable : $template"
        exit 1
    fi

    cat "$path"
}

#############################################
#   3) Injection des snippets
#############################################

document_apply_snippets() {
    local content="$1"

    content="${content//\{\{HEADER\}\}/$HEADER_SNIPPETS}"
    content="${content//\{\{BODY\}\}/$BODY_SNIPPETS}"
    content="${content//\{\{FOOTER\}\}/$FOOTER_SNIPPETS}"
    content="${content//\{\{SIDEBAR\}\}/$SIDEBAR_SNIPPETS}"

    echo "$content"
}

#############################################
#   4) Construction du contenu final
#############################################

document_build() {
    local template_content
    template_content="$(document_load_template "$TEMPLATE")"

    document_apply_snippets "$template_content"
}

#############################################
#   5) Écriture du fichier final
#############################################

document_write_file() {
    local title="$1"
    local content="$2"

    # Sécurisation absolue de DEST_DIR
    if [[ -z "$DEST_DIR" ]]; then
        DEST_DIR="$HOME/Documents/nouveau_doc"
    fi

    mkdir -p "$DEST_DIR"

    local filename

    if [[ "$USE_SLUG" == true ]]; then
        filename="$(document_slugify "$title").md"
    else
        filename="$title.md"
    fi

    local path="$DEST_DIR/$filename"

    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY-RUN] Fichier généré : $path"
        echo "----------------------------------------"
        echo "$content"
        echo "----------------------------------------"
        return 0
    fi

    echo "$content" > "$path"

    if [[ "$VERBOSE" == true ]]; then
        echo "[OK] Document créé : $path"
    fi

    if [[ "$OPEN_TYPORA" == true ]]; then
        typora "$path" >/dev/null 2>&1 &
    fi
}

#############################################
#   6) Fonction principale
#############################################

document_generate() {
    local title="$1"

    local content
    content="$(document_build)"

    if [[ "$PREVIEW" == true ]]; then
        echo "────────── PREVIEW ──────────"
        echo "$content"
        echo "──────────────────────────────"
    fi

    document_write_file "$title" "$content"
}
