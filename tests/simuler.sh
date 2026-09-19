#!/usr/bin/env bash
# Simule chaque module avec GHDL : compilation dans un dossier de travail à part
# (les sources restent propres), puis exécution du banc de test et trace VCD.
#
#   bash tests/simuler.sh            (GHDL installé)
#   docker run --rm -v "$PWD":/src -w /src ghdl/ghdl:ubuntu22-mcode bash tests/simuler.sh
#
# Sort en erreur si un module ne compile pas, ou si une assertion de sévérité
# « error » échoue pendant la simulation.

set -uo pipefail
SORTIE="${SORTIE:-simulations}"
mkdir -p "$SORTIE"

# module : durée simulée (les bancs ralentissent l'horloge à 12 kHz, sauf cmp_1bit).
# MicroPDM est absent : son design est inachevé et ne compile pas encore.
MODULES=(
  "VHDL/cmp_1bit:5ms"
  "VHDL/chenillard:7sec"
  "VHDL/chronometre:80ms"
  "VHDL/peripherique_UART:250ms"
  "VHDL/peripherique_UART2:250ms"
  "uart:15ms"
)

# Accélération : les diviseurs comptent des millions de cycles avant chaque
# changement visible, ce qui prendrait des heures à simuler. Comme l'auteur
# l'avait noté en commentaire, la simulation les divise par mille, sur une
# copie des sources : les fichiers du dépôt gardent les valeurs de la carte.
declare -A ACCELERATION=(
  ["VHDL/chenillard"]='s/x"0B71B00"/x"0002EE0"/; s/x"16E3600"/x"0005DC0"/; s/x"2255100"/x"0008CA0"/'
)

echecs=0
for entree in "${MODULES[@]}"; do
  dossier="${entree%%:*}"
  duree="${entree##*:}"
  nom="$(basename "$dossier")"
  travail="$(mktemp -d)"
  mkdir -p "$travail/src"
  cp "$dossier"/*.vhd "$travail/src/"
  if [ -n "${ACCELERATION[$dossier]:-}" ]; then
    sed -i "${ACCELERATION[$dossier]}" "$travail"/src/*.vhd
  fi
  if ghdl -i --workdir="$travail" -fsynopsys "$travail"/src/*.vhd &&
     ghdl -m --workdir="$travail" -fsynopsys icebreaker_tb > /dev/null &&
     ghdl -r --workdir="$travail" -fsynopsys icebreaker_tb \
          --vcd="$SORTIE/$nom.vcd" --stop-time="$duree" --assert-level=error > "$SORTIE/$nom.log" 2>&1; then
    echo "  OK     $nom ($duree simulées)"
  else
    echo "  ÉCHEC  $nom"; tail -5 "$SORTIE/$nom.log" 2>/dev/null
    echecs=$((echecs + 1))
  fi
  rm -rf "$travail"
done

# Vérification automatique : l'UART décodée comme le ferait un PC (tests/uart_verif_tb.vhd).
travail="$(mktemp -d)"
if ghdl -i --workdir="$travail" -fsynopsys uart/uart.vhd tests/uart_verif_tb.vhd &&
   ghdl -m --workdir="$travail" -fsynopsys uart_verif_tb > /dev/null &&
   ghdl -r --workdir="$travail" -fsynopsys uart_verif_tb         --vcd="$SORTIE/uart_verif.vcd" --stop-time=10ms --assert-level=error > "$SORTIE/uart_verif.log" 2>&1; then
  echo "  OK     uart_verif : $(grep -o 'UART verifiee.*' "$SORTIE/uart_verif.log")"
  echo "         $(grep -o 'Debit mesure.*' "$SORTIE/uart_verif.log")"
else
  echo "  ÉCHEC  uart_verif"; grep -E "error|Debit" "$SORTIE/uart_verif.log" | head -5
  echecs=$((echecs + 1))
fi
rm -rf "$travail"

[ "$echecs" -eq 0 ] && echo "Tous les modules se simulent." || { echo "$echecs module(s) en échec."; exit 1; }
