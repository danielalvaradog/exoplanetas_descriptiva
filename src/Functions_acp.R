# ==============================================================================
# Functions_acp.R - Funciones para ACP con imputación multivariada
#                  (exoplanetas NASA)
#
# Cada función tiene una sola responsabilidad y es testeable por separado.
# Dependencias: tidyverse, missMDA, FactoMineR
# ==============================================================================

suppressMessages({
  library(tidyverse)
  library(missMDA)
  library(FactoMineR)
  library(knitr)
  library(kableExtra)   # tablas del Rmd
})

# ------------------------------------------------------------------------------
# 0. Identidad visual — tema NASA
#
# NOTA: usar SIEMPRE nasa_col() / nasa_pal() para extraer colores.
#   nasa_colors["primary"] devuelve un vector CON NOMBRE, y un vector con
#   nombres en scale_fill_manual() se matchea contra los niveles del factor.
#   Si los nombres no coinciden, ggplot pinta grey50 (bug ya encontrado).
# ------------------------------------------------------------------------------
nasa_colors <- c(
  primary   = "#0B3D91",   # azul NASA profundo
  secondary = "#FC3D21",   # rojo/naranja NASA
  accent1   = "#1A5276",   # azul medio
  accent2   = "#F4D03F",   # amarillo
  accent3   = "#5B2C6F",   # violeta
  accent4   = "#117A65",   # verde azulado
  accent5   = "#E67E22",   # naranja
  accent6   = "#2980B9",   # celeste
  accent7   = "#8E44AD",   # morado
  light_bg  = "#F8F9FA",
  dark_txt  = "#2C3E50"
)

# Paleta completa del tema, en orden de uso
nasa_palette <- c(
  "#0B3D91", "#FC3D21", "#117A65", "#F4D03F",
  "#5B2C6F", "#E67E22", "#2980B9", "#8E44AD"
)

# Extrae valores CRUDOS sin nombres (seguro para scale_*_manual)
nasa_col <- function(...) unname(nasa_colors[c(...)])

# Paleta discreta: n colores del tema, siempre sin nombres
nasa_pal <- function(n = 8) rep_len(nasa_palette, n)

# Escala de relleno del tema. Si se pasa `niveles`, se respeta el orden
# nivel -> color de forma EXPLÍCITA (lo más robusto).
scale_fill_nasa <- function(niveles = NULL, n = 8, ...) {
  if (is.null(niveles)) {
    scale_fill_manual(values = nasa_pal(n), ...)
  } else {
    scale_fill_manual(values = setNames(nasa_pal(length(niveles)), niveles), ...)
  }
}

# Escala de color (líneas/puntos) del tema
scale_color_nasa <- function(n = 8, ...) {
  scale_color_manual(values = nasa_pal(n), ...)
}

theme_nasa <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", size = 13,
                                color = nasa_col("primary"), margin = margin(b = 4)),
      plot.subtitle = element_text(size = 10, color = "gray35",
                                   face = "plain", margin = margin(b = 8)),
      plot.caption = element_text(size = 8, face = "italic", color = "gray55",
                                  hjust = 0, margin = margin(t = 8)),
      axis.title = element_text(face = "bold", size = 10, color = nasa_col("dark_txt")),
      axis.text = element_text(size = 9.5, color = "gray30"),
      axis.text.x = element_text(angle = 0, hjust = 0.5),
      legend.position = "top",
      legend.title = element_text(face = "bold", size = 9),
      legend.text = element_text(size = 8.5),
      panel.grid.major = element_line(color = "#E4E8EE", linewidth = 0.4),
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),   # sin líneas verticales: más limpio
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white", color = NA),
      panel.border = element_rect(fill = NA, color = "#CBD2DA", linewidth = 0.6),
      strip.background = element_rect(fill = nasa_col("primary"), color = NA),
      strip.text = element_text(color = "white", face = "bold", size = 10),
      plot.margin = margin(10, 12, 10, 12)
    )
}

# ------------------------------------------------------------------------------
# 1. Selección de variables y transformación
# ------------------------------------------------------------------------------

# Las 16 variables numéricas de contenido que entran al ACP.
VARS_ACP <- c(
  "pl_orbper", "pl_orbsmax", "pl_rade", "pl_bmasse", "pl_orbeccen",
  "pl_insol", "pl_eqt", "st_teff", "st_rad", "st_mass", "st_met", "st_logg",
  "sy_dist", "sy_vmag", "sy_kmag", "sy_gaiamag"
)

