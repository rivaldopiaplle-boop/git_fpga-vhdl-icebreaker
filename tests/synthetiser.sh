#!/usr/bin/env bash
# Synthétise chaque design pour la carte iCEBreaker (Lattice iCE40 UP5K, boîtier
# SG48) avec la chaîne libre : GHDL + Yosys, placement-routage nextpnr, puis
# icepack pour le fichier de programmation. Relève les ressources occupées.
#
# Outils : OSS CAD Suite (yosys avec le greffon ghdl, nextpnr-ice40, icepack).

set -uo pipefail
SORTIE="${SORTIE:-synthese}"
mkdir -p "$SORTIE"
MODULES=(VHDL/cmp_1bit VHDL/chenillard VHDL/chronometre VHDL/peripherique_UART VHDL/peripherique_UART2 uart)

echecs=0
for dossier in "${MODULES[@]}"; do
  nom="$(basename "$dossier")"
  travail="$(mktemp -d)"
  # Le design seul : le banc de test n'est pas synthétisable.
  sources=$(ls "$dossier"/*.vhd | grep -v '_tb\.vhd$')
  if ghdl -a --workdir="$travail" -fsynopsys $sources &&
     yosys -q -m ghdl -p "ghdl --workdir=$travail -fsynopsys icebreaker; synth_ice40 -top icebreaker -json $travail/d.json" > "$SORTIE/$nom.yosys.log" 2>&1 &&
     nextpnr-ice40 -q --up5k --package sg48 --pcf "$dossier/broches.pcf" --pcf-allow-unconstrained \
       --json "$travail/d.json" --asc "$travail/d.asc" --report "$SORTIE/$nom.rapport.json" > "$SORTIE/$nom.nextpnr.log" 2>&1 &&
     icepack "$travail/d.asc" "$SORTIE/$nom.bin"; then
    occupation=$(python3 -c "
import json
r = json.load(open('$SORTIE/$nom.rapport.json'))['utilization']
lc = r.get('ICESTORM_LC', {})
print(f\"{lc.get('used')} cellules logiques sur {lc.get('available')}\")")
    frequence=$(python3 -c "
import json
f = json.load(open('$SORTIE/$nom.rapport.json')).get('fmax', {})
print(', '.join(f'{v[\"achieved\"]:.0f} MHz' for v in f.values()) or '-')")
    echo "  OK     $nom : $occupation, horloge max $frequence"
  else
    echo "  ÉCHEC  $nom"; tail -5 "$SORTIE/$nom".*.log 2>/dev/null
    echecs=$((echecs + 1))
  fi
  rm -rf "$travail"
done

[ "$echecs" -eq 0 ] && echo "Tous les designs se synthétisent pour l'iCE40 UP5K." || { echo "$echecs design(s) en échec."; exit 1; }
