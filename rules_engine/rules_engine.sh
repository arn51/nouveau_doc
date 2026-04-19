#############################################
#   RULES ENGINE — Moteur DSL complet
#############################################
DSL_VERBOSE="${DSL_VERBOSE:-false}"

# TOKENS et POSTFIX sont globaux
declare -ag TOKENS=()
declare -ag POSTFIX=()

#############################################
#   0) Évaluation d’un atome logique brut
#############################################

rule_eval_atom() {
    local atom="$1"
    local key expected value

    key="${atom%%=*}"
    expected="${atom#*=}"

    case "$key" in
        DOC_TYPE)
            value="$DOC_TYPE"
            ;;
        CATEGORY)
            value="$CATEGORY"
            ;;
        PROFILE)
            value="$PROFILE"
            ;;
        TEMPLATE)
            value="$TEMPLATE"
            ;;
        *)
            # Atome inconnu → faux
            return 1
            ;;
    esac

    ####echo "[DEBUG ATOM] atom=$atom value=$value" >&2

    [[ "${value,,}" == "${expected,,}" ]]
}

#############################################
#   1) TOKENISATION
#############################################

rules_tokenize() {
    local expr="$1"
    TOKENS=()

    # Séparer parenthèses
    expr="${expr//(/ ( }"
    expr="${expr//)/ ) }"

    read -ra raw <<< "$expr"
    local count=${#raw[@]}
    local i=0

    while (( i < count )); do
        local t="${raw[$i]}"

        # Parenthèses
        if [[ "$t" == "(" || "$t" == ")" ]]; then
            TOKENS+=("$t")
            ((i++))
            continue
        fi

        # Opérateurs multi-mots
        if (( i + 1 < count )); then
            local next="${raw[$((i+1))]}"

            case "$next" in
                contains|starts_with|ends_with|matches|in)
                    local key="$t"
                    local op="$next"
                    local val="${raw[$((i+2))]}"

                    # Récupérer valeurs multi-mots
                    if (( i + 3 < count )); then
                        local j=$((i+3))
                        while (( j < count )) && [[ ! "${raw[$j]}" =~ ^(AND|OR|NOT|\(|\))$ ]]; do
                            val+=" ${raw[$j]}"
                            ((j++))
                        done
                        i=$j
                    else
                        i=$((i+3))
                    fi

                    TOKENS+=("$key $op $val")
                    continue
                    ;;
            esac
        fi

        # Opérateurs logiques
        case "$t" in
            AND|OR|NOT)
                TOKENS+=("$t")
                ((i++))
                continue
                ;;
        esac

        # Atome simple
        TOKENS+=("$t")
        ((i++))
    done
}

#############################################
#   2) PRIORITÉ DES OPÉRATEURS
#############################################

rules_op_precedence() {
    case "$1" in
        NOT) echo 3 ;;
        AND) echo 2 ;;
        OR)  echo 1 ;;
        *)   echo 0 ;;
    esac
}

#############################################
#   3) CONVERSION EN POSTFIX (RPN)
#############################################

rules_to_postfix() {
    POSTFIX=()
    local -a stack=()
    local token

    declare -A prec=(
        [NOT]=3
        [AND]=2
        [OR]=1
    )

    for token in "${TOKENS[@]}"; do
        case "$token" in
            "(" )
                stack+=("(")
                ;;

            ")" )
                while (( ${#stack[@]} > 0 )) && [[ "${stack[-1]}" != "(" ]]; do
                    POSTFIX+=("${stack[-1]}")
                    unset 'stack[-1]'
                done
                [[ "${stack[-1]}" == "(" ]] && unset 'stack[-1]'
                ;;

            AND|OR|NOT )
                while (( ${#stack[@]} > 0 )) &&
                      [[ "${stack[-1]}" != "(" ]] &&
                      (( prec["${stack[-1]}"] >= prec["$token"] )); do
                    POSTFIX+=("${stack[-1]}")
                    unset 'stack[-1]'
                done
                stack+=("$token")
                ;;

            * )
                POSTFIX+=("$token")
                ;;
        esac
    done

    while (( ${#stack[@]} > 0 )); do
        POSTFIX+=("${stack[-1]}")
        unset 'stack[-1]'
    done
}

#############################################
#   4) ÉVALUATION D’UN ATOME
#############################################

rules_eval_atom() {
    local atom="$1"

    # On réutilise ta fonction existante
    if rule_eval_atom "$atom"; then
        return 0
    else
        return 1
    fi
}

#############################################
#   5) ÉVALUATION POSTFIX
#############################################

rules_eval_postfix() {
    local token
    local -a stack=()

    for token in "${POSTFIX[@]}"; do
        case "$token" in
            NOT)
                local a="${stack[-1]:-false}"
                unset 'stack[-1]'
                [[ "$a" == true ]] && stack+=(false) || stack+=(true)
                ;;

            AND)
                local b="${stack[-1]:-false}"; unset 'stack[-1]'
                local a="${stack[-1]:-false}"; unset 'stack[-1]'
                [[ "$a" == true && "$b" == true ]] && stack+=(true) || stack+=(false)
                ;;

            OR)
                local b="${stack[-1]:-false}"; unset 'stack[-1]'
                local a="${stack[-1]:-false}"; unset 'stack[-1]'
                [[ "$a" == true || "$b" == true ]] && stack+=(true) || stack+=(false)
                ;;

            *)
                if rules_eval_atom "$token"; then
                    stack+=(true)
                else
                    stack+=(false)
                fi
                ;;
        esac
    done

    [[ "${stack[-1]:-false}" == true ]]
}

#############################################
#   6) ÉVALUATION D’UNE CONDITION
#############################################

rules_eval_condition() {
    local expr="$1"

    rules_tokenize "$expr"
    rules_to_postfix

    if rules_eval_postfix; then
        return 0
    else
        return 1
    fi
}

#############################################
#   7) CONSTRUCTION DE L’ARBRE LOGIQUE
#############################################

rules_build_tree() {
    local -a stack=()
    local token

    for token in "${POSTFIX[@]}"; do
        case "$token" in
            AND|OR)
                local right="${stack[-1]}"; unset 'stack[-1]'
                local left="${stack[-1]}"; unset 'stack[-1]'
                stack+=("OP:$token|L:$left|R:$right")
                ;;
            NOT)
                local child="${stack[-1]}"; unset 'stack[-1]'
                stack+=("OP:NOT|L:$child")
                ;;
            *)
                stack+=("ATOM:$token")
                ;;
        esac
    done

    # Debug pour vérifier
    ####echo "[DEBUG TREE] ROOT=${stack[-1]}" >&2

    # Affichage minimal pour l’instant
    echo "${stack[-1]}"
}

