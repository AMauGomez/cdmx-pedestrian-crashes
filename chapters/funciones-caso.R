################################################################################
# Funciones compartidas por los capítulos del caso de estudio
# (atropellamientos en la CDMX, datos del C5)
################################################################################

suppressPackageStartupMessages({
  library(readr); library(dplyr); library(tidyr); library(ggplot2)
})
theme_set(theme_minimal(base_size = 12))
ZONA <- "America/Mexico_City"
LABORABLES <- c("Lunes", "Martes", "Miércoles", "Jueves", "Viernes")

# Todos los reportes de atropellamiento (2022 a febrero de 2024)
leer_atropellamientos <- function(archivo = "datos/atropellamientos_cdmx.csv") {
  if (!file.exists(archivo)) stop("Primero corre 0-datos-atropellamientos.R")
  read_csv(archivo, show_col_types = FALSE) |>
    mutate(momento = as.POSIXct(paste(fecha, hora), tz = ZONA),
           hora_num = as.integer(substr(hora, 1, 2)),
           mes = substr(fecha, 1, 7))
}

# Atropellamientos confirmados en la hora pico de días laborables
hora_pico <- function(df, inicio = 18, fin = 21) {
  df |> filter(codigo_cierre == "A", dia_semana %in% LABORABLES,
               hora_num >= inicio, hora_num < fin)
}

# Quita "casi duplicados": un mismo atropellamiento confirmado con dos folios.
# Regla: un reporte a menos de `minutos` y `metros` del anterior del mismo día
# se considera el mismo hecho (ver capítulo 2, verificación de supuestos).
depurar_duplicados <- function(df, minutos = 10, metros = 500) {
  df |>
    arrange(momento) |>
    group_by(fecha) |>
    mutate(minutos_al_anterior = as.numeric(momento - lag(momento), units = "mins"),
           metros_al_anterior = 111000 * sqrt((latitud - lag(latitud))^2 +
                                                (cos(latitud * pi / 180) * (longitud - lag(longitud)))^2),
           repetido = !is.na(minutos_al_anterior) & minutos_al_anterior < minutos &
                      !is.na(metros_al_anterior) & metros_al_anterior < metros) |>
    ungroup() |>
    filter(!repetido) |>
    select(-minutos_al_anterior, -metros_al_anterior, -repetido)
}

# Minutos entre atropellamientos consecutivos en el "reloj de hora pico":
# el tiempo solo corre dentro de la ventana [inicio, fin) de cada día del
# periodo [desde, hasta]; al cerrar la ventana de un día, el reloj sigue en la
# ventana del siguiente. Por la pérdida de memoria de la exponencial, en un
# proceso de Poisson estos intervalos son exponenciales e independientes
# (capítulo 2 explica por qué NO hay que medir solo dentro de cada ventana).
tiempos_entre <- function(df, desde = min(df$fecha), hasta = max(df$fecha),
                          inicio = 18, fin = 21, laborables = TRUE) {
  dias <- seq(as.Date(desde), as.Date(hasta), by = "day")
  if (laborables) dias <- dias[format(dias, "%u") <= "5"]
  dia <- match(as.Date(df$fecha), dias)
  minuto <- as.numeric(difftime(df$momento,
                                as.POSIXct(paste(df$fecha, sprintf("%02d:00:00", inicio)), tz = ZONA),
                                units = "mins"))
  reloj <- sort(unique((dia - 1) * (fin - inicio) * 60 + minuto))
  diff(reloj)
}

# La forma ingenua (sesgada): solo intervalos dentro de la misma ventana diaria.
# Se usa en el capítulo 2 para mostrar el sesgo.
tiempos_dentro_de_ventana <- function(df) {
  unlist(lapply(split(df$momento, df$fecha), function(x) {
    as.numeric(diff(sort(unique(x))), units = "mins")
  }), use.names = FALSE)
}

# Intervalos de un mes "aaaa-mm" (hora pico, depurados)
tiempos_mes <- function(df, mes) {
  inicio <- as.Date(paste0(mes, "-01"))
  final <- seq(inicio, by = "month", length.out = 2)[2] - 1
  tiempos_entre(df |> filter(.data$mes == !!mes), inicio, final)
}

# La muestra del curso: marzo de 2023, hora pico, sin casi duplicados
muestra_curso <- function(df = leer_atropellamientos()) {
  tiempos_mes(hora_pico(df) |> depurar_duplicados(), "2023-03")
}
