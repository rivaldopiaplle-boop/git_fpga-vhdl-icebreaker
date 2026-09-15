# FPGA : périphériques en VHDL sur iCEBreaker

Travaux de conception matérielle en VHDL sur la carte iCEBreaker (FPGA Lattice iCE40, horloge 12 MHz), du comparateur au périphérique UART complet, chaque module avec son banc de test.

## Ce que contient le dossier

| Dossier | Contenu | Lignes VHDL |
|---|---|---|
| `VHDL/cmp_1bit/` | Comparateur 1 bit : premier module et son banc de test | ~110 |
| `VHDL/chenillard/` | Chenillard sur les LED | ~160 |
| `VHDL/chronometre/` | Chronomètre : compteurs cascadés, affichage | ~390 |
| `VHDL/peripherique_UART/` | Transmission UART | ~550 |
| `VHDL/peripherique_UART2/` | UART complet : générateur de débit (230 400 bauds), émission, réception | ~825 |
| `VHDL/MicroPDM/` | Acquisition d'un microphone PDM et envoi par UART | ~600 |
| `uart/` | Version isolée du module UART | - |

Chaque dossier contient `icebreaker.vhd` (le design) et `icebreaker_tb.vhd` (le banc de test).

## Reprendre le projet

- **Simulation** : GHDL + GTKWave, `ghdl -a icebreaker.vhd icebreaker_tb.vhd && ghdl -r icebreaker_tb --vcd=onde.vcd`
- **Synthèse et programmation** : chaîne libre Yosys + nextpnr-ice40 + icepack/iceprog, ou l'environnement fourni en cours

## À améliorer

- [ ] Supprimer `peripherique_UART (copie 1)` et les zip redondants une fois vérifiés
- [ ] Un `Makefile` commun : simulation, synthèse, programmation
- [ ] Captures des chronogrammes des bancs de test pour la fiche du portfolio
- [ ] Schéma de l'architecture du périphérique UART
