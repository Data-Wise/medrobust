# Coerce to data frame (S3 - Legacy)

Extract bounds as a data frame for further analysis or export. NOTE:
This is a legacy S3 method. The package now uses S7 methods (see
s7-methods.R).

## Usage

``` r
# S3 method for class 'medrobust_bounds'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)
```

## Arguments

- x:

  An object of class `medrobust_bounds`.

- row.names:

  Optional row names (not used).

- optional:

  Logical (not used).

- ...:

  Additional arguments (not used).

## Value

A data frame with one row containing the bounds.