# Variables excluidas del ACP, con su justificación exacta (documentada a pedido
# del usuario). Se conserva el motivo para poder reportarlo.
EXCLUIDAS_ACP <- c(
  "pl_radj"   = "duplicado exacto de pl_rade en radios de Jupiter (colinealidad perfecta)",
  "pl_bmassj" = "duplicado exacto de pl_bmasse en masas de Jupiter (colinealidad perfecta)",
  "disc_year" = "metadato temporal, no propiedad fisica del planeta",
  "sy_snum"   = "conteo discreto con cardinalidad minima; mejor como suplementaria/ACM",
  "sy_pnum"   = "conteo discreto con poca cardinalidad; mejor como suplementaria/ACM"
)

# Variables que van en log10, decididas por diagnostico de asimetria sobre el
# subset con masa (ver PLAN_acp.md seccion 1.4). Nunca incluye magnitudes.
VARS_LOG10 <- c("pl_orbper", "pl_orbsmax", "pl_bmasse", "pl_insol",
                "st_teff", "st_rad", "st_mass", "sy_dist")

#' Selecciona las variables del ACP, filtra por masa observada y aplica log10.
#'
#' @param df data.frame crudo (todas las columnas del CSV)
#' @param restringir_por_masa TRUE = filtrar a filas con pl_bmasse no nulo
#' @return lista con $matriz (numerica, con NA) y $n_origen / $n_subset
seleccionar_variables_acp <- function(df, restringir_por_masa = TRUE) {
  n_origen <- nrow(df)

  d <- df %>%
    mutate(across(everything(), ~ suppressWarnings(as.numeric(.x))))

  if (restringir_por_masa) {
    d <- d %>% filter(!is.na(pl_bmasse))
  }
  n_subset <- nrow(d)

  mat <- d %>% select(all_of(VARS_ACP))

  # log10 selectivo: valores <= 0 pasan a NA (entran al pool de imputacion)
  mat <- mat %>%
    mutate(across(
      any_of(VARS_LOG10),
      ~ ifelse(is.na(.x) | .x <= 0, NA_real_, log10(.x))
    ))

  list(matriz = mat, n_origen = n_origen, n_subset = n_subset)
}

# ------------------------------------------------------------------------------
# 2. Diagnostico de nulos y viabilidad del caso-completo
# ------------------------------------------------------------------------------

#' Diagnostica completitud por variable y viabilidad del caso-completo.
#'
#' Regla de viabilidad: >= 5-10 observaciones por variable y preferentemente
#' > 1000 registros para ejes estables.
#'
#' @param mat matriz numerica ya seleccionada (puede contener NA)
#' @param min_por_var observaciones minimas por variable (default 5)
#' @param min_total registros minimos totales (default 1000)
#' @return lista con $por_variable, $casos_completos, $viabilidad
diagnostico_nulos <- function(mat, min_por_var = 5, min_total = 1000) {
  n <- nrow(mat)
  p <- ncol(mat)

  por_variable <- map_dfr(names(mat), function(v) {
    x <- mat[[v]]
    tibble(
      variable      = v,
      n_observados  = sum(!is.na(x)),
      n_nulos       = sum(is.na(x)),
      pct_nulos     = round(sum(is.na(x)) / n * 100, 1),
      asimetria     = round(moments_skew(x[!is.na(x)]), 2)
    )
  })

  completos <- sum(stats::complete.cases(mat))
  min_recomendado <- max(min_por_var * p, min_total)

  list(
    por_variable      = por_variable,
    n                 = n,
    p                 = p,
    casos_completos   = completos,
    pct_completos     = round(completos / n * 100, 2),
    min_recomendado   = min_recomendado,
    viabilidad        = completos >= min_recomendado
  )
}

# Asimetria (skewness) manual para no depender de e1071/momentos
moments_skew <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) < 3) return(NA_real_)
  s <- stats::sd(x)
  if (is.na(s) || s == 0) return(NA_real_)
  m <- mean(x)
  mean(((x - m) / s)^3)
}

# ------------------------------------------------------------------------------
# 3. Imputacion multivariada (missMDA)
# ------------------------------------------------------------------------------

