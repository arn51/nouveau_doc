#!/usr/bin/env bash

if [[ -n "$NOUVEAU_DOC_ROOT" ]]; then
    export PATH="$NOUVEAU_DOC_ROOT/bin:$PATH"
    export RULES_ENGINE_DIR="$NOUVEAU_DOC_ROOT/rules_engine"
    export RULES_DIR="$NOUVEAU_DOC_ROOT/rules"
    export TEMPLATES_DIR="$NOUVEAU_DOC_ROOT/templates"
    export SNIPPETS_DIR="$NOUVEAU_DOC_ROOT/snippets"
fi

total_tests=0
passed_tests=0
json_global=""
supported_types=(journal bug projet technique idee todo general meeting)

# Modes
watch_mode=false
watch_debug=false
watch_fast=false
ci_mode=false
ci_junit=false
ci_summary=false
ci_failures_only=false
ci_github=false
ci_markdown=false
ci_jsonl=false
ci_annotations=false
ci_badge=false
ci_badge_file=false
ci_badge_json=false
ci_badge_extended=false
ci_badge_file_extended=false
ci_badge_file_json=false
ci_badge_file_json_extended=false
ci_badge_auto=false
ci_report_all=false
ci_badges_per_type=false

case "$1" in
    --watch) watch_mode=true ;;
    --watch-debug) watch_debug=true ;;
    --watch-fast) watch_fast=true ;;
    --ci) ci_mode=true ;;
    --ci-junit) ci_junit=true ;;
    --ci-summary) ci_summary=true ;;
    --ci-failures-only) ci_failures_only=true ;;
    --ci-github) ci_github=true ;;
    --ci-markdown) ci_markdown=true ;;
    --ci-jsonl) ci_jsonl=true ;;
    --ci-annotations) ci_annotations=true ;;
    --ci-badge) ci_badge=true ;;
    --ci-badge-file) ci_badge_file=true ;;
    --ci-badge-json) ci_badge_json=true ;;
    --ci-badge-extended) ci_badge_extended=true ;;
    --ci-badge-file-extended) ci_badge_file_extended=true ;;
    --ci-badge-file-json) ci_badge_file_json=true ;;
    --ci-badge-file-json-extended) ci_badge_file_json_extended=true ;;
    --ci-badge-auto) ci_badge_auto=true ;;
    --ci-report-all) ci_report_all=true ;;
    --ci-badges-per-type) ci_badges_per_type=true ;;
esac


# Dossiers à surveiller (pas le dossier du script)
watch_paths=(
    "${RULES_DIR:-$HOME/.config/nouveau_doc/rules}"
    "${TEMPLATES_DIR:-$HOME/.config/nouveau_doc/templates}"
)

# -------------------------
# MODE AUTO : détection des types depuis les fichiers .rules
# -------------------------

# En local : ~/.config/nouveau_doc/rules
# En CI : $NOUVEAU_DOC_ROOT/rules
rules_dir="${RULES_DIR:-$HOME/.config/nouveau_doc/rules}"

auto_types=()

while IFS= read -r line; do
    type=$(echo "$line" | cut -d'=' -f2)
    auto_types+=("$type")
done < <(grep -R "DOC_TYPE=" "$rules_dir" | cut -d':' -f2 | sort -u)

generate_title() {
    case "$1" in
        journal) echo "Journal automatique" ;;
        bug) echo "Bug automatique" ;;
        projet) echo "Projet automatique" ;;
        technique) echo "Note technique automatique" ;;
        idee) echo "Idée automatique" ;;
        todo) echo "Liste TODO automatique" ;;
        general) echo "Document général automatique" ;;
        meeting) echo "Réunion automatique" ;;
        *) echo "Document $1 automatique" ;;
    esac
}

types=()
for t in "${auto_types[@]}"; do
    types+=("$(generate_title "$t")")
done

unsupported_types=()
for t in "${auto_types[@]}"; do
    if ! printf '%s\n' "${supported_types[@]}" | grep -qx "$t"; then
        unsupported_types+=("$t")
    fi
done

template_to_type() {
    local file="$1"
    basename "$file" | sed -E 's/template_(.*)\.md/\1/'
}

get_impacted_type() {
    local file="$1"

    # Cas 1 : fichier .rules
    if [[ "$file" == *.rules ]]; then
        grep -oP '(?<=DOC_TYPE=).*' "$file"
        return
    fi

    # Cas 2 : template
    if [[ "$file" == *template_*.md ]]; then
        template_to_type "$file"
        return
    fi

    # Cas 3 : inconnu → retest complet
    echo "__ALL__"
}

