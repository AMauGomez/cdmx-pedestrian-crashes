################################################################################
# Inferencia Estadística · Caso de estudio: atropellamientos en la CDMX
# 0. Descarga y preparación de los datos
#
# Fuente: Incidentes viales reportados por C5, Gobierno de la Ciudad de México
# (Centro de Comando, Control, Cómputo, Comunicaciones y Contacto Ciudadano).
# https://datos.cdmx.gob.mx/dataset/incidentes-viales-c5 · Licencia CC BY 4.0
#
# El archivo original (2022 a febrero de 2024) pesa ~100 MB. Este script lo
# descarga una sola vez y guarda en datos/ dos archivos pequeños:
#   * atropellamientos_cdmx.csv   todos los reportes de atropellamiento
#   * tipos_incidente_cdmx.csv    conteo de reportes por tipo y código de cierre
################################################################################

library(readr)
library(dplyr)

dir.create("datos", showWarnings = FALSE)
url <- "https://archivo.datos.cdmx.gob.mx/C5/incidentes_viales/inViales_2022_2024.csv"
crudo <- "datos/inViales_2022_2024.csv"
if (!file.exists(crudo)) {
  options(timeout = 1800)
  download.file(url, crudo, mode = "wb")
}

c5 <- read_csv(crudo, col_types = cols(.default = "c"), progress = FALSE) |>
  filter(fecha_creacion >= "2022-01-01")

# Conteo de todos los reportes por tipo de incidente y código de cierre
# Códigos de cierre: A = afirmativo (confirmado), D = duplicado, F = falso, I = informativo
c5 |>
  count(incidente_c4, codigo_cierre, name = "reportes") |>
  write_csv("datos/tipos_incidente_cdmx.csv")

# Reportes de atropellamiento, con las columnas que usa el curso
c5 |>
  filter(incidente_c4 == "Atropellado") |>
  transmute(folio, fecha = fecha_creacion, hora = hora_creacion, dia_semana,
            codigo_cierre, alcaldia = alcaldia_catalogo,
            latitud = as.numeric(latitud), longitud = as.numeric(longitud)) |>
  write_csv("datos/atropellamientos_cdmx.csv")

cat("Listo: datos/atropellamientos_cdmx.csv y datos/tipos_incidente_cdmx.csv\n")
