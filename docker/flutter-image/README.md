# Imagem `flutter`

Ubuntu 24.04 + Flutter SDK oficial (plataforma web habilitada) + toolchain nativa (`build-essential`, `clang`, `cmake`,
`ninja`). Alternativa à `ghcr.io/cirruslabs/flutter`, que parou na 3.44.0.

```dockerfile
FROM ghcr.io/samuelalvesg/flutter:3.47.5
```

Uso no GitHub Actions, tags e variáveis: ver o [README](../../README.md). Android e iOS não estão habilitados nesta imagem.
O SDK vem do tarball oficial do Google, com o SHA-256 conferido contra o manifesto de releases.
