# Imagens de CI (Flutter, Rust, .NET)

> Docker images for CI: **Flutter** (web/WASM), **Rust** (wasm32, flutter_rust_bridge, wasm-pack) and **.NET** (dotnet-ef).
> Ready-made toolchains for GitHub Actions `container:` jobs, Coolify and any Dockerfile `FROM`. Published on `ghcr.io`.
> Keywords: flutter docker image, flutter web ci, flutter wasm, flutter_rust_bridge, rust wasm32, dotnet sdk ci, github actions container, ghcr.

Imagens prontas para acelerar CI e builds: o toolchain já vem instalado, em vez de ser baixado e compilado a cada execução
(`cargo install flutter_rust_bridge_codegen`, `dotnet tool install dotnet-ef`, SDK do Flutter...). Publicadas no GitHub
Container Registry por [`flutter-image.yml`](.github/workflows/flutter-image.yml). Licença Apache-2.0
(ver `LICENSE` em cada pasta); o Flutter SDK (BSD-3), o .NET SDK (MIT), Rust (MIT/Apache-2.0) e os pacotes Ubuntu dentro das
imagens mantêm as licenças próprias.

| Imagem | Conteúdo | Tags | Pasta |
|---|---|---|---|
| `ghcr.io/<dono>/flutter` | Ubuntu 24.04 + Flutter SDK oficial (web habilitado) + `clang/cmake/ninja` | `3.47.5`, `3.47`, `latest`, `3.47-sha-<commit>` | [`flutter-image`](docker/flutter-image) |
| `ghcr.io/<dono>/flutter-rust` | a imagem `flutter` + Rust stable e nightly fixa com `wasm32` e `rust-src`, `flutter_rust_bridge_codegen`, `wasm-pack` | idem (a versão é a do Flutter) | [`rust-image`](docker/rust-image) |
| `ghcr.io/<dono>/rust` | Ubuntu 24.04 + Rust stable e nightly fixa com `wasm32`, `clippy`, `rustfmt`, FRB codegen, `wasm-pack` | `1.0.0`, `1.0`, `latest` (revisão da imagem; as versões do Rust estão nos labels) | [`rust-image`](docker/rust-image) |
| `ghcr.io/<dono>/dotnet` | SDK .NET (padrão 10.0) + `dotnet-ef`, `python3`, `jq` | `10.0.0`, `10.0`, `latest` | [`dotnet-image`](docker/dotnet-image) |

Cada tag fixa (`3.47.5`) nunca é sobrescrita por outra versão; `X.Y` e `latest` andam para a publicação mais nova. Para build
reproduzível, fixe por digest: `image: ghcr.io/<dono>/flutter@sha256:...` (o digest aparece no resumo do workflow).

Labels OCI em todas (`org.opencontainers.image.{title,description,version,source,revision,created,licenses,documentation}`),
mais `dev.flutter.version`, `dev.rust.stable`, `dev.rust.nightly`, `dev.frb.version`. As imagens publicadas levam
**SBOM e proveniência** (attestations do buildx); a atestação assinada só é emitida quando o repositório é público.

## Usar no GitHub Actions

```yaml
jobs:
  web:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/<dono>/flutter-rust:3.47.5
      credentials: { username: "${{ github.actor }}", password: "${{ secrets.GITHUB_TOKEN }}" }  # só se o pacote for privado
    steps:
      - uses: actions/checkout@v4
      - run: flutter pub get && flutter analyze && flutter test
```

O runner troca o `HOME` e faz o checkout com outro dono; as imagens guardam tudo em caminhos de sistema
(`/usr/local/cargo`, `/sdks/flutter`...) e confiam em qualquer diretório no git, por isso funcionam como `container:`.
Testes do backend com Testcontainers precisam do socket do Docker do host:
`container.options: -v /var/run/docker.sock:/var/run/docker.sock`.

**Não cobertos:** Android, iOS, macOS e Windows (precisam de SDK Android/JDK ou de runner próprio). As imagens são `linux/amd64`.

## Usar como base de Dockerfile (Coolify, qualquer lugar)

```dockerfile
FROM ghcr.io/<dono>/flutter-rust:3.47.5 AS build-env
```

O pacote nasce **privado**. Para qualquer pessoa (ou o Coolify) puxar sem login: *Package settings → Change visibility → Public*
(o `GITHUB_TOKEN` do workflow não consegue mudar isso).

## Construir localmente

```bash
docker build -t flutter:3.47.5 --build-arg FLUTTER_VERSION=3.47.5 docker/flutter-image && docker/flutter-image/test.sh flutter:3.47.5 3.47.5
docker build -t flutter-rust:3.47.5 --build-arg BASE=flutter:3.47.5 docker/rust-image && docker/rust-image/test.sh flutter-rust:3.47.5 flutter
docker build -t dotnet:10.0 --build-arg DOTNET_VERSION=10.0 docker/dotnet-image && docker/dotnet-image/test.sh dotnet:10.0 10
```

Build args: `FLUTTER_VERSION` (qualquer versão do canal `stable`; o SHA-256 do tarball é conferido contra o manifesto do Google),
`RUST_STABLE`, `RUST_NIGHTLY`, `FRB_VERSION`, `WASM_PACK_VERSION`, `DOTNET_VERSION`, `DOTNET_EF_VERSION`.

## Publicar

Disparo manual (*Actions → CI images → Run workflow*, com a versão do Flutter e do .NET) ou push em `docker/**` na `main`.
Pull requests só constroem e testam (o `flutter-rust` só roda ao publicar, pois constrói sobre a `flutter` publicada).
Atualizar uma versão: rodar o workflow com a versão nova; as tags `X.Y.Z` antigas continuam disponíveis.

## Como as imagens são achadas no GitHub

- **Página do pacote (ghcr.io):** título, descrição, versão, licença e link de origem vêm dos labels OCI que o workflow grava
  (a descrição de cada imagem cita o que ela contém e as tags). O README do pacote é o do repositório ligado pelo label `source`.
- **Busca por repositório:** o repositório que publica precisa de descrição e *topics*. Comando (efeito externo, rodar com
  decisão do mantenedor; aplica-se ao repositório que de fato publicar as imagens):

  ```bash
  gh repo edit <dono>/<repo> \
    --description "Docker images for CI: Flutter (web/WASM), Rust (wasm32, flutter_rust_bridge) and .NET (dotnet-ef) on ghcr.io" \
    --add-topic docker --add-topic docker-image --add-topic ghcr --add-topic github-actions --add-topic ci \
    --add-topic flutter --add-topic flutter-web --add-topic flutter-rust-bridge --add-topic rust --add-topic webassembly \
    --add-topic dotnet --add-topic dotnet-ef --add-topic coolify
  ```

  O GitHub aceita até 20 topics, em minúsculas e com hífen.
- **Visibilidade:** pacote e repositório precisam ser públicos para aparecer em buscas e para qualquer pessoa puxar sem login.

## Visibilidade

Este repositório é público, então os pacotes publicados por ele podem ser públicos e têm atestação assinada de proveniência.
Pacotes novos do GHCR nascem privados: *Package settings → Change visibility → Public* (o `GITHUB_TOKEN` do workflow não
consegue mudar isso).
