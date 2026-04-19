#!/usr/bin/env bash

#############################################
#   Nouveau Loader Minimaliste
#   (Option B – Architecture moderne)
#############################################

# --- 1) Chemins ---
ENGINE_DIR="$HOME/.local/bin/rules_engine"
MODULES_DIR="$ENGINE_DIR/modules"

# --- 2) Chargement des engines ---
source "$ENGINE_DIR/hooks_engine.sh"
source "$ENGINE_DIR/cli_engine.sh"
source "$ENGINE_DIR/context_engine.sh"
source "$ENGINE_DIR/plugins_engine.sh"
source "$ENGINE_DIR/rules_engine.sh"
source "$ENGINE_DIR/document_engine.sh"
source "$ENGINE_DIR/crt_palettes.sh"
source "$ENGINE_DIR/crt_effects.sh"
source "$ENGINE_DIR/tree_renderer.sh"
source "$ENGINE_DIR/stack_renderer.sh"
source "$ENGINE_DIR/modules_engine.sh"