#' Imputa la matriz con PCA multiple. La variable restringida (masa) ya viene
#' observada (filtro previo), por lo que no se imputa nunca.
#'
#' @param mat matriz numerica con NA
#' @param ncp número de componentes; si NULL se estima por validacion cruzada
#' @return lista con $X (matriz imputada), $ncp, $pct_imputado
imputar_acp <- function(mat, ncp = NULL) {
  X <- as.matrix(mat)
  storage.mode(X) <- "double"

  if (is.null(ncp)) {
    est <- missMDA::estim_ncpPCA(X)
    # estim_ncpPCA puede devolver escalar o lista segun version/paquete
    est <- suppressWarnings(as.integer(unlist(est)[1]))
    if (length(est) == 0 || is.na(est) || est < 1) est <- 2
    ncp <- max(1, min(est, ncol(X) - 1, nrow(X) - 1))
  }

  imp <- missMDA::imputePCA(X, ncp = ncp, ncpmax = ncp)
  # missMDA devuelve $completeObs (matriz imputada) y $fittedX (reconstruida)
  X_imp <- imp$completeObs
  if (is.null(X_imp)) X_imp <- imp$X   # compatibilidad con otras versiones

  list(
    X             = X_imp,
    ncp           = ncp,
    pct_imputado  = round(mean(is.na(X)) * 100, 1),
    celdas_por_var = round(colMeans(is.na(X)) * 100, 1)
  )
}

# ------------------------------------------------------------------------------
# 4. ACP (FactoMineR)
# ------------------------------------------------------------------------------

#' Ejecuta el ACP estandarizado.
#'
#' @param X matriz numérica ya imputada (sin NA)
#' @param ncp número de componentes a retener
#' @param quali_sup data.frame opcional con variables categóricas SUPLEMENTARIAS
#'   (no influyen en los ejes, pero permiten colorear el mapa de individuos)
#' @return objeto PCA de FactoMineR
correr_acp <- function(X, ncp = 5, quali_sup = NULL) {
  stopifnot(!anyNA(X))
  df <- as.data.frame(X)

  quali_nombres <- NULL
  if (!is.null(quali_sup)) {
    stopifnot(nrow(quali_sup) == nrow(df))
    # FactoMineR espera las cualitativas DENTRO de X y declarar sus nombres
    # en quali.sup (las trata como suplementarias: no influyen en los ejes).
    quali_nombres <- names(quali_sup)
    df <- bind_cols(df, as.data.frame(quali_sup))
  }

  FactoMineR::PCA(
    df,
    scale.unit = TRUE,
    ncp       = ncp,
    quali.sup = quali_nombres,
    graph     = FALSE
  )
}

#' Extrae la tabla de eigenvalores / varianza explicada.
resumen_ejes <- function(res, ncp = 5) {
  ev <- res$eig
  tibble(
    eje         = seq_len(min(ncp, nrow(ev))),
    eigenvalor  = round(ev[1:min(ncp, nrow(ev)), 1], 3),
    pct_var     = round(ev[1:min(ncp, nrow(ev)), 2], 2),
    pct_acum    = round(ev[1:min(ncp, nrow(ev)), 3], 2)
  )
}

#' Aportes de variables a los primeros ejes (para interpretacion).
#'
#' NOTA: FactoMineR nombra sus columnas "Dim.1", "Dim.2", ... (con PUNTO).
#' Nunca parsear ese string; se renombra por POSICION para no depender del
#' formato que use cada version de FactoMineR.
aportes_variables <- function(res, ncp = 4) {
  m <- res$var$contrib[, seq_len(min(ncp, ncol(res$var$contrib))), drop = FALSE]
  colnames(m) <- paste0("Dim", seq_len(ncol(m)))

  m %>%
    as.data.frame() %>%
    rownames_to_column("variable") %>%
    pivot_longer(-variable, names_to = "eje", values_to = "contribucion")
}

#' cos2 de las variables en los primeros ejes, con eje ya renombrado por posicion.
cos2_variables <- function(res, ncp = 4) {
  m <- res$var$cos2[, seq_len(min(ncp, ncol(res$var$cos2))), drop = FALSE]
  colnames(m) <- paste0("Dim", seq_len(ncol(m)))

  m %>%
    as.data.frame() %>%
    rownames_to_column("variable") %>%
    pivot_longer(-variable, names_to = "eje", values_to = "cos2") %>%
    mutate(eje = factor(eje, levels = paste0("Dim", seq_len(ncol(m)))))
}

# ------------------------------------------------------------------------------
# 5. Graficos del ACP con el tema NASA (ggplot2)
#
# Reemplazan a plot() de FactoMineR, que usa el estilo base de R (gris y sin
# vida). Asi TODOS los graficos del informe comparten el mismo tema.
# ------------------------------------------------------------------------------

