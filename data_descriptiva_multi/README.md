# Diccionario de datos — NASA Exoplanet Archive

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

### 2.1 Identificación y estructura del catálogo

| Columna | Descripción | Unidad / tipo |
|---|---|---|
| `pl_name` | Nombre del planeta (convención nomenclatura IAU/Archivo). | texto |
| `hostname` | Nombre de la estrella hospedadora del planeta. | texto |
| `default_flag` | Marca de fila por defecto: 1 en la fila de parámetros de referencia del planeta (una por planeta); 0 en conjuntos alternativos de otras referencias. | flag 0/1 |
| `sy_snum` | Número de estrellas en el sistema planetario. | conteo |
| `sy_pnum` | Número de planetas en el sistema. | conteo |

### 2.2 Descubrimiento y publicación

| Columna | Descripción | Unidad / tipo |
|---|---|---|
| `discoverymethod` | Método astrofísico con el que se detectó el planeta (tránsito, velocidad radial, microlente, imagen, temporización, etc.). | texto |
| `disc_year` | Año de publicación del descubrimiento del planeta. | año |
| `disc_facility` | Instalación / telescopio / misión que hizo la observación del descubrimiento. | texto |
| `soltype` | Tipo de solución del registro (estado de publicación: confirmado publicado, candidato de proyecto Kepler/TESS, etc.). | texto |
| `pl_refname` | Referencia bibliográfica principal de los parámetros planetarios (URL de ADS/repositorio). | texto |

### 2.3 Parámetros planetarios (contenido)

| Columna | Descripción | Unidad / tipo |
|---|---|---|
| `pl_orbper` | Período orbital del planeta (tiempo en completar una órbita). | días |
| `pl_orbsmax` | Semieje mayor de la órbita del planeta alrededor de la estrella. | UA |
| `pl_rade` | Radio del planeta. | R⊕ |
| `pl_radj` | Radio del planeta en unidades de Júpiter (duplicado exacto de pl_rade). | Rjup |
| `pl_bmasse` | Masa del planeta (masa más caracterizada del registro). | M⊕ |
| `pl_bmassj` | Masa del planeta en unidades de Júpiter (duplicado exacto de pl_bmasse). | Mjup |
| `pl_bmassprov` | Naturaleza de la masa reportada: Mass (masa verdadera), Msini (masa mínima de RV) o Msin(i)/sin(i). | texto |
| `pl_orbeccen` | Excentricidad de la órbita (0 = circular). | adim. [0,1] |
| `pl_insol` | Flujo de insolación que recibe el planeta respecto a Tierra (densidad de flujo en la órbita). | S⊕ |
| `pl_eqt` | Temperatura de equilibrio del planeta (con el supuesto de albedo usado por el archivo). | K |
| `ttv_flag` | Marca de variaciones del tiempo de tránsito (TTV) detectadas: 1 si el sistema exhibe TTV. | flag 0/1 |

### 2.4 Parámetros estelares (contenido)

| Columna | Descripción | Unidad / tipo |
|---|---|---|
| `st_refname` | Referencia bibliográfica principal de los parámetros estelares. | texto |
| `st_spectype` | Tipo espectral de la estrella (clasificación de Morgan-Keenan, p. ej. G0 V). | texto |
| `st_teff` | Temperatura efectiva (fotosférica) de la estrella. | K |
| `st_rad` | Radio de la estrella. | R☉ |
| `st_mass` | Masa de la estrella. | M☉ |
| `st_met` | Metalicidad de la estrella (abundancia de metales, log10). | log10(Fe/H) |
| `st_metratio` | Escala de la metalicidad reportada: [Fe/H] (solo hierro), [M/H] (todos los metales) o [m/H]. | texto |
| `st_logg` | Gravedad superficial de la estrella (expresada logarítmicamente). | log10(cm/s²) |

### 2.5 Posición, distancia y fotometría del sistema

