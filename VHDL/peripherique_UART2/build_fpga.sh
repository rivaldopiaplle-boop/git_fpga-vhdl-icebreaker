#!/bin/bash

# Vérification du nombre d'arguments
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 -e <entity name> | -p <pin_map_file.pcf>"
    exit 1
fi

# Traitement des options
while getopts "e:p:" opt; do
    case "$opt" in
        e)
            ENTITY_NAME="$OPTARG"
            echo "Fichier pour -e : $ENTITY_NAME"
            ;;
        p)
            PIN_MAP_FILE="$OPTARG"
            echo "Fichier pour -p : $PIN_MAP_FILE"
            ;;
        *)
            echo "Option invalide"
            exit 1
            ;;
    esac
done

# Vérifier qu'au moins une option a été fournie
if [[ -z "$ENTITY_NAME" && -z "$PIN_MAP_FILE" ]]; then
    echo "Erreur : Vous devez fournir soit -e <fichier>, soit -p <fichier>"
    exit 1
fi

# Étape 1 : Synthèse avec Yosys et GHDL
yosys -m ghdl.so -p "ghdl $ENTITY_NAME; proc; opt; fsm; opt; memory; opt; write_verilog $ENTITY_NAME.v"

# Vérification de la réussite de Yosys
if [[ $? -ne 0 ]]; then
    echo "Erreur lors de la synthèse avec Yosys/GHDL."
    exit 1
fi

# Étape 2 : Génération du JSON pour nextpnr-ice40
yosys -p "synth_ice40 -top $ENTITY_NAME -json $ENTITY_NAME.json" "$ENTITY_NAME.v"

# Vérification de la réussite de Yosys synth_ice40
if [[ $? -ne 0 ]]; then
    echo "Erreur lors de la génération du fichier JSON avec Yosys."
    exit 1
fi

# Étape 3 : Placement et routage avec nextpnr-ice40
nextpnr-ice40 --up5k --json "$ENTITY_NAME.json" --pcf "$PIN_MAP_FILE" --asc "$ENTITY_NAME.asc" --package sg48

# Vérification de la réussite de nextpnr
if [[ $? -ne 0 ]]; then
    echo "Erreur lors du placement et du routage avec nextpnr-ice40."
    exit 1
fi

# Étape 4 : Génération du fichier binaire avec icepack
icepack "$ENTITY_NAME.asc" "$ENTITY_NAME.bin"

# Vérification de la réussite d'icepack
if [[ $? -ne 0 ]]; then
    echo "Erreur lors de la génération du fichier binaire avec icepack."
    exit 1
fi

echo "Compilation terminée avec succès ! Fichier généré : $ENTITY_NAME.bin"

# programmation FPGA  
iceprog "$ENTITY_NAME.bin"
