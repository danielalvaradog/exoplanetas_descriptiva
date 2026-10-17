# Plan — ACP con imputación multivariada sobre exoplanetas NASA

> Documento de planificación. No contiene el análisis final; describe el proceso
> por fases, las decisiones metodológicas y su justificación.
> Autor del plan: agente `astro-analyst` (entorno multiagéntico OpenCode).

## 0. Resumen ejecutivo

Se hará un **Análisis de Componentes Principales (ACP)** con **las 16 variables
numéricas físicas** del dataset, en lugar de las 6 usadas en el EDA inicial.

El problema central es el nulo de la masa planetaria (`pl_bmasse`): 83% de los
36.418 registros. Se descartó el análisis de casos completos (quedan solo 349
observaciones, 0,96%) y se adopta **imputación multivariada** sobre el
subconjunto de planetas con masa observada (6.207, 17,0%), **sin imputar
nunca la masa**.

**Limitación crítica (ya detectada):** ese subconjunto tiene un fuerte sesgo de
seleccion (ver Fase 2). El ACP describe a los planetas con masa conocida, no a
la población total de exoplanetas. Esto debe declararse explícitamente en el
reporte.

- **Lenguaje:** R (proyecto `renv`, se mantiene el codebase en R).
- **Stack:** `FactoMineR` + `missMDA`.
- **Estado de las variables:** 21 numéricas de contenido → 16 en el ACP (5
  excluidas, justificadas en Fase 1).

---

## Fase 0 — Preparación del entorno

R no está instalado en el WSL actual. Instalar:

```bash
sudo apt-get update
sudo apt-get install -y r-base r-base-dev
```

Dependencias de R para este análisis (vía `renv` del proyecto o `install.packages`):

| Paquete | Uso |
|---|---|
| `FactoMineR` | ACP (`PCA()`), interpretación (ejes, contribuciones, cos²) |
| `missMDA` | Imputación multivariada en espacio de componentes (`imputePCA`, `estim_ncpPCA`) |
| `tidyverse` | Manipulación y visualización (ya en el proyecto) |
| `naniar` / `visdat` | Diagnóstico de nulos |
| `corrplot` | Matriz de correlación (ya en el proyecto) |

Validar: `Rscript -e 'library(FactoMineR); library(missMDA); cat("ok\n")'`.

---

## Fase 1 — Selección y justificación de variables

### 1.1 Universo: 21 numéricas de contenido

Se detectaron **21 columnas numéricas de contenido** descartando las de
metadatos de precisión (`*err1`, `*err2`, `*lim`) y de identificación/texto.

### 1.2 Las 16 variables INCLUIDAS en el ACP

| Variable | Descripción | % nulos (full) |
|---|---|---|
| `pl_orbper` | Período orbital (días) | 8,7% |
| `pl_orbsmax` | Semi-eje mayor (AU) | 45,1% |
| `pl_rade` | Radio planetario (R⊕) | 31,8% |
| `pl_bmasse` | **Masa planetaria (M⊕) — restringida** | 83,0% |
| `pl_orbeccen` | Excentricidad orbital | 50,0% |
| `pl_insol` | Insolación recibida (Flux Earth) | 58,2% |
| `pl_eqt` | Temperatura de equilibrio (K) | 54,5% |
| `st_teff` | Temperatura efectiva estelar (K) | 8,2% |
| `st_rad` | Radio estelar (R☉) | 8,0% |
| `st_mass` | Masa estelar (M☉) | 15,6% |
| `st_met` | Metalicidad estelar ([Fe/H]) | 37,5% |
| `st_logg` | Gravedad superficial estelar (log g) | 18,6% |
| `sy_dist` | Distancia al sistema (pc) | 2,3% |
| `sy_vmag` | Magnitud V del sistema | 2,0% |
| `sy_kmag` | Magnitud K del sistema | 2,0% |
| `sy_gaiamag` | Magnitud Gaia del sistema | 2,8% |

### 1.3 Las 5 variables EXCLUIDAS y su justificación exacta

Documentado a pedido del usuario — por qué no entran al ACP:

