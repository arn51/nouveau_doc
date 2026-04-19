#############################################
#   EFFETS CRT — VERSION HARMONISÉE
#############################################

# Largeur standard des effets (option 3)
CRT_WIDTH=60

crt_offset() {
    local depth="$1"
    printf "%*s" "$((depth * 1))" ""
}

crt_jitter() {
    # Jitter léger (optionnel)
    printf ""
}

beam_wobble() {
    # Wobble léger (optionnel)
    printf ""
}

phosphor_grain() {
    local width="$1"
    local char="$2"
    printf '%*s' "$width" | tr ' ' "$char"
}

crt_bloom_line() {
    printf "%b" "${C_BLOOM}$(printf '%*s' $CRT_WIDTH | tr ' ' "$1")${C_RESET}"
}

crt_fade_line() {
    printf "%b" "${C_DECAY1}$(phosphor_grain $CRT_WIDTH "$1")${C_RESET}"
}

crt_scanline() {
    printf "%b" "${C_SCAN}$(printf '%*s' $CRT_WIDTH | tr ' ' '.')${C_RESET}"
}

crt_ghostline() {
    printf "%b" "${C_GHOST}$(printf '%*s' $CRT_WIDTH | tr ' ' '.')${C_RESET}"
}

crt_vignette() {
    local depth="$1"
    if (( depth >= 2 )); then
        printf "%b" "$C_VIG1"
    elif (( depth == 1 )); then
        printf "%b" "$C_VIG2"
    else
        printf "%b" "$C_VIG3"
    fi
}

