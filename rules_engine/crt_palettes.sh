#############################################
#   PALETTES CRT
#############################################

crt_palette_amber() {
    C_BLOOM="\033[38;5;214m"
    C_PULSE_LOW="\033[38;5;130m"
    C_PULSE_MED="\033[38;5;208m"
    C_PULSE_HIGH="\033[38;5;220m"

    C_DECAY1="\033[38;5;178m"
    C_DECAY2="\033[38;5;94m"

    C_SCAN="\033[38;5;94m"
    C_GHOST="\033[38;5;52m"

    C_VIG1="\033[38;5;94m"
    C_VIG2="\033[38;5;52m"
    C_VIG3="\033[38;5;16m"

    C_OP="\033[38;5;214m"
    C_TRUE="\033[38;5;220m"
    C_FALSE="\033[38;5;94m"
}

crt_palette_blue() {
    C_BLOOM="\033[38;5;81m"
    C_PULSE_LOW="\033[38;5;75m"
    C_PULSE_MED="\033[38;5;111m"
    C_PULSE_HIGH="\033[38;5;123m"

    C_DECAY1="\033[38;5;75m"
    C_DECAY2="\033[38;5;25m"

    C_SCAN="\033[38;5;24m"
    C_GHOST="\033[38;5;17m"

    C_VIG1="\033[38;5;18m"
    C_VIG2="\033[38;5;17m"
    C_VIG3="\033[38;5;16m"

    C_OP="\033[38;5;81m"
    C_TRUE="\033[38;5;117m"
    C_FALSE="\033[38;5;25m"
}

crt_palette_green() {
    C_BLOOM="\033[38;5;118m"
    C_PULSE_LOW="\033[38;5;70m"
    C_PULSE_MED="\033[38;5;112m"
    C_PULSE_HIGH="\033[38;5;120m"

    C_DECAY1="\033[38;5;70m"
    C_DECAY2="\033[38;5;22m"

    C_SCAN="\033[38;5;22m"
    C_GHOST="\033[38;5;22m"

    C_VIG1="\033[38;5;22m"
    C_VIG2="\033[38;5;16m"
    C_VIG3="\033[38;5;0m"

    C_OP="\033[38;5;118m"
    C_TRUE="\033[38;5;120m"
    C_FALSE="\033[38;5;28m"
}

crt_palette_white() {
    C_BLOOM="\033[38;5;255m"
    C_PULSE_LOW="\033[38;5;250m"
    C_PULSE_MED="\033[38;5;252m"
    C_PULSE_HIGH="\033[38;5;255m"

    C_DECAY1="\033[38;5;250m"
    C_DECAY2="\033[38;5;245m"

    C_SCAN="\033[38;5;240m"
    C_GHOST="\033[38;5;236m"

    C_VIG1="\033[38;5;236m"
    C_VIG2="\033[38;5;235m"
    C_VIG3="\033[38;5;233m"

    C_OP="\033[38;5;255m"
    C_TRUE="\033[38;5;255m"
    C_FALSE="\033[38;5;250m"
}

crt_set_mode() {
    case "$1" in
        blue)  crt_palette_blue ;;
        green) crt_palette_green ;;
        white) crt_palette_white ;;
        amber|*) crt_palette_amber ;;
    esac
}
