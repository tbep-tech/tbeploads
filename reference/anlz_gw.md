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
which gives incorrect gradients for Lower Tampa Bay, Terra Ceia Bay, and
Manatee River in the wet season. Until those polygons are obtained,
hardcoded gradient values from the 2021 FDEP potentiometric surface map
are used (the same values applied for 2022-2024 in the original SAS
analysis, as no updated contours were available at that time).

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
#>     Year Month source          segment      tn_load     tp_load   hy_load
#> 1   2022     1     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 2   2022     2     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 3   2022     3     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 4   2022     4     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 5   2022     5     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 6   2022     6     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 7   2022     7     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 8   2022     8     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 9   2022     9     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 10  2022    10     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 11  2022    11     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 12  2022    12     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 13  2023     1     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 14  2023     2     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 15  2023     3     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 16  2023     4     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 17  2023     5     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 18  2023     6     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 19  2023     7     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 20  2023     8     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 21  2023     9     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 22  2023    10     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 23  2023    11     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 24  2023    12     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 25  2024     1     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 26  2024     2     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 27  2024     3     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 28  2024     4     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 29  2024     5     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 30  2024     6     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 31  2024     7     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 32  2024     8     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 33  2024     9     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 34  2024    10     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 35  2024    11     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 36  2024    12     GW   Boca Ciega Bay 0.0004188783 0.003957298 0.0132126
#> 37  2022     1     GW Hillsborough Bay 1.7256820120 0.205373694 6.1532324
#> 38  2022     2     GW Hillsborough Bay 1.7256820120 0.205373694 6.1532324
#> 39  2022     3     GW Hillsborough Bay 1.7256820120 0.205373694 6.1532324
#> 40  2022     4     GW Hillsborough Bay 1.7256820120 0.205373694 6.1532324
#> 41  2022     5     GW Hillsborough Bay 1.7256820120 0.205373694 6.1532324
#> 42  2022     6     GW Hillsborough Bay 1.7256820120 0.205373694 6.1532324
#> 43  2022     7     GW Hillsborough Bay 1.7302181240 0.205882714 6.1692374
#> 44  2022     8     GW Hillsborough Bay 1.7302181240 0.205882714 6.1692374
#> 45  2022     9     GW Hillsborough Bay 1.7302181240 0.205882714 6.1692374
#> 46  2022    10     GW Hillsborough Bay 1.7302181240 0.205882714 6.1692374
#> 47  2022    11     GW Hillsborough Bay 1.7256820120 0.205373694 6.1532324
#> 48  2022    12     GW Hillsborough Bay 1.7256820120 0.205373694 6.1532324
#> 49  2023     1     GW Hillsborough Bay 1.7256820120 0.205373694 6.1532324
#> 50  2023     2     GW Hillsborough Bay 1.7256820120 0.205373694 6.1532324
#> 51  2023     3     GW Hillsborough Bay 1.7256820120 0.205373694 6.1532324
#> 52  2023     4     GW Hillsborough Bay 1.7256820120 0.205373694 6.1532324
#> 53  2023     5     GW Hillsborough Bay 1.7256820120 0.205373694 6.1532324
#> 54  2023     6     GW Hillsborough Bay 1.7256820120 0.205373694 6.1532324
#> 55  2023     7     GW Hillsborough Bay 1.7302181240 0.205882714 6.1692374
#> 56  2023     8     GW Hillsborough Bay 1.7302181240 0.205882714 6.1692374
#> 57  2023     9     GW Hillsborough Bay 1.7302181240 0.205882714 6.1692374
#> 58  2023    10     GW Hillsborough Bay 1.7302181240 0.205882714 6.1692374
#> 59  2023    11     GW Hillsborough Bay 1.7256820120 0.205373694 6.1532324
#> 60  2023    12     GW Hillsborough Bay 1.7256820120 0.205373694 6.1532324
#> 61  2024     1     GW Hillsborough Bay 1.7256820120 0.205373694 6.1532324
#> 62  2024     2     GW Hillsborough Bay 1.7256820120 0.205373694 6.1532324
#> 63  2024     3     GW Hillsborough Bay 1.7256820120 0.205373694 6.1532324
#> 64  2024     4     GW Hillsborough Bay 1.7256820120 0.205373694 6.1532324
#> 65  2024     5     GW Hillsborough Bay 1.7256820120 0.205373694 6.1532324
#> 66  2024     6     GW Hillsborough Bay 1.7256820120 0.205373694 6.1532324
#> 67  2024     7     GW Hillsborough Bay 1.7302181240 0.205882714 6.1692374
#> 68  2024     8     GW Hillsborough Bay 1.7302181240 0.205882714 6.1692374
#> 69  2024     9     GW Hillsborough Bay 1.7302181240 0.205882714 6.1692374
#> 70  2024    10     GW Hillsborough Bay 1.7302181240 0.205882714 6.1692374
#> 71  2024    11     GW Hillsborough Bay 1.7256820120 0.205373694 6.1532324
#> 72  2024    12     GW Hillsborough Bay 1.7256820120 0.205373694 6.1532324
#> 73  2022     1     GW  Lower Tampa Bay 0.0012566349 0.008785422 0.0333856
#> 74  2022     2     GW  Lower Tampa Bay 0.0012566349 0.008785422 0.0333856
#> 75  2022     3     GW  Lower Tampa Bay 0.0012566349 0.008785422 0.0333856
#> 76  2022     4     GW  Lower Tampa Bay 0.0012566349 0.008785422 0.0333856
#> 77  2022     5     GW  Lower Tampa Bay 0.0012566349 0.008785422 0.0333856
#> 78  2022     6     GW  Lower Tampa Bay 0.0012566349 0.008785422 0.0333856
#> 79  2022     7     GW  Lower Tampa Bay 0.0248591051 0.138126958 0.8883175
#> 80  2022     8     GW  Lower Tampa Bay 0.0248591051 0.138126958 0.8883175
#> 81  2022     9     GW  Lower Tampa Bay 0.0248591051 0.138126958 0.8883175
#> 82  2022    10     GW  Lower Tampa Bay 0.0248591051 0.138126958 0.8883175
#> 83  2022    11     GW  Lower Tampa Bay 0.0012566349 0.008785422 0.0333856
#> 84  2022    12     GW  Lower Tampa Bay 0.0012566349 0.008785422 0.0333856
#> 85  2023     1     GW  Lower Tampa Bay 0.0012566349 0.008785422 0.0333856
#> 86  2023     2     GW  Lower Tampa Bay 0.0012566349 0.008785422 0.0333856
#> 87  2023     3     GW  Lower Tampa Bay 0.0012566349 0.008785422 0.0333856
#> 88  2023     4     GW  Lower Tampa Bay 0.0012566349 0.008785422 0.0333856
#> 89  2023     5     GW  Lower Tampa Bay 0.0012566349 0.008785422 0.0333856
#> 90  2023     6     GW  Lower Tampa Bay 0.0012566349 0.008785422 0.0333856
#> 91  2023     7     GW  Lower Tampa Bay 0.0248591051 0.138126958 0.8883175
#> 92  2023     8     GW  Lower Tampa Bay 0.0248591051 0.138126958 0.8883175
#> 93  2023     9     GW  Lower Tampa Bay 0.0248591051 0.138126958 0.8883175
#> 94  2023    10     GW  Lower Tampa Bay 0.0248591051 0.138126958 0.8883175
#> 95  2023    11     GW  Lower Tampa Bay 0.0012566349 0.008785422 0.0333856
#> 96  2023    12     GW  Lower Tampa Bay 0.0012566349 0.008785422 0.0333856
#> 97  2024     1     GW  Lower Tampa Bay 0.0012566349 0.008785422 0.0333856
#> 98  2024     2     GW  Lower Tampa Bay 0.0012566349 0.008785422 0.0333856
#> 99  2024     3     GW  Lower Tampa Bay 0.0012566349 0.008785422 0.0333856
#> 100 2024     4     GW  Lower Tampa Bay 0.0012566349 0.008785422 0.0333856
#> 101 2024     5     GW  Lower Tampa Bay 0.0012566349 0.008785422 0.0333856
#> 102 2024     6     GW  Lower Tampa Bay 0.0012566349 0.008785422 0.0333856
#> 103 2024     7     GW  Lower Tampa Bay 0.0248591051 0.138126958 0.8883175
#> 104 2024     8     GW  Lower Tampa Bay 0.0248591051 0.138126958 0.8883175
#> 105 2024     9     GW  Lower Tampa Bay 0.0248591051 0.138126958 0.8883175
#> 106 2024    10     GW  Lower Tampa Bay 0.0248591051 0.138126958 0.8883175
#> 107 2024    11     GW  Lower Tampa Bay 0.0012566349 0.008785422 0.0333856
#> 108 2024    12     GW  Lower Tampa Bay 0.0012566349 0.008785422 0.0333856
#> 109 2022     1     GW    Manatee River 0.0013889123 0.009821594 0.0328558
#> 110 2022     2     GW    Manatee River 0.0013889123 0.009821594 0.0328558
#> 111 2022     3     GW    Manatee River 0.0013889123 0.009821594 0.0328558
#> 112 2022     4     GW    Manatee River 0.0013889123 0.009821594 0.0328558
#> 113 2022     5     GW    Manatee River 0.0013889123 0.009821594 0.0328558
#> 114 2022     6     GW    Manatee River 0.0013889123 0.009821594 0.0328558
#> 115 2022     7     GW    Manatee River 0.0228457034 0.107664561 0.8100667
#> 116 2022     8     GW    Manatee River 0.0228457034 0.107664561 0.8100667
#> 117 2022     9     GW    Manatee River 0.0228457034 0.107664561 0.8100667
#> 118 2022    10     GW    Manatee River 0.0228457034 0.107664561 0.8100667
#> 119 2022    11     GW    Manatee River 0.0013889123 0.009821594 0.0328558
#> 120 2022    12     GW    Manatee River 0.0013889123 0.009821594 0.0328558
#> 121 2023     1     GW    Manatee River 0.0013889123 0.009821594 0.0328558
#> 122 2023     2     GW    Manatee River 0.0013889123 0.009821594 0.0328558
#> 123 2023     3     GW    Manatee River 0.0013889123 0.009821594 0.0328558
#> 124 2023     4     GW    Manatee River 0.0013889123 0.009821594 0.0328558
#> 125 2023     5     GW    Manatee River 0.0013889123 0.009821594 0.0328558
#> 126 2023     6     GW    Manatee River 0.0013889123 0.009821594 0.0328558
#> 127 2023     7     GW    Manatee River 0.0228457034 0.107664561 0.8100667
#> 128 2023     8     GW    Manatee River 0.0228457034 0.107664561 0.8100667
#> 129 2023     9     GW    Manatee River 0.0228457034 0.107664561 0.8100667
#> 130 2023    10     GW    Manatee River 0.0228457034 0.107664561 0.8100667
#> 131 2023    11     GW    Manatee River 0.0013889123 0.009821594 0.0328558
#> 132 2023    12     GW    Manatee River 0.0013889123 0.009821594 0.0328558
#> 133 2024     1     GW    Manatee River 0.0013889123 0.009821594 0.0328558
#> 134 2024     2     GW    Manatee River 0.0013889123 0.009821594 0.0328558
#> 135 2024     3     GW    Manatee River 0.0013889123 0.009821594 0.0328558
#> 136 2024     4     GW    Manatee River 0.0013889123 0.009821594 0.0328558
#> 137 2024     5     GW    Manatee River 0.0013889123 0.009821594 0.0328558
#> 138 2024     6     GW    Manatee River 0.0013889123 0.009821594 0.0328558
#> 139 2024     7     GW    Manatee River 0.0228457034 0.107664561 0.8100667
#> 140 2024     8     GW    Manatee River 0.0228457034 0.107664561 0.8100667
#> 141 2024     9     GW    Manatee River 0.0228457034 0.107664561 0.8100667
#> 142 2024    10     GW    Manatee River 0.0228457034 0.107664561 0.8100667
#> 143 2024    11     GW    Manatee River 0.0013889123 0.009821594 0.0328558
#> 144 2024    12     GW    Manatee River 0.0013889123 0.009821594 0.0328558
#> 145 2022     1     GW Middle Tampa Bay 0.0227613545 0.129185120 0.7931208
#> 146 2022     2     GW Middle Tampa Bay 0.0227613545 0.129185120 0.7931208
#> 147 2022     3     GW Middle Tampa Bay 0.0227613545 0.129185120 0.7931208
#> 148 2022     4     GW Middle Tampa Bay 0.0227613545 0.129185120 0.7931208
#> 149 2022     5     GW Middle Tampa Bay 0.0227613545 0.129185120 0.7931208
#> 150 2022     6     GW Middle Tampa Bay 0.0227613545 0.129185120 0.7931208
#> 151 2022     7     GW Middle Tampa Bay 0.0260606245 0.147265119 0.9126274
#> 152 2022     8     GW Middle Tampa Bay 0.0260606245 0.147265119 0.9126274
#> 153 2022     9     GW Middle Tampa Bay 0.0260606245 0.147265119 0.9126274
#> 154 2022    10     GW Middle Tampa Bay 0.0260606245 0.147265119 0.9126274
#> 155 2022    11     GW Middle Tampa Bay 0.0227613545 0.129185120 0.7931208
#> 156 2022    12     GW Middle Tampa Bay 0.0227613545 0.129185120 0.7931208
#> 157 2023     1     GW Middle Tampa Bay 0.0227613545 0.129185120 0.7931208
#> 158 2023     2     GW Middle Tampa Bay 0.0227613545 0.129185120 0.7931208
#> 159 2023     3     GW Middle Tampa Bay 0.0227613545 0.129185120 0.7931208
#> 160 2023     4     GW Middle Tampa Bay 0.0227613545 0.129185120 0.7931208
#> 161 2023     5     GW Middle Tampa Bay 0.0227613545 0.129185120 0.7931208
#> 162 2023     6     GW Middle Tampa Bay 0.0227613545 0.129185120 0.7931208
#> 163 2023     7     GW Middle Tampa Bay 0.0260606245 0.147265119 0.9126274
#> 164 2023     8     GW Middle Tampa Bay 0.0260606245 0.147265119 0.9126274
#> 165 2023     9     GW Middle Tampa Bay 0.0260606245 0.147265119 0.9126274
#> 166 2023    10     GW Middle Tampa Bay 0.0260606245 0.147265119 0.9126274
#> 167 2023    11     GW Middle Tampa Bay 0.0227613545 0.129185120 0.7931208
#> 168 2023    12     GW Middle Tampa Bay 0.0227613545 0.129185120 0.7931208
#> 169 2024     1     GW Middle Tampa Bay 0.0227613545 0.129185120 0.7931208
#> 170 2024     2     GW Middle Tampa Bay 0.0227613545 0.129185120 0.7931208
#> 171 2024     3     GW Middle Tampa Bay 0.0227613545 0.129185120 0.7931208
#> 172 2024     4     GW Middle Tampa Bay 0.0227613545 0.129185120 0.7931208
#> 173 2024     5     GW Middle Tampa Bay 0.0227613545 0.129185120 0.7931208
#> 174 2024     6     GW Middle Tampa Bay 0.0227613545 0.129185120 0.7931208
#> 175 2024     7     GW Middle Tampa Bay 0.0260606245 0.147265119 0.9126274
#> 176 2024     8     GW Middle Tampa Bay 0.0260606245 0.147265119 0.9126274
#> 177 2024     9     GW Middle Tampa Bay 0.0260606245 0.147265119 0.9126274
#> 178 2024    10     GW Middle Tampa Bay 0.0260606245 0.147265119 0.9126274
#> 179 2024    11     GW Middle Tampa Bay 0.0227613545 0.129185120 0.7931208
#> 180 2024    12     GW Middle Tampa Bay 0.0227613545 0.129185120 0.7931208
#> 181 2022     1     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 182 2022     2     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 183 2022     3     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 184 2022     4     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 185 2022     5     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 186 2022     6     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 187 2022     7     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 188 2022     8     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 189 2022     9     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 190 2022    10     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 191 2022    11     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 192 2022    12     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 193 2023     1     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 194 2023     2     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 195 2023     3     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 196 2023     4     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 197 2023     5     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 198 2023     6     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 199 2023     7     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 200 2023     8     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 201 2023     9     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 202 2023    10     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 203 2023    11     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 204 2023    12     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 205 2024     1     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 206 2024     2     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 207 2024     3     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 208 2024     4     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 209 2024     5     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 210 2024     6     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 211 2024     7     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 212 2024     8     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 213 2024     9     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 214 2024    10     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 215 2024    11     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 216 2024    12     GW    Old Tampa Bay 0.5487809114 0.163081117 5.0150378
#> 217 2022     1     GW   Terra Ceia Bay 0.0001763698 0.001344820 0.0038045
#> 218 2022     2     GW   Terra Ceia Bay 0.0001763698 0.001344820 0.0038045
#> 219 2022     3     GW   Terra Ceia Bay 0.0001763698 0.001344820 0.0038045
#> 220 2022     4     GW   Terra Ceia Bay 0.0001763698 0.001344820 0.0038045
#> 221 2022     5     GW   Terra Ceia Bay 0.0001763698 0.001344820 0.0038045
#> 222 2022     6     GW   Terra Ceia Bay 0.0001763698 0.001344820 0.0038045
#> 223 2022     7     GW   Terra Ceia Bay 0.0043835838 0.022380890 0.1561988
#> 224 2022     8     GW   Terra Ceia Bay 0.0043835838 0.022380890 0.1561988
#> 225 2022     9     GW   Terra Ceia Bay 0.0043835838 0.022380890 0.1561988
#> 226 2022    10     GW   Terra Ceia Bay 0.0043835838 0.022380890 0.1561988
#> 227 2022    11     GW   Terra Ceia Bay 0.0001763698 0.001344820 0.0038045
#> 228 2022    12     GW   Terra Ceia Bay 0.0001763698 0.001344820 0.0038045
#> 229 2023     1     GW   Terra Ceia Bay 0.0001763698 0.001344820 0.0038045
#> 230 2023     2     GW   Terra Ceia Bay 0.0001763698 0.001344820 0.0038045
#> 231 2023     3     GW   Terra Ceia Bay 0.0001763698 0.001344820 0.0038045
#> 232 2023     4     GW   Terra Ceia Bay 0.0001763698 0.001344820 0.0038045
#> 233 2023     5     GW   Terra Ceia Bay 0.0001763698 0.001344820 0.0038045
#> 234 2023     6     GW   Terra Ceia Bay 0.0001763698 0.001344820 0.0038045
#> 235 2023     7     GW   Terra Ceia Bay 0.0043835838 0.022380890 0.1561988
#> 236 2023     8     GW   Terra Ceia Bay 0.0043835838 0.022380890 0.1561988
#> 237 2023     9     GW   Terra Ceia Bay 0.0043835838 0.022380890 0.1561988
#> 238 2023    10     GW   Terra Ceia Bay 0.0043835838 0.022380890 0.1561988
#> 239 2023    11     GW   Terra Ceia Bay 0.0001763698 0.001344820 0.0038045
#> 240 2023    12     GW   Terra Ceia Bay 0.0001763698 0.001344820 0.0038045
#> 241 2024     1     GW   Terra Ceia Bay 0.0001763698 0.001344820 0.0038045
#> 242 2024     2     GW   Terra Ceia Bay 0.0001763698 0.001344820 0.0038045
#> 243 2024     3     GW   Terra Ceia Bay 0.0001763698 0.001344820 0.0038045
#> 244 2024     4     GW   Terra Ceia Bay 0.0001763698 0.001344820 0.0038045
#> 245 2024     5     GW   Terra Ceia Bay 0.0001763698 0.001344820 0.0038045
#> 246 2024     6     GW   Terra Ceia Bay 0.0001763698 0.001344820 0.0038045
#> 247 2024     7     GW   Terra Ceia Bay 0.0043835838 0.022380890 0.1561988
#> 248 2024     8     GW   Terra Ceia Bay 0.0043835838 0.022380890 0.1561988
#> 249 2024     9     GW   Terra Ceia Bay 0.0043835838 0.022380890 0.1561988
#> 250 2024    10     GW   Terra Ceia Bay 0.0043835838 0.022380890 0.1561988
#> 251 2024    11     GW   Terra Ceia Bay 0.0001763698 0.001344820 0.0038045
#> 252 2024    12     GW   Terra Ceia Bay 0.0001763698 0.001344820 0.0038045

# annual totals
anlz_gw(yrrng = c(2022, 2024), summtime = 'year')
#>    Year source          segment     tn_load    tp_load    hy_load
#> 1  2022     GW   Boca Ciega Bay  0.00502654 0.04748757  0.1585512
#> 2  2023     GW   Boca Ciega Bay  0.00502654 0.04748757  0.1585512
#> 3  2024     GW   Boca Ciega Bay  0.00502654 0.04748757  0.1585512
#> 4  2022     GW Hillsborough Bay 20.72632859 2.46652041 73.9028084
#> 5  2023     GW Hillsborough Bay 20.72632859 2.46652041 73.9028084
#> 6  2024     GW Hillsborough Bay 20.72632859 2.46652041 73.9028084
#> 7  2022     GW  Lower Tampa Bay  0.10948950 0.62279120  3.8203550
#> 8  2023     GW  Lower Tampa Bay  0.10948950 0.62279120  3.8203550
#> 9  2024     GW  Lower Tampa Bay  0.10948950 0.62279120  3.8203550
#> 10 2022     GW    Manatee River  0.10249411 0.50923100  3.5031130
#> 11 2023     GW    Manatee River  0.10249411 0.50923100  3.5031130
#> 12 2024     GW    Manatee River  0.10249411 0.50923100  3.5031130
#> 13 2022     GW Middle Tampa Bay  0.28633333 1.62254143  9.9954764
#> 14 2023     GW Middle Tampa Bay  0.28633333 1.62254143  9.9954764
#> 15 2024     GW Middle Tampa Bay  0.28633333 1.62254143  9.9954764
#> 16 2022     GW    Old Tampa Bay  6.58537094 1.95697341 60.1804539
#> 17 2023     GW    Old Tampa Bay  6.58537094 1.95697341 60.1804539
#> 18 2024     GW    Old Tampa Bay  6.58537094 1.95697341 60.1804539
#> 19 2022     GW   Terra Ceia Bay  0.01894529 0.10028212  0.6552311
#> 20 2023     GW   Terra Ceia Bay  0.01894529 0.10028212  0.6552311
#> 21 2024     GW   Terra Ceia Bay  0.01894529 0.10028212  0.6552311

if (FALSE) { # \dontrun{
# pass concentrations from the Water Atlas API
anlz_gw(yrrng = c(2022, 2024), wqdat = util_gw_getwq())
} # }
```
