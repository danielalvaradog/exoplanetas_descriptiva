# ==============================================================================
# functions.R - Funciones de Apoyo para EDA Exoplanetas NASA (Actualizado)
# ==============================================================================

if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  tidyverse,   # Manipulación de datos y visualización
  scales,      # Formato de ejes y escalas
  patchwork,   # Combinación de gráficos
  corrplot,    # Visualización de matrices de correlación
  knitr,       # Tablas kable
  kableExtra,  # Estilo de tablas en Rmd
  RColorBrewer,# Paletas de color
  nortest      # Pruebas de normalidad para N grande (ad.test, lillie.test)
)

# ------------------------------------------------------------------------------
# 1. Definición de Paletas y Temas
# ------------------------------------------------------------------------------
nasa_colors <- c(
  primary   = "#0B3D91", 
  secondary = "#FC3D21", 
  accent1   = "#1A5276", 
  accent2   = "#F4D03F", 
  accent3   = "#5B2C6F", 
  accent4   = "#117A65", 
  light_bg  = "#F8F9FA", 
  dark_txt  = "#2C3E50"  
)

nasa_palette <- c("#0B3D91", "#FC3D21", "#117A65", "#F4D03F", "#5B2C6F", "#E67E22", "#2980B9", "#8E44AD")

theme_nasa <- function() {
  theme_minimal(base_size = 11) +
    theme(
      plot.title = element_text(face = "bold", size = 12, color = nasa_colors["primary"]),
      plot.subtitle = element_text(size = 10, color = "gray30"),
      plot.caption = element_text(size = 8, face = "italic", color = "gray50"),
      axis.title = element_text(face = "bold", size = 10, color = nasa_colors["dark_txt"]),
      axis.text = element_text(size = 9),
      panel.grid.major = element_line(color = "gray90", linewidth = 0.3),
      panel.grid.minor = element_blank(),
      legend.position = "bottom",
      legend.title = element_text(face = "bold", size = 9),
      strip.background = element_rect(fill = nasa_colors["primary"], color = NA),
      strip.text = element_text(color = "white", face = "bold", size = 10)
    )
}

# ------------------------------------------------------------------------------
# 2. Preparación y Factorización del Dataset
# ------------------------------------------------------------------------------
prepare_exoplanet_data <- function(df) {
  df_clean <- df %>%
    select(
      any_of(c("pl_name")),
      discoverymethod,
      disc_facility,
      ttv_flag,
      soltype,
      sy_snum,
      sy_pnum,
      st_spectype,
      pl_rade,
      pl_bmasse,
      pl_orbper,
      pl_eqt,
      st_teff,
      sy_dist
    ) %>%
    mutate(
      discoverymethod = factor(discoverymethod),
      ttv_flag = factor(ttv_flag, levels = c(0, 1), labels = c("No TTV", "Sí TTV")),
      soltype = factor(soltype),
      sy_pnum_fct = factor(sy_pnum, ordered = TRUE),
      
      # Nueva Variable 1: Número de estrellas como factor
      sy_snum_fct = factor(case_when(
        sy_snum == 1 ~ "1 Estrella",
        sy_snum == 2 ~ "2 Estrellas",
        sy_snum >= 3 ~ "3+ Estrellas",
        TRUE ~ NA_character_
      )),
      
      # Nueva Variable 2: Clase espectral principal (O, B, A, F, G, K, M)
      st_spectype_class = factor(str_extract(st_spectype, "^[OBAFGKM]")),
      
      # Nueva Variable 3: Principales instalaciones de descubrimiento
      disc_facility_top = factor(fct_lump_n(disc_facility, n = 5, other_level = "Otros Observatorios")),
      
      pl_rade = as.numeric(pl_rade),
      pl_bmasse = as.numeric(pl_bmasse),
      pl_orbper = as.numeric(pl_orbper),
      pl_eqt = as.numeric(pl_eqt),
      st_teff = as.numeric(st_teff),
      sy_dist = as.numeric(sy_dist)
    )
  
  return(df_clean)
}

# ------------------------------------------------------------------------------
# 3. Análisis Univariado Categórico y Cuantitativo (con Normalidad)
# ------------------------------------------------------------------------------
plot_univariate_cuali <- function(df, var_name, title_label) {
  var_sym <- sym(var_name)
  
  df_summary <- df %>%
    filter(!is.na(!!var_sym)) %>%
    count(!!var_sym) %>%
    mutate(pct = n / sum(n) * 100)
  
  colors_to_use <- rep(nasa_palette, length.out = nrow(df_summary))
  
  p <- ggplot(df_summary, aes(x = reorder(!!var_sym, -n), y = n, fill = !!var_sym)) +
    geom_col(show.legend = FALSE, width = 0.7, color = "black", alpha = 0.85) +
    geom_text(aes(label = sprintf("%d (%.1f%%)", n, pct)), 
              vjust = -0.5, size = 3.2, fontface = "bold") +
    scale_fill_manual(values = colors_to_use) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
    labs(
      title = paste("Distribución de", title_label),
      x = title_label,
      y = "Frecuencia Absoluta",
      caption = "Fuente: NASA Exoplanet Archive"
    ) +
    theme_nasa() +
    theme(axis.text.x = element_text(angle = 30, hjust = 1))
  
  return(p)
}