| Variable excluida | Motivo |
|---|---|
| `pl_radj` | **Duplicado exacto de `pl_rade` en unidades de Júpiter.** `pl_radj = pl_rade × 0.10046`. Colinealidad perfecta → el ACP produce un eigenvalor 0 y una dirección espuria. Se conserva solo `pl_rade` (unidad terrestre, coherente con `pl_bmasse`). |
| `pl_bmassj` | **Duplicado exacto de `pl_bmasse` en unidades de Júpiter** (mismo problema de colinealidad perfecta). Conservar una sola escala evita redundancia. |
| `disc_year` | **Metadato temporal, no una propiedad física del planeta.** Es el año de descubrimiento; su variación refleja la actividad de los telescopios, no la astrofísica. Incluirlo distorsuiría los ejes del ACP con un artefacto de calendario. Es además un entero discreto con poca dispersión relativa. |
| `sy_snum` | **Conteo discreto con cardinalidad mínima** (1, 2, 3+ estrellas; ~95% son 1). Aporta casi nula varianza y su naturaleza es categórica ordinal, no continua. Encaja mejor como **variable suplementaria** o en el ACM (Fase 5). |
| `sy_pnum` | **Conteo discreto** (número de planetas del sistema). Mismo argumento: poca cardinalidad, distribución muy asimétrica, es categórica ordinal. Se analiza mejor en el ACM (Fase 5) o como variable suplementaria cualitativa. |

> Nota: `default_flag`, `ttv_flag` y `st_spectype` no se consideran porque son
> categóricas/flags, no numéricas — su lugar es el ACM (Fase 5).

### 1.4 Transformación previa — DECIDIDA CON DATOS

Criterio aplicado: `log10` solo si (a) todos los valores son > 0 y (b) la
transformación **reduce** el valor absoluto de la asimetría de forma sustancial.
La asimetría se midió sobre el subconjunto con masa (n = 6.207), que es la
población real del ACP.

| Variable | asim. original | asim. log10 | Decisión |
|---|---|---|---|
| `pl_orbper` | 73,04 | 0,70 | **log10** |
| `pl_orbsmax` | 36,87 | 0,67 | **log10** |
| `pl_bmasse` | 4,57 | −0,34 | **log10** |
| `pl_insol` | 17,84 | −0,40 | **log10** |
| `st_teff` | 15,45 | 0,24 | **log10** |
| `st_rad` | 9,59 | 1,24 | **log10** |
| `st_mass` | 13,03 | −2,07 | **log10** |
| `sy_dist` | 2,99 | 0,38 | **log10** |
| `pl_rade` | 0,35 | −0,49 | **sin transformar** |
| `pl_eqt` | 0,47 | −1,02 | **sin transformar** |
| `pl_orbeccen` | 1,63 | — | **sin transformar** (966 ceros) |
| `st_logg` | −2,22 | −3,75 | **sin transformar** |
| `st_met` | 7,31 | — | **sin transformar** (negativos y ceros) |
| `sy_vmag` | 1,11 | −0,75 | **sin transformar** |
| `sy_kmag` | 0,61 | −1,16 | **sin transformar** |
| `sy_gaiamag` | 0,08 | −0,65 | **sin transformar** |

**Corrección respecto a la primera versión de este plan:** se había previsto
logaritmear también `pl_rade` y las tres magnitudes. El diagnóstico lo descarta:

- **Magnitudes (`sy_vmag`, `sy_kmag`, `sy_gaiamag`) ya son logarítmicas por
  definición** (mag = −2.5·log10(flux)). Transformarlas de nuevo **empeora** la
  asimetría (p. ej. `sy_gaiamag` pasa de 0,08 a −0,65) y `sy_kmag` además tiene
  valores negativos (mín −3,04), incompatible con el logaritmo.
- **`pl_rade` ya es casi simétrico dentro del subset con masa** (asim 0,35):
  los planetas con masa son mayoritariamente grandes, el subset filtra la cola.
  En el dataset completo su asimetría era 48,87; otro efecto del sesgo de selección.

**Manejo de no-positivos:** para las variables en `log10`, cualquier valor
`<= 0` se convierte en `NA` antes de transformar (afecta a 1 celda de `pl_insol`
y 1 de `st_mass`). Esas celdas pasan al pool de imputación en Fase 3, lo cual es
consistente con el método.

**Justificación:** el ACP con `scale.unit = TRUE` estandariza por desviación,
pero no corrige la asimetría; con valores extremos (órdenes de magnitud) unos
pocos individuos dominarían los ejes. El `log10` selectivo evita eso sin
transformar variables que ya están bien comportadas.

---

## Fase 2 — Diagnóstico de nulos y viabilidad del caso-completo

### 2.1 Tamaño del subconjunto con masa observada

- Registros totales: **36.418**
- Con `pl_bmasse` observada: **6.207 (17,0%)** — el usuario estimó 13%; el valor
  real es 17,0%. Se corrige el dato porque afecta el cálculo de potencia.

### 2.2 Completitud de las otras variables DENTRO del subconjunto con masa