#' Circulo de correlaciones (cargas de variables sobre dos ejes).
#'
#' @param res objeto PCA de FactoMineR
#' @param ejes vector con los dos ejes a graficar, ej. c(1,2)
plot_circulo_correlaciones <- function(res, ejes = c(1, 2)) {
  v <- as.data.frame(res$var$coord[, ejes, drop = FALSE])
  names(v) <- c("x", "y")
  v$variable <- rownames(v)
  v$cos2 <- res$var$cos2[, ejes[1]] + res$var$cos2[, ejes[2]]

  varianza <- res$eig[ejes, 2]

  ggplot(v, aes(x = x, y = y)) +
    geom_hline(yintercept = 0, color = "gray65", linewidth = 0.4) +
    geom_vline(xintercept = 0, color = "gray65", linewidth = 0.4) +
    geom_path(
      data = unit_circle(),
      aes(x, y), color = "gray70", linewidth = 0.5, linetype = "dashed",
      inherit.aes = FALSE
    ) +
    geom_segment(aes(x = 0, y = 0, xend = x, yend = y),
                 arrow = grid::arrow(length = grid::unit(0.14, "cm")),
                 color = nasa_col("primary"), linewidth = 0.7, alpha = 0.85) +
    geom_point(color = nasa_col("secondary"), size = 2.6, alpha = 0.9) +
    geom_text(aes(label = variable), vjust = -1.1, size = 3.2,
              color = nasa_col("dark_txt"), fontface = "bold") +
    coord_fixed() +
    scale_x_continuous(limits = c(-1.05, 1.05), breaks = seq(-1, 1, 0.5)) +
    scale_y_continuous(limits = c(-1.05, 1.05), breaks = seq(-1, 1, 0.5)) +
    labs(
      title = "Círculo de correlaciones",
      subtitle = "Longitud de la flecha = calidad de representación (cos²); ángulo entre flechas = correlación",
      x = sprintf("Dim%d (%.1f%% de varianza)", ejes[1], varianza[1]),
      y = sprintf("Dim%d (%.1f%% de varianza)", ejes[2], varianza[2]),
      caption = "Fuente: NASA Exoplanet Archive"
    ) +
    theme_nasa()
}

# circulo unitario para la referencia
unit_circle <- function(n = 200) {
  t <- seq(0, 2 * pi, length.out = n)
  tibble(x = cos(t), y = sin(t))
}

#' Mapa de individuos coloreado por una variable cualitativa suplementaria.
#'
#' @param res objeto PCA de FactoMineR (debe haberse pasado quali.sup)
#' @param grupo nombre de la variable categórica por la que colorear
#' @param min_pct agrupa en "Otros" los grupos con menos de este % de individuos
#'   (evita leyendas ilegibles con métodos minoritarios)
plot_individuos_acp <- function(res, grupo = NULL, ejes = c(1, 2), min_pct = 3) {
  # FactoMineR guarda las suplementarias en res$call$quali.sup$quali.sup
  qs <- res$call$quali.sup$quali.sup

  d <- as.data.frame(res$ind$coord[, ejes, drop = FALSE])
  names(d) <- c("x", "y")

  disponible <- !is.null(grupo) && !is.null(qs) && grupo %in% colnames(qs)
  if (disponible) {
    g <- as.factor(qs[, grupo])
    # Agrupa los grupos minoritarios para que la leyenda sea legible
    pct <- prop.table(table(g)) * 100
    chicos <- names(pct)[pct < min_pct]
    if (length(chicos) > 0 && length(chicos) < nlevels(g)) {
      g <- fct_lump_prop(g, prop = min_pct / 100, other_level = "Otros")
    }
    d$grupo <- g
    titulo_grupo <- grupo
  } else {
    d$grupo <- factor("Todos")
    titulo_grupo <- "Grupo"
  }

  niveles <- levels(d$grupo)
  varianza <- res$eig[ejes, 2]

  ggplot(d, aes(x = x, y = y, color = grupo)) +
    geom_hline(yintercept = 0, color = "gray75", linewidth = 0.35) +
    geom_vline(xintercept = 0, color = "gray75", linewidth = 0.35) +
    geom_point(alpha = 0.6, size = 1.6) +
    guides(color = guide_legend(override.aes = list(alpha = 1, size = 3))) +
    labs(
      title = "Mapa de individuos del ACP",
      subtitle = sprintf("Cada punto es un exoplaneta; color = %s (variable suplementaria, no define los ejes)",
                         titulo_grupo),
      x = sprintf("Dim%d (%.1f%% de varianza)", ejes[1], varianza[1]),
      y = sprintf("Dim%d (%.1f%% de varianza)", ejes[2], varianza[2]),
      color = titulo_grupo,
      caption = "Fuente: NASA Exoplanet Archive"
    ) +
    scale_color_nasa(n = length(niveles)) +
    theme_nasa()
}
