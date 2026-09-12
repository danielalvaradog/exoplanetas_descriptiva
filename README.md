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
│   └── NASA_Exoplanet_Archive_Data.csv   # Dataset de exoplanetas
├── src/
│   └── Functions_exo.R                   # Funciones auxiliares para el análisis
├── renv/                                 # Dependencias del proyecto (renv)
├── EDA_Exoplanets.Rmd                    # Documento principal del análisis
├── EDA_Exoplanets.html                   # Reporte renderizado
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

4. Renderizar el documento:
   ```r
   rmarkdown::render("EDA_Exoplanets.Rmd")
   ```

## Dependencias principales

El proyecto utiliza las siguientes librerías de R (gestionadas con `renv`):

- `tidyverse` (dplyr, ggplot2, tidyr, purrr, stringr)
- `knitr` / `rmarkdown`
- `kableExtra`
- `corrplot`

## Fuente de datos

- [NASA Exoplanet Archive](https://www.kaggle.com/datasets/ljunes/nasa-exoplanets-a-multi-source-dataset)




