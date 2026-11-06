# Contribuindo

## Construir e testar localmente

```bash
docker build -t flutter:3.47.5 --build-arg FLUTTER_VERSION=3.47.5 docker/flutter-image && docker/flutter-image/test.sh flutter:3.47.5 3.47.5
docker build -t flutter-rust:3.47.5 --build-arg BASE=flutter:3.47.5 --build-arg WITH_APP_TOOLS=true docker/rust-image && docker/rust-image/test.sh flutter-rust:3.47.5 flutter
docker build -t dotnet:10.0 --build-arg DOTNET_VERSION=10.0 docker/dotnet-image && docker/dotnet-image/test.sh dotnet:10.0 10
```

Build args: `FLUTTER_VERSION` (qualquer versão do canal `stable`; o SHA-256 do tarball é conferido contra o manifesto do
Google), `RUST_STABLE`, `RUST_NIGHTLY`, `FRB_VERSION`, `WASM_PACK_VERSION`, `DOTNET_VERSION`, `DOTNET_EF_VERSION`.

## Pull requests

Pull requests constroem e testam as imagens, sem publicar. O `flutter-rust` só roda ao publicar, porque constrói sobre a
`flutter` publicada; o job `rust` valida o mesmo Dockerfile.

## Publicação (mantenedores)

Push em `docker/**` na `main`, ou *Actions → CI images → Run workflow* com as versões do Flutter e do .NET. As tags
`X.Y.Z` anteriores continuam disponíveis. Pacotes novos do GHCR nascem privados: *Package settings → Change visibility → Public*.
