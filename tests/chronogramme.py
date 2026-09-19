"""Trace un chronogramme SVG à partir d'une trace VCD de GHDL, sans GTKWave.

    python tests/chronogramme.py simulations/uart_verif.vcd uart.svg \
        --signaux uart_verif_tb.start uart_verif_tb.tx uart_verif_tb.ready \
        --debut 0 --fin 2ms --titre "UART : deux trames"

Les signaux se désignent par leur chemin (portée.nom). Sans --signaux, tous les
signaux du banc de test sont tracés, horloge exclue : à l'échelle d'un
chronogramme lisible, elle ne serait qu'un aplat.
"""
import argparse
import re
import sys
from xml.sax.saxutils import escape

UNITES = {"fs": 1e-15, "ps": 1e-12, "ns": 1e-9, "us": 1e-6, "ms": 1e-3, "s": 1.0, "sec": 1.0}


def en_secondes(texte):
    m = re.fullmatch(r"\s*([\d.]+)\s*(fs|ps|ns|us|ms|sec|s)?\s*", texte)
    if not m:
        raise ValueError(f"durée illisible : {texte}")
    return float(m.group(1)) * UNITES[m.group(2) or "s"]


def lire_vcd(chemin, voulus, fin_s):
    """Renvoie {chemin: (largeur, [(t_s, valeur), ...])} pour les signaux voulus."""
    echelle = 1e-15
    portees, ids, largeurs, traces = [], {}, {}, {}
    t = 0.0
    with open(chemin, encoding="ascii", errors="replace") as f:
        en_tete = True
        for ligne in f:
            ligne = ligne.strip()
            if not ligne:
                continue
            if en_tete:
                if ligne.startswith("$timescale"):
                    m = re.search(r"(\d+)\s*(fs|ps|ns|us|ms|s)", ligne + next(f, ""))
                    echelle = int(m.group(1)) * UNITES[m.group(2)]
                elif ligne.startswith("$scope"):
                    portees.append(ligne.split()[2])
                elif ligne.startswith("$upscope"):
                    portees.pop()
                elif ligne.startswith("$var"):
                    _, _, largeur, code, nom, *_ = ligne.split()
                    nom = nom.split("[")[0]  # « donnee[7:0] » se désigne « donnee »
                    chemin_sig = ".".join(portees + [nom])
                    if voulus is None and len(portees) == 1 and nom != "clk":
                        voulus_implicites.append(chemin_sig)
                    ids.setdefault(code, []).append(chemin_sig)
                    largeurs[chemin_sig] = int(largeur)
                elif ligne.startswith("$enddefinitions"):
                    en_tete = False
                    cibles = set(voulus or voulus_implicites)
                    for code in list(ids):
                        ids[code] = [c for c in ids[code] if c in cibles]
                        for c in ids[code]:
                            traces[c] = []
                continue
            if ligne[0] == "#":
                t = int(ligne[1:]) * echelle
                if t > fin_s:
                    break
            elif ligne[0] in "01xXzZuUwWlLhH-":
                for c in ids.get(ligne[1:], ()):
                    traces[c].append((t, ligne[0].lower()))
            elif ligne[0] in "bB":
                valeur, code = ligne[1:].split()
                for c in ids.get(code, ()):
                    traces[c].append((t, valeur.lower()))
    ordre = voulus or voulus_implicites
    return [(c, largeurs[c], traces[c]) for c in ordre if c in traces]


voulus_implicites = []


def valeur_lisible(v, largeur):
    if largeur == 1:
        return v
    if any(ch not in "01" for ch in v):
        return "x"
    n = int(v, 2)
    return f"{n}" if largeur < 8 else f"0x{n:0{largeur // 4}X}"


