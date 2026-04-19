#############################################
#   RENDERER CRT — ARBRE LOGIQUE
#############################################

C_BRANCH="\033[38;5;240m"
C_RESET="\033[0m"

render_pulse_block() {
    local offset jitter wobble
    offset="$(crt_offset "$1")"
    jitter="$(crt_jitter)"
    wobble="$(beam_wobble)"
    printf "%b\n" "${offset}${jitter}${wobble}${2}"
}

render_effects_block() {
    local depth="$1"
    local offset jitter wobble
    offset="$(crt_offset "$depth")"
    jitter="$(crt_jitter)"
    wobble="$(beam_wobble)"

    printf "%b\n" "${offset}${jitter}${wobble}$(crt_bloom_line '*')"
    printf "%b\n" "${offset}${jitter}${wobble}$(crt_fade_line ':')"
    printf "%b\n" "${offset}${jitter}${wobble}$(crt_fade_line '.')"
    printf "%b\n" "${offset}${jitter}${wobble}$(crt_scanline)"
}

render_atom() {
    local atom="$1"
    local prefix="$2"
    local branch="$3"
    local depth="$4"

    local vignette="$(crt_vignette "$depth")"

    if rule_eval_atom "$atom"; then
        printf "%b\n" "${vignette}${prefix}${C_BRANCH}${branch}──${C_RESET} ${C_TRUE}${atom}${C_RESET}"
    else
        printf "%b\n" "${vignette}${prefix}${C_BRANCH}${branch}──${C_RESET} ${C_FALSE}${atom}${C_RESET}"
    fi

    render_effects_block "$depth"
}

render_operator() {
    local op="$1"
    local prefix="$2"
    local branch="$3"
    local depth="$4"

    local vignette="$(crt_vignette "$depth")"

    printf "%b\n" "${vignette}${prefix}${C_BRANCH}${branch}──${C_RESET} ${C_OP}${op}${C_RESET}"
    printf "%b\n" "$(crt_ghostline)"

    render_effects_block "$depth"
}

print_tree() {
    local node="$1"
    local prefix="$2"
    local branch="$3"
    local depth="$4"

    # ATOM
    if [[ "$node" =~ ^ATOM:(.*)$ ]]; then
        render_atom "${BASH_REMATCH[1]}" "$prefix" "$branch" "$depth"
        return
    fi

    # OP BINAIRE
    if [[ "$node" =~ ^OP:([A-Z]+)\|L:(.*)\|R:(.*)$ ]]; then
        local op="${BASH_REMATCH[1]}"
        local left="${BASH_REMATCH[2]}"
        local right="${BASH_REMATCH[3]}"

        render_operator "$op" "$prefix" "$branch" "$depth"

        local next_prefix="${prefix}${C_BRANCH}│   ${C_RESET}"
        print_tree "$left"  "$next_prefix" "├" $((depth+1))
        print_tree "$right" "$next_prefix" "└" $((depth+1))
        return
    fi

    # NOT
    if [[ "$node" =~ ^OP:NOT\|L:(.*)$ ]]; then
        local child="${BASH_REMATCH[1]}"

        render_operator "NOT" "$prefix" "$branch" "$depth"

        local next_prefix="${prefix}${C_BRANCH}│   ${C_RESET}"
        print_tree "$child" "$next_prefix" "└" $((depth+1))
        return
    fi
}

debug_tree() {
    echo "Arbre logique :"
    print_tree "$1" "" "" 0
}
