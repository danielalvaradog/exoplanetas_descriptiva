# Estadística Descriptiva Multivariada - Exoplanetas NASA

Proyecto de análisis exploratorio de datos (EDA) sobre el conjunto de datos de exoplanetas del NASA Exoplanet Archive.

## Descripción

Este proyecto realiza un análisis estadístico descriptivo multivariado de exoplanetas confirmados, explorando sus características físicas, orbitales y observacionales. Se analizan las relaciones entre métodos de descubrimiento, masa, radio, temperaturas y la estructura de los sistemas planetarios.

## Autor

**Daniel Alvarado** - 145310

## Estructura del proyecto

```
descriptiva_multi/
├── data_descriptiva_multi/
│   ├── NASA_Exoplanet_Archive_Data.csv   # Dataset de exoplanetas
│   └── README.md                         # Diccionario de las 91 columnas
├── src/
│   ├── Functions_exo.R                   # Funciones auxiliares del EDA inicial
│   ├── Functions_acp.R                   # Funciones del ACP (selección, imputación, tema, gráficos)
│   ├── Functions_acp_extendido.R         # Funciones del ejercicio con metadatos
│   ├── Functions_acm.R                   # Funciones del ACM (diagnóstico categórico, MCA, mapeo de categorías)
│   └── generar_diccionario.py            # Genera el diccionario de datos (91 columnas)
├── renv/                                 # Dependencias del proyecto (renv)
├── EDA_Exoplanets.Rmd                    # Documento del EDA inicial (6 variables)
├── EDA_Exoplanets.html                   # Reporte renderizado
├── ACP_Exoplanets.Rmd                    # ACP con imputación multivariada (16 variables)
├── ACP_extendido_metadatos.Rmd           # Ejercicio: ACP incluyendo metadatos de precisión
├── ACM_Exoplanets.Rmd                    # ACM con variables categóricas (5 activas verificadas)
├── PLAN_acp.md                           # Plan metodológico del ACP (fases y justificación)
├── renv.lock                             # Lockfile de dependencias
├── descriptiva_multi.Rproj               # Archivo de proyecto RStudio
└── README.md
```

## Variables analizadas

### Cualitativas / Categóricas
- `discoverymethod`: Método astrofísico de descubrimiento
- `ttv_flag`: Variaciones en el Tiempo de Tránsito (TTV)
- `soltype`: Tipo de solución de publicación
- `sy_pnum_fct`: Número de planetas en el sistema
- `sy_snum_fct`: Número de estrellas en el sistema
- `st_spectype_class`: Clase espectral de la estrella hospedadora
- `disc_facility_top`: Instalación/Telescopio de descubrimiento

### Cuantitativas Continuas
- `pl_rade`: Radio planetario (R⊕)
- `pl_bmasse`: Masa planetaria (M⊕)
- `pl_orbper`: Período orbital (días)
- `pl_eqt`: Temperatura de equilibrio planetaria (K)
- `st_teff`: Temperatura efectiva estelar (K)
- `sy_dist`: Distancia al sistema (parsecs)

## Contenido del análisis

### EDA inicial (`EDA_Exoplanets.Rmd`)

1. **Análisis Univariado**
   - Distribución de variables cualitativas
   - Estadísticos descriptivos y distribución de variables cuantitativas

2. **Análisis Bivariado**
   - Relaciones Cuali-Cuali
   - Relaciones Cuali-Cuanti
   - Relaciones Cuanti-Cuanti

3. **Análisis Multivariado**
   - Matriz de correlación de Pearson
   - Matriz de varianzas y covarianzas

### ACP (`ACP_Exoplanets.Rmd`)

Análisis de Componentes Principales con **las 16 variables numéricas físicas**
(completitud, sesgo de selección, imputación multivariada con `missMDA` y
interpretación de ejes con `FactoMineR`). Ver `PLAN_acp.md` para la
justificación metodológica fase por fase.

