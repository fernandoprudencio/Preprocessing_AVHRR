#### Load libraries
library(rgee)
library(raster)
library(tidyverse)
library(sf)

#### Initialize Earth Engine
ee_Initialize(drive = TRUE)

#### Define a region of interest with sf
ee_roi <- st_read(system.file("shape/nc.shp", package = "sf")) %>%
  summarise() %>%
  st_geometry() %>%
  sf_as_ee()

#### Search into the Earth Engine’s public data archive
avhrr <- ee$ImageCollection("NOAA/CDR/AVHRR/NDVI/V5")

#### Define type of quality filter
bit1 <- ee$Number(2)$pow(1)$int() #Bit 1: Pixel is cloudy
bit2 <- ee$Number(2)$pow(2)$int() #Bit 2: Pixel contains cloud shadow

#### Build quality filter function
qaFilter <- function(img) {
  # Extract the NDVI band
  ndvi <- img$select("NDVI")
  
  # Extract the QUALITY band
  qa <- img$select("QA")
  
  # Select pixels to mask
  qa_mask <- qa$bitwiseAnd(bit1)$eq(0)$
    And(qa$bitwiseAnd(bit2)$eq(0))
  
  # Mask pixels with value zero
  ndvi$updateMask(qa_mask) %>% return()
}

#### Apply quality filter
ndvi_mask <- avhrr$map(qaFilter)

#### Extract time series of average values
##### create period
period <- seq(as.Date("2015-01-01"), as.Date("2019-12-01"), by = "1 month")

##### build function to extract time series
ts_extract <- function(date, images, roi) {
  # print(date)
  year <- str_sub(date, 1, 4) %>% as.numeric()
  month <- str_sub(date, 6, 7) %>% as.numeric()
  ndvi <- images$
    filter(ee$Filter$calendarRange(year, year, "year"))$
    filter(ee$Filter$calendarRange(month, month, "month"))$
    median()
  
  data <- ee_extract(ndvi, roi, fun = ee$Reducer$mean(), scale = 5000)
  
  if (ncol(data) == 0) { data <- data.frame(NDVI = rep(NA, nrow(data))) }
  
  return(data)
}

##### extract time series
ts <- sapply(period, FUN = ts_extract, images = ndvi_mask, roi = ee_roi)

##### plot time series
df <- t(as.data.frame(ts)) %>%
  as_tibble() %>%
  rename("value" = "V1") %>%
  mutate(period, value = value * .0001)

ggplot(df, aes(period, value)) +
  geom_line() +
  geom_point() +
  labs(y = "NDVI") +
  scale_x_date(
    limits = c(as.Date("2015-01-01"), as.Date("2020-01-01")),
    date_breaks = "1 year",
    date_labels = "%b%Y", expand = expansion(mult = c(.02, 0))
  ) +
  scale_y_continuous(
    breaks = seq(-.1, 1, .1)
  ) +
  theme_bw() +
  theme(
    legend.background = element_rect(fill = "white", color = "black"),
    legend.margin = margin(3, 7, 7, 7),
    legend.key.width = unit(1.6, "cm"),
    legend.key.height = unit(1.1, "cm"),
    legend.position = c(0.77, 0.78),
    legend.title = element_blank(),
    legend.text = element_text(size = 15, family = "Source Sans Pro"),
    axis.text.x = element_text(
      size = 12, colour = "black", family = "Source Sans Pro",
      face = "bold", angle = 0, vjust = .6
    ),
    axis.text.y = element_text(
      size = 13, face = "bold", family = "Source Sans Pro", color = "black"
    ),
    axis.title.x = element_blank(),
    axis.title.y = element_text(
      face = "bold", family = "Source Sans Pro", color = "black", size = 20
    ),
    axis.ticks.x = element_line(color = "black"),
    axis.ticks.y = element_line(color = "black"),
    panel.grid = element_blank(),
    panel.border = element_rect(size = .5, color = "black"),
    plot.margin = margin(1.5, .1, 1, 1, "cm"),
    axis.line.y = element_line(
      size = .8, color = "black"
    )
  )