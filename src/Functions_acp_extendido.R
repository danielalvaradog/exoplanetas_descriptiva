# ==============================================================================
# Functions_acp_extendido.R
#   Funciones para el EJERCICIO DE APRENDIZAJE: ¿qué pasa si se incluyen los
#   metadatos de precisión (*err1, *err2, *lim) en el ACP?
#
# Es un módulo SEPARADO de Functions_acp.R: no debe usarse para el análisis
# principal, solo para este ejercicio comparativo.
#
# Dependencias: tidyverse, missMDA, FactoMineR
# ==============================================================================

suppressMessages({
  library(tidyverse)
  library(missMDA)
  library(FactoMineR)
  source("src/Functions_acp.R")   # reutiliza tema, helpers y ACP principal
})

# Columnas que NO son numéricas de contenido (texto, flags, coordenadas)
COLUMNAS_NO_NUMERICAS <- c(
  "pl_name", "hostname", "discoverymethod", "disc_facility", "soltype",
  "pl_refname", "st_refname", "sy_refname", "rastr", "decstr",
  "pl_bmassprov", "st_metratio", "rowupdate", "pl_pubdate", "releasedate",
  "default_flag", "ttv_flag", "st_spectype", "ra", "dec"
)

# ------------------------------------------------------------------------------
# 1. Detección de columnas
# ------------------------------------------------------------------------------

#' Clasifica las columnas del CSV: numéricas de contenido vs metadatos de
#' precisión. Devuelve también las no numéricas para transparencia.
detectar_columnas <- function(df) {
  nms <- names(df)
  metadatos <- grep("(err1|err2|lim)$", nms, value = TRUE)
  no_numericas <- intersect(nms, COLUMNAS_NO_NUMERICAS)
  contenido <- setdiff(nms, c(metadatos, no_numericas))

  list(
    contenido   = contenido,
    metadatos   = metadatos,
    no_numericas = no_numericas,
    err1 = grep("err1$", metadatos, value = TRUE),
    err2 = grep("err2$", metadatos, value = TRUE),
    lim  = grep("lim$",  metadatos, value = TRUE)
  )
}

# ------------------------------------------------------------------------------
# 2. Preparación del conjunto extendido
# ------------------------------------------------------------------------------

#' Construye la matriz del ejercicio con las variables pedidas.
#' Aplica log10 SOLO donde es válido (todas las variables son > 0); los
#' metadatos err2 son negativos y por eso quedan fuera del log10.
#'
#' @param df CSV crudo
#' @param vars vector de nombres de columnas a incluir
#' @param restringir_por_masa filtra a filas con pl_bmasse observado
preparar_extendido <- function(df, vars, restringir_por_masa = TRUE,
                               vars_log10 = NULL) {
  d <- df %>% mutate(across(everything(), ~ suppressWarnings(as.numeric(.x))))
  if (restringir_por_masa) d <- d %>% filter(!is.na(pl_bmasse))

  mat <- d %>% select(all_of(vars))

  if (!is.null(vars_log10)) {
    vars_log10 <- intersect(vars_log10, names(mat))
    mat <- mat %>%
      mutate(across(
        all_of(vars_log10),
        ~ ifelse(is.na(.x) | .x <= 0, NA_real_, log10(.x))
      ))
  }
  mat
}

# ------------------------------------------------------------------------------
# 3. Diagnósticos específicos de los metadatos
# ------------------------------------------------------------------------------

#' Diagnostica varianza: detecta columnas con varianza cero (rompen
#' scale.unit = TRUE) y casi cero (correlaciones inestables).
#' @param mat matriz numérica
#' @param tol_casi umbral de varianza por debajo del cual se considera "casi 0"
diagnostico_varianza <- function(mat, tol_casi = 1e-4) {
  v <- sapply(mat, var, na.rm = TRUE)
  tibble(
    variable = names(v),
    varianza = as.numeric(v),
    clase = case_when(
      is.na(v)         ~ "indeterminada",
      v == 0           ~ "CERO (rompe ACP)",
      v < tol_casi     ~ "casi cero (inestable)",
      TRUE             ~ "ok"
    )
  ) %>% arrange(varianza)
}

