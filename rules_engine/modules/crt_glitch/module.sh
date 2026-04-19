module_register() {
    crt_glitch_line() {
        local chars="▒░▓█"
        local out=""
        for i in {1..60}; do
            out+="${chars:RANDOM%4:1}"
        done
        printf "%b" "\033[38;5;199m$out\033[0m"
    }

    # Hook : remplace scanline
    crt_scanline() {
        crt_glitch_line
    }

    echo "[MODULE] CRT Glitch activé"
}
