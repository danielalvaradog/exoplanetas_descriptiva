#!/usr/bin/env python3
# Genera data_descriptiva_multi/README.md: diccionario de las 91 columnas.
# Descripciones basadas en la documentacion oficial del NASA Exoplanet Archive
# (https://exoplanetarchive.ipac.caltech.edu/docs/API_PS_columns.html), traducidas
# al espanol. Convierte los errores/limites en notas derivadas para evitar
# redundancia y garantizar cobertura completa del header.
import csv, sys

# Descripciones base (columnas de contenido y de texto). Unidades entre parentesis.
DESC = {
 "pl_name":          ("Nombre del planeta (convención nomenclatura IAU/Archivo).", "texto"),
 "hostname":         ("Nombre de la estrella hospedadora del planeta.", "texto"),
 "default_flag":     ("Marca de fila por defecto: 1 en la fila de parámetros de referencia del planeta (una por planeta); 0 en conjuntos alternativos de otras referencias.", "flag 0/1"),
 "sy_snum":          ("Número de estrellas en el sistema planetario.", "conteo"),
 "sy_pnum":          ("Número de planetas en el sistema.", "conteo"),
 "discoverymethod":  ("Método astrofísico con el que se detectó el planeta (tránsito, velocidad radial, microlente, imagen, temporización, etc.).", "texto"),
 "disc_year":        ("Año de publicación del descubrimiento del planeta.", "año"),
 "disc_facility":    ("Instalación / telescopio / misión que hizo la observación del descubrimiento.", "texto"),
 "soltype":          ("Tipo de solución del registro (estado de publicación: confirmado publicado, candidato de proyecto Kepler/TESS, etc.).", "texto"),
 "pl_refname":       ("Referencia bibliográfica principal de los parámetros planetarios (URL de ADS/repositorio).", "texto"),
 "pl_orbper":        ("Período orbital del planeta (tiempo en completar una órbita).", "días"),
 "pl_orbsmax":       ("Semieje mayor de la órbita del planeta alrededor de la estrella.", "UA"),
 "pl_rade":          ("Radio del planeta.", "R⊕"),
 "pl_radj":          ("Radio del planeta en unidades de Júpiter (duplicado exacto de pl_rade).", "Rjup"),
 "pl_bmasse":        ("Masa del planeta (masa más caracterizada del registro).", "M⊕"),
 "pl_bmassj":        ("Masa del planeta en unidades de Júpiter (duplicado exacto de pl_bmasse).", "Mjup"),
 "pl_bmassprov":     ("Naturaleza de la masa reportada: Mass (masa verdadera), Msini (masa mínima de RV) o Msin(i)/sin(i).", "texto"),
 "pl_orbeccen":      ("Excentricidad de la órbita (0 = circular).", "adim. [0,1]"),
 "pl_insol":         ("Flujo de insolación que recibe el planeta respecto a Tierra (densidad de flujo en la órbita).", "S⊕"),
 "pl_eqt":           ("Temperatura de equilibrio del planeta (con el supuesto de albedo usado por el archivo).", "K"),
 "ttv_flag":         ("Marca de variaciones del tiempo de tránsito (TTV) detectadas: 1 si el sistema exhibe TTV.", "flag 0/1"),
 "st_refname":       ("Referencia bibliográfica principal de los parámetros estelares.", "texto"),
 "st_spectype":      ("Tipo espectral de la estrella (clasificación de Morgan-Keenan, p. ej. G0 V).", "texto"),
 "st_teff":          ("Temperatura efectiva (fotosférica) de la estrella.", "K"),
 "st_rad":           ("Radio de la estrella.", "R☉"),
 "st_mass":          ("Masa de la estrella.", "M☉"),
 "st_met":           ("Metalicidad de la estrella (abundancia de metales, log10).", "log10(Fe/H)"),
 "st_metratio":      ("Escala de la metalicidad reportada: [Fe/H] (solo hierro), [M/H] (todos los metales) o [m/H].", "texto"),
 "st_logg":          ("Gravedad superficial de la estrella (expresada logarítmicamente).", "log10(cm/s²)"),
 "sy_refname":       ("Referencia bibliográfica principal de los parámetros del sistema.", "texto"),
 "rastr":            ("Coordenada RA de la estrella en formato sexagesimal de arco ('hh mm ss.s').", "texto"),
 "ra":               ("Ascensión recta (RA) del sistema (equinoccio J2000).", "horas [0, 24)"),
 "decstr":           ("Coordenada Dec de la estrella en formato sexagesimal ('±dd mm ss.s').", "texto"),
 "dec":              ("Declinación (Dec) del sistema (equinoccio J2000).", "grados [−90, +90]"),
 "sy_dist":          ("Distancia al sistema (medida de parallax de Gaia u otra fuente).", "parsecs"),
 "sy_vmag":          ("Magnitud aparente del sistema en banda V de Johnson.", "mag"),
 "sy_kmag":          ("Magnitud aparente del sistema en banda K infrarroja.", "mag"),
 "sy_gaiamag":       ("Magnitud aparente del sistema en la banda G de Gaia.", "mag"),
 "rowupdate":        ("Fecha en la que se actualizó por última vez esta fila en el archivo.", "fecha YYYY-MM-DD"),
 "pl_pubdate":       ("Fecha (mes) de publicación de la medición o parámetro del planeta.", "año-mes YYYY-MM"),
 "releasedate":      ("Fecha en que el registro se añadió/añadirá al archivo público.", "fecha YYYY-MM-DD"),
}

