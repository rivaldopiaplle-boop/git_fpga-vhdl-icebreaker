#!/usr/bin/env bash
# Trace les chronogrammes des simulations (à lancer après tests/simuler.sh).
set -euo pipefail
S="${SORTIE:-simulations}"
C="${CHRONOGRAMMES:-chronogrammes}"
mkdir -p "$C"
PY="$(command -v python3 || command -v python)"
t() { "$PY" tests/chronogramme.py "$@"; }
tb=icebreaker_tb

t "$S/cmp_1bit.vcd" "$C/cmp_1bit.svg" --fin 5ms \
  --titre "Comparateur 1 bit : les LED suivent les boutons"
t "$S/chenillard.vcd" "$C/chenillard.svg" --fin 7s \
  --signaux $tb.btn_n $tb.led1 $tb.led2 $tb.led3 \
  --titre "Chenillard : les LED s'allument tour à tour"
t "$S/chronometre.vcd" "$C/chronometre.svg" --fin 80ms \
  --signaux $tb.btn_n $tb.btn1 $tb.btn2 $tb.btn3 $tb.led2 $tb.led3 $tb.led4 \
  --titre "Chronomètre : machine d'états (btn1 zéro, btn2 marche, btn3 pause ; LED2 à LED4 : l'état)"
t "$S/peripherique_UART2.vcd" "$C/uart-peripherique.svg" --fin 250ms \
  --signaux $tb.btn_n $tb.btn1 $tb.btn2 $tb.btn3 $tb.tx $tb.led_red_n \
  --titre "Périphérique UART : trames émises sur TX (horloge du banc ralentie : 4,4 ms par bit)"
t "$S/uart_verif.vcd" "$C/uart-verif.svg" --fin 110us \
  --signaux uart_verif_tb.reset uart_verif_tb.ld_t uart_verif_tb.start uart_verif_tb.donnee uart_verif_tb.tx uart_verif_tb.ready \
  --titre "UART vérifiée : 0x55 puis 0xA3, décodés et comparés (226 416 bauds)"