#' ¿El nulo del error coincide con el nulo de su variable base?
#' Si coinciden ~100%, el nulo es ESTRUCTURAL, no aleatorio (no MCAR), y
#' "imputar el error de una medida inexistente" es conceptualmente absurdo.
#'
#' @param mat matriz con las variables (valores) y sus *err1
#' @param pares nombre de las variables base a evaluar
nulo_estructural <- function(mat, pares) {
  map_dfr(pares, function(b) {
    e <- paste0(b, "err1")
    if (!e %in% names(mat)) return(NULL)
    vb <- is.na(mat[[b]]); ve <- is.na(mat[[e]])
    tibble(
      variable       = b,
      error          = e,
      n_nulo_valor   = sum(vb),
      n_nulo_error   = sum(ve),
      pct_coincide   = round(mean(vb == ve) * 100, 1),
      interpretacion = ifelse(mean(vb == ve) > 0.90,
                              "nulo ESTRUCTURAL (no MCAR)", "parcial")
    )
  })
}

#' ¿El error de medida crece con la magnitud de la medida? (heterocedasticidad)
#' Correlación log10(valor) vs log10(err1) sobre pares con ambos > 0.
heterocedasticidad <- function(df, pares) {
  map_dfr(pares, function(b) {
    e <- paste0(b, "err1")
    if (!e %in% names(df)) return(NULL)
    v <- suppressWarnings(as.numeric(df[[b]]))
    er <- suppressWarnings(as.numeric(df[[e]]))
    ok <- !is.na(v) & !is.na(er) & v > 0 & er > 0
    if (sum(ok) < 50) return(NULL)
    r <- suppressWarnings(cor(log10(v[ok]), log10(er[ok])))
    tibble(
      variable   = b,
      error      = e,
      n          = sum(ok),
      r_log      = round(r, 3),
      lectura    = case_when(
        r >= 0.7 ~ "MUY fuerte: el error escala con la magnitud",
        r >= 0.4 ~ "fuerte",
        TRUE     ~ "débil"
      )
    )
  })
}

#' Distribución de valores en las columnas *lim (flags).
distribucion_lim <- function(df, cols) {
  map_dfr(cols, function(c) {
    v <- suppressWarnings(as.numeric(df[[c]]))
    v <- v[!is.na(v)]
    if (length(v) == 0) return(NULL)
    tibble(
      columna     = c,
      n           = length(v),
      pct_cero    = round(mean(v == 0) * 100, 1),
      n_val_distintos = n_distinct(v),
      varianza    = round(var(v), 6)
    )
  }) %>% arrange(pct_cero)
}

# ------------------------------------------------------------------------------
# 4. ACP extendido y comparación
# ------------------------------------------------------------------------------

#' Corre el ACP del conjunto extendido con imputación previa.
#' Elimina primero las variables con varianza cero (documentando la exclusión).
#'
#' @param mat matriz del ejercicio (con NA)
#' @param ncp componentes para la imputación
#' @return lista con $resultado (PCA), $excluidas_varianza, $imputacion
acp_extendido <- function(mat, ncp_imp = 5, ncp = 10) {
  dv <- diagnostico_varianza(mat)
  excluidas <- dv$variable[dv$clase == "CERO (rompe ACP)"]
  mat2 <- mat[, setdiff(names(mat), excluidas), drop = FALSE]

  imp <- imputar_acp(mat2, ncp = ncp_imp)

  # renameo por posición para no depender del formato "Dim.1" de FactoMineR
  res <- FactoMineR::PCA(as.data.frame(imp$X), scale.unit = TRUE,
                         ncp = ncp, graph = FALSE)

  list(
    resultado          = res,
    excluidas_varianza = excluidas,
    imputacion         = imp,
    casi_cero          = dv$variable[dv$clase == "casi cero (inestable)"]
  )
}

#' Tabla comparativa de eigenvalores entre dos ACP.
comparar_eigenvalores <- function(res_a, res_b, etiqueta_a, etiqueta_b, n = 5) {
  tibble(
    eje       = paste0("Dim", 1:n),
    a = round(res_a$eig[1:n, 2], 2),
    b = round(res_b$eig[1:n, 2], 2)
  ) %>%
    rename(!!etiqueta_a := a, !!etiqueta_b := b) %>%
    mutate(acum_a = cumsum(.data[[etiqueta_a]]),
           acum_b = cumsum(.data[[etiqueta_b]]))
}

#' Comparación de aportes de variables entre dos ACP (mismas variables).
comparar_aportes <- function(res_a, res_b, variables, eje = 1) {
  a <- res_a$var$contrib[, eje]
  b <- res_b$var$contrib[, eje]
  common <- intersect(intersect(names(a), names(b)), variables)
  tibble(
    variable = common,
    a = round(a[common], 2),
    b = round(b[common], 2)
  ) %>% arrange(desc(a))
}
