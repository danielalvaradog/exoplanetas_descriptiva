# ==============================================================================
# Functions_acm.R
#   ACM (Analisis de Correspondencias Multiples) sobre las categoricas del
#   dataset de exoplanetas. Continuacion de la Fase 5 del ACP.
#
# Patron heredado del ACP: DIAGNOSTICO ANTES de decision. Ninguna exclusion
# sale de la intuicion: se verifica con datos (nulos, cardinalidad, niveles
# minimos) y se documenta la razon exacta.
#
# Dependencias: FactoMineR, tidyverse
# ==============================================================================

suppressMessages({
  library(tidyverse)
  library(FactoMineR)
  source("src/Functions_acp.R")   # reutiliza nasa_col, theme_nasa, scale_*_nasa
})

# Universo de columnas no-numericas de contenido (texto, flags, fechas, coords)
CAT_CANDIDATAS <- c(
  "discoverymethod", "disc_facility", "soltype", "pl_bmassprov",
  "st_metratio", "st_spectype", "ttv_flag", "default_flag",
  "pl_name", "hostname", "pl_refname", "st_refname", "sy_refname",
  "rastr", "decstr", "rowupdate", "pl_pubdate", "releasedate"
)

# Nivel minimo para conservar un nivel sin agrupar
NIVEL_MINIMO <- 100

# ------------------------------------------------------------------------------
# 1. Diagnostico de viabilidad ( ANTES de decidir exclusiones )
# ------------------------------------------------------------------------------

#' Diagnostica cada candidata categorica para el ACM.
#' Devuelve por variable: nulos, cardinalidad, nivel minimo, nivel dominante y
#' un veredicto motivado. El veredicto se basa en datos, no en intuicion.
#'
#' @param df data.frame crudo
#' @param vars candidatas a diagnosticar
#' @param min_nivel frecuencia minima para conservar un nivel sin agrupar
diagnostico_categoricas <- function(df, vars = CAT_CANDIDATAS,
                                    min_nivel = NIVEL_MINIMO) {
  n <- nrow(df)
  map_dfr(vars, function(v) {
    x <- as.character(df[[v]])
    x <- ifelse(is.na(x) | x == "" , NA_character_, x)
    obs <- x[!is.na(x)]
    tab <- sort(table(obs), decreasing = TRUE)
    n_niv <- length(tab)
    nulos_pct <- round((n - length(obs)) / n * 100, 1)

    # clasificacion automatica del problema
    problema <-
      if (nulos_pct >= 80)              "no viable: nulos estructurales (>=80%)"
      else if (niv_dominante_pct(tab, n) >= 95) "no viable: un nivel domina >=95%"
      else if (n_niv == 0)              "no viable: columna vacia"
      else if (es_continua_disfrazada(obs)) "no viable: continua o fecha (sin niveles naturales)"
      else if (n_niv >= 1000)           "no viable: llave de identidad (sin significado categorico)"
      else if (v == "default_flag")     "marcador de fila, no propiedad del planeta"
      else if (n_niv > min_nivel * 4)   "requiere agrupacion agresiva"
      else if (min(tab) < min_nivel)    "activa con agrupacion de raros"
      else                              "activa sin tratamiento"

    tibble(
      variable        = v,
      n_observados    = length(obs),
      pct_nulos       = nulos_pct,
      n_niveles       = n_niv,
      n_nivel_minimo  = if (n_niv == 0) NA_length_ else as.integer(tab[n_niv]),
      nivel_dominante = names(tab)[1],
      pct_dominante   = round(tab[1] / n * 100, 1),
      problemas       = problema
    )
  })
}

# helper: % del total que aporta el nivel mas frecuente
niv_dominante_pct <- function(tab, n_total) round(as.numeric(tab[1]) / n_total * 100, 1)

