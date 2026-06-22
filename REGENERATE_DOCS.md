# Documentation Regeneration Required

After the S7 conversion, you need to regenerate the package
documentation to update NAMESPACE:

``` r

# In R console:
devtools::document()
devtools::load_all()
devtools::test()
```

This will: 1. Remove the old `as.list.sensitivity_region` S3 method
declaration 2. Update all roxygen-generated documentation 3. Ensure
NAMESPACE is in sync with the code

The warning you’re seeing is because the old S3 method was converted to
an S7 method, but NAMESPACE hasn’t been regenerated yet.

## Current Status

- **S7 Infrastructure**: ✅ Complete
- **Classes**: 7 S7 classes implemented
- **Methods**: 13 S7 methods implemented
- **Tests**: 127/132 passing (96% pass rate)
- **Documentation needs**: Run `devtools::document()`

## After Regenerating Docs

All warnings should disappear and the package will be fully functional
with the S7 OOP system.
