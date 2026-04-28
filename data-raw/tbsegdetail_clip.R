library(sf)
library(leaflet)
library(mapedit)
library(devtools)

devtools::load_all()

# Display tbsegdetail in WGS84 for leaflet
tbseg_wgs <- sf::st_transform(tbsegdetail, 4326)

# Base map showing the current detailed shoreline as a reference.
# Red outlines show the existing polygon boundaries including creek geometry.
map <- leaflet() |>
  addProviderTiles("CartoDB.Positron") |>
  addPolygons(
    data        = tbseg_wgs,
    color       = "red",
    weight      = 1.5,
    fillOpacity = 0.08,
    label       = ~as.character(bay_seg)
  )

# Draw polygon(s) over the main open-water areas to KEEP.
# Use the polygon tool to outline the bay interior, excluding tidal rivers
# and creek arms.  Draw as many polygons as needed — they are unioned before
# clipping.  Click 'Done' when finished.
message(
  "Draw polygon(s) around the open-water bay areas to retain.\n",
  "Exclude creek/river arms that extend into the watershed.\n",
  "Click 'Done' when finished."
)
keep_poly <- mapedit::drawFeatures(map = map)

# Union all drawn polygons into one mask and reproject to match tbsegdetail
clip_mask <- keep_poly |>
  sf::st_geometry() |>
  sf::st_union() |>
  sf::st_transform(sf::st_crs(tbsegdetail))

# Clip tbsegdetail to the retained open-water areas
tbsegdetail_clip <- sf::st_intersection(tbsegdetail, clip_mask)

# Preview: original red outline, clipped blue fill
op <- par(mar = c(0, 0, 2, 0))
plot(sf::st_geometry(tbseg_wgs), border = "red", lwd = 0.8,
     main = "Original (red outline) vs. clipped (blue fill)")
plot(sf::st_transform(tbsegdetail_clip, 4326) |> sf::st_geometry(),
     col = adjustcolor("steelblue", 0.4), border = "steelblue", add = TRUE)
par(op)

# Save the clipping mask so this session can be reproduced without redrawing.
save(clip_mask,        file = "data-raw/tbsegdetail_clip_mask.RData")

# Save the clipped layer.  To use it as the default shoreline reference in
# util_gw_grad() and util_gw_showgrad(), overwrite the package dataset:
#
#   tbsegdetail <- tbsegdetail_clip
#   save(tbsegdetail, file = "data/tbsegdetail.RData", compress = "xz")
#
# Or pass it explicitly: util_gw_grad(contdry, shoreline = tbsegdetail_clip)
save(tbsegdetail_clip, file = "data-raw/tbsegdetail_clip.RData")

message("Saved:\n  data-raw/tbsegdetail_clip_mask.RData\n  data-raw/tbsegdetail_clip.RData")
