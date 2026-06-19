# medrobust: Robust Causal Mediation Analysis Under Differential Misclassification

Provides tools for conducting sensitivity analysis for causal mediation
effects when the exposure or mediator is measured with differential
misclassification (e.g., recall bias, outcome-dependent measurement
error). Unlike existing measurement error correction methods that assume
non-differential error or require validation data, 'medrobust' derives
partial identification bounds that remain valid without gold-standard
measurements. The package implements methods developed in Tofighi (2025)
for partial identification bounds for Natural Direct Effects (NDE) and
Natural Indirect Effects (NIE), data-driven falsification via testable
implications, sensitivity analysis over user-specified ranges of
misclassification parameters, diagnostic tools and publication-quality
visualizations, bootstrap inference for confidence intervals via
percentile and bias-corrected and accelerated (BCa) methods, and
synthetic data generation for power analysis and methods research. The
package handles both mediator misclassification and exposure
misclassification within a unified framework. The partial identification
approach builds on Manski (2003, ISBN:978-0387004549); confidence
intervals for the partially identified bounds use the construction of
Imbens and Manski (2004)
[doi:10.1111/j.1468-0262.2004.00549.x](https://doi.org/10.1111/j.1468-0262.2004.00549.x)
.

## See also

Useful links:

- <https://github.com/data-wise/medrobust>

- <https://data-wise.github.io/medrobust/>

- Report bugs at <https://github.com/data-wise/medrobust/issues>

## Author

**Maintainer**: Davood Tofighi <dtofighi@gmail.com>
([ORCID](https://orcid.org/0000-0001-8523-7776))