Fases: selección de variables → diagnóstico de nulos y viabilidad →
imputación multivariada → ACP y sensibilidad → ACM (posterior).

### ACM (`ACM_Exoplanets.Rmd`)

**Análisis de Correspondencias Múltiples** sobre las variables categóricas.
De 18 candidatas, 5 quedan como activas tras un **diagnóstico previo con
evidencia** (nulos, cardinalidad, nivel dominante): `discoverymethod`,
`disc_facility`, `pl_bmassprov`, `st_metratio` y `ttv_flag`. Las 13 excluidas
se justifican una por una (incluida `soltype`, que es constante dentro del
subconjunto con masa). El alcance y las decisiones de tratamiento (nivel "Sin
dato", agrupación de niveles con n < 100, exclusión de `default_flag`) están
documentados en el propio documento. Corre sobre el **mismo subconjunto con
masa (6.207 filas)** que el ACP.

### Diccionario de datos (`data_descriptiva_multi/README.md`)

Referencia de **las 91 columnas** del dataset: qué significa cada variable,
su unidad y la convención de los sufijos de precisión (`*err1`, `*err2`,
`*lim`). Se regenera con `python3 src/generar_diccionario.py` (verifica
cobertura 91/91 automáticamente).

### Ejercicio extendido (`ACP_extendido_metadatos.Rmd`)

**Ejercicio de aprendizaje, no es el análisis principal.** Responde qué pasaría
si se incluyeran las 50 columnas de metadatos de precisión (`*err1`, `*err2`,
`*lim`) además de las 21 numéricas de contenido. Documenta con evidencia numérica
por qué se excluyen: nulos estructurales, heterocedasticidad (r = 0,979),
varianza cero, dilución de varianza y pérdida de interpretabilidad de los ejes.

Para renderizar todo:

```bash
Rscript -e 'rmarkdown::render("EDA_Exoplanets.Rmd")'
Rscript -e 'rmarkdown::render("ACP_Exoplanets.Rmd")'
Rscript -e 'rmarkdown::render("ACP_extendido_metadatos.Rmd")'
Rscript -e 'rmarkdown::render("ACM_Exoplanets.Rmd")'
```

## Dependencias principales

El proyecto utiliza las siguientes librerías de R (gestionadas con `renv`):

- `tidyverse` (dplyr, ggplot2, tidyr, purrr, stringr)
- `knitr` / `rmarkdown`
- `kableExtra`
- `corrplot`
- `FactoMineR`, `missMDA` (para el ACP y el ACM)
- `ggrepel` (etiquetas de los mapas del ACM)
- `pandoc` (sistema, necesario para renderizar)

## Requisitos

- R >= 4.4.2
- RStudio (recomendado)

## Instalación y ejecución

1. Clonar el repositorio:
   ```bash
   git clone <url-del-repositorio>
   cd descriptiva_multi
   ```

2. Restaurar las dependencias con renv:
   ```r
   # Abrir el proyecto en RStudio o ejecutar:
   renv::restore()
   ```

3. Descargar los datos:
   - Ir a [Kaggle: NASA Exoplanet Archive](https://www.kaggle.com/datasets/ljunes/nasa-exoplanets-a-multi-source-dataset)
   - Descargar el dataset de planetas confirmados
   - Guardar como `data_descriptiva_multi/NASA_Exoplanet_Archive_Data.csv`

4. Renderizar los documentos:
   ```r
   rmarkdown::render("EDA_Exoplanets.Rmd")   # EDA inicial
   rmarkdown::render("ACP_Exoplanets.Rmd")   # ACP con imputación multivariada
   rmarkdown::render("ACM_Exoplanets.Rmd")   # ACM con variables categóricas
   ```

## Fuente de datos

- [NASA Exoplanet Archive](https://www.kaggle.com/datasets/ljunes/nasa-exoplanets-a-multi-source-dataset)




