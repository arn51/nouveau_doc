#############################################
#   CLI ENGINE — Parsing des options
#############################################

cli_show_help() {
    cat <<EOF
Usage: nouveau_doc [options] "Titre du document"

Options :
  -p, --profile NAME        Utiliser un profil spécifique
  -c, --category NAME       Définir une catégorie
  -t, --template FILE       Utiliser un template spécifique
      --dir PATH            Définir le dossier de destination
      --no-open             Ne pas ouvrir Typora après création
      --preview             Afficher le contenu généré
      --slug                Générer un slug pour le nom de fichier
      --dry-run             Simuler sans créer de fichier
  -v, --verbose             Mode verbeux
      --help                Afficher cette aide
      --version             Afficher la version de l’outil
EOF
}

cli_show_version() {
    echo "nouveau_doc version $VERSION"
}

cli_parse() {
    # Valeurs par défaut
    PROFILE="${PROFILE:-perso}"
    CATEGORY="${CATEGORY:-Général}"
    TEMPLATE="${TEMPLATE:-}"
    DEST_DIR="$HOME/Documents/Docs"
    OPEN_TYPORA=true
    PREVIEW=false
    USE_SLUG=false
    DRY_RUN=false
    VERBOSE=false

    # Parsing
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--profile)
                PROFILE="$2"
                shift 2
                ;;
            -c|--category)
                CATEGORY="$2"
                shift 2
                ;;
            -t|--template)
                TEMPLATE="$2"
                shift 2
                ;;
            --dir)
                DEST_DIR="$2"
                shift 2
                ;;
            --no-open)
                OPEN_TYPORA=false
                shift
                ;;
            --preview)
                PREVIEW=true
                shift
                ;;
            --slug)
                USE_SLUG=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                cli_show_help
                exit 0
                ;;
            --version)
                cli_show_version
                exit 0
                ;;
            --)
                shift
                break
                ;;
            -*)
                echo "Erreur: option inconnue '$1'" >&2
                exit 1
                ;;
            *)
                break
                ;;
        esac
    done

    # Titre obligatoire
    if [[ $# -eq 0 ]]; then
        echo "Erreur: aucun titre fourni." >&2
        exit 1
    fi

    RAW_TITLE="$1"
    shift

    # Nettoyage du titre
    TITLE="$(clean_title "$RAW_TITLE")"
}