def tracer(signaux, debut, fin, titre, sortie):
    marge_g, largeur_trace, hauteur_ligne, haut = 190, 900, 34, 46
    hauteur = haut + hauteur_ligne * len(signaux) + 40
    largeur = marge_g + largeur_trace + 20

    def x(t):
        return marge_g + (min(max(t, debut), fin) - debut) / (fin - debut) * largeur_trace

    svg = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{largeur}" height="{hauteur}" '
        f'viewBox="0 0 {largeur} {hauteur}" font-family="ui-monospace, Consolas, monospace" font-size="12">',
        f'<rect width="{largeur}" height="{hauteur}" fill="#f7f7f5"/>',
        f'<text x="16" y="26" font-size="15" font-weight="bold" fill="#1d2433">{escape(titre)}</text>',
    ]
    for i, (chemin, large, points) in enumerate(signaux):
        y0 = haut + i * hauteur_ligne
        bas, haut_sig = y0 + 24, y0 + 6
        svg.append(f'<line x1="{marge_g}" y1="{y0 + 30}" x2="{marge_g + largeur_trace}" y2="{y0 + 30}" stroke="#e2e2de"/>')
        svg.append(f'<text x="16" y="{y0 + 19}" fill="#1d2433">{escape(chemin.split(".")[-1])}</text>')
        # Valeur au début de la fenêtre, puis changements dans la fenêtre
        courant = "x"
        segments = []
        for t, v in points:
            if t <= debut:
                courant = v
            elif t < fin:
                segments.append((t, v))
        instants = [(debut, courant)] + segments + [(fin, None)]
        if large == 1:
            chemin_svg = []
            for (t1, v), (t2, _) in zip(instants, instants[1:]):
                y = haut_sig if v in ("1", "h") else bas if v in ("0", "l") else (haut_sig + bas) / 2
                chemin_svg.append(f"L{x(t1):.1f},{y} L{x(t2):.1f},{y}")
            d = "M" + " ".join(chemin_svg)[1:]
            svg.append(f'<path d="{d}" fill="none" stroke="#2f6fd6" stroke-width="1.6"/>')
        else:
            for (t1, v), (t2, _) in zip(instants, instants[1:]):
                x1, x2 = x(t1), x(t2)
                svg.append(f'<polygon points="{x1 + 2},{haut_sig} {x2 - 2},{haut_sig} {x2},{(haut_sig + bas) / 2} '
                           f'{x2 - 2},{bas} {x1 + 2},{bas} {x1},{(haut_sig + bas) / 2}" '
                           f'fill="#e8eefb" stroke="#2f6fd6" stroke-width="1.2"/>')
                texte = valeur_lisible(v, large)
                if x2 - x1 > 8 * len(texte) + 6:
                    svg.append(f'<text x="{(x1 + x2) / 2:.1f}" y="{bas - 5}" text-anchor="middle" fill="#1d2433">{escape(texte)}</text>')
    # Graduation temporelle
    y_axe = haut + hauteur_ligne * len(signaux) + 14
    for k in range(6):
        t = debut + (fin - debut) * k / 5
        for unite, facteur in (("s", 1), ("ms", 1e-3), ("us", 1e-6), ("ns", 1e-9)):
            if (fin - debut) >= facteur * 5 or unite == "ns":
                etiquette = f"{t / facteur:g} {unite}"
                break
        svg.append(f'<text x="{x(t):.1f}" y="{y_axe}" text-anchor="middle" fill="#6b7280">{etiquette}</text>')
    svg.append("</svg>")
    with open(sortie, "w", encoding="utf-8") as f:
        f.write("\n".join(svg))


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("vcd")
    p.add_argument("svg")
    p.add_argument("--signaux", nargs="*")
    p.add_argument("--debut", default="0")
    p.add_argument("--fin", required=True)
    p.add_argument("--titre", default="")
    a = p.parse_args()
    debut, fin = en_secondes(a.debut), en_secondes(a.fin)
    signaux = lire_vcd(a.vcd, a.signaux, fin)
    if not signaux:
        sys.exit("Aucun signal trouvé : vérifier les chemins (portée.nom).")
    tracer(signaux, debut, fin, a.titre or a.vcd, a.svg)
    print(f"{a.svg} : {len(signaux)} signaux")


if __name__ == "__main__":
    main()
