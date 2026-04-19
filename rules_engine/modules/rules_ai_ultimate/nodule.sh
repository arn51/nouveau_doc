#!/usr/bin/env bash

#############################################
#   Déclarations globales
#############################################

declare -gA BASE_WEIGHTS=(
    [journal]=5
    [bug]=7
    [projet]=6
    [tutoriel]=5
    [technique]=4
    [idee]=3
    [todo]=3
    [general]=1
)

declare -gA WEIGHTS
declare -gA TYPE_COUNT

#############################################
#   Fonctions globales
#############################################

ai_build_profile() {
    # init
    for t in "${!BASE_WEIGHTS[@]}"; do
        WEIGHTS[$t]="${BASE_WEIGHTS[$t]}"
        TYPE_COUNT[$t]=0
    done

    # stats
    while IFS=";" read -r title detected final ts; do
        [[ "$title" =~ ^# ]] && continue
        [[ -z "$final" ]] && continue
        ((TYPE_COUNT[$final]++))
    done < "$AI_DB"

    # ajustement des poids
    max=1
    for t in "${!TYPE_COUNT[@]}"; do
        (( TYPE_COUNT[$t] > max )) && max="${TYPE_COUNT[$t]}"
    done

    for t in "${!TYPE_COUNT[@]}"; do
        bonus=$(( TYPE_COUNT[$t] * 2 / max ))
        ((WEIGHTS[$t] += bonus))
    done
}

ai_score() {
    local type="$1"
    local score=0
    local t="$RAW_TITLE"

    case "$type" in
        journal)
            [[ "$t" =~ [Jj]ournal|[Ll]og ]] && ((score+=5))
            [[ "$t" =~ ^[0-9]{1,2}[/-][0-9]{1,2} ]] && ((score+=7))
            ;;
        bug)
            [[ "$t" =~ [Bb]ug|[Ii]ssue|#[0-9]+ ]] && ((score+=8))
            ;;
        projet)
            [[ "$t" =~ [Pp]rojet|[Rr]oadmap ]] && ((score+=6))
            ;;
        tutoriel)
            [[ "$t" =~ [Tt]uto|[Gg]uide|[Hh]ow.?to ]] && ((score+=6))
            ;;
        technique)
            [[ "$t" =~ [Tt]ech|[Aa]rchitecture|[Dd]esign ]] && ((score+=5))
            ;;
        idee)
            [[ "$t" =~ [Ii]dée|[Cc]oncept|[Rr]éflexion ]] && ((score+=4))
            ;;
        todo)
            [[ "$t" =~ [Tt]odo|[Tt]âche ]] && ((score+=4))
            ;;
    esac

    ((score += WEIGHTS[$type]))
    echo "$score"
}

ai_classify() {
    local best_type="general"
    local best_score=0

    for type in "${!WEIGHTS[@]}"; do
        local s
        s="$(ai_score "$type")"
        if (( s > best_score )); then
            best_score="$s"
            best_type="$type"
        fi
    done

    echo "$best_type"
}

ai_profile() {
    echo "Profil d'écriture (AI ULTIMATE)"
    echo "--------------------------------"
    for t in "${!TYPE_COUNT[@]}"; do
        printf "%-10s : %3d docs (poids=%d)\n" "$t" "${TYPE_COUNT[$t]}" "${WEIGHTS[$t]}"
    done
}

#############################################
#   module_register
#############################################

module_register() {

    AI_DB="$CONFIG_DIR/ai_history.db"
    [[ -f "$AI_DB" ]] || echo "#title;detected;final;timestamp" > "$AI_DB"

    hook_register pre_context '
    # Détection simple d’abord
    DOC_TYPE="$(detect_doc_type)"

    # Puis ajustement par le profil si tu veux
    ai_build_profile
    PROFILE_TYPE="$(ai_classify)"

    # Fusion : si detect_doc_type a trouvé quelque chose, on le garde
    # sinon on prend le type du profil
    if [[ "$DOC_TYPE" == "general" || -z "$DOC_TYPE" ]]; then
        DOC_TYPE="$PROFILE_TYPE"
    fi
    '

    hook_register post_document '
        echo "$RAW_TITLE;$DOC_TYPE;$CATEGORY;$(date +%s)" >> "$AI_DB"
    '

    hook_register pre_tree '
    [[ "$VERBOSE" != true ]] && return
    echo "[DEBUG ULTIMATE] DOC_TYPE avant finalisation : $DOC_TYPE" >&2

    # Finalisation du type par ULTIMATE
    if [[ -z "$DOC_TYPE" || "$DOC_TYPE" == "general" || "$DOC_TYPE" == "Général" ]]; then
        DOC_TYPE="$(detect_doc_type)"
    fi

    echo "[DEBUG ULTIMATE] DOC_TYPE après finalisation : $DOC_TYPE" >&2
'



    echo "[MODULE] AI Rules Pack ULTIMATE chargé"
}
