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
visualizations, bootstrap inference for confidence intervals (percentile
and BCa methods), and synthetic data generation for power analysis and
methods research. The package handles both mediator misclassification
and exposure misclassification within a unified framework.

## See also

Useful links:

- <https://github.com/data-wise/medrobust>

- Report bugs at <https://github.com/data-wise/medrobust/issues>

## Author

**Maintainer**: Davood Tofighi <dtofighi@gmail.com>
([ORCID](https://orcid.org/0000-0001-8523-7776))