| Variable | % no-nulo (dentro de los 6.207) |
|---|---|
| `pl_bmasse` | 100,0% |
| `disc_year` (excluida) | 100,0% |
| `sy_dist` | 98,7% |
| `st_mass` | 97,0% |
| `pl_orbper` | 86,3% |
| `sy_vmag` / `sy_kmag` / `sy_gaiamag` | 89,0 / 88,9 / 88,4% |
| `pl_orbsmax` | 84,3% |
| `pl_orbeccen` | 73,6% |
| `st_teff` | 71,3% |
| `st_rad` | 68,3% |
| `st_met` | 65,7% |
| `st_logg` | 58,8% |
| `pl_rade` | 46,4% |
| `pl_eqt` | 27,9% |
| **`pl_insol`** | **10,5%** |

### 2.3 Viabilidad del caso-completo → NO VIABLE

| Escenario | Casos completos |
|---|---|
| Las 16 variables del ACP, filtrando por masa | **349 (0,96%)** |
| Sin `pl_insol` | 981 |
| Subconjunto "estrella + masa + radio" | 1.771 |

Regla práctica: un ACP con 16 dimensiones necesita, como mínimo, ~5–10
observaciones por variable (~80–160), y preferiblemente >1.000 para estabilidad
de ejes e interpretación. **349 está en el límite inferior y es insuficiente**;
además el subconjunto quedaría aún más sesgado.

**Decisión: el caso-completo NO es viable. Se procede a imputación multivariada**
de las 15 variables no-masa sobre los 6.207 registros con masa observada.

### 2.4 Sesgo de selección (hallazgo central — debe documentarse)

Comparando el dataset completo vs el subconjunto con masa:

| Método descubrimiento | % completo | % con masa |
|---|---|---|
| Transit | 90,2% | 46,3% |
| Radial Velocity | 7,0% | **39,9%** |
| Microlensing | 1,9% | 10,5% |
| Imaging | 0,4% | 2,0% |

Magnitudes (medianas):

| Variable | Completo | Con masa |
|---|---|---|
| `pl_rade` | 2,29 R⊕ | **9,89 R⊕** |
| `pl_orbper` | 10,33 d | 13,73 d |
| `sy_dist` | 594 pc | **137 pc** |

**Interpretación:** los planetas con masa medida son predominantemente los
detectados por **velocidad radial**, en sistemas **más cercanos**, con radios
**más grandes**. Es esperable: la masa se mide mejor en planetas masivos cercanos.
Esto NO es un muestreo aleatorio.

**Consecuencia para el reporte:** el ACP describe la estructura de variación de
los *exoplanetas con masa conocida*. No se puede generalizar a los ~30.000
planetas detectados solo por tránsito sin masa. Debe declararse como
**limitación** en el texto del Rmd.

---

## Fase 3 — Imputación multivariada (missMDA)

La masa **nunca se imputa** (por diseño y por el sesgo anterior). Se imputan las
otras 15 variables.

### 3.1 Método

`missMDA::imputePCA()`: imputa valores faltantes **proyectando en el espacio de
componentes principales**, iterando entre estimación de componentes y
reconstrucción. Es el método adecuado cuando los datos son inherentemente
multivariados (como en ACP), porque respeta la estructura de correlaciones.

### 3.2 Nº de componentes para la imputación

`missMDA::estim_ncpPCA()` estima el número óptimo de dimensiones por
validación cruzada. Usar ese valor (no el máximo) para evitar sobreajuste en la
imputación.

### 3.3 Procedimiento

1. Subset: `df_masa <- df[!is.na(df$pl_bmasse), ]` (6.207 × 16).
2. Matriz numérica con transformaciones de Fase 1.4.
3. `ncp <- estim_ncpPCA(df_num, ...)` → nº de componentes.
4. `imp <- imputePCA(df_num, ncp = ncp)` → lista con `$X` (matriz imputada).
5. **Validar la imputación:**
   - Comparar distribuciones observado vs imputado por variable (densidad).
   - Verificar que las correlaciones imputadas no se colapsan hacia 0 ni 1.
   - Reportar % de celdas imputadas por variable (será muy alto en `pl_insol`).

### 3.4 Advertencia sobre `pl_insol` y `pl_eqt`

`pl_insol` tiene solo 10,5% observado dentro del subset → ~89,5% sería imputado.
Eso es estadísticamente frágil: la variable imputada aporta más ruido reconstructo
que señal. **Recomendación a evaluar:** hacer un ACP de 16 variables y un
**ACP de sensibilidad sin `pl_insol`** (y quizás sin `pl_eqt`) para comparar si
los ejes principales son estables. Si los ejes cambian mucho, reportar el ACP
reducido como el resultado principal.

