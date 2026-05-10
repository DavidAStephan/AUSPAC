# Deprecated NK stub files

`nk_simple.mod` and `nk_discounted.mod` are abandoned New-Keynesian stub models from an early development phase. They are not part of any active pipeline (data prep, estimation, IRF generation, or test suite) and produce no outputs that any other script depends on.

They are retained in the tree as historical artefacts only. They can be removed with:

```bash
git rm dynare/nk_simple.mod dynare/nk_discounted.mod
```

(The Phase F cleanup author was prevented from doing this directly by an interactive permission check.)
