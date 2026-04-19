#!/usr/bin/env bash

detect_doc_type() {
    local title="$1"
    local t="$(echo "$title" | tr '[:upper:]' '[:lower:]')"

    if [[ "$t" =~ journal ]]; then DOC_TYPE="journal"; return; fi
    if [[ "$t" =~ id[ée]e ]]; then DOC_TYPE="idee"; return; fi
    if [[ "$t" =~ bug ]]; then DOC_TYPE="bug"; return; fi
    if [[ "$t" =~ (meeting|réunion|reunion) ]]; then DOC_TYPE="meeting"; return; fi
    if [[ "$t" =~ projet ]]; then DOC_TYPE="projet"; return; fi
    if [[ "$t" =~ (technique|note technique) ]]; then DOC_TYPE="technique"; return; fi

    DOC_TYPE="general"
}

module_register() {

    hook_register pre_context '
        detect_doc_type "$RAW_TITLE"
    '

    hook_register post_context '
        echo "[DEBUG POST] RAW_TITLE : $RAW_TITLE" >&2
        echo "[DEBUG POST] DOC_TYPE : $DOC_TYPE" >&2
    '

    hook_register post_context '
        case "$DOC_TYPE" in
            journal|idee|todo|general)
                PROFILE="perso"
                ;;
            bug|meeting|projet|technique)
                PROFILE="travail"
                ;;
            *)
                PROFILE="perso"
                ;;
        esac
    '

    hook_register post_context '
        case "$DOC_TYPE" in
            journal)   CATEGORY="journal" ;;
            idee)      CATEGORY="idee" ;;
            bug)       CATEGORY="bug" ;;
            meeting)   CATEGORY="meeting" ;;
            projet)    CATEGORY="projet" ;;
            technique) CATEGORY="technique" ;;
            todo)      CATEGORY="todo" ;;
            general)   CATEGORY="general" ;;
            *)
                CATEGORY="general"
                ;;
        esac
    '

    hook_register post_context '
        case "$CATEGORY" in
            journal)   TEMPLATE="template_journal" ;;
            idee)      TEMPLATE="template_idee" ;;
            bug)       TEMPLATE="template_bug" ;;
            meeting)   TEMPLATE="template_meeting" ;;
            projet)    TEMPLATE="template_projet" ;;
            technique) TEMPLATE="template_technique" ;;
            todo)      TEMPLATE="template_todo" ;;
            general)   TEMPLATE="template_general" ;;
            *)
                TEMPLATE="template_general"
                ;;
        esac
    '

    echo "[MODULE] AI Rules Pack (Advanced) chargé"
}