plot_univariate_cuanti <- function(df, var_name, title_label, log_scale = FALSE, unit = "") {
  var_sym <- sym(var_name)
  df_clean <- df %>% filter(!is.na(!!var_sym), !!var_sym > 0)
  vals <- pull(df_clean, !!var_sym)
  
  # Prueba de Normalidad de Anderson-Darling (robusta para N > 5000)
  ad_test <- nortest::ad.test(vals)
  p_val_str <- if (ad_test$p.value < 0.001) "< 0.001" else sprintf("%.4f", ad_test$p.value)
  norm_subtitle <- sprintf("Prueba Anderson-Darling: A = %.2f, p-valor %s (%s)", 
                           ad_test$statistic, p_val_str, 
                           if(ad_test$p.value < 0.05) "No Normal" else "Normal")
  
  p_hist <- ggplot(df_clean, aes(x = !!var_sym)) +
    geom_histogram(aes(y = after_stat(density)), bins = 35, fill = nasa_colors["primary"], color = "white", alpha = 0.75) +
    geom_density(color = nasa_colors["secondary"], linewidth = 1) +
    labs(
      title = paste("Distribución de", title_label),
      subtitle = norm_subtitle,
      x = paste0(title_label, if(unit != "") paste0(" (", unit, ")") else ""),
      y = "Densidad"
    ) +
    theme_nasa()
  
  p_box <- ggplot(df_clean, aes(x = "", y = !!var_sym)) +
    geom_boxplot(fill = nasa_colors["accent2"], alpha = 0.7, outlier.color = nasa_colors["secondary"], outlier.size = 1.5) +
    coord_flip() +
    labs(x = "", y = paste0(title_label, if(unit != "") paste0(" (", unit, ")") else "")) +
    theme_nasa() +
    theme(axis.text.y = element_blank(), axis.ticks.y = element_blank())
  
  if (log_scale) {
    p_hist <- p_hist + scale_x_log10(labels = comma)
    p_box <- p_box + scale_y_log10(labels = comma)
  } else {
    p_hist <- p_hist + scale_x_continuous(labels = comma)
    p_box <- p_box + scale_y_continuous(labels = comma)
  }
  
  combined <- p_hist / p_box + plot_layout(heights = c(3, 1))
  return(combined)
}

summary_cuanti_table <- function(df, var_name, var_label) {
  var_sym <- sym(var_name)
  
  df %>%
    summarise(
      Variable = var_label,
      N_Validos = sum(!is.na(!!var_sym)),
      N_Nulos = sum(is.na(!!var_sym)),
      Media = mean(!!var_sym, na.rm = TRUE),
      Mediana = median(!!var_sym, na.rm = TRUE),
      Desv_Est = sd(!!var_sym, na.rm = TRUE),
      Mínimo = min(!!var_sym, na.rm = TRUE),
      Q1 = quantile(!!var_sym, 0.25, na.rm = TRUE),
      Q3 = quantile(!!var_sym, 0.75, na.rm = TRUE),
      Máximo = max(!!var_sym, na.rm = TRUE),
      # Estadístico y p-valor de Anderson-Darling
      AD_Stat = round(nortest::ad.test(na.omit(!!var_sym))$statistic, 2),
      AD_p_value = ifelse(nortest::ad.test(na.omit(!!var_sym))$p.value < 0.001, "< 0.001", 
                          round(nortest::ad.test(na.omit(!!var_sym))$p.value, 4))
    )
}

# ------------------------------------------------------------------------------
# 4. Análisis Bivariado Categórico-Categórico (con Chi-cuadrado / Fisher)
# ------------------------------------------------------------------------------
plot_cuali_cuali <- function(df, var1, var2, label1, label2, position = "fill") {
  sym1 <- sym(var1)
  sym2 <- sym(var2)
  
  df_filtered <- df %>% filter(!is.na(!!sym1), !is.na(!!sym2))
  
  # Tabla de contingencia
  tab <- table(df_filtered[[var1]], df_filtered[[var2]])
  
  # Evaluación de condiciones para Chi-Cuadrado vs Fisher Exacto
  exp_counts <- suppressWarnings(chisq.test(tab)$expected)
  has_low_counts <- any(exp_counts < 5)
  
  if (!has_low_counts) {
    test_res <- chisq.test(tab)
    test_name <- "Chi-cuadrado"
    stat_val <- sprintf("χ² = %.2f", test_res$statistic)
  } else {
    # Prueba exacta de Fisher con p-valor simulado por Monte Carlo para matrices grandes
    test_res <- fisher.test(tab, simulate.p.value = TRUE, B = 2000)
    test_name <- "Exacta de Fisher (Simulada)"
    stat_val <- "Fisher Exact"
  }
  
  p_val_str <- if (test_res$p.value < 0.001) "< 0.001" else sprintf("%.4f", test_res$p.value)
  assoc_str <- if (test_res$p.value < 0.05) "Asociación Significativa" else "Sin Asociación Significativa"
  subtitle_text <- sprintf("Prueba %s: %s, p-valor %s (%s)", test_name, stat_val, p_val_str, assoc_str)
  
  colors_to_use <- rep(nasa_palette, length.out = length(unique(df_filtered[[var2]])))
  y_lab <- if (position == "fill") "Proporción" else "Conteo"
  
  p <- ggplot(df_filtered, aes(x = !!sym1, fill = !!sym2)) +
    geom_bar(position = position, color = "black", alpha = 0.85, width = 0.7) +
    scale_fill_manual(values = colors_to_use) +
    labs(
      title = paste(label1, "vs.", label2),
      subtitle = subtitle_text,
      x = label1,
      y = y_lab,
      fill = label2
    ) +
    theme_nasa() +
    theme(axis.text.x = element_text(angle = 35, hjust = 1))
  
  if (position == "fill") {
    p <- p + scale_y_continuous(labels = percent)
  }
  
  return(p)
}

