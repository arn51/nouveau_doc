#!/usr/bin/env bash

#############################################
#   MODULE : AI Rules Pack PRO+
#   Auto-apprentissage + ajustement dynamique
#############################################

module_register() {

    AI_DB="$CONFIG_DIR/ai_history.db"

    [[ -f "$AI_DB" ]] || echo "#title;detected;final;timestamp" > "$AI_DB"

    #############################################
    #   1) Poids de base (modifiables)
    #############################################

    declare -A BASE_WEIGHTS=(
        [journal]=5
        [bug]=7
        [projet]=6
        [tutoriel]=5
        [technique]=4
        [idee]=3
        [todo]=3
        [general]=1
    )

    declare -A WEIGHTS

    #############################################
    #   2) Chargement des poids dynamiques
    #############################################

    ai_load_weights() {
        for t in "${!BASE_WEIGHTS[@]}"; do
            WEIGHTS[$t]="${BASE_WEIGHTS[$t]}"
        done

        # Analyse de l'historique
        while IFS=";" read -r title detected final ts; do
            [[ "$title" =~ ^# ]] && continue
            [[ -z "$final" ]] && continue

            # Renforcement des catégories utilisées
            ((WEIGHTS[$final]++))
        done < "$AI_DB"
    }

    #############################################
    #   3) Détection de patterns récurrents
    #############################################

    ai_detect_patterns() {
        declare -A WORDS

        while IFS=";" read -r title detected final ts; do
            [[ "$title" =~ ^# ]] && continue
            for w in $title; do
                w="${w,,}"
                w="${w//[^a-z0-9]/}"
                [[ -z "$w" ]] && continue
                ((WORDS[$w]++))
            done
        done < "$AI_DB"

        # On garde les mots fréquents
        PATTERNS=()
        for w in "${!WORDS[@]}"; do
            if (( WORDS[$w] >= 3 )); then
                PATTERNS+=("$w")
            fi
        done
    }

    #############################################
    #   4) Scoring avancé avec patterns
    #############################################

    ai_score() {
        local type="$1"
        local score=0
        local t="$RAW_TITLE"

        # Scoring PRO (comme dans AI-PRO)
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

        # Pondération dynamique
        ((score += WEIGHTS[$type]))

        # Bonus si le titre contient un pattern récurrent
        for p in "${PATTERNS[@]}"; do
            if [[ "${t,,}" =~ $p ]]; then
                ((score+=2))
            fi
        done

        echo "$score"
    }

    #############################################
    #   5) Classification multi-critères
    #############################################

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

    #############################################
    #   6) Hooks
    #############################################

    hook_register pre_context '
        ai_load_weights
        ai_detect_patterns
        DOC_TYPE="$(ai_classify)"
    '

    hook_register post_document '
        echo "$RAW_TITLE;$DOC_TYPE;$CATEGORY;$(date +%s)" >> "$AI_DB"
    '

    hook_register post_context '
        [[ "$VERBOSE" != true ]] && return
        echo "[DEBUG PRO+] DOC_TYPE après PRO+ : $DOC_TYPE" >&2
        if [[ "$VERBOSE" == true ]]; then
            echo "[AI-PRO+] Type détecté : $DOC_TYPE" >&2
            echo "[AI-PRO+] Poids dynamiques : ${WEIGHTS[$DOC_TYPE]}" >&2
            echo "[AI-PRO+] Patterns détectés : ${PATTERNS[*]}" >&2
        fi
    '


    echo "[MODULE] AI Rules Pack PRO+ chargé"
}
