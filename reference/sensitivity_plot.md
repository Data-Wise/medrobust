# Create Sensitivity Analysis Plots

Generate publication-quality visualizations of partial identification
bounds as a function of sensitivity parameters.

## Usage

``` r
sensitivity_plot(
  bounds_object,
  param = "psi_sn",
  effect = c("both", "NIE", "NDE"),
  plot_type = c("bounds", "heatmap", "contour"),
  show_naive = TRUE,
  show_null = TRUE,
  color_scheme = "default",
  theme = "bw",
  ...
)
```

## Arguments

- bounds_object:

  An object of class `medrobust_bounds` returned by
  [`bound_ne`](https://data-wise.github.io/medrobust/reference/bound_ne.md).

- param:

  Character vector specifying which parameter(s) to plot on the x-axis.
  Options: "psi_sn", "psi_sp", "sn0", "sp0". Can specify multiple for
  faceted plots.

- effect:

  Character string: "NIE", "NDE", or "both" (default).

- plot_type:

  Character string specifying plot type:

  - "bounds" (default): Line plot showing upper and lower bounds

  - "heatmap": 2D heatmap of bound width (requires two parameters)

  - "contour": Contour plot of bounds (requires two parameters)

- show_naive:

  Logical indicating whether to overlay the naive estimate (assuming no
  misclassification). Default is TRUE.

- show_null:

  Logical indicating whether to show horizontal line at null value
  (effect = 1 for OR/RR, effect = 0 for RD). Default is TRUE.

- color_scheme:

  Character string specifying color palette: "default", "viridis",
  "colorblind", "grayscale".

- theme:

  Character string for ggplot2 theme: "bw" (default), "minimal",
  "classic", "void".

- ...:

  Additional arguments passed to ggplot2 functions.

## Value

A ggplot2 object that can be further customized or saved.

## Details

The function creates different plot types to visualize sensitivity
analysis:

**Bounds plot**: Shows how the lower and upper bounds vary as a function
of one sensitivity parameter, with other parameters held fixed or
averaged.

**Heatmap**: Shows the width of the identification region (upper -
lower) as a function of two sensitivity parameters simultaneously.

**Contour plot**: Shows contour lines of the bounds in 2D parameter
space.

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic bounds plot
sensitivity_plot(bounds, param = "psi_sn", effect = "NIE")

# Show both effects
sensitivity_plot(bounds, param = "psi_sn", effect = "both")

# Heatmap of bound width
sensitivity_plot(bounds,
                param = c("psi_sn", "sn0"),
                plot_type = "heatmap")

# Customize and save
p <- sensitivity_plot(bounds, param = "psi_sn") +
  labs(title = "My Custom Title") +
  theme(legend.position = "bottom")
ggsave("sensitivity_plot.pdf", p, width = 8, height = 6)
} # }
```
