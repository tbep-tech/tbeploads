# Calculate groundwater loads to Tampa Bay segments

Calculate groundwater loads to Tampa Bay segments

## Usage

``` r
anlz_gw(yrrng = c(2022, 2024), wqdat = NULL, summtime = c("month", "year"))
```

## Arguments

- yrrng:

  integer vector of length 2, start and end year, e.g. `c(2022, 2024)`.

- wqdat:

  data frame of Floridan aquifer TN and TP concentrations (mg/L) as
  returned by
  [`util_gw_getwq`](https://tbep-tech.github.io/tbeploads/reference/util_gw_getwq.md),
  with columns `bay_seg`, `tn_mgl`, and `tp_mgl`. When `NULL` (default),
  hardcoded concentrations from the 2022-2024 loading analysis are used.

- summtime:

  character, temporal summarization: `'month'` (default) returns one row
  per segment per month, `'year'` sums to annual totals.

## Value

A data frame with columns:

- `Year`: integer

- `Month`: integer (omitted when `summtime = 'year'`)

- `source`: character, `"GW"`

- `bay_seg`: integer, bay segment number (1-7)

- `segment`: character, bay segment name

- `tn_load`: numeric, total nitrogen load (tons/month or tons/year)

- `tp_load`: numeric, total phosphorus load (tons/month or tons/year)

- `hy_load`: numeric, hydrologic load (million m\\^3\\/month or million
  m\\^3\\/year)

## Details

Estimates groundwater loads to each Tampa Bay segment for three aquifer
layers following the methodology in Zarbock et al. (1994).

**Floridan aquifer:** Flow is computed with Darcy's Law: \$\$Q = 7.4805
\times 10^{-6} \cdot T \cdot I \cdot L\$\$ where \\T\\ is transmissivity
(ft\\^2\\/day), \\I\\ is the hydraulic gradient (ft/mile), and \\L\\ is
the flow zone length (miles). \\Q\\ is in MGD. Nutrient loads (kg/month)
are: \$\$\text{load} = Q \cdot C \cdot 8.342 \cdot 30.5 / 2.2\$\$ where
\\C\\ is the TN or TP concentration (mg/L). Hydrologic load
(m\\^3\\/month) is \\Q \cdot 3785 \cdot 30.5\\.

**Hydraulic gradients:** The gradient section below contains a
commented-out framework that calls
[`util_gw_getcontour`](https://tbep-tech.github.io/tbeploads/reference/util_gw_getcontour.md)
and
[`util_gw_grad`](https://tbep-tech.github.io/tbeploads/reference/util_gw_grad.md)
to compute gradients dynamically from FDEP potentiometric surface
contours. This approach requires Floridan aquifer flow-zone polygons
(not yet available) to replace
[`tbsubshed`](https://tbep-tech.github.io/tbeploads/reference/tbsubshed.md),
which gives incorrect gradients for segments 4, 6, and 7 in the wet
season. Until those polygons are obtained, hardcoded gradient values
from the 2021 FDEP potentiometric surface map are used (the same values
applied for 2022-2024 in the original SAS analysis, as no updated
contours were available at that time).

**Surficial and intermediate aquifers:** Loads are fixed constants per
segment. Surficial values are from `gwupdate95-98_final.xls` (1995-1998
SWFWMD monitoring data). Intermediate values are means from SWFWMD
monitoring over 1999-2003. These have not changed since the original
analysis.

**Season assignment:** Months 1-6 and 11-12 are dry season; months 7-10
are wet season.

## Examples

``` r
# monthly segment loads using hardcoded 2022-2024 gradients and concentrations
anlz_gw(yrrng = c(2022, 2024))
#>     Year Month source bay_seg          segment      tn_load     tp_load
#> 1   2022     1     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 2   2022     1     GW       2 Hillsborough Bay 1.7256820120 0.205373694
#> 3   2022     1     GW       3 Middle Tampa Bay 0.0227613545 0.129185120
#> 4   2022     1     GW       4  Lower Tampa Bay 0.0012566349 0.008785422
#> 5   2022     1     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 6   2022     1     GW       6   Terra Ceia Bay 0.0001763698 0.001344820
#> 7   2022     1     GW       7    Manatee River 0.0013889123 0.009821594
#> 8   2022     2     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 9   2022     2     GW       2 Hillsborough Bay 1.7256820120 0.205373694
#> 10  2022     2     GW       3 Middle Tampa Bay 0.0227613545 0.129185120
#> 11  2022     2     GW       4  Lower Tampa Bay 0.0012566349 0.008785422
#> 12  2022     2     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 13  2022     2     GW       6   Terra Ceia Bay 0.0001763698 0.001344820
#> 14  2022     2     GW       7    Manatee River 0.0013889123 0.009821594
#> 15  2022     3     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 16  2022     3     GW       2 Hillsborough Bay 1.7256820120 0.205373694
#> 17  2022     3     GW       3 Middle Tampa Bay 0.0227613545 0.129185120
#> 18  2022     3     GW       4  Lower Tampa Bay 0.0012566349 0.008785422
#> 19  2022     3     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 20  2022     3     GW       6   Terra Ceia Bay 0.0001763698 0.001344820
#> 21  2022     3     GW       7    Manatee River 0.0013889123 0.009821594
#> 22  2022     4     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 23  2022     4     GW       2 Hillsborough Bay 1.7256820120 0.205373694
#> 24  2022     4     GW       3 Middle Tampa Bay 0.0227613545 0.129185120
#> 25  2022     4     GW       4  Lower Tampa Bay 0.0012566349 0.008785422
#> 26  2022     4     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 27  2022     4     GW       6   Terra Ceia Bay 0.0001763698 0.001344820
#> 28  2022     4     GW       7    Manatee River 0.0013889123 0.009821594
#> 29  2022     5     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 30  2022     5     GW       2 Hillsborough Bay 1.7256820120 0.205373694
#> 31  2022     5     GW       3 Middle Tampa Bay 0.0227613545 0.129185120
#> 32  2022     5     GW       4  Lower Tampa Bay 0.0012566349 0.008785422
#> 33  2022     5     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 34  2022     5     GW       6   Terra Ceia Bay 0.0001763698 0.001344820
#> 35  2022     5     GW       7    Manatee River 0.0013889123 0.009821594
#> 36  2022     6     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 37  2022     6     GW       2 Hillsborough Bay 1.7256820120 0.205373694
#> 38  2022     6     GW       3 Middle Tampa Bay 0.0227613545 0.129185120
#> 39  2022     6     GW       4  Lower Tampa Bay 0.0012566349 0.008785422
#> 40  2022     6     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 41  2022     6     GW       6   Terra Ceia Bay 0.0001763698 0.001344820
#> 42  2022     6     GW       7    Manatee River 0.0013889123 0.009821594
#> 43  2022     7     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 44  2022     7     GW       2 Hillsborough Bay 1.7302181240 0.205882714
#> 45  2022     7     GW       3 Middle Tampa Bay 0.0260606245 0.147265119
#> 46  2022     7     GW       4  Lower Tampa Bay 0.0248591051 0.138126958
#> 47  2022     7     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 48  2022     7     GW       6   Terra Ceia Bay 0.0043835838 0.022380890
#> 49  2022     7     GW       7    Manatee River 0.0228457034 0.107664561
#> 50  2022     8     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 51  2022     8     GW       2 Hillsborough Bay 1.7302181240 0.205882714
#> 52  2022     8     GW       3 Middle Tampa Bay 0.0260606245 0.147265119
#> 53  2022     8     GW       4  Lower Tampa Bay 0.0248591051 0.138126958
#> 54  2022     8     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 55  2022     8     GW       6   Terra Ceia Bay 0.0043835838 0.022380890
#> 56  2022     8     GW       7    Manatee River 0.0228457034 0.107664561
#> 57  2022     9     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 58  2022     9     GW       2 Hillsborough Bay 1.7302181240 0.205882714
#> 59  2022     9     GW       3 Middle Tampa Bay 0.0260606245 0.147265119
#> 60  2022     9     GW       4  Lower Tampa Bay 0.0248591051 0.138126958
#> 61  2022     9     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 62  2022     9     GW       6   Terra Ceia Bay 0.0043835838 0.022380890
#> 63  2022     9     GW       7    Manatee River 0.0228457034 0.107664561
#> 64  2022    10     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 65  2022    10     GW       2 Hillsborough Bay 1.7302181240 0.205882714
#> 66  2022    10     GW       3 Middle Tampa Bay 0.0260606245 0.147265119
#> 67  2022    10     GW       4  Lower Tampa Bay 0.0248591051 0.138126958
#> 68  2022    10     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 69  2022    10     GW       6   Terra Ceia Bay 0.0043835838 0.022380890
#> 70  2022    10     GW       7    Manatee River 0.0228457034 0.107664561
#> 71  2022    11     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 72  2022    11     GW       2 Hillsborough Bay 1.7256820120 0.205373694
#> 73  2022    11     GW       3 Middle Tampa Bay 0.0227613545 0.129185120
#> 74  2022    11     GW       4  Lower Tampa Bay 0.0012566349 0.008785422
#> 75  2022    11     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 76  2022    11     GW       6   Terra Ceia Bay 0.0001763698 0.001344820
#> 77  2022    11     GW       7    Manatee River 0.0013889123 0.009821594
#> 78  2022    12     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 79  2022    12     GW       2 Hillsborough Bay 1.7256820120 0.205373694
#> 80  2022    12     GW       3 Middle Tampa Bay 0.0227613545 0.129185120
#> 81  2022    12     GW       4  Lower Tampa Bay 0.0012566349 0.008785422
#> 82  2022    12     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 83  2022    12     GW       6   Terra Ceia Bay 0.0001763698 0.001344820
#> 84  2022    12     GW       7    Manatee River 0.0013889123 0.009821594
#> 85  2023     1     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 86  2023     1     GW       2 Hillsborough Bay 1.7256820120 0.205373694
#> 87  2023     1     GW       3 Middle Tampa Bay 0.0227613545 0.129185120
#> 88  2023     1     GW       4  Lower Tampa Bay 0.0012566349 0.008785422
#> 89  2023     1     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 90  2023     1     GW       6   Terra Ceia Bay 0.0001763698 0.001344820
#> 91  2023     1     GW       7    Manatee River 0.0013889123 0.009821594
#> 92  2023     2     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 93  2023     2     GW       2 Hillsborough Bay 1.7256820120 0.205373694
#> 94  2023     2     GW       3 Middle Tampa Bay 0.0227613545 0.129185120
#> 95  2023     2     GW       4  Lower Tampa Bay 0.0012566349 0.008785422
#> 96  2023     2     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 97  2023     2     GW       6   Terra Ceia Bay 0.0001763698 0.001344820
#> 98  2023     2     GW       7    Manatee River 0.0013889123 0.009821594
#> 99  2023     3     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 100 2023     3     GW       2 Hillsborough Bay 1.7256820120 0.205373694
#> 101 2023     3     GW       3 Middle Tampa Bay 0.0227613545 0.129185120
#> 102 2023     3     GW       4  Lower Tampa Bay 0.0012566349 0.008785422
#> 103 2023     3     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 104 2023     3     GW       6   Terra Ceia Bay 0.0001763698 0.001344820
#> 105 2023     3     GW       7    Manatee River 0.0013889123 0.009821594
#> 106 2023     4     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 107 2023     4     GW       2 Hillsborough Bay 1.7256820120 0.205373694
#> 108 2023     4     GW       3 Middle Tampa Bay 0.0227613545 0.129185120
#> 109 2023     4     GW       4  Lower Tampa Bay 0.0012566349 0.008785422
#> 110 2023     4     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 111 2023     4     GW       6   Terra Ceia Bay 0.0001763698 0.001344820
#> 112 2023     4     GW       7    Manatee River 0.0013889123 0.009821594
#> 113 2023     5     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 114 2023     5     GW       2 Hillsborough Bay 1.7256820120 0.205373694
#> 115 2023     5     GW       3 Middle Tampa Bay 0.0227613545 0.129185120
#> 116 2023     5     GW       4  Lower Tampa Bay 0.0012566349 0.008785422
#> 117 2023     5     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 118 2023     5     GW       6   Terra Ceia Bay 0.0001763698 0.001344820
#> 119 2023     5     GW       7    Manatee River 0.0013889123 0.009821594
#> 120 2023     6     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 121 2023     6     GW       2 Hillsborough Bay 1.7256820120 0.205373694
#> 122 2023     6     GW       3 Middle Tampa Bay 0.0227613545 0.129185120
#> 123 2023     6     GW       4  Lower Tampa Bay 0.0012566349 0.008785422
#> 124 2023     6     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 125 2023     6     GW       6   Terra Ceia Bay 0.0001763698 0.001344820
#> 126 2023     6     GW       7    Manatee River 0.0013889123 0.009821594
#> 127 2023     7     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 128 2023     7     GW       2 Hillsborough Bay 1.7302181240 0.205882714
#> 129 2023     7     GW       3 Middle Tampa Bay 0.0260606245 0.147265119
#> 130 2023     7     GW       4  Lower Tampa Bay 0.0248591051 0.138126958
#> 131 2023     7     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 132 2023     7     GW       6   Terra Ceia Bay 0.0043835838 0.022380890
#> 133 2023     7     GW       7    Manatee River 0.0228457034 0.107664561
#> 134 2023     8     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 135 2023     8     GW       2 Hillsborough Bay 1.7302181240 0.205882714
#> 136 2023     8     GW       3 Middle Tampa Bay 0.0260606245 0.147265119
#> 137 2023     8     GW       4  Lower Tampa Bay 0.0248591051 0.138126958
#> 138 2023     8     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 139 2023     8     GW       6   Terra Ceia Bay 0.0043835838 0.022380890
#> 140 2023     8     GW       7    Manatee River 0.0228457034 0.107664561
#> 141 2023     9     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 142 2023     9     GW       2 Hillsborough Bay 1.7302181240 0.205882714
#> 143 2023     9     GW       3 Middle Tampa Bay 0.0260606245 0.147265119
#> 144 2023     9     GW       4  Lower Tampa Bay 0.0248591051 0.138126958
#> 145 2023     9     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 146 2023     9     GW       6   Terra Ceia Bay 0.0043835838 0.022380890
#> 147 2023     9     GW       7    Manatee River 0.0228457034 0.107664561
#> 148 2023    10     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 149 2023    10     GW       2 Hillsborough Bay 1.7302181240 0.205882714
#> 150 2023    10     GW       3 Middle Tampa Bay 0.0260606245 0.147265119
#> 151 2023    10     GW       4  Lower Tampa Bay 0.0248591051 0.138126958
#> 152 2023    10     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 153 2023    10     GW       6   Terra Ceia Bay 0.0043835838 0.022380890
#> 154 2023    10     GW       7    Manatee River 0.0228457034 0.107664561
#> 155 2023    11     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 156 2023    11     GW       2 Hillsborough Bay 1.7256820120 0.205373694
#> 157 2023    11     GW       3 Middle Tampa Bay 0.0227613545 0.129185120
#> 158 2023    11     GW       4  Lower Tampa Bay 0.0012566349 0.008785422
#> 159 2023    11     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 160 2023    11     GW       6   Terra Ceia Bay 0.0001763698 0.001344820
#> 161 2023    11     GW       7    Manatee River 0.0013889123 0.009821594
#> 162 2023    12     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 163 2023    12     GW       2 Hillsborough Bay 1.7256820120 0.205373694
#> 164 2023    12     GW       3 Middle Tampa Bay 0.0227613545 0.129185120
#> 165 2023    12     GW       4  Lower Tampa Bay 0.0012566349 0.008785422
#> 166 2023    12     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 167 2023    12     GW       6   Terra Ceia Bay 0.0001763698 0.001344820
#> 168 2023    12     GW       7    Manatee River 0.0013889123 0.009821594
#> 169 2024     1     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 170 2024     1     GW       2 Hillsborough Bay 1.7256820120 0.205373694
#> 171 2024     1     GW       3 Middle Tampa Bay 0.0227613545 0.129185120
#> 172 2024     1     GW       4  Lower Tampa Bay 0.0012566349 0.008785422
#> 173 2024     1     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 174 2024     1     GW       6   Terra Ceia Bay 0.0001763698 0.001344820
#> 175 2024     1     GW       7    Manatee River 0.0013889123 0.009821594
#> 176 2024     2     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 177 2024     2     GW       2 Hillsborough Bay 1.7256820120 0.205373694
#> 178 2024     2     GW       3 Middle Tampa Bay 0.0227613545 0.129185120
#> 179 2024     2     GW       4  Lower Tampa Bay 0.0012566349 0.008785422
#> 180 2024     2     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 181 2024     2     GW       6   Terra Ceia Bay 0.0001763698 0.001344820
#> 182 2024     2     GW       7    Manatee River 0.0013889123 0.009821594
#> 183 2024     3     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 184 2024     3     GW       2 Hillsborough Bay 1.7256820120 0.205373694
#> 185 2024     3     GW       3 Middle Tampa Bay 0.0227613545 0.129185120
#> 186 2024     3     GW       4  Lower Tampa Bay 0.0012566349 0.008785422
#> 187 2024     3     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 188 2024     3     GW       6   Terra Ceia Bay 0.0001763698 0.001344820
#> 189 2024     3     GW       7    Manatee River 0.0013889123 0.009821594
#> 190 2024     4     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 191 2024     4     GW       2 Hillsborough Bay 1.7256820120 0.205373694
#> 192 2024     4     GW       3 Middle Tampa Bay 0.0227613545 0.129185120
#> 193 2024     4     GW       4  Lower Tampa Bay 0.0012566349 0.008785422
#> 194 2024     4     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 195 2024     4     GW       6   Terra Ceia Bay 0.0001763698 0.001344820
#> 196 2024     4     GW       7    Manatee River 0.0013889123 0.009821594
#> 197 2024     5     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 198 2024     5     GW       2 Hillsborough Bay 1.7256820120 0.205373694
#> 199 2024     5     GW       3 Middle Tampa Bay 0.0227613545 0.129185120
#> 200 2024     5     GW       4  Lower Tampa Bay 0.0012566349 0.008785422
#> 201 2024     5     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 202 2024     5     GW       6   Terra Ceia Bay 0.0001763698 0.001344820
#> 203 2024     5     GW       7    Manatee River 0.0013889123 0.009821594
#> 204 2024     6     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 205 2024     6     GW       2 Hillsborough Bay 1.7256820120 0.205373694
#> 206 2024     6     GW       3 Middle Tampa Bay 0.0227613545 0.129185120
#> 207 2024     6     GW       4  Lower Tampa Bay 0.0012566349 0.008785422
#> 208 2024     6     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 209 2024     6     GW       6   Terra Ceia Bay 0.0001763698 0.001344820
#> 210 2024     6     GW       7    Manatee River 0.0013889123 0.009821594
#> 211 2024     7     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 212 2024     7     GW       2 Hillsborough Bay 1.7302181240 0.205882714
#> 213 2024     7     GW       3 Middle Tampa Bay 0.0260606245 0.147265119
#> 214 2024     7     GW       4  Lower Tampa Bay 0.0248591051 0.138126958
#> 215 2024     7     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 216 2024     7     GW       6   Terra Ceia Bay 0.0043835838 0.022380890
#> 217 2024     7     GW       7    Manatee River 0.0228457034 0.107664561
#> 218 2024     8     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 219 2024     8     GW       2 Hillsborough Bay 1.7302181240 0.205882714
#> 220 2024     8     GW       3 Middle Tampa Bay 0.0260606245 0.147265119
#> 221 2024     8     GW       4  Lower Tampa Bay 0.0248591051 0.138126958
#> 222 2024     8     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 223 2024     8     GW       6   Terra Ceia Bay 0.0043835838 0.022380890
#> 224 2024     8     GW       7    Manatee River 0.0228457034 0.107664561
#> 225 2024     9     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 226 2024     9     GW       2 Hillsborough Bay 1.7302181240 0.205882714
#> 227 2024     9     GW       3 Middle Tampa Bay 0.0260606245 0.147265119
#> 228 2024     9     GW       4  Lower Tampa Bay 0.0248591051 0.138126958
#> 229 2024     9     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 230 2024     9     GW       6   Terra Ceia Bay 0.0043835838 0.022380890
#> 231 2024     9     GW       7    Manatee River 0.0228457034 0.107664561
#> 232 2024    10     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 233 2024    10     GW       2 Hillsborough Bay 1.7302181240 0.205882714
#> 234 2024    10     GW       3 Middle Tampa Bay 0.0260606245 0.147265119
#> 235 2024    10     GW       4  Lower Tampa Bay 0.0248591051 0.138126958
#> 236 2024    10     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 237 2024    10     GW       6   Terra Ceia Bay 0.0043835838 0.022380890
#> 238 2024    10     GW       7    Manatee River 0.0228457034 0.107664561
#> 239 2024    11     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 240 2024    11     GW       2 Hillsborough Bay 1.7256820120 0.205373694
#> 241 2024    11     GW       3 Middle Tampa Bay 0.0227613545 0.129185120
#> 242 2024    11     GW       4  Lower Tampa Bay 0.0012566349 0.008785422
#> 243 2024    11     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 244 2024    11     GW       6   Terra Ceia Bay 0.0001763698 0.001344820
#> 245 2024    11     GW       7    Manatee River 0.0013889123 0.009821594
#> 246 2024    12     GW       1    Old Tampa Bay 0.5487809114 0.163081117
#> 247 2024    12     GW       2 Hillsborough Bay 1.7256820120 0.205373694
#> 248 2024    12     GW       3 Middle Tampa Bay 0.0227613545 0.129185120
#> 249 2024    12     GW       4  Lower Tampa Bay 0.0012566349 0.008785422
#> 250 2024    12     GW       5   Boca Ciega Bay 0.0004188783 0.003957298
#> 251 2024    12     GW       6   Terra Ceia Bay 0.0001763698 0.001344820
#> 252 2024    12     GW       7    Manatee River 0.0013889123 0.009821594
#>       hy_load
#> 1   5.0150378
#> 2   6.1532324
#> 3   0.7931208
#> 4   0.0333856
#> 5   0.0132126
#> 6   0.0038045
#> 7   0.0328558
#> 8   5.0150378
#> 9   6.1532324
#> 10  0.7931208
#> 11  0.0333856
#> 12  0.0132126
#> 13  0.0038045
#> 14  0.0328558
#> 15  5.0150378
#> 16  6.1532324
#> 17  0.7931208
#> 18  0.0333856
#> 19  0.0132126
#> 20  0.0038045
#> 21  0.0328558
#> 22  5.0150378
#> 23  6.1532324
#> 24  0.7931208
#> 25  0.0333856
#> 26  0.0132126
#> 27  0.0038045
#> 28  0.0328558
#> 29  5.0150378
#> 30  6.1532324
#> 31  0.7931208
#> 32  0.0333856
#> 33  0.0132126
#> 34  0.0038045
#> 35  0.0328558
#> 36  5.0150378
#> 37  6.1532324
#> 38  0.7931208
#> 39  0.0333856
#> 40  0.0132126
#> 41  0.0038045
#> 42  0.0328558
#> 43  5.0150378
#> 44  6.1692374
#> 45  0.9126274
#> 46  0.8883175
#> 47  0.0132126
#> 48  0.1561988
#> 49  0.8100667
#> 50  5.0150378
#> 51  6.1692374
#> 52  0.9126274
#> 53  0.8883175
#> 54  0.0132126
#> 55  0.1561988
#> 56  0.8100667
#> 57  5.0150378
#> 58  6.1692374
#> 59  0.9126274
#> 60  0.8883175
#> 61  0.0132126
#> 62  0.1561988
#> 63  0.8100667
#> 64  5.0150378
#> 65  6.1692374
#> 66  0.9126274
#> 67  0.8883175
#> 68  0.0132126
#> 69  0.1561988
#> 70  0.8100667
#> 71  5.0150378
#> 72  6.1532324
#> 73  0.7931208
#> 74  0.0333856
#> 75  0.0132126
#> 76  0.0038045
#> 77  0.0328558
#> 78  5.0150378
#> 79  6.1532324
#> 80  0.7931208
#> 81  0.0333856
#> 82  0.0132126
#> 83  0.0038045
#> 84  0.0328558
#> 85  5.0150378
#> 86  6.1532324
#> 87  0.7931208
#> 88  0.0333856
#> 89  0.0132126
#> 90  0.0038045
#> 91  0.0328558
#> 92  5.0150378
#> 93  6.1532324
#> 94  0.7931208
#> 95  0.0333856
#> 96  0.0132126
#> 97  0.0038045
#> 98  0.0328558
#> 99  5.0150378
#> 100 6.1532324
#> 101 0.7931208
#> 102 0.0333856
#> 103 0.0132126
#> 104 0.0038045
#> 105 0.0328558
#> 106 5.0150378
#> 107 6.1532324
#> 108 0.7931208
#> 109 0.0333856
#> 110 0.0132126
#> 111 0.0038045
#> 112 0.0328558
#> 113 5.0150378
#> 114 6.1532324
#> 115 0.7931208
#> 116 0.0333856
#> 117 0.0132126
#> 118 0.0038045
#> 119 0.0328558
#> 120 5.0150378
#> 121 6.1532324
#> 122 0.7931208
#> 123 0.0333856
#> 124 0.0132126
#> 125 0.0038045
#> 126 0.0328558
#> 127 5.0150378
#> 128 6.1692374
#> 129 0.9126274
#> 130 0.8883175
#> 131 0.0132126
#> 132 0.1561988
#> 133 0.8100667
#> 134 5.0150378
#> 135 6.1692374
#> 136 0.9126274
#> 137 0.8883175
#> 138 0.0132126
#> 139 0.1561988
#> 140 0.8100667
#> 141 5.0150378
#> 142 6.1692374
#> 143 0.9126274
#> 144 0.8883175
#> 145 0.0132126
#> 146 0.1561988
#> 147 0.8100667
#> 148 5.0150378
#> 149 6.1692374
#> 150 0.9126274
#> 151 0.8883175
#> 152 0.0132126
#> 153 0.1561988
#> 154 0.8100667
#> 155 5.0150378
#> 156 6.1532324
#> 157 0.7931208
#> 158 0.0333856
#> 159 0.0132126
#> 160 0.0038045
#> 161 0.0328558
#> 162 5.0150378
#> 163 6.1532324
#> 164 0.7931208
#> 165 0.0333856
#> 166 0.0132126
#> 167 0.0038045
#> 168 0.0328558
#> 169 5.0150378
#> 170 6.1532324
#> 171 0.7931208
#> 172 0.0333856
#> 173 0.0132126
#> 174 0.0038045
#> 175 0.0328558
#> 176 5.0150378
#> 177 6.1532324
#> 178 0.7931208
#> 179 0.0333856
#> 180 0.0132126
#> 181 0.0038045
#> 182 0.0328558
#> 183 5.0150378
#> 184 6.1532324
#> 185 0.7931208
#> 186 0.0333856
#> 187 0.0132126
#> 188 0.0038045
#> 189 0.0328558
#> 190 5.0150378
#> 191 6.1532324
#> 192 0.7931208
#> 193 0.0333856
#> 194 0.0132126
#> 195 0.0038045
#> 196 0.0328558
#> 197 5.0150378
#> 198 6.1532324
#> 199 0.7931208
#> 200 0.0333856
#> 201 0.0132126
#> 202 0.0038045
#> 203 0.0328558
#> 204 5.0150378
#> 205 6.1532324
#> 206 0.7931208
#> 207 0.0333856
#> 208 0.0132126
#> 209 0.0038045
#> 210 0.0328558
#> 211 5.0150378
#> 212 6.1692374
#> 213 0.9126274
#> 214 0.8883175
#> 215 0.0132126
#> 216 0.1561988
#> 217 0.8100667
#> 218 5.0150378
#> 219 6.1692374
#> 220 0.9126274
#> 221 0.8883175
#> 222 0.0132126
#> 223 0.1561988
#> 224 0.8100667
#> 225 5.0150378
#> 226 6.1692374
#> 227 0.9126274
#> 228 0.8883175
#> 229 0.0132126
#> 230 0.1561988
#> 231 0.8100667
#> 232 5.0150378
#> 233 6.1692374
#> 234 0.9126274
#> 235 0.8883175
#> 236 0.0132126
#> 237 0.1561988
#> 238 0.8100667
#> 239 5.0150378
#> 240 6.1532324
#> 241 0.7931208
#> 242 0.0333856
#> 243 0.0132126
#> 244 0.0038045
#> 245 0.0328558
#> 246 5.0150378
#> 247 6.1532324
#> 248 0.7931208
#> 249 0.0333856
#> 250 0.0132126
#> 251 0.0038045
#> 252 0.0328558

# annual totals
anlz_gw(yrrng = c(2022, 2024), summtime = 'year')
#>    Year source bay_seg          segment     tn_load    tp_load    hy_load
#> 1  2022     GW       1    Old Tampa Bay  6.58537094 1.95697341 60.1804539
#> 2  2022     GW       2 Hillsborough Bay 20.72632859 2.46652041 73.9028084
#> 3  2022     GW       3 Middle Tampa Bay  0.28633333 1.62254143  9.9954764
#> 4  2022     GW       4  Lower Tampa Bay  0.10948950 0.62279120  3.8203550
#> 5  2022     GW       5   Boca Ciega Bay  0.00502654 0.04748757  0.1585512
#> 6  2022     GW       6   Terra Ceia Bay  0.01894529 0.10028212  0.6552311
#> 7  2022     GW       7    Manatee River  0.10249411 0.50923100  3.5031130
#> 8  2023     GW       1    Old Tampa Bay  6.58537094 1.95697341 60.1804539
#> 9  2023     GW       2 Hillsborough Bay 20.72632859 2.46652041 73.9028084
#> 10 2023     GW       3 Middle Tampa Bay  0.28633333 1.62254143  9.9954764
#> 11 2023     GW       4  Lower Tampa Bay  0.10948950 0.62279120  3.8203550
#> 12 2023     GW       5   Boca Ciega Bay  0.00502654 0.04748757  0.1585512
#> 13 2023     GW       6   Terra Ceia Bay  0.01894529 0.10028212  0.6552311
#> 14 2023     GW       7    Manatee River  0.10249411 0.50923100  3.5031130
#> 15 2024     GW       1    Old Tampa Bay  6.58537094 1.95697341 60.1804539
#> 16 2024     GW       2 Hillsborough Bay 20.72632859 2.46652041 73.9028084
#> 17 2024     GW       3 Middle Tampa Bay  0.28633333 1.62254143  9.9954764
#> 18 2024     GW       4  Lower Tampa Bay  0.10948950 0.62279120  3.8203550
#> 19 2024     GW       5   Boca Ciega Bay  0.00502654 0.04748757  0.1585512
#> 20 2024     GW       6   Terra Ceia Bay  0.01894529 0.10028212  0.6552311
#> 21 2024     GW       7    Manatee River  0.10249411 0.50923100  3.5031130

if (FALSE) { # \dontrun{
# pass concentrations from the Water Atlas API
anlz_gw(yrrng = c(2022, 2024), wqdat = util_gw_getwq())
} # }
```