---

## Fase 4 — ACP (FactoMineR)

### 4.1 Ejecución

```r
library(FactoMineR)
res.pca <- PCA(X_imputada, scale.unit = TRUE, ncp = 5, graph = FALSE)
```

`scale.unit = TRUE` estandariza (equivale a trabajar sobre la matriz de
correlación), necesario por las unidades heterogéneas (días, K, R⊕, pc...).

### 4.2 Salidas a producir e interpretar

1. **Eigenvalores / varianza explicada** — barras de scree + % acumulado. Criterio
   de retención: Kaiser (eigenvalor > 1) + scree + paralelel analysis si es posible.
2. **Círculo de correlaciones** — aportes de variables a Dim 1 y Dim 2.
3. **Gráfico de variables con `cos2`** — calidad de representación; variables con
   cos² bajo no se interpretan en ese plano.
4. **Contribuciones (`contrib`)** — qué variables "empujan" cada eje (>1/punto de
   referencia = 100/p).
5. **Mapa de individuos** — coloreado por `discoverymethod` (variable suplementaria
   cualitativa) para ver si los métodos se separan en el espacio del ACP.
6. **Interpretación de ejes** — nombrar cada eje según las variables que lo
   dominan (ej. "tamaño/masa del planeta", "entorno estelar", "distancia/luminosidad").

### 4.3 Variables suplementarias

- Cualitativas: `discoverymethod`, `soltype`, `st_spectype_class` → superpuestas
  sobre el ACP para interpretación (sin influir en los ejes).
- Cuantitativas descartadas de Fase 1 (`sy_pnum`, `sy_snum`, `disc_year`) →
  proyectadas como suplementarias para ver su correlación con los ejes.

---

## Fase 5 — ACM con variables categóricas (POSTERIOR, solo plan)

Dejado para después, según el usuario. Implicaciones ya anticipadas:

- Variables candidatas: `discoverymethod`, `soltype`, `ttv_flag`,
  `st_spectype_class`, `disc_facility_top`, `sy_pnum_fct`, `sy_snum_fct`.
- Herramienta: `FactoMineR::MCA()`.
- El `pl_insol`/`pl_eqt` imputados no afectan el ACM (es sobre categóricas).
- Decidir si el ACM corre sobre el mismo subset de 6.207 (consistencia) o sobre
  el total (representatividad). Se recomienda **ambos** para comparar.

---

## Estructura propuesta de archivos R

Manteniendo el codebase en R y la convención del proyecto (`src/` con funciones):

```
exoplanetas_descriptiva/
├── src/
│   ├── Functions_exo.R          # existente (EDA inicial)
│   └── Functions_acp.R          # nuevo: preparación, imputación, ACP
├── EDA_Exoplanets.Rmd           # existente
├── ACP_Exoplanets.Rmd           # nuevo: reporte del ACP
└── data_descriptiva_multi/      # sin cambios
```

`Functions_acp.R` contendrá funciones testeables (una responsabilidad cada una):

- `seleccionar_variables_acp(df)` — aplica Fase 1 (incluye log10).
- `diagnostico_nulos(df, vars)` — Fase 2, devuelve tabla de completitud + % completos.
- `imputar_acp(df_num, ncp)` — Fase 3, envuelve `estim_ncpPCA` + `imputePCA`.
- `correr_acp(X, ncp)` — Fase 4, envuelve `PCA()`.

---

## Criterios de éxito

- [ ] Las 16 variables seleccionadas y las 5 excluidas documentadas con justificación.
- [ ] Diagnóstico de nulos reproducible (tabla 2.2).
- [ ] Sesgo de selección declarado en el texto del reporte.
- [ ] Imputación validada (distribuciones y correlaciones comparadas).
- [ ] ACP corre sin errores; eigenvalores, cos² y contribuciones interpretados.
- [ ] Cada eje con nombre sustantivo y variables que lo dominan.
- [ ] Sensibilidad con/sin `pl_insol` reportada.

## Riesgos abiertos

1. **`pl_insol` imputada al ~90%** → puede degradar el ACP. Mitigación: análisis
   de sensibilidad (Fase 3.4).
2. **Sesgo de selección** no es corregible con imputación; solo se declara.
3. **Convergencia de `imputePCA`** con muchas celdas faltantes → si no converge,
   bajar `ncp` o usar `impCA`/método alternativo.