# helper: detecta cadenas que en realidad son fechas o coordenadas continuas.
# Una binaria (0/1) o con pocos niveles distintos es categorica legitima;
# solo se marca "continua" si hay MUCHOS valores numéricos distintos.
# OJO: ninguna regex con \d funciona en el motor TRE de R sin perl=TRUE
# (verificado: "[\d.]" se interpreta como clase de "d" y "x").
es_continua_disfrazada <- function(obs) {
  if (length(obs) == 0) return(FALSE)
  m <- obs[1:min(length(obs), 50)]
  fecha    <- all(grepl("^\\d{4}-\\d{2}(-\\d{2})?$", m, perl = TRUE))
  coord    <- all(grepl("^[-+]?\\d+h\\d+m[\\d.]+s$|^[-+]?\\d+d\\d+m[\\d.]+s$",
                        m, perl = TRUE))
  numerica <-
    length(m) > 5 &&
    all(!is.na(suppressWarnings(as.numeric(m)))) &&
    length(unique(obs)) > 10
  fecha || coord || numerica
}

# ------------------------------------------------------------------------------
# 2. Preparacion de las categoricas ACTIVAS
# ------------------------------------------------------------------------------

#' Agrupa niveles por debajo del minimo en "Otros".
agrupar_raros <- function(x, min_nivel = NIVEL_MINIMO, etiqueta = "Otros") {
  x <- factor(x)
  tab <- table(x, useNA = "no")
  raros <- names(tab)[tab < min_nivel]
  if (length(raros) == 0) return(x)
  xr <- as.character(x)
  xr[xr %in% raros] <- etiqueta
  factor(xr)
}

#' Colapsa las variantes por release de Kepler de soltype: 9 -> 4 niveles.
#' q1_qX_... son versiones del MISMO catalogo KOI, no estados distintos.
colapsar_soltype <- function(x) {
  x <- as.character(x)
  x[grepl("^Kepler Project Candidate", x)] <- "Kepler Project Candidate"
  factor(x, levels = c("Published Confirmed", "Kepler Project Candidate",
                       "Published Candidate", "TESS Project Candidate"))
}

#' Construye la tabla de factores ACTIVAS para el ACM.
#' Mismo filtro de masa que el ACP (consistencia) + Decisiones confirmadas:
#'   - "Sin dato" como propio nivel (nunca descartar filas)
#'   - agrupacion de niveles con n < min_nivel
#'   - colapso de variantes Kepler en soltype (9 -> 4)
#'
#' @return data.frame de factores / lista con $tabla y $registro de transformaciones
preparar_categoricas <- function(df, restringir_por_masa = TRUE) {
  d <- df
  if (restringir_por_masa) {
    bm <- suppressWarnings(as.numeric(d$pl_bmasse))
    d <- d[!is.na(bm) & d$pl_bmasse != "", , drop = FALSE]
  }

  # registro de transformaciones (transparencia del tratamiento)
  registro <- list()

  # NOTA DE ALCANCE (verificada en subset, ver Rmd): soltype queda como
  # variable ACTIVA EXCLUIDA dentro del subset con masa: 100% de las filas
  # son "Published Confirmed" (los candidatos Kepler/TESS no tienen masa),
  # por lo que no aporta inercia al ACM. colapsar_soltype() se conserva en
  # este modulo para el escenario alternativo de catálogo completo.
  out <- data.frame(
    discoverymethod = agrupar_raros(d$discoverymethod),
    disc_facility   = agrupar_raros(d$disc_facility, etiqueta = "Otras instalaciones"),
    pl_bmassprov    = agrupar_raros(factor(
      ifelse(is.na(d$pl_bmassprov) | d$pl_bmassprov == "",
             "Sin dato", as.character(d$pl_bmassprov)))),
    st_metratio     = agrupar_raros(factor(
      ifelse(is.na(d$st_metratio) | d$st_metratio == "",
             "Sin dato", as.character(d$st_metratio)))),
    ttv_flag        = factor(
      ifelse(is.na(d$ttv_flag), "Sin dato", ifelse(d$ttv_flag == "1", "Sí", "No")),
      levels = c("Sí", "No")),
    stringsAsFactors = TRUE
  )

  registro$n_subset    <- nrow(out)
  registro$J_activas   <- ncol(out)
  registro$m_categorias <- sum(sapply(out, nlevels))

  list(tabla = out, registro = registro)
}

# ------------------------------------------------------------------------------
# 3. Ejecucion del ACM y resumenes
# ------------------------------------------------------------------------------

