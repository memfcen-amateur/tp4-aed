for (archivo in file.path("R", dir("R"))) {
  source(archivo)
}

abalone <- leer_abalone("data/abalone.data")

algoritmos <- list(
  kvmc = entrenar_k_vecinos,
  # lda no se lleva con formulas todavia
  # lda = clasificadora_segun_variable,
  rlog = rlog,
  qda = qda
)

m1 <- adulto ~ anillos + peso.total + long.diametro + long.altura


rlog1 <- algoritmos[["rlog"]](adulto ~ anillos, abalone)
tasa_aciertos(abalone$adulto, rlog1$predecir(abalone))

qda1 <- qda(m1, abalone)
tasa_aciertos(abalone$adulto, qda1$predecir(abalone))
# Probando las funciones de a pedacitos
params <- estimar_parametros_qda(m1, abalone)
predecir_m1 <- generador_predecir_qda(params$muk, params$pik, params$sigmak)
predecir_m1(params$muk[[2]])

rlog1 <- rlog(adulto ~ anillos + long.diametro, abalone,
              tasa_aprendizaje = 1e-5, min_delta = 1e-7, max_ciclos = 10000)

rlog2 <- rlog(m1, abalone,
              tasa_aprendizaje = 1e-5, min_delta = 1e-6)

str(rlog1)
str(rlog2)

evolucion_parametros <- function(valores_beta) {
  #' Dada la matriz de valores_beta que devuelve `rlog()`, grafica
  #' la evolución de los parámetros a través de las iteraciones.
  valores_beta %>% t() %>% as_tibble() %>%
    gather(coef, valor) %>%
    group_by(coef) %>%
    mutate(x = row_number()) %>%
    ggplot(aes(x, valor, color = coef)) +
    geom_line()
}

evolucion_parametros(rlog1$valores_beta)
evolucion_parametros(rlog2$valores_beta)

grafica_roc <- function(aucroc) {
  # Genera la gráfica de "área bajo la curva" de ROC
  aucroc %>% ggplot(aes(fpr, tpr)) + geom_line()
}

roc1 <- aucroc(abalone$adulto, as.vector(rlog1$probs), seq(0, 1, 0.1))
roc2 <- aucroc(abalone$adulto, as.vector(rlog2$probs), seq(0, 1, 0.1))

grafica_roc(roc1)
grafica_roc(roc2)

tibble(x = as.vector(rlog1$probs)) %>% ggplot(aes(x)) + geom_histogram()
tibble(x = as.vector(rlog2$probs)) %>% ggplot(aes(x)) + geom_histogram()
mean(rlog1$probs)
mean(rlog2$probs)

##### Grafiquitos parte descriptiva del TP ####
GGally::ggpairs(abalone)

variables_explicativas <- names(select(abalone, anillos:peso.dif))

freqpoly <- function(df, var_y, var_x) {
  ggplot(df, aes_string(x = var_x, color = var_y)) +
    geom_freqpoly()
}

violin <- function(df, nombre_x, nombre_y) {
  ggplot(df, aes_string(x = nombre_x, y = nombre_y, color = nombre_x)) +
    geom_boxplot()
}


graficar_var <- function(df, var_x) {
  ggsave(paste(IMG_DIR, "boxplot_", var_x, ".png", sep = ""), violin(df, "adulto", var_x))
  ggsave(paste(IMG_DIR, "freqpoly_", var_x, ".png", sep = ""), freqpoly(df, "adulto", var_x))
}

IMG_DIR = "imagenes/"
walk(variables_explicativas, ~graficar_var(abalone, .))

abalone %>% 
  group_by(adulto) %>%
  summarise_all(mean)

abalone %>%
  ggplot(aes(long.altura, peso.total, color = adulto)) +
  geom_point()

abalone %>% ggplot(aes(long.altura)) + geom_histogram() + coord_trans(y = "log1p")

abalone <- abalone %>%
  mutate(long.altura = ifelse(long.altura > 0.3, NA, long.altura))

# abalone %>% select(adulto:peso.dif)


abalone %>% 
  group_by(adulto) %>%
  summarise(q = n()) %>%
  mutate(p = q/sum(q))

abalone %>% 
  group_by(adulto) %>%
  summarise_if(is.numeric, mean, na.rm = T)

abalone %>%
  ggplot(aes(long.altura, sqrt(peso.caparazon), color = adulto)) +
  geom_jitter(alpha = 0.3) +
  guides(alpha = "none")