#############################################
#   8) CONSTRUCTION DE LA PILE D’ÉVALUATION
#############################################
####echo "[DEBUG DSL] POSTFIX = ${POSTFIX[*]}"

rules_build_stack() {
    local -a stack=()
    local token
    local out=""

    for token in "${POSTFIX[@]}"; do
        case "$token" in
            AND)
                local b="${stack[-1]}"; unset 'stack[-1]'
                local a="${stack[-1]}"; unset 'stack[-1]'
                local r=$(( a && b ))
                out+="AND ($a , $b) → $r"$'\n'
                stack+=("$r")
                ;;

            OR)
                local b="${stack[-1]}"; unset 'stack[-1]'
                local a="${stack[-1]}"; unset 'stack[-1]'
                local r=$(( a || b ))
                out+="OR ($a , $b) → $r"$'\n'
                stack+=("$r")
                ;;

            NOT)
                local a="${stack[-1]}"; unset 'stack[-1]'
                local r=$(( ! a ))
                out+="NOT ($a) → $r"$'\n'
                stack+=("$r")
                ;;

            *)
                if rules_eval_atom "$token"; then
                    out+="push true  ← $token"$'\n'
                    stack+=(1)
                else
                    out+="push false ← $token"$'\n'
                    stack+=(0)
                fi
                ;;
        esac
    done

    echo "$out"
}

#############################################
#   9) CHARGEMENT DES RÈGLES
#############################################

rules_load_file() {
    local file="$1"
    [[ -f "$file" ]] || return 0

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^# ]] && continue

        # Chaque ligne est une règle logique
        RULES+=("$line")
    done < "$file"
}

rules_load_all() {
    RULES_RAW=()
    POSTFIXES=()

    local file line cleaned
    local -a POSTFIX_LOCAL

    for file in "$RULES_DIR"/*.rules; do
        [[ -f "$file" ]] || continue

        while IFS= read -r line; do
            # Nettoyage
            cleaned="${line%%#*}"
            cleaned="$(echo "$cleaned" | sed 's/^[ \t]*//;s/[ \t]*$//')"

            [[ -z "$cleaned" ]] && continue

            # Stockage de la règle brute
            RULES_RAW+=("$cleaned")

            # Tokenisation + postfix
            rules_tokenize "$cleaned"
            rules_to_postfix

            # Stockage postfix
            POSTFIX_LOCAL=("${POSTFIX[@]}")
            POSTFIXES+=("${POSTFIX_LOCAL[*]}")


            ####echo "[DEBUG LOAD] Règle brute : $cleaned" >&2
            ####echo "[DEBUG LOAD] Postfix : ${POSTFIX[*]}" >&2
            ####echo "[DEBUG LOAD_ALL] POSTFIX après chargement : ${POSTFIX[*]}" >&2


        done < "$file"
    done
}

# Groupes de règles
declare -a RULES_TYPE RULES_PROFILE RULES_CATEGORY RULES_TEMPLATE RULES_GLOBAL

for rule in "${POSTFIXES[@]}"; do
    prefix="${rule%%=*}"

    case "$prefix" in
        DOC_TYPE)  RULES_TYPE+=("$rule") ;;
        PROFILE)   RULES_PROFILE+=("$rule") ;;
        CATEGORY)  RULES_CATEGORY+=("$rule") ;;
        TEMPLATE)  RULES_TEMPLATE+=("$rule") ;;
        *)         RULES_GLOBAL+=("$rule") ;;
    esac
done