#' Corre el ACM con FactoMineR sobre la tabla de factores.
#' Por defecto pide un espectro casi completo (ncp = m - J; FactoMineR lo
#' trunca al rango valido) para que los % de inercia ajustada no se calculen
#' sobre una base reducida.
correr_acm <- function(tabla, ncp = NULL) {
  J <- ncol(tabla)
  m <- sum(sapply(tabla, function(x) nlevels(x)))
  if (is.null(ncp)) ncp <- max(1L, m - J)
  for (k in seq(ncp, 1)) {                      # FactoMineR rechaza ncp > rango
    r <- try(FactoMineR::MCA(as.data.frame(tabla), ncp = k, graph = FALSE),
             silent = TRUE)
    if (!inherits(r, "try-error")) return(r)
  }
  stop("No fue posible correr el MCA.")
}

#' Resumen de ejes: eigenvalores CRUDOS + ajustados (Nenadic-Greenacre).
#' En MCA la inercia total = m/J - 1, y el nivel "de azar" es 1/J por eje.
#' La ajustada lambda* = (J/(J-1) * (lambda - 1/J))^2 es la medida estandar
#' para decidir retencion: si vale 0, el eje es ruido por debajo del azar.
#'
#' @param res objeto MCA de FactoMineR
#' @param J numero de variables activas
resumen_ejes_mca <- function(res, J) {
  raw     <- res$eig[, 1]
  n_ejes  <- length(raw)
  ajust   <- (J / (J - 1) * (raw - 1 / J))^2          # Nenadic & Greenacre 2007
  total_aj <- sum(ajust)

  tibble(
    eje          = paste0("Dim", seq_len(n_ejes)),
    eigen_crudo  = round(raw, 4),
    ajustada     = round(ajust, 4),
    pct_ajustada = round(ajust / total_aj * 100, 2),
    pct_acum     = round(cumsum(ajust / total_aj * 100), 2),
    conservar    = ajust > 0
  )
}

#' Asigna a cada etiqueta de categoria de FactoMineR su VARIABLE de origen,
#' recorriendo los bloques en orden: FactoMineR lista las categorias consecutivas
#' por variable y en el orden definido de la tabla (los droplevels respetan
#' el orden de los niveles). No existe un parseo fiable de la etiqueta: el
#' prefijo "var_nivel" se aplica solo a ALGUNAS variables (verificado).
#'
#' @return vector de nombres de variable, un elemento por etiqueta
mapear_categorias <- function(tabla, etiquetas) {
  sizes <- sapply(tabla, function(x) nlevels(droplevels(x)))
  stopifnot(length(etiquetas) == sum(sizes))   # mismo orden de columnas

  salida <- character(length(etiquetas))
  idx <- 1
  for (j in seq_along(sizes)) {                 # el orden de columnas de `tabla`
    if (idx > length(etiquetas)) break
    bloque <- etiquetas[idx:(idx + sizes[j] - 1)]
    niveles <- levels(droplevels(tabla[[j]]))
    posibles <- c(niveles, paste(names(tabla)[j], niveles, sep = "_"))
    stopifnot(all(bloque %in% posibles))       # sanidad: bloque ~ variable j
    salida[idx:(idx + sizes[j] - 1)] <- names(tabla)[j]
    idx <- idx + sizes[j]
  }
  salida
}

#' Tabla larga de categorias con variable atribuida correctamente.
tabla_categorias <- function(res, tabla, ncp = 4, medida = c("contrib", "cos2")) {
  medida <- match.arg(medida)
  m <- if (medida == "contrib") res$var$contrib else res$var$cos2
  n <- min(ncp, ncol(m))
  mm <- m[, seq_len(n), drop = FALSE]          # renombre por posicion
  colnames(mm) <- paste0("Dim", seq_len(n))
  df <- as.data.frame(mm)
  df$nivel <- rownames(mm)
  df$variable <- mapear_categorias(tabla, rownames(mm))
  df %>% pivot_longer(all_of(colnames(mm)),
                      names_to = "eje", values_to = "valor" )
}

# ------------------------------------------------------------------------------
# 4. Graficos (tema NASA del proyecto)
# ------------------------------------------------------------------------------

