rgee Demo: Image preprocessing MODIS
================
Fernando Prudencio
October 28, 2020

### Load libraries

``` r
library(rgee)
library(raster)
library(tidyverse)
library(sf)
```

### Initialize Earth Egine

``` r
ee_Initialize(drive = TRUE)
```

    ## ── rgee 1.0.6 ─────────────────────────────────────── earthengine-api 0.1.236 ── 
    ##  ✓ email: not_defined
    ##  ✓ Google Drive credentials: ✓ Google Drive credentials:  FOUND
    ##  ✓ Initializing Google Earth Engine: ✓ Initializing Google Earth Engine:  DONE!
    ##  ✓ Earth Engine user: users/datasetfprudencio 
    ## ────────────────────────────────────────────────────────────────────────────────

### Define a region of interest with sf

``` r
ee_roi <- st_read(system.file("shape/nc.shp", package = "sf")) %>%
  st_geometry() %>%
  sf_as_ee()
```

    ## Reading layer `nc' from data source `/home/fernando/R/x86_64-pc-linux-gnu-library/3.6/sf/shape/nc.shp' using driver `ESRI Shapefile'
    ## Simple feature collection with 100 features and 14 fields
    ## geometry type:  MULTIPOLYGON
    ## dimension:      XY
    ## bbox:           xmin: -84.32385 ymin: 33.88199 xmax: -75.45698 ymax: 36.58965
    ## geographic CRS: NAD27

### Search into the Earth Engine’s public data archive

``` r
ndvi_mak <- ee$ImageCollection("NOAA/CDR/AVHRR/NDVI/V5")
```

### Define type of quality filter

You can see more details about quality in [AVHRR
dataset](https://developers.google.com/earth-engine/datasets/catalog/NOAA_CDR_AVHRR_NDVI_V5)

``` r
bit1 <- ee$Number(2)$pow(1)$int()
```

Before calculating the **climatology** of any variable, for a given
period (eg: **1981-2016**), first a time series field is created within
a dataframe, in addition to an identifier field **\[id\]**.

Build a data frame with a date field and an identity field for the
period from 1981 to 2016 (by month) \`