| Columna | Descripción | Unidad / tipo |
|---|---|---|
| `sy_refname` | Referencia bibliográfica principal de los parámetros del sistema. | texto |
| `rastr` | Coordenada RA de la estrella en formato sexagesimal de arco ('hh mm ss.s'). | texto |
| `ra` | Ascensión recta (RA) del sistema (equinoccio J2000). | horas [0, 24) |
| `decstr` | Coordenada Dec de la estrella en formato sexagesimal ('±dd mm ss.s'). | texto |
| `dec` | Declinación (Dec) del sistema (equinoccio J2000). | grados [−90, +90] |
| `sy_dist` | Distancia al sistema (medida de parallax de Gaia u otra fuente). | parsecs |
| `sy_vmag` | Magnitud aparente del sistema en banda V de Johnson. | mag |
| `sy_kmag` | Magnitud aparente del sistema en banda K infrarroja. | mag |
| `sy_gaiamag` | Magnitud aparente del sistema en la banda G de Gaia. | mag |

### 2.6 Fechas administrativas del archivo

| Columna | Descripción | Unidad / tipo |
|---|---|---|
| `rowupdate` | Fecha en la que se actualizó por última vez esta fila en el archivo. | fecha YYYY-MM-DD |
| `pl_pubdate` | Fecha (mes) de publicación de la medición o parámetro del planeta. | año-mes YYYY-MM |
| `releasedate` | Fecha en que el registro se añadió/añadirá al archivo público. | fecha YYYY-MM-DD |

## 3. Metadatos de precisión (50 columnas)

Se listan las 50 columnas de metadatos restantes; su significado se resume en
la convención de la sección 1.

### 3.1 Incertidumbres (`*err1` — 18 columnas)

| `pl_orbpererr1` | Incertidumbre positiva de la período orbital (pl_orbper). | unidad de la base |
| `pl_orbsmaxerr1` | Incertidumbre positiva de la semieje mayor (pl_orbsmax). | unidad de la base |
| `pl_radeerr1` | Incertidumbre positiva de la radio planetario (pl_rade). | unidad de la base |
| `pl_radjerr1` | Incertidumbre positiva de la radio en Rjup (pl_radj). | unidad de la base |
| `pl_bmasseerr1` | Incertidumbre positiva de la masa en M⊕ (pl_bmasse). | unidad de la base |
| `pl_bmassjerr1` | Incertidumbre positiva de la masa en Mjup (pl_bmassj). | unidad de la base |
| `pl_orbeccenerr1` | Incertidumbre positiva de la excentricidad (pl_orbeccen). | unidad de la base |
| `pl_insolerr1` | Incertidumbre positiva de la insolación (pl_insol). | unidad de la base |
| `pl_eqterr1` | Incertidumbre positiva de la temperatura de equilibrio (pl_eqt). | unidad de la base |
| `st_tefferr1` | Incertidumbre positiva de la temperatura efectiva estelar (st_teff). | unidad de la base |
| `st_raderr1` | Incertidumbre positiva de la radio estelar (st_rad). | unidad de la base |
| `st_masserr1` | Incertidumbre positiva de la masa estelar (st_mass). | unidad de la base |
| `st_meterr1` | Incertidumbre positiva de la metalicidad (st_met). | unidad de la base |
| `st_loggerr1` | Incertidumbre positiva de la gravedad superficial (st_logg). | unidad de la base |
| `sy_disterr1` | Incertidumbre positiva de la distancia al sistema (sy_dist). | unidad de la base |
| `sy_vmagerr1` | Incertidumbre positiva de la magnitud V (sy_vmag). | unidad de la base |
| `sy_kmagerr1` | Incertidumbre positiva de la magnitud K (sy_kmag). | unidad de la base |
| `sy_gaiamagerr1` | Incertidumbre positiva de la magnitud G de Gaia (sy_gaiamag). | unidad de la base |

### 3.2 Incertidumbres (`*err2` — 18 columnas)

| `pl_orbpererr2` | Incertidumbre negativa de la período orbital (pl_orbper). | unidad de la base |
| `pl_orbsmaxerr2` | Incertidumbre negativa de la semieje mayor (pl_orbsmax). | unidad de la base |
| `pl_radeerr2` | Incertidumbre negativa de la radio planetario (pl_rade). | unidad de la base |
| `pl_radjerr2` | Incertidumbre negativa de la radio en Rjup (pl_radj). | unidad de la base |
| `pl_bmasseerr2` | Incertidumbre negativa de la masa en M⊕ (pl_bmasse). | unidad de la base |
| `pl_bmassjerr2` | Incertidumbre negativa de la masa en Mjup (pl_bmassj). | unidad de la base |
| `pl_orbeccenerr2` | Incertidumbre negativa de la excentricidad (pl_orbeccen). | unidad de la base |
| `pl_insolerr2` | Incertidumbre negativa de la insolación (pl_insol). | unidad de la base |
| `pl_eqterr2` | Incertidumbre negativa de la temperatura de equilibrio (pl_eqt). | unidad de la base |
| `st_tefferr2` | Incertidumbre negativa de la temperatura efectiva estelar (st_teff). | unidad de la base |
| `st_raderr2` | Incertidumbre negativa de la radio estelar (st_rad). | unidad de la base |
| `st_masserr2` | Incertidumbre negativa de la masa estelar (st_mass). | unidad de la base |
| `st_meterr2` | Incertidumbre negativa de la metalicidad (st_met). | unidad de la base |
| `st_loggerr2` | Incertidumbre negativa de la gravedad superficial (st_logg). | unidad de la base |
| `sy_disterr2` | Incertidumbre negativa de la distancia al sistema (sy_dist). | unidad de la base |
| `sy_vmagerr2` | Incertidumbre negativa de la magnitud V (sy_vmag). | unidad de la base |
| `sy_kmagerr2` | Incertidumbre negativa de la magnitud K (sy_kmag). | unidad de la base |
| `sy_gaiamagerr2` | Incertidumbre negativa de la magnitud G de Gaia (sy_gaiamag). | unidad de la base |

### 3.3 Banderas de límite (`*lim` — 14 columnas)

| `pl_orbperlim` | Bandera de límite de la período orbital (pl_orbper): 0 = valor medido; 1 = límite. | 0 / 1 |
| `pl_orbsmaxlim` | Bandera de límite de la semieje mayor (pl_orbsmax): 0 = valor medido; 1 = límite. | 0 / 1 |
| `pl_radelim` | Bandera de límite de la radio planetario (pl_rade): 0 = valor medido; 1 = límite. | 0 / 1 |
| `pl_radjlim` | Bandera de límite de la radio en Rjup (pl_radj): 0 = valor medido; 1 = límite. | 0 / 1 |
| `pl_bmasselim` | Bandera de límite de la masa en M⊕ (pl_bmasse): 0 = valor medido; 1 = límite. | 0 / 1 |
| `pl_bmassjlim` | Bandera de límite de la masa en Mjup (pl_bmassj): 0 = valor medido; 1 = límite. | 0 / 1 |
| `pl_orbeccenlim` | Bandera de límite de la excentricidad (pl_orbeccen): 0 = valor medido; 1 = límite. | 0 / 1 |
| `pl_insollim` | Bandera de límite de la insolación (pl_insol): 0 = valor medido; 1 = límite. | 0 / 1 |
| `pl_eqtlim` | Bandera de límite de la temperatura de equilibrio (pl_eqt): 0 = valor medido; 1 = límite. | 0 / 1 |
| `st_tefflim` | Bandera de límite de la temperatura efectiva estelar (st_teff): 0 = valor medido; 1 = límite. | 0 / 1 |
| `st_radlim` | Bandera de límite de la radio estelar (st_rad): 0 = valor medido; 1 = límite. | 0 / 1 |
| `st_masslim` | Bandera de límite de la masa estelar (st_mass): 0 = valor medido; 1 = límite. | 0 / 1 |
| `st_metlim` | Bandera de límite de la metalicidad (st_met): 0 = valor medido; 1 = límite. | 0 / 1 |
| `st_logglim` | Bandera de límite de la gravedad superficial (st_logg): 0 = valor medido; 1 = límite. | 0 / 1 |

---

*Cobertura verificada: 91/91 columnas documentadas.*