#' Scree plot del ACM con eigenvalores crudos y ajustados.
plot_scree_mca <- function(resumen, J) {
  pausa <- 1 / J
  bind_rows(
    resumen %>%
      transmute(eje, tipo = "Ajustados", valor = ajustada) ,
    resumen %>%
      transmute(eje, tipo = "Crudos (indicador)", valor = eigen_crudo)
  ) %>%
    ggplot(aes(x = eje, y = valor, fill = tipo)) +
    geom_col(position = "dodge", width = 0.75) +
    geom_text(aes(label = sprintf("%.2f", valor), fontface = "bold"),
              position = position_dodge(width = 0.75), vjust = -0.4, size = 2.8) +
    geom_hline(yintercept = 0, linetype = "solid", color = "gray55") +
    scale_fill_nasa(niveles = c("Ajustados", "Crudos (indicador)")) +
    labs(title = "Scree plot del ACM",
         subtitle = sprintf("Un eje conserva inercia real si su eigenvalor crudo supera 1/J = %.2f; por debajo, su inercia ajustada es 0 (ruido)",
                            pausa),
         x = "", y = "Inercia (eigenvalor)", fill = "") +
    theme_nasa()
}

#' Aportes de categorias a un eje, como barras. Espera la salida de
#' tabla_categorias() (columnas: nivel, variable, eje, valor).
plot_aportes_categorias <- function(tcp, eje = "Dim1", n = 12) {
  tcp %>%
    filter(.data$eje == !!eje, valor > 0) %>%
    mutate(nivel = fct_reorder(nivel, valor)) %>%
    top_n(n, valor) %>%
    ggplot(aes(x = nivel, y = valor, fill = variable)) +
    geom_col(width = 0.75) +
    geom_hline(yintercept = 0, color = "gray50") +
    coord_flip() +
    labs(title = paste0("Aporte de categorias a ", eje),
         subtitle = "Los niveles con mayor influencia definen qué estructura el eje",
         x = "", y = "% de aporte al eje", fill = "Variable activa") +
    theme_nasa() +
    theme(legend.position = "bottom")
}

#' Mapa de categorias (res$var$coord) con colores por variable (via mapeo).
plot_categorias_acm <- function(res, tabla, ejes = 1:2) {
  co <- data.frame(res$var$coord[, ejes, drop = FALSE])
  colnames(co) <- paste0("Dim", seq_along(ejes))
  co$nivel <- rownames(co)
  co$variable <- mapear_categorias(tabla, rownames(co))
  ggplot(co, aes(x = Dim1, y = Dim2, color = variable)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray60") +
    geom_vline(xintercept = 0, linetype = "dashed", color = "gray60") +
    geom_point(size = 2.6) +
    ggrepel::geom_text_repel(aes(label = nivel), size = 2.9, max.overlaps = 40,
                             seed = 1234) +
    scale_color_nasa(n = n_distinct(co$variable)) +
    labs(title = "Mapa de categorias del ACM",
         subtitle = "Categorias cercanas entre si comparten perfiles; lejos del origen = perfil diferenciado",
         x = "Dim 1", y = "Dim 2", color = "Variable activa",
         caption = "Fuente: NASA Exoplanet Archive") +
    theme_nasa() +
    theme(legend.position = "bottom")
}

#' Mapa de individuos coloreado por una variable.
plot_individuos_acm <- function(res, grupo) {
  co <- data.frame(res$ind$coord[, 1:2, drop = FALSE])
  colnames(co) <- c("Dim1", "Dim2")
  co$grupo <- grupo
  ggplot(co, aes(x = Dim1, y = Dim2, color = grupo)) +
    geom_point(alpha = 0.35, size = 1.1) +
    scale_color_nasa(n = n_distinct(co$grupo)) +
    labs(title = "Mapa de individuos del ACM",
         subtitle = "Filas (planeta-parametro) proyectadas en las dimensiones",
         x = "Dim 1", y = "Dim 2", color = "",
         caption = "Fuente: NASA Exoplanet Archive") +
    theme_nasa() +
    theme(legend.position = "bottom")
}
