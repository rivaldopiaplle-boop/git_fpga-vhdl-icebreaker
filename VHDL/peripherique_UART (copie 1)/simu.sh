#!/bin/bash

# Vérification du nombre d'arguments
if [[ $# -lt 2 ]]; then
    echo "Usage: $0  -t <entity testbench> | -s <stop_time>"
    exit 1
fi

# Déclaration du tableau pour plusieurs fichiers -v
COMPONENT_FILES=()

# Traitement des options
while getopts "t:s:" opt; do
    case "$opt" in
        t)
            ENTITY_TB="$OPTARG"
            ;;
        s)
            STOP_TIME="$OPTARG"
            ;;
        *)
            echo "Option invalide"
            exit 1
            ;;
    esac
done

#ENTITY_TB=$(basename "$TESTBENCH_FILE" .vhd)

# Compilation des fichiers VHDL
#for file in "${COMPONENT_FILES[@]}"; do
#    ghdl -a "$file"
#done


#ghdl -a $COMPONENT_FILE
#ghdl -a $TESTBENCH_FILE
ghdl -e $ENTITY_TB
ghdl -r $ENTITY_TB --vcd=$ENTITY_TB.vcd --vcd-enums --stop-time=$STOP_TIME    
gtkwave $ENTITY_TB.vcd -a layout.gtkw
