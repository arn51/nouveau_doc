#############################################
#   STACK EVAL — MODE CRT LÉGER
#############################################

stack_eval_crt() {
    local line

    local halo="${C_BLOOM}$(printf '%*s' 60 | tr ' ' '-')${C_RESET}"
    local fade="${C_DECAY1}$(printf '%*s' 60 | tr ' ' '.')${C_RESET}"

    echo -e "${C_OP}STACK EVAL :${C_RESET}"
    echo -e "$halo"

    while IFS= read -r line; do
        echo -e "${C_TRUE}${line}${C_RESET}"
    done <<< "$STACK_EVAL_CONTENT"

    echo -e "$fade"
}