# Nombres legibles para las bases de errores/limites:
BASES = {
 "pl_orbper":"período orbital (pl_orbper)", "pl_orbsmax":"semieje mayor (pl_orbsmax)",
 "pl_rade":"radio planetario (pl_rade)", "pl_radj":"radio en Rjup (pl_radj)",
 "pl_bmasse":"masa en M⊕ (pl_bmasse)", "pl_bmassj":"masa en Mjup (pl_bmassj)",
 "pl_orbeccen":"excentricidad (pl_orbeccen)", "pl_insol":"insolación (pl_insol)",
 "pl_eqt":"temperatura de equilibrio (pl_eqt)", "st_teff":"temperatura efectiva estelar (st_teff)",
 "st_rad":"radio estelar (st_rad)", "st_mass":"masa estelar (st_mass)",
 "st_met":"metalicidad (st_met)", "st_logg":"gravedad superficial (st_logg)",
 "sy_dist":"distancia al sistema (sy_dist)", "sy_vmag":"magnitud V (sy_vmag)",
 "sy_kmag":"magnitud K (sy_kmag)", "sy_gaiamag":"magnitud G de Gaia (sy_gaiamag)",
}

def descripcion(col):
    """Descripcion de una columna: base directa o derivada por sufijo."""
    if col in DESC:
        return DESC[col]
    if col.endswith("err1"):
        base = col[:-4]
        return f"Incertidumbre positiva (asimétrica superior) de la {BASES[base]}."
    if col.endswith("err2"):
        base = col[:-4]
        return f"Incertidumbre negativa (asimétrica inferior) de la {BASES[base]}."
    if col.endswith("lim"):
        base = col[:-3]
        return f"Bandera de límite: 0 si {base} es un valor medido; 1 si es un límite (superior o inferior) y no una medición."
    return "SIN DESCRIPCION"

CONTEXTO = {
 "pl_name":"identificacion", "hostname":"identificacion", "default_flag":"identificacion",
 "sy_snum":"identificacion", "sy_pnum":"identificacion",
 "discoverymethod":"descubrimiento", "disc_year":"descubrimiento", "disc_facility":"descubrimiento",
 "soltype":"descubrimiento", "pl_refname":"descubrimiento",
 "pl_orbper":"planeta", "pl_orbsmax":"planeta", "pl_rade":"planeta", "pl_radj":"planeta",
 "pl_bmasse":"planeta", "pl_bmassj":"planeta", "pl_bmassprov":"planeta",
 "pl_orbeccen":"planeta", "pl_insol":"planeta", "pl_eqt":"planeta", "ttv_flag":"planeta",
 "st_refname":"estrella", "st_spectype":"estrella", "st_teff":"estrella", "st_rad":"estrella",
 "st_mass":"estrella", "st_met":"estrella", "st_metratio":"estrella", "st_logg":"estrella",
 "sy_refname":"sistema", "rastr":"sistema", "ra":"sistema", "decstr":"sistema", "dec":"sistema",
 "sy_dist":"sistema", "sy_vmag":"sistema", "sy_kmag":"sistema", "sy_gaiamag":"sistema",
 "rowupdate":"administracion", "pl_pubdate":"administracion", "releasedate":"administracion",
}  # contexto del SISTEMA (sy_refname, coords, distancias, magnitudes, fechas)

SECCIONES = [
 ("identificacion", "2.1 Identificación y estructura del catálogo"),
 ("descubrimiento", "2.2 Descubrimiento y publicación"),
 ("planeta",        "2.3 Parámetros planetarios (contenido)"),
 ("estrella",       "2.4 Parámetros estelares (contenido)"),
 ("sistema",        "2.5 Posición, distancia y fotometría del sistema"),
 ("administracion", "2.6 Fechas administrativas del archivo"),
]