run_test() {
    local titre="$1"
    local output
    output="$(nouveau_doc "$titre" 2>&1)"

    local doc_type profile category template
    doc_type=$(echo "$output" | grep -oP '(?<=DOC_TYPE : ).*' | head -n 1)
    profile=$(echo "$output" | grep -oP '(?<=PROFILE=).*' | head -n 1)
    category=$(echo "$output" | grep -oP '(?<=CATEGORY=).*' | head -n 1)
    template=$(echo "$output" | grep -oP '(?<=TEMPLATE=).*' | head -n 1)

    local errors=()

    add_error() {
        errors+=("\"$1\"")
    }

    case "$doc_type" in
        journal)
            [[ "$profile" != "perso" ]] && add_error "PROFILE should be 'perso'"
            [[ "$category" != "journal" ]] && add_error "CATEGORY should be 'journal'"
            [[ "$template" != "template_journal" ]] && add_error "TEMPLATE should be 'template_journal'"
            ;;
        bug)
            [[ "$profile" != "travail" ]] && add_error "PROFILE should be 'travail'"
            [[ "$category" != "bug" ]] && add_error "CATEGORY should be 'bug'"
            [[ "$template" != "template_bug" ]] && add_error "TEMPLATE should be 'template_bug'"
            ;;
        projet)
            [[ "$profile" != "travail" ]] && add_error "PROFILE should be 'travail'"
            [[ "$category" != "projet" ]] && add_error "CATEGORY should be 'projet'"
            [[ "$template" != "template_projet" ]] && add_error "TEMPLATE should be 'template_projet'"
            ;;
        technique)
            [[ "$profile" != "travail" ]] && add_error "PROFILE should be 'travail'"
            [[ "$category" != "technique" ]] && add_error "CATEGORY should be 'technique'"
            [[ "$template" != "template_technique" ]] && add_error "TEMPLATE should be 'template_technique'"
            ;;
        idee)
            [[ "$profile" != "perso" ]] && add_error "PROFILE should be 'perso'"
            [[ "$category" != "idee" ]] && add_error "CATEGORY should be 'idee'"
            [[ "$template" != "template_idee" ]] && add_error "TEMPLATE should be 'template_idee'"
            ;;
        todo)
            [[ "$profile" != "perso" ]] && add_error "PROFILE should be 'perso'"
            [[ "$category" != "todo" ]] && add_error "CATEGORY should be 'todo'"
            [[ "$template" != "template_todo" ]] && add_error "TEMPLATE should be 'template_todo'"
            ;;
        general)
            [[ "$profile" != "perso" ]] && add_error "PROFILE should be 'perso'"
            [[ "$category" != "general" ]] && add_error "CATEGORY should be 'general'"
            [[ "$template" != "template_general" ]] && add_error "TEMPLATE should be 'template_general'"
            ;;
        meeting)
            [[ "$profile" != "travail" ]] && add_error "PROFILE should be 'travail'"
            [[ "$category" != "meeting" ]] && add_error "CATEGORY should be 'meeting'"
            [[ "$template" != "template_meeting" ]] && add_error "TEMPLATE should be 'template_meeting'"
            ;;
        *)
            add_error "Unknown DOC_TYPE '$doc_type'"
            ;;
    esac

    local json_errors
    json_errors=$(printf "%s," "${errors[@]}")
    json_errors="[${json_errors%,}]"

    local status="OK"
    [[ ${#errors[@]} -gt 0 ]] && status="FAIL"



    # On renvoie trois blocs séparés
    echo "###JSON###"
    cat <<EOF
{
  "title": "$titre",
  "doc_type": "$doc_type",
  "profile": "$profile",
  "category": "$category",
  "template": "$template",
  "status": "$status",
  "errors": $json_errors
}
EOF

    echo "###MD###"
    echo "| $titre | $doc_type | $profile | $category | $template | $status |"

    echo "###HUMAN###"
    echo "$titre → $status"
}

get_impacted_type() {
    local file="$1"

    # Cas 1 : fichier .rules
    if [[ "$file" == *.rules ]]; then
        grep -oP '(?<=DOC_TYPE=).*' "$file"
        return
    fi

    # Cas 2 : template
    if [[ "$file" == *template_*.md ]]; then
        basename "$file" | sed -E 's/template_(.*)\.md/\1/'
        return
    fi

    # Cas 3 : inconnu → retester tout
    echo "__ALL__"
}

run_all_tests() {
    clear
    echo "=== VALIDATION AUTOMATIQUE ($(date '+%H:%M:%S')) ==="
    echo

    # Remise à zéro des compteurs
    total_tests=0
    passed_tests=0
    json_global=""
    md_output=""
    human_output=""

    # -------------------------
    # 1) JSON GLOBAL
    # -------------------------
    json_global="$(
    cat <<EOF
{
  "tests": [
EOF
    )"

    first=true

    for titre in "${types[@]}"; do
        result="$(run_test "$titre")"

        json_block=$(echo "$result" | awk '/###JSON###/{flag=1;next}/###MD###/{flag=0}flag')
        md_block=$(echo "$result" | awk '/###MD###/{flag=1;next}/###HUMAN###/{flag=0}flag')
        human_block=$(echo "$result" | awk '/###HUMAN###/{flag=1;next}flag')

        status=$(echo "$json_block" | grep -oP '(?<="status": ")[^"]+')

        ((total_tests++))
        [[ "$status" == "OK" ]] && ((passed_tests++))

        if [[ "$first" == true ]]; then
            first=false
            json_global+="$json_block"
        else
            json_global+=",$json_block"
        fi

        md_output+="$md_block"$'\n'
        human_output+="$human_block"$'\n'
    done

    json_global+="
  ]
}"

    echo "$json_global"

    # -------------------------
    # SCORE GLOBAL
    # -------------------------
    echo
    echo "## Score global"
    percent=$(( 100 * passed_tests / total_tests ))
    echo "$passed_tests / $total_tests tests OK → ${percent}%"

    # -------------------------
    # 2) MARKDOWN
    # -------------------------
    echo
    echo "# Rapport de validation"
    echo
    echo "## Tableau récapitulatif"
    echo
    echo "| Titre | DOC_TYPE | PROFILE | CATEGORY | TEMPLATE | Status |"
    echo "|-------|----------|---------|----------|----------|--------|"
    echo "$md_output"

    echo
    echo "## Types non supportés"
    echo

    if [[ ${#unsupported_types[@]} -eq 0 ]]; then
        echo "Aucun type non supporté détecté."
    else
        echo "| Type détecté | Statut |"
        echo "|--------------|--------|"
        for t in "${unsupported_types[@]}"; do
            echo "| $t | ❌ Non supporté |"
        done
    fi

    # -------------------------
    # 3) RÉSUMÉ HUMAIN
    # -------------------------
    echo
    echo "## Résumé humain"
    echo
    echo -e "$human_output"

    echo
    if [[ $passed_tests -eq $total_tests ]]; then
        echo -e "✔ Tous les tests sont passés avec succès"
    else
        echo -e "❌ $passed_tests / $total_tests tests OK"
    fi

    echo
    echo "Types non supportés :"

    if [[ ${#unsupported_types[@]} -eq 0 ]]; then
        echo "✔ Aucun type non supporté"
    else
        for t in "${unsupported_types[@]}"; do
            echo "❌ $t"
        done
    fi

    # -------------------------
    # 4) EXPORT MARKDOWN DANS report.md
    # -------------------------
    {
        echo "# Rapport de validation"
        echo
        echo "Généré automatiquement le $(date '+%Y-%m-%d %H:%M:%S')"
        echo
        echo "## Score global"
        percent=$(( 100 * passed_tests / total_tests ))
        echo "$passed_tests / $total_tests tests OK → ${percent}%"
        echo
        echo "## Tableau récapitulatif"
        echo
        echo "| Titre | DOC_TYPE | PROFILE | CATEGORY | TEMPLATE | Status |"
        echo "|-------|----------|---------|----------|----------|--------|"
        echo "$md_output"
        echo
        echo "## Résumé humain"
        echo
        echo "$human_output"
        echo
        echo "## Types non supportés"
        echo

        if [[ ${#unsupported_types[@]} -eq 0 ]]; then
            echo "Aucun type non supporté détecté."
        else
            echo "| Type détecté | Statut |"
            echo "|--------------|--------|"
            for t in "${unsupported_types[@]}"; do
                echo "| $t | ❌ Non supporté |"
            done
        fi
    } > report.md

    # -------------------------
    # 5) EXPORT JSON DANS report.json
    # -------------------------
    echo "$json_global" > report.json
}

run_ci_tests() {
    total_tests=0
    passed_tests=0
    json_global="{\"tests\": ["
    first=true

    for titre in "${types[@]}"; do
        result="$(run_test "$titre")"

        json_block=$(echo "$result" | awk '/###JSON###/{flag=1;next}/###MD###/{flag=0}flag')
        status=$(echo "$json_block" | grep -oP '(?<="status": ")[^"]+')

        ((total_tests++))
        [[ "$status" == "OK" ]] && ((passed_tests++))

        if [[ "$first" == true ]]; then
            first=false
            json_global+="$json_block"
        else
            json_global+=",$json_block"
        fi
    done

    percent=$(( 100 * passed_tests / total_tests ))

    json_global+=",
  \"summary\": {
    \"passed\": $passed_tests,
    \"total\": $total_tests,
    \"percent\": $percent
  }
}"

    echo "$json_global"

    # Exit code strict
    if [[ $passed_tests -eq $total_tests ]]; then
        exit 0
    else
        exit 1
    fi
}

run_ci_junit() {
    total_tests=0
    passed_tests=0

    junit_file="report.junit.xml"

    # Début du fichier XML
    echo "<testsuite name=\"nouveau_doc\">" > "$junit_file"

    for titre in "${types[@]}"; do
        result="$(run_test "$titre")"

        json_block=$(echo "$result" | awk '/###JSON###/{flag=1;next}/###MD###/{flag=0}flag')

        status=$(echo "$json_block" | grep -oP '(?<="status": ")[^"]+')
        errors=$(echo "$json_block" | grep -oP '(?<="errors": ).*')

        ((total_tests++))

        testcase_name=$(echo "$json_block" | grep -oP '(?<="title": ")[^"]+')

        echo "  <testcase name=\"$testcase_name\">" >> "$junit_file"

        if [[ "$status" != "OK" ]]; then
            echo "    <failure message=\"$errors\"/>" >> "$junit_file"
        else
            ((passed_tests++))
        fi

        echo "  </testcase>" >> "$junit_file"
    done

    # Fin du fichier XML
    echo "</testsuite>" >> "$junit_file"

    echo "JUnit report generated: $junit_file"

    # Exit code strict
    if [[ $passed_tests -eq $total_tests ]]; then
        exit 0
    else
        exit 1
    fi
}

run_ci_summary() {
    total_tests=0
    passed_tests=0

    for titre in "${types[@]}"; do
        result="$(run_test "$titre")"

        json_block=$(echo "$result" | awk '/###JSON###/{flag=1;next}/###MD###/{flag=0}flag')
        status=$(echo "$json_block" | grep -oP '(?<="status": ")[^"]+')

        ((total_tests++))
        [[ "$status" == "OK" ]] && ((passed_tests++))
    done

    percent=$(( 100 * passed_tests / total_tests ))

    if [[ $passed_tests -eq $total_tests ]]; then
        echo "$passed_tests/$total_tests OK ($percent%)"
        exit 0
    else
        echo "❌ $passed_tests/$total_tests tests OK ($percent%)"
        exit 1
    fi
}

run_ci_failures_only() {
    total_tests=0
    failed_tests=0

    failures_json="["

    first=true

    for titre in "${types[@]}"; do
        result="$(run_test "$titre")"

        json_block=$(echo "$result" \
            | awk '/###JSON###/{flag=1;next}/###MD###/{flag=0}flag')

        status=$(echo "$json_block" \
            | grep -oP '(?<="status": ")[^"]+')

        ((total_tests++))

        if [[ "$status" != "OK" ]]; then
            ((failed_tests++))

            if [[ "$first" == true ]]; then
                first=false
                failures_json+="$json_block"
            else
                failures_json+=",$json_block"
            fi
        fi
    done

    failures_json+="]"

    if [[ $failed_tests -eq 0 ]]; then
        echo "✔ Aucun échec"
        exit 0
    else
        echo "$failures_json"
        exit 1
    fi
}

run_ci_github() {
    total_tests=0
    failed_tests=0

    for titre in "${types[@]}"; do
        result="$(run_test "$titre")"

        json_block=$(echo "$result" \
            | awk '/###JSON###/{flag=1;next}/###MD###/{flag=0}flag')

        status=$(echo "$json_block" \
            | grep -oP '(?<="status": ")[^"]+')

        title=$(echo "$json_block" \
            | grep -oP '(?<="title": ")[^"]+')

        errors=$(echo "$json_block" \
            | grep -oP '(?<="errors": ).*')

        ((total_tests++))

        if [[ "$status" != "OK" ]]; then
            ((failed_tests++))

            # Nettoyage du JSON d’erreurs
            clean_errors=$(echo "$errors" | sed 's/^\[//; s/\]$//; s/"//g')

            # Annotation GitHub Actions
            echo "::error title=$title,type=$status::$clean_errors"
        fi
    done

    # Exit code strict
    if [[ $failed_tests -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

run_ci_markdown() {
    total_tests=0
    passed_tests=0

    markdown="# Résultats des tests\n\n"

    failures_section="## Échecs\n\n"
    has_failures=false

    for titre in "${types[@]}"; do
        result="$(run_test "$titre")"

        json_block=$(echo "$result" \
            | awk '/###JSON###/{flag=1;next}/###MD###/{flag=0}flag')

        status=$(echo "$json_block" \
            | grep -oP '(?<="status": ")[^"]+')

        title=$(echo "$json_block" \
            | grep -oP '(?<="title": ")[^"]+')

        errors=$(echo "$json_block" \
            | grep -oP '(?<="errors": ).*')

        ((total_tests++))

        if [[ "$status" == "OK" ]]; then
            ((passed_tests++))
        else
            has_failures=true

            clean_errors=$(echo "$errors" \
                | sed 's/^\[//; s/\]$//; s/"//g')

            failures_section+="- **$title**\n"
            failures_section+="  - $clean_errors\n\n"
        fi
    done

    percent=$(( 100 * passed_tests / total_tests ))

    markdown+="**$passed_tests / $total_tests OK ($percent%)**\n\n"

    if [[ "$has_failures" == true ]]; then
        markdown+="$failures_section"
    else
        markdown+="Aucun échec.\n"
    fi

    echo -e "$markdown"

    # Exit code strict
    if [[ $passed_tests -eq $total_tests ]]; then
        exit 0
    else
        exit 1
    fi
}

run_ci_jsonl() {
    total_tests=0
    failed_tests=0

    for titre in "${types[@]}"; do
        result="$(run_test "$titre")"

        json_block=$(echo "$result" \
            | awk '/###JSON###/{flag=1;next}/###MD###/{flag=0}flag')

        status=$(echo "$json_block" \
            | grep -oP '(?<="status": ")[^"]+')

        ((total_tests++))
        [[ "$status" != "OK" ]] && ((failed_tests++))

        # On imprime le bloc JSON sur une seule ligne
        echo "$json_block" | tr -d '\n'
        echo
    done

    # Exit code strict
    if [[ $failed_tests -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

run_ci_annotations() {
    total_tests=0
    passed_tests=0

    markdown="# Résultats des tests\n\n"
    failures_section="## Échecs\n\n"
    has_failures=false

    for titre in "${types[@]}"; do
        result="$(run_test "$titre")"

        json_block=$(echo "$result" \
            | awk '/###JSON###/{flag=1;next}/###MD###/{flag=0}flag')

        status=$(echo "$json_block" \
            | grep -oP '(?<="status": ")[^"]+')

        title=$(echo "$json_block" \
            | grep -oP '(?<="title": ")[^"]+')

        errors=$(echo "$json_block" \
            | grep -oP '(?<="errors": ).*')

        ((total_tests++))

        if [[ "$status" == "OK" ]]; then
            ((passed_tests++))
        else
            has_failures=true

            clean_errors=$(echo "$errors" \
                | sed 's/^\[//; s/\]$//; s/"//g')

            # Annotation GitHub Actions
            echo "::error title=$title,type=$status::$clean_errors"

            # Markdown summary
            failures_section+="- **$title**\n"
            failures_section+="  - $clean_errors\n\n"
        fi
    done

    percent=$(( 100 * passed_tests / total_tests ))

    markdown+="**$passed_tests / $total_tests OK ($percent%)**\n\n"

    if [[ "$has_failures" == true ]]; then
        markdown+="$failures_section"
    else
        markdown+="Aucun échec.\n"
    fi

    # Impression du résumé Markdown
    echo -e "$markdown"

    # Exit code strict
    if [[ $passed_tests -eq $total_tests ]]; then
        exit 0
    else
        exit 1
    fi
}

run_ci_badge() {
    total_tests=0
    passed_tests=0

    for titre in "${types[@]}"; do
        result="$(run_test "$titre")"

        json_block=$(echo "$result" \
            | awk '/###JSON###/{flag=1;next}/###MD###/{flag=0}flag')

        status=$(echo "$json_block" \
            | grep -oP '(?<="status": ")[^"]+')

        ((total_tests++))
        [[ "$status" == "OK" ]] && ((passed_tests++))
    done

    percent=$(( 100 * passed_tests / total_tests ))

    # Couleur du badge
    if [[ $percent -eq 100 ]]; then
        color="brightgreen"
    elif [[ $percent -ge 80 ]]; then
        color="yellow"
    else
        color="red"
    fi

    # Badge Markdown
    echo "![Tests](https://img.shields.io/badge/tests-${percent}%25-${color})"

    # Exit code strict
    if [[ $passed_tests -eq $total_tests ]]; then
        exit 0
    else
        exit 1
    fi
}

run_ci_badge_file() {
    total_tests=0
    passed_tests=0

    for titre in "${types[@]}"; do
        result="$(run_test "$titre")"

        json_block=$(echo "$result" \
            | awk '/###JSON###/{flag=1;next}/###MD###/{flag=0}flag')

        status=$(echo "$json_block" \
            | grep -oP '(?<="status": ")[^"]+')

        ((total_tests++))
        [[ "$status" == "OK" ]] && ((passed_tests++))
    done

    percent=$(( 100 * passed_tests / total_tests ))

    # Couleur du badge
    if [[ $percent -eq 100 ]]; then
        color="#4c1"        # brightgreen
    elif [[ $percent -ge 80 ]]; then
        color="#dfb317"     # yellow
    else
        color="#e05d44"     # red
    fi

    # Fichier SVG
    badge_file="tests_badge.svg"

    cat > "$badge_file" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="150" height="20">
  <linearGradient id="smooth" x2="0" y2="100%">
    <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
    <stop offset="1" stop-opacity=".1"/>
  </linearGradient>
  <rect rx="3" width="150" height="20" fill="#555"/>
  <rect rx="3" x="70" width="80" height="20" fill="$color"/>
  <path fill="$color" d="M70 0h4v20h-4z"/>
  <rect rx="3" width="150" height="20" fill="url(#smooth)"/>
  <g fill="#fff" text-anchor="middle"
     font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="11">
    <text x="35" y="14">tests</text>
    <text x="110" y="14">${percent}%</text>
  </g>
</svg>
EOF

    echo "$badge_file"

    # Exit code strict
    if [[ $passed_tests -eq $total_tests ]]; then
        exit 0
    else
        exit 1
    fi
}

run_ci_badge_json() {
    total_tests=0
    passed_tests=0

    for titre in "${types[@]}"; do
        result="$(run_test "$titre")"

        json_block=$(echo "$result" \
            | awk '/###JSON###/{flag=1;next}/###MD###/{flag=0}flag')

        status=$(echo "$json_block" \
            | grep -oP '(?<="status": ")[^"]+')

        ((total_tests++))
        [[ "$status" == "OK" ]] && ((passed_tests++))
    done

    percent=$(( 100 * passed_tests / total_tests ))

    # Couleur du badge
    if [[ $percent -eq 100 ]]; then
        color="brightgreen"
    elif [[ $percent -ge 80 ]]; then
        color="yellow"
    else
        color="red"
    fi

    badge_file="tests_badge.json"

    cat > "$badge_file" <<EOF
{
  "schemaVersion": 1,
  "label": "tests",
  "message": "${percent}%",
  "color": "$color"
}
EOF

    echo "$badge_file"

    # Exit code strict
    if [[ $passed_tests -eq $total_tests ]]; then
        exit 0
    else
        exit 1
    fi
}

run_ci_badge_extended() {
    total_tests=0
    passed_tests=0

    for titre in "${types[@]}"; do
        result="$(run_test "$titre")"

        json_block=$(echo "$result" \
            | awk '/###JSON###/{flag=1;next}/###MD###/{flag=0}flag')

        status=$(echo "$json_block" \
            | grep -oP '(?<="status": ")[^"]+')

        ((total_tests++))
        [[ "$status" == "OK" ]] && ((passed_tests++))
    done

    percent=$(( 100 * passed_tests / total_tests ))

    # Couleur du badge
    if [[ $percent -eq 100 ]]; then
        color="brightgreen"
    elif [[ $percent -ge 80 ]]; then
        color="yellow"
    else
        color="red"
    fi

    # Message étendu : "7/8 (87%)"
    message="${passed_tests}/${total_tests} (${percent}%)"

    # Encodage URL pour shields.io
    encoded_message=$(echo "$message" | sed 's/%/%25/g; s/ /%20/g; s/\//%2F/g; s/(/%28/g; s/)/%29/g')

    echo "![Tests](https://img.shields.io/badge/tests-${encoded_message}-${color})"

    # Exit code strict
    if [[ $passed_tests -eq $total_tests ]]; then
        exit 0
    else
        exit 1
    fi
}

run_ci_badge_file_extended() {
    total_tests=0
    passed_tests=0

    for titre in "${types[@]}"; do
        result="$(run_test "$titre")"

        json_block=$(echo "$result" \
            | awk '/###JSON###/{flag=1;next}/###MD###/{flag=0}flag')

        status=$(echo "$json_block" \
            | grep -oP '(?<="status": ")[^"]+')

        ((total_tests++))
        [[ "$status" == "OK" ]] && ((passed_tests++))
    done

    percent=$(( 100 * passed_tests / total_tests ))

    # Couleur du badge
    if [[ $percent -eq 100 ]]; then
        color="#4c1"        # brightgreen
    elif [[ $percent -ge 80 ]]; then
        color="#dfb317"     # yellow
    else
        color="#e05d44"     # red
    fi

    # Message étendu : "7/8 (87%)"
    message="${passed_tests}/${total_tests} (${percent}%)"

    badge_file="tests_badge_extended.svg"

    cat > "$badge_file" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="180" height="20">
  <linearGradient id="smooth" x2="0" y2="100%">
    <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
    <stop offset="1" stop-opacity=".1"/>
  </linearGradient>
  <rect rx="3" width="180" height="20" fill="#555"/>
  <rect rx="3" x="70" width="110" height="20" fill="$color"/>
  <path fill="$color" d="M70 0h4v20h-4z"/>
  <rect rx="3" width="180" height="20" fill="url(#smooth)"/>
  <g fill="#fff" text-anchor="middle"
     font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="11">
    <text x="35" y="14">tests</text>
    <text x="125" y="14">$message</text>
  </g>
</svg>
EOF

    echo "$badge_file"

    # Exit code strict
    if [[ $passed_tests -eq $total_tests ]]; then
        exit 0
    else
        exit 1
    fi
}

run_ci_badge_file_json() {
    badge_json="tests_badge.json"
    badge_svg="tests_badge_from_json.svg"

    if [[ ! -f "$badge_json" ]]; then
        echo "Erreur : fichier $badge_json introuvable. Lance d'abord --ci-badge-json."
        exit 1
    fi

    # Extraction des champs JSON
    message=$(grep -oP '(?<="message": ")[^"]+' "$badge_json")
    color=$(grep -oP '(?<="color": ")[^"]+' "$badge_json")

    # Largeur dynamique (simple estimation)
    base_width=70
    msg_width=$(( ${#message} * 7 ))
    total_width=$(( base_width + msg_width ))

    cat > "$badge_svg" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="$total_width" height="20">
  <linearGradient id="smooth" x2="0" y2="100%">
    <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
    <stop offset="1" stop-opacity=".1"/>
  </linearGradient>
  <rect rx="3" width="$total_width" height="20" fill="#555"/>
  <rect rx="3" x="$base_width" width="$msg_width" height="20" fill="$color"/>
  <path fill="$color" d="M$base_width 0h4v20h-4z"/>
  <rect rx="3" width="$total_width" height="20" fill="url(#smooth)"/>
  <g fill="#fff" text-anchor="middle"
     font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="11">
    <text x="$(( base_width / 2 ))" y="14">tests</text>
    <text x="$(( base_width + msg_width / 2 ))" y="14">$message</text>
  </g>
</svg>
EOF

    echo "$badge_svg"
    exit 0
}

run_ci_badge_file_json_extended() {
    badge_json="tests_badge.json"
    badge_svg="tests_badge_extended_from_json.svg"

    if [[ ! -f "$badge_json" ]]; then
        echo "Erreur : fichier $badge_json introuvable. Lance d'abord --ci-badge-json."
        exit 1
    fi

    # Extraction du label et de la couleur depuis le JSON
    label=$(grep -oP '(?<="label": ")[^"]+' "$badge_json")
    color=$(grep -oP '(?<="color": ")[^"]+' "$badge_json")

    # Recalcul du score réel
    total_tests=0
    passed_tests=0

    for titre in "${types[@]}"; do
        result="$(run_test "$titre")"
        json_block=$(echo "$result" | awk '/###JSON###/{flag=1;next}/###MD###/{flag=0}flag')
        status=$(echo "$json_block" | grep -oP '(?<="status": ")[^"]+')
        ((total_tests++))
        [[ "$status" == "OK" ]] && ((passed_tests++))
    done

    percent=$(( 100 * passed_tests / total_tests ))
    message="${passed_tests}/${total_tests} (${percent}%)"

    # Largeur dynamique
    base_width=70
    msg_width=$(( ${#message} * 7 ))
    total_width=$(( base_width + msg_width ))

    cat > "$badge_svg" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="$total_width" height="20">
  <linearGradient id="smooth" x2="0" y2="100%">
    <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
    <stop offset="1" stop-opacity=".1"/>
  </linearGradient>
  <rect rx="3" width="$total_width" height="20" fill="#555"/>
  <rect rx="3" x="$base_width" width="$msg_width" height="20" fill="$color"/>
  <path fill="$color" d="M$base_width 0h4v20h-4z"/>
  <rect rx="3" width="$total_width" height="20" fill="url(#smooth)"/>
  <g fill="#fff" text-anchor="middle"
     font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="11">
    <text x="$(( base_width / 2 ))" y="14">$label</text>
    <text x="$(( base_width + msg_width / 2 ))" y="14">$message</text>
  </g>
</svg>
EOF

    echo "$badge_svg"

    # Exit code strict
    if [[ $passed_tests -eq $total_tests ]]; then
        exit 0
    else
        exit 1
    fi
}

run_ci_badge_per_type() {
    local type="$1"
    local titre="$(generate_title "$type")"

    # Exécuter un seul test
    result="$(run_test "$titre")"
    json_block=$(echo "$result" | awk '/###JSON###/{flag=1;next}/###MD###/{flag=0}flag')
    status=$(echo "$json_block" | grep -oP '(?<="status": ")[^"]+')

    # Score individuel
    if [[ "$status" == "OK" ]]; then
        percent=100
    else
        percent=0
    fi

    # Couleur
    if [[ $percent -eq 100 ]]; then
        color="#4c1"
    else
        color="#e05d44"
    fi

    # Nom du fichier
    badge_file="tests_${type}.svg"

    # Génération du badge
    cat > "$badge_file" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="150" height="20">
  <rect rx="3" width="150" height="20" fill="#555"/>
  <rect rx="3" x="70" width="80" height="20" fill="$color"/>
  <g fill="#fff" text-anchor="middle"
     font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="11">
    <text x="35" y="14">$type</text>
    <text x="110" y="14">${percent}%</text>
  </g>
</svg>
EOF

    echo "$badge_file"
}

run_ci_badge_auto() {
    total_tests=0
    passed_tests=0

    # 1) Exécution des tests une seule fois
    for titre in "${types[@]}"; do
        result="$(run_test "$titre")"
        json_block=$(echo "$result" | awk '/###JSON###/{flag=1;next}/###MD###/{flag=0}flag')
        status=$(echo "$json_block" | grep -oP '(?<="status": ")[^"]+')
        ((total_tests++))
        [[ "$status" == "OK" ]] && ((passed_tests++))
    done

    percent=$(( 100 * passed_tests / total_tests ))

    # Couleur dynamique
    if [[ $percent -eq 100 ]]; then
        color="brightgreen"
        color_hex="#4c1"
    elif [[ $percent -ge 80 ]]; then
        color="yellow"
        color_hex="#dfb317"
    else
        color="red"
        color_hex="#e05d44"
    fi

    # Messages
    message_simple="${percent}%"
    message_extended="${passed_tests}/${total_tests} (${percent}%)"

    # 2) Badge JSON
    cat > tests_badge.json <<EOF
{
  "schemaVersion": 1,
  "label": "tests",
  "message": "$message_simple",
  "color": "$color"
}
EOF

    # 3) Badge SVG simple
    cat > tests_badge.svg <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="150" height="20">
  <rect rx="3" width="150" height="20" fill="#555"/>
  <rect rx="3" x="70" width="80" height="20" fill="$color_hex"/>
  <g fill="#fff" text-anchor="middle" font-family="DejaVu Sans" font-size="11">
    <text x="35" y="14">tests</text>
    <text x="110" y="14">$message_simple</text>
  </g>
</svg>
EOF

    # 4) Badge SVG extended
    cat > tests_badge_extended.svg <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="180" height="20">
  <rect rx="3" width="180" height="20" fill="#555"/>
  <rect rx="3" x="70" width="110" height="20" fill="$color_hex"/>
  <g fill="#fff" text-anchor="middle" font-family="DejaVu Sans" font-size="11">
    <text x="35" y="14">tests</text>
    <text x="125" y="14">$message_extended</text>
  </g>
</svg>
EOF

    # 5) Badge SVG depuis JSON (simple)
    cat > tests_badge_from_json.svg <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="150" height="20">
  <rect rx="3" width="150" height="20" fill="#555"/>
  <rect rx="3" x="70" width="80" height="20" fill="$color_hex"/>
  <g fill="#fff" text-anchor="middle" font-family="DejaVu Sans" font-size="11">
    <text x="35" y="14">tests</text>
    <text x="110" y="14">$message_simple</text>
  </g>
</svg>
EOF

    # 6) Badge SVG depuis JSON (extended)
    cat > tests_badge_extended_from_json.svg <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="180" height="20">
  <rect rx="3" width="180" height="20" fill="#555"/>
  <rect rx="3" x="70" width="110" height="20" fill="$color_hex"/>
  <g fill="#fff" text-anchor="middle" font-family="DejaVu Sans" font-size="11">
    <text x="35" y="14">tests</text>
    <text x="125" y="14">$message_extended</text>
  </g>
</svg>
EOF

    echo "Badges générés : tests_badge.json, tests_badge.svg, tests_badge_extended.svg, tests_badge_from_json.svg, tests_badge_extended_from_json.svg"

    # Exit strict
    if [[ $passed_tests -eq $total_tests ]]; then
        exit 0
    else
        exit 1
    fi
}

run_ci_report_all() {
    total_tests=0
    passed_tests=0
    results_json="["

    first=true

    # 1) Exécution des tests une seule fois
    for titre in "${types[@]}"; do
        result="$(run_test "$titre")"
        json_block=$(echo "$result" | awk '/###JSON###/{flag=1;next}/###MD###/{flag=0}flag')

        status=$(echo "$json_block" | grep -oP '(?<="status": ")[^"]+')

        ((total_tests++))
        [[ "$status" == "OK" ]] && ((passed_tests++))

        if [[ "$first" == true ]]; then
            first=false
            results_json+="$json_block"
        else
            results_json+=",$json_block"
        fi
    done

    results_json+="]"

    percent=$(( 100 * passed_tests / total_tests ))

    # Couleur dynamique
    if [[ $percent -eq 100 ]]; then
        color="brightgreen"
        color_hex="#4c1"
    elif [[ $percent -ge 80 ]]; then
        color="yellow"
        color_hex="#dfb317"
    else
        color="red"
        color_hex="#e05d44"
    fi

    message_simple="${percent}%"
    message_extended="${passed_tests}/${total_tests} (${percent}%)"

    # 2) Génération des rapports
    echo "$results_json" > report.json

    echo -e "# Résultats des tests\n\n**$passed_tests / $total_tests OK ($percent%)**\n" > report.md
    if [[ $passed_tests -ne $total_tests ]]; then
        echo -e "## Échecs\n" >> report.md
        echo "$results_json" | jq -r '.[] | select(.status!="OK") | "- **\(.title)**\n  - \(.errors[])"' >> report.md
    fi

    # JUnit
    {
        echo '<?xml version="1.0" encoding="UTF-8"?>'
        echo "<testsuite tests=\"$total_tests\" failures=\"$((total_tests-passed_tests))\">"
        echo "$results_json" | jq -r '
            .[] |
            if .status=="OK" then
                "<testcase name=\"" + .title + "\"/>"
            else
                "<testcase name=\"" + .title + "\"><failure>" + (.errors | join(", ")) + "</failure></testcase>"
            end
        '
        echo "</testsuite>"
    } > report.junit.xml

    # 3) Génération des badges (identiques à --ci-badge-auto)
    echo "$results_json" | jq -r '
        {
            schemaVersion: 1,
            label: "tests",
            message: "'"$message_simple"'",
            color: "'"$color"'"
        }
    ' > tests_badge.json

    # SVG simple
    cat > tests_badge.svg <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="150" height="20">
  <rect rx="3" width="150" height="20" fill="#555"/>
  <rect rx="3" x="70" width="80" height="20" fill="$color_hex"/>
  <g fill="#fff" text-anchor="middle" font-family="DejaVu Sans" font-size="11">
    <text x="35" y="14">tests</text>
    <text x="110" y="14">$message_simple</text>
  </g>
</svg>
EOF

    # SVG extended
    cat > tests_badge_extended.svg <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="180" height="20">
  <rect rx="3" width="180" height="20" fill="#555"/>
  <rect rx="3" x="70" width="110" height="20" fill="$color_hex"/>
  <g fill="#fff" text-anchor="middle" font-family="DejaVu Sans" font-size="11">
    <text x="35" y="14">tests</text>
    <text x="125" y="14">$message_extended</text>
  </g>
</svg>
EOF

    # SVG depuis JSON
    cp tests_badge.svg tests_badge_from_json.svg

    # SVG extended depuis JSON
    cp tests_badge_extended.svg tests_badge_extended_from_json.svg

    echo "Rapports générés."

    # Exit strict
    if [[ $passed_tests -eq $total_tests ]]; then
        exit 0
    else
        exit 1
    fi
}

run_fast_test() {
    local type="$1"
    local titre="$(generate_title "$type")"

    clear
    echo "=== VALIDATION RAPIDE : $type ($(date '+%H:%M:%S')) ==="
    echo

    result="$(run_test "$titre")"

    json_block=$(echo "$result" | awk '/###JSON###/{flag=1;next}/###MD###/{flag=0}flag')
    md_block=$(echo "$result" | awk '/###MD###/{flag=1;next}/###HUMAN###/{flag=0}flag')
    human_block=$(echo "$result" | awk '/###HUMAN###/{flag=1;next}flag')

    echo "$json_block"
    echo
    echo "$md_block"
    echo
    echo "$human_block"
}

if [[ "$watch_mode" == true || "$watch_debug" == true || "$watch_fast" == true ]]; then
    echo "Mode watch activé ${watch_fast:+(FAST)} ${watch_debug:+(DEBUG)}"
    echo "CTRL+C pour quitter."
    echo

    while true; do
        changed=$(inotifywait -e modify,create,delete -r "${watch_paths[@]}" --format "%w%f" 2>/dev/null)

        # Ignorer fichiers temporaires
        if ignore_file "$changed"; then
            continue
        fi

        # Mode debug
        if [[ "$watch_debug" == true ]]; then
            echo "[DEBUG] Modification détectée : $changed"
        fi

        # Mode FAST
        if [[ "$watch_fast" == true ]]; then
            impacted=$(get_impacted_type "$changed")

            if [[ "$impacted" == "__ALL__" ]]; then
                echo "[FAST] Type inconnu → retest complet"
                run_all_tests
            else
                echo "[FAST] Retest du type : $impacted"
                run_fast_test "$impacted"
            fi

        else
            # Mode watch normal ou debug
            run_all_tests
        fi
    done
elif [[ "$ci_mode" == true ]]; then
    run_ci_tests
elif [[ "$ci_junit" == true ]]; then
    run_ci_junit
elif [[ "$ci_summary" == true ]]; then
    run_ci_summary
elif [[ "$ci_failures_only" == true ]]; then
    run_ci_failures_only
elif [[ "$ci_github" == true ]]; then
    run_ci_github
elif [[ "$ci_markdown" == true ]]; then
    run_ci_markdown
elif [[ "$ci_jsonl" == true ]]; then
    run_ci_jsonl
elif [[ "$ci_annotations" == true ]]; then
    run_ci_annotations
elif [[ "$ci_badge" == true ]]; then
    run_ci_badge
elif [[ "$ci_badge_file" == true ]]; then
    run_ci_badge_file
elif [[ "$ci_badge_json" == true ]]; then
    run_ci_badge_json
elif [[ "$ci_badge_extended" == true ]]; then
    run_ci_badge_extended
elif [[ "$ci_badge_file_extended" == true ]]; then
    run_ci_badge_file_extended
elif [[ "$ci_badge_file_json" == true ]]; then
    run_ci_badge_file_json
elif [[ "$ci_badge_file_json_extended" == true ]]; then
    run_ci_badge_file_json_extended
elif [[ "$ci_badge_auto" == true ]]; then
    run_ci_badge_auto
elif [[ "$ci_report_all" == true ]]; then
    run_ci_report_all
elif [[ "$ci_badges_per_type" == true ]]; then
    for t in "${supported_types[@]}"; do
        run_ci_badge_per_type "$t"
    done
    exit 0
else
    run_all_tests
fi












