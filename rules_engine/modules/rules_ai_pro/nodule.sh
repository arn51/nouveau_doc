#!/usr/bin/env bash

#############################################
#   MODULE : AI Rules Pack PRO
#   Classification avancée par scoring
#############################################

module_register() {

    AI_DB="$CONFIG_DIR/ai_history.db"

    #############################################
    #   1) Initialisation de la base d’apprentissage
    #############################################

    [[ -f "$AI_DB" ]] || echo "#title;detected;final;timestamp" > "$AI_DB"

    #############################################
    #   2) Poids heuristiques (modifiable)
    #############################################

    declare -A WEIGHTS=(
        [journal]=5
        [bug]=7
        [projet]=6
        [tutoriel]=5
        [technique]=4
        [idee]=3
        [todo]=3
        [general]=1
    )

    #############################################
    #   3) Fonction de scoring
    #############################################

    ai_score() {
        local type="$1"
        local score=0
        local t="$RAW_TITLE"

        # Mots-clés
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

        # Pondération heuristique
        ((score += WEIGHTS[$type]))

        echo "$score"
    }

    #############################################
    #   4) Classification multi-critères
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
    #   5) Hook : classification avancée
    #############################################

    hook_register pre_context '
        DOC_TYPE="$(ai_classify)"
    '

    #############################################
    #   6) Auto-apprentissage (simple)
    #############################################

    hook_register post_document '
        echo "$RAW_TITLE;$DOC_TYPE;$CATEGORY;$(date +%s)" >> "$AI_DB"
    '

    #############################################
    #   7) Log PRO
    #############################################

    hook_register post_context '
    [[ "$VERBOSE" != true ]] && return
    echo "[DEBUG PRO] DOC_TYPE après PRO : $DOC_TYPE" >&2
    if [[ "$VERBOSE" == true ]]; then
        echo "[AI-PRO] Type détecté : $DOC_TYPE" >&2
        echo "[AI-PRO] Poids utilisés : ${WEIGHTS[$DOC_TYPE]}" >&2
    fi
    '


    echo "[MODULE] AI Rules Pack PRO chargé"
}