# ------------------------------------------------------------------------------
# 5. Otras Funciones Bivariadas y Correlación
# ------------------------------------------------------------------------------
plot_cuali_cuanti <- function(df, var_cuali, var_cuanti, label_cuali, label_cuanti, log_scale = TRUE) {
  sym_cuali <- sym(var_cuali)
  sym_cuanti <- sym(var_cuanti)
  
  df_filtered <- df %>% filter(!is.na(!!sym_cuali), !is.na(!!sym_cuanti), !!sym_cuanti > 0)
  colors_to_use <- rep(nasa_palette, length.out = length(unique(df_filtered[[var_cuali]])))
  
  p <- ggplot(df_filtered, aes(x = reorder(!!sym_cuali, !!sym_cuanti, FUN = median), y = !!sym_cuanti, fill = !!sym_cuali)) +
    geom_boxplot(alpha = 0.7, outlier.alpha = 0.4, outlier.size = 1) +
    scale_fill_manual(values = colors_to_use) +
    labs(
      title = paste(label_cuanti, "según", label_cuali),
      x = label_cuali,
      y = label_cuanti
    ) +
    theme_nasa() +
    theme(legend.position = "none", axis.text.x = element_text(angle = 35, hjust = 1))
  
  if (log_scale) {
    p <- p + scale_y_log10(labels = comma)
  } else {
    p <- p + scale_y_continuous(labels = comma)
  }
  
  return(p)
}

plot_cuanti_cuanti <- function(df, var1, var2, label1, label2, log_x = TRUE, log_y = TRUE, color_var = NULL) {
  sym1 <- sym(var1)
  sym2 <- sym(var2)
  
  df_filtered <- df %>% filter(!is.na(!!sym1), !is.na(!!sym2), !!sym1 > 0, !!sym2 > 0)
  
  if (!is.null(color_var)) {
    sym_col <- sym(color_var)
    colors_to_use <- rep(nasa_palette, length.out = length(unique(df_filtered[[color_var]])))
    
    p <- ggplot(df_filtered, aes(x = !!sym1, y = !!sym2, color = !!sym_col)) +
      geom_point(alpha = 0.6, size = 1.8) +
      scale_color_manual(values = colors_to_use)
  } else {
    p <- ggplot(df_filtered, aes(x = !!sym1, y = !!sym2)) +
      geom_point(alpha = 0.5, color = nasa_colors["primary"], size = 1.8)
  }
  
  p <- p +
    geom_smooth(method = "lm", color = nasa_colors["secondary"], se = TRUE, linetype = "dashed") +
    labs(
      title = paste("Relación entre", label1, "y", label2),
      x = label1,
      y = label2
    ) +
    theme_nasa()
  
  if (log_x) p <- p + scale_x_log10(labels = comma)
  if (log_y) p <- p + scale_y_log10(labels = comma)
  
  return(p)
}

plot_pearson_correlation <- function(df, vars_cuanti = NULL, use_log = TRUE) {
  if (is.null(vars_cuanti)) {
    vars_cuanti <- c("pl_rade", "pl_bmasse", "pl_orbper", "pl_eqt", "st_teff", "sy_dist")
  }
  
  df_num <- df %>% 
    select(any_of(vars_cuanti)) %>% 
    mutate(across(everything(), as.numeric))
  
  if (use_log) {
    df_num <- df_num %>%
      mutate(across(everything(), ~ ifelse(.x > 0, log10(.x), NA_real_)))
  }
  
  cor_matrix <- cor(df_num, use = "pairwise.complete.obs", method = "pearson")
  
  corrplot::corrplot(
    cor_matrix,
    method = "color",
    type = "upper",
    order = "hclust",
    addCoef.col = "black",
    number.cex = 0.8,
    tl.col = nasa_colors["dark_txt"],
    tl.srt = 45,
    col = colorRampPalette(c(nasa_colors["primary"], "white", nasa_colors["secondary"]))(200),
    title = paste0("Matriz de Correlación de Pearson", if(use_log) " (Escala Log10)" else ""),
    mar = c(0, 0, 2, 0)
  )
  
  return(cor_matrix)
}