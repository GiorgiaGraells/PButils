
<!-- README.md is generated from README.Rmd. Please edit that file -->

# PButils

<!-- badges: start -->

[![R-CMD-check](https://github.com/GiorgiaGraells/PButils/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/GiorgiaGraells/PButils/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

## Overview

**PButils** provides utility functions to support the processing of
planetary boundary data extracted from the literature.

A common issue in planetary boundary and footprint datasets is that
**values and units are stored together in the same column**, making
comparison, harmonisation, and calculation difficult.

The first core functionality of PButils is to **separate numeric values
from their units**, while preserving the original data.

Future functionality will focus on:

- unit harmonisation across comparable variables,
- calculation of boundary overshoot at territorial and per-capita
  scales.

## Installation

You can install the development version of PButils from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("GiorgiaGraells/PButils")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(PButils)
## basic example code
```

## Example data

PButils ships with an example dataset used throughout the package
documentation:

``` r
data("Nitrogen_Data")

names(Nitrogen_Data)
#>  [1] "authors"                    "title"                     
#>  [3] "publication_year"           "approach"                  
#>  [5] "approach_detail"            "downscaling_scale"         
#>  [7] "location_name"              "control_variable"          
#>  [9] "variable_description"       "variable_extra_description"
#> [11] "response_variable"          "response_ecosystem"        
#> [13] "global_limit_considered"    "year"                      
#> [15] "boundary_percapita"         "territorial_boundary"      
#> [17] "footprint_percapita"        "territorial_footprint"     
#> [19] "overshoot"                  "calculation_resolution"    
#> [21] "data_reference"             "social_policy_involved"    
#> [23] "observations"
```

This dataset contains several columns where numeric values and units are
stored together as character strings (e.g. `"5.4 kg N cap⁻¹ yr⁻¹"`).

## Separating values and units

### Single column

The `separate_unit_value()` function separates a column containing both
values and units into two new columns:

- `<column>_value` (numeric)
- `<column>_unit` (character)

while **preserving the original column**.

``` r
out <- separate_unit_value(
  df = Nitrogen_Data,
  columns = "boundary_percapita"
)

names(out)
#>  [1] "authors"                    "title"                     
#>  [3] "publication_year"           "approach"                  
#>  [5] "approach_detail"            "downscaling_scale"         
#>  [7] "location_name"              "control_variable"          
#>  [9] "variable_description"       "variable_extra_description"
#> [11] "response_variable"          "response_ecosystem"        
#> [13] "global_limit_considered"    "year"                      
#> [15] "boundary_percapita"         "boundary_percapita_value"  
#> [17] "boundary_percapita_unit"    "territorial_boundary"      
#> [19] "footprint_percapita"        "territorial_footprint"     
#> [21] "overshoot"                  "calculation_resolution"    
#> [23] "data_reference"             "social_policy_involved"    
#> [25] "observations"
```

``` r
head(
  out[, c("boundary_percapita",
          "boundary_percapita_value",
          "boundary_percapita_unit")]
)
#>   boundary_percapita boundary_percapita_value boundary_percapita_unit
#> 1               <NA>                       NA                    <NA>
#> 2            8.9 kgN                      8.9                     kgN
#> 3         8.9 kgN/yr                      8.9                  kgN/yr
#> 4         8.9 kgN/yr                      8.9                  kgN/yr
#> 5         8.9 kgN/yr                      8.9                  kgN/yr
#> 6         8.9 kgN/yr                      8.9                  kgN/yr
```

### Multiple columns at once

You can also process multiple columns in a single call:

``` r
out2 <- separate_unit_value(
  df = Nitrogen_Data,
  columns = c("global_limit_considered", "boundary_percapita")
)

names(out2)
#>  [1] "authors"                       "title"                        
#>  [3] "publication_year"              "approach"                     
#>  [5] "approach_detail"               "downscaling_scale"            
#>  [7] "location_name"                 "control_variable"             
#>  [9] "variable_description"          "variable_extra_description"   
#> [11] "response_variable"             "response_ecosystem"           
#> [13] "global_limit_considered"       "global_limit_considered_value"
#> [15] "global_limit_considered_unit"  "year"                         
#> [17] "boundary_percapita"            "boundary_percapita_value"     
#> [19] "boundary_percapita_unit"       "territorial_boundary"         
#> [21] "footprint_percapita"           "territorial_footprint"        
#> [23] "overshoot"                     "calculation_resolution"       
#> [25] "data_reference"                "social_policy_involved"       
#> [27] "observations"
```

Each input column generates its own `_value` and `_unit` pair:

``` r
head(
  out2[, c("global_limit_considered_value",
           "global_limit_considered_unit",
           "boundary_percapita_value",
           "boundary_percapita_unit")]
)
#>   global_limit_considered_value global_limit_considered_unit
#> 1                            NA                         <NA>
#> 2                            62                       TgN/yr
#> 3                            62                       TgN/yr
#> 4                            62                       TgN/yr
#> 5                            62                       TgN/yr
#> 6                            62                       TgN/yr
#>   boundary_percapita_value boundary_percapita_unit
#> 1                       NA                    <NA>
#> 2                      8.9                     kgN
#> 3                      8.9                  kgN/yr
#> 4                      8.9                  kgN/yr
#> 5                      8.9                  kgN/yr
#> 6                      8.9                  kgN/yr
```

## Low-level helpers

PButils also exposes the underlying helper functions used internally:

``` r
extract_value(Nitrogen_Data$boundary_percapita)
#>   [1]   NA  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9
#>  [16]  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9
#>  [31]  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9
#>  [46]  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9
#>  [61]  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9
#>  [76]  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9
#>  [91]  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9
#> [106]  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9
#> [121]  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9
#> [136]  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9  8.9
#> [151]  8.9  8.9 19.0 19.0 19.0 19.0 19.0 16.8  9.0  8.1  9.0 10.8 19.3  6.8   NA
#> [166]  2.9  2.9   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA
#> [181]   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA
#> [196]   NA   NA   NA   NA  5.0   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA
#> [211]   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA  8.4  8.4  8.4  8.4  8.4
#> [226]  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4
#> [241]  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4
#> [256]  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4
#> [271]  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4
#> [286]  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4
#> [301]  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4
#> [316]  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4
#> [331]  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4
#> [346]  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4
#> [361]  8.4  8.4  8.4  8.4  8.4  8.4  8.4  8.4   NA   NA   NA   NA   NA   NA   NA
#> [376]   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA
#> [391]   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA
#> [406]   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA
#> [421]   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA
#> [436]   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA
#> [451]   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA
#> [466]   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA
#> [481]   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA
#> [496]   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA
#> [511]   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA
#> [526]   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA
#> [541]   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA
#> [556]   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA   NA
#> [571]   NA   NA   NA   NA   NA   NA
extract_unit(Nitrogen_Data$boundary_percapita)
#>   [1] NA        "kgN"     "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr" 
#>   [8] "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr" 
#>  [15] "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr" 
#>  [22] "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr" 
#>  [29] "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr" 
#>  [36] "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr" 
#>  [43] "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr" 
#>  [50] "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr" 
#>  [57] "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr" 
#>  [64] "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr" 
#>  [71] "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr" 
#>  [78] "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr" 
#>  [85] "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr" 
#>  [92] "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr" 
#>  [99] "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr" 
#> [106] "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr" 
#> [113] "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr" 
#> [120] "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr" 
#> [127] "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr" 
#> [134] "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr" 
#> [141] "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr" 
#> [148] "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/yr"  "kgN/cap" "kgN/cap"
#> [155] "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap"
#> [162] "kgN/cap" "kgN/cap" "kgN/cap" NA        "kgN/cap" "kgN/cap" NA       
#> [169] NA        NA        NA        NA        NA        NA        NA       
#> [176] NA        NA        NA        NA        NA        NA        NA       
#> [183] NA        NA        NA        NA        NA        NA        NA       
#> [190] NA        NA        NA        NA        NA        NA        NA       
#> [197] NA        NA        NA        "kgN/cap" NA        NA        NA       
#> [204] NA        NA        NA        NA        NA        NA        NA       
#> [211] NA        NA        NA        NA        NA        NA        NA       
#> [218] NA        NA        NA        "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap"
#> [225] "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap"
#> [232] "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap"
#> [239] "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap"
#> [246] "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap"
#> [253] "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap"
#> [260] "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap"
#> [267] "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap"
#> [274] "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap"
#> [281] "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap"
#> [288] "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap"
#> [295] "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap"
#> [302] "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap"
#> [309] "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap"
#> [316] "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap"
#> [323] "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap"
#> [330] "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap"
#> [337] "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap"
#> [344] "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap"
#> [351] "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap"
#> [358] "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap"
#> [365] "kgN/cap" "kgN/cap" "kgN/cap" "kgN/cap" NA        NA        NA       
#> [372] NA        NA        NA        NA        NA        NA        NA       
#> [379] NA        NA        NA        NA        NA        NA        NA       
#> [386] NA        NA        NA        NA        NA        NA        NA       
#> [393] NA        NA        NA        NA        NA        NA        NA       
#> [400] NA        NA        NA        NA        NA        NA        NA       
#> [407] NA        NA        NA        NA        NA        NA        NA       
#> [414] NA        NA        NA        NA        NA        NA        NA       
#> [421] NA        NA        NA        NA        NA        NA        NA       
#> [428] NA        NA        NA        NA        NA        NA        NA       
#> [435] NA        NA        NA        NA        NA        NA        NA       
#> [442] NA        NA        NA        NA        NA        NA        NA       
#> [449] NA        NA        NA        NA        NA        NA        NA       
#> [456] NA        NA        NA        NA        NA        NA        NA       
#> [463] NA        NA        NA        NA        NA        NA        NA       
#> [470] NA        NA        NA        NA        NA        NA        NA       
#> [477] NA        NA        NA        NA        NA        NA        NA       
#> [484] NA        NA        NA        NA        NA        NA        NA       
#> [491] NA        NA        NA        NA        NA        NA        NA       
#> [498] NA        NA        NA        NA        NA        NA        NA       
#> [505] NA        NA        NA        NA        NA        NA        NA       
#> [512] NA        NA        NA        NA        NA        NA        NA       
#> [519] NA        NA        NA        NA        NA        NA        NA       
#> [526] NA        NA        NA        NA        NA        NA        NA       
#> [533] NA        NA        NA        NA        NA        NA        NA       
#> [540] NA        NA        NA        NA        NA        NA        NA       
#> [547] NA        NA        NA        NA        NA        NA        NA       
#> [554] NA        NA        NA        NA        NA        NA        NA       
#> [561] NA        NA        NA        NA        NA        NA        NA       
#> [568] NA        NA        NA        NA        NA        NA        NA       
#> [575] NA        NA
```

These can be useful when working directly with vectors rather than data
frames.

## Notes

- Original columns are **never modified or removed**
- Newly created \_value and \_unit columns are inserted immediately
  after their source column to facilitate quick inspection.
- Missing values are preserved as `NA`
- The implementation avoids non-base piping to keep dependencies minimal

## Development status

PButils is under active development. The API may evolve as additional
unit harmonisation and overshoot calculations are added.

Bug reports and feature requests are welcome:
<https://github.com/GiorgiaGraells/PButils/issues>
