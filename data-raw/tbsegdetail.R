library(sf)
library(mapedit)
library(leaflet)
library(dplyr)
library(devtools)

devtools::load_all()

load(file = 'data-raw/tbsegdetail.RData')

# Step 1: Draw a line across Boca Ciega Bay to split it into North (5) / South (55).
# The line must fully cross the polygon from one shore to the other.
bcb <- tbsegdetail |>
  filter(bay_segment == "BCB")

map <- leaflet(bcb) |>
  addTiles() |>
  addPolygons(color = "blue", weight = 2, fillOpacity = 0.1)

message("Draw a line across Boca Ciega Bay separating North (segment 5) from South (segment 55).")
split_line <- drawFeatures(map = map)

# Step 2: Split a bounding box with the drawn line to get two half-plane clip
# polygons, then intersect BCB with each half and dissolve.  Splitting BCB
# directly fractures every island sub-polygon and returns dozens of pieces.
line_geom <- st_union(st_geometry(split_line))

clip_box <- bcb |>
  st_bbox() |>
  st_as_sfc() |>
  st_buffer(0.5)  # expand well past all BCB islands so the line fully divides it

halves <- lwgeom::st_split(clip_box, line_geom) |>
  st_collection_extract("POLYGON") |>
  st_as_sf()

stopifnot("Split line must fully cross the BCB bounding area" = nrow(halves) == 2)

bcb_parts <- lapply(seq_len(nrow(halves)), function(i) {
  st_sf(geometry = st_union(st_intersection(st_geometry(bcb), st_geometry(halves[i, ]))))
}) |>
  bind_rows()

stopifnot("Expected exactly 2 parts after splitting BCB" = nrow(bcb_parts) == 2)

# Step 3: Label North (higher centroid latitude = bay_seg 5) and South (bay_seg 55).
cents <- st_coordinates(st_centroid(bcb_parts))
bcb_parts <- bcb_parts[order(cents[, "Y"], decreasing = TRUE), ]
bcb_parts$bay_seg   <- c(5L, 55L)
bcb_parts$long_name <- c("Boca Ciega Bay", "Boca Ciega Bay South")

# Step 4: Rebuild tbsegdetail with numeric bay_seg and BCB replaced by the two parts.
tbsegdetail <- tbsegdetail |>
  filter(long_name != "Boca Ciega Bay") |>
  mutate(
    bay_seg = case_match(
      bay_segment,
      "OTB" ~ 1L,
      "HB"  ~ 2L,
      "MTB" ~ 3L,
      "LTB" ~ 4L,
      "TCB" ~ 6L,
      "MR"  ~ 7L
    )
  ) |>
  select(bay_seg) |>
  bind_rows(select(bcb_parts, bay_seg, geometry)) |>
  arrange(bay_seg) |>
  st_transform(6443)

save(tbsegdetail, file = "data/tbsegdetail.RData", compress = "xz")