BASES_CON_ERRORES = list(BASES.keys())
HDR = "| Columna | Descripción | Unidad / tipo |\n|---|---|---|\n"
ROW = "| `{}` | {} | {} |\n"

with open("data_descriptiva_multi/NASA_Exoplanet_Archive_Data.csv", newline="") as f:
    cols = csv.DictReader(f).fieldnames
assert len(cols) == 91, f"se esperaban 91 columnas, hay {len(cols)}"

file = open("data_descriptiva_multi/README.md", "w", encoding="utf-8")
w = file.write
w("""# Diccionario de datos — NASA Exoplanet Archive

Referencia completa de las **91 columnas** de
`NASA_Exoplanet_Archive_Data.csv` (36.418 filas). Descripciones traducidas de
la documentación oficial del
[NASA Exoplanet Archive](https://exoplanetarchive.ipac.caltech.edu/docs/API_PS_columns.html)
(tabla *Planetary Systems*, PS).

## Cómo leer este catálogo

- **Filas**: el catálogo tiene **varias filas por planeta** (36.418 filas ↔
  5.757 planetas únicos). La fila con `default_flag = 1` es el conjunto de
  parámetros de referencia de cada planeta; el resto son conjuntos
  alternativos de otras referencias bibliográficas.
- **Metadatos de precisión**: cada parámetro medido llega con
  `*err1` / `*err2` (incertidumbres asimétricas ±) y/o `*lim` (bandera de
  límite). Cubren 18 variables de contenido.

## 1. Convención de sufijos de precisión (18 bases × 50 columnas)

| Sufijo | Significado |
|---|---|
| `*err1` | Incertidumbre **positiva** (la mitad superior del error asimétrico) |
| `*err2` | Incertidumbre **negativa** (la mitad inferior, normalmente con signo distinto al de err1) |
| `*lim`  | Bandera de **límite**: 0 = valor medido; 1 = el valor es un límite superior o inferior |

Las bases que tienen estos sufijos son: `pl_orbper`, `pl_orbsmax`, `pl_rade`,
`pl_radj`, `pl_bmasse`, `pl_bmassj`, `pl_orbeccen`, `pl_insol`, `pl_eqt`,
`st_teff`, `st_rad`, `st_mass`, `st_met`, `st_logg`, `sy_dist`, `sy_vmag`,
`sy_kmag`, `sy_gaiamag`.

## 2. Columnas de contenido (41 columnas)

""")

for id_seccion, titulo in SECCIONES:
    w(f"### {titulo}\n\n")
    w(HDR)
    for col in cols:
        if CONTEXTO.get(col) == id_seccion:
            desc, unidad = DESC[col]
            w(ROW.format(col, desc.replace("|", "/"), unidad))
    w("\n")

w("""## 3. Metadatos de precisión (50 columnas)

Se listan las 50 columnas de metadatos restantes; su significado se resume en
la convención de la sección 1.

### 3.1 Incertidumbres (`*err1` — 18 columnas)

""")
for col in cols:
    if col.endswith("err1"):
        base = col[:-4]
        w(ROW.format(col, f"Incertidumbre positiva de la {BASES[base]}.", "unidad de la base"))

w("\n### 3.2 Incertidumbres (`*err2` — 18 columnas)\n\n")
for col in cols:
    if col.endswith("err2"):
        base = col[:-4]
        w(ROW.format(col, f"Incertidumbre negativa de la {BASES[base]}.", "unidad de la base"))

n_lim = sum(1 for c in cols if c.endswith("lim") and c not in DESC)
w("\n### 3.3 Banderas de límite (`*lim` — 14 columnas)\n\n")
for col in cols:
    if col.endswith("lim") and col not in DESC:
        base = col[:-3]
        w(ROW.format(col, f"Bandera de límite de la {BASES[base]}: 0 = valor medido; 1 = límite.", "0 / 1"))

verificacion = sum(1 for c in cols if c in DESC) + \
               sum(1 for c in cols if c.endswith(("err1","err2"))) + \
               sum(1 for c in cols if c.endswith("lim") and c not in DESC)
assert verificacion == len(cols), f"cobertura {verificacion} de {len(cols)}: faltaron {[c for c in cols if descripcion(c)=='SIN DESCRIPCION']}"
w(f"\n---\n\n*Cobertura verificada: {verificacion}/{len(cols)} columnas documentadas.*\n")
file.close()
print("README.md del diccionario generado, cobertura:", verificacion, "/", len(cols))
