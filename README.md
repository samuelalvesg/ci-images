# Imagens de CI (Flutter, Rust, .NET)

Imagens Docker prontas para CI e builds: o toolchain já vem instalado, sem baixar o Flutter SDK, compilar
`flutter_rust_bridge_codegen` ou instalar `dotnet-ef` a cada execução. Servem como `container:` de jobs do GitHub Actions
e como `FROM` de qualquer Dockerfile (Coolify, Docker, Podman).

## Imagens

| Imagem | O que traz | Tags |
|---|---|---|
| `ghcr.io/samuelalvesg/flutter` | Ubuntu 24.04, Flutter SDK oficial (web habilitado), `clang`, `cmake`, `ninja` | `3.47.9`, `3.47`, `latest` |
| `ghcr.io/samuelalvesg/flutter-rust` | a imagem `flutter` + Rust (stable e nightly fixa com `wasm32` e `rust-src`), `flutter_rust_bridge_codegen`, `wasm-pack`, `wasm-opt`, `protoc` + `protoc-gen-dart` | `3.47.9`, `3.47`, `latest` (mesma versão do Flutter) |
| `ghcr.io/samuelalvesg/flutter-linux` | a imagem `flutter-rust` + toolchain do Flutter para Linux desktop: GTK3, gstreamer, libsecret, appindicator | `3.47.9`, `3.47`, `latest` (mesma versão do Flutter) |
| `ghcr.io/samuelalvesg/flutter-android` | a imagem `flutter-rust` + JDK 17, Android SDK (plataforma 36, build-tools 36.0.0, NDK 28.2.13676358) e os 4 alvos Rust do Android | `3.47.9`, `3.47`, `latest` (mesma versão do Flutter) |
| `ghcr.io/samuelalvesg/rust` | Ubuntu 24.04, Rust (stable e nightly fixa com `wasm32`), `clippy`, `rustfmt`, `flutter_rust_bridge_codegen`, `wasm-pack` | `1.0.0`, `1.0`, `latest` |
| `ghcr.io/samuelalvesg/dotnet` | SDK .NET 10, `dotnet-ef`, `python3`, `jq` | `10.0.0`, `10.0`, `latest` |

**Tags:** `X.Y.Z` é fixa (não muda de conteúdo para outra versão); `X.Y` e `latest` seguem a publicação mais nova;
`X.Y-sha-<commit>` identifica o commit de origem. Para build reproduzível, use o digest:
`ghcr.io/samuelalvesg/flutter@sha256:...`.

**Arquitetura:** `linux/amd64`.

**Qual imagem para qual plataforma do Flutter**

| Plataforma | Imagem | Observação |
|---|---|---|
| Web (JS e WASM) | `flutter-rust` | traz o toolchain Rust/`wasm32` para o `flutter_rust_bridge` |
| Linux desktop | `flutter-linux` | |
| Android (APK e AAB) | `flutter-android` | assinatura de release fica por conta do seu workflow (keystore como secret) |
| Windows | nenhuma | precisa do MSVC: use um runner `windows-*` |
| macOS e iOS | nenhuma | precisam do Xcode: use um runner `macos-*`; imagens Docker de macOS não são distribuídas |

Windows, macOS e iOS não rodam em contêiner Linux, por isso não existem imagens para eles.

Cada imagem traz labels OCI (`org.opencontainers.image.*`) com versão, licença e origem, mais `dev.flutter.version`,
`dev.rust.stable`, `dev.rust.nightly` e `dev.frb.version`, e vem com SBOM e proveniência assinada.

## Usar no GitHub Actions

```yaml
jobs:
  web:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/samuelalvesg/flutter-rust:3.47.9
    steps:
      - uses: actions/checkout@v4
      - run: flutter pub get && flutter analyze && flutter test
```

As imagens funcionam como `container:` mesmo com o `HOME` trocado pelo runner e o checkout feito por outro usuário: nada
depende de `/root` e o git confia em qualquer diretório. Se o pacote for privado, acrescente
`credentials: { username: "${{ github.actor }}", password: "${{ secrets.GITHUB_TOKEN }}" }`.

Testes .NET com Testcontainers precisam do socket do Docker do host:

```yaml
    container:
      image: ghcr.io/samuelalvesg/dotnet:10.0
      options: -v /var/run/docker.sock:/var/run/docker.sock
```

## Usar como base de Dockerfile

```dockerfile
FROM ghcr.io/samuelalvesg/flutter-rust:3.47.9 AS build-env
WORKDIR /app
COPY . .
RUN flutter build web --release --wasm
```

## Variáveis e caminhos

- **flutter / flutter-rust:** `FLUTTER_ROOT=/sdks/flutter`, `PUB_CACHE=/root/.pub-cache`, `CI=true`.
- **rust / flutter-rust:** `RUSTUP_HOME=/usr/local/rustup`, `CARGO_HOME=/usr/local/cargo`. A nightly fixa é
  `nightly-2026-06-01` (use `cargo +nightly-2026-06-01 ...` ou `rustup run`).
- **dotnet:** `NUGET_PACKAGES=/usr/local/nuget/packages`, `DOTNET_CLI_HOME=/usr/local/dotnet-home`; `dotnet-ef` no `PATH`.

## Entrega contínua (workflow reutilizável)

`.github/workflows/cd-image.yml` constrói a imagem de uma aplicação, publica em `ghcr.io/<dono>/<imagem>` (tag `sha-<commit>` sempre; com a entrada `version`, também `<version>` e `latest`) e, se
pedido, chama a API de deploy do Coolify. Chame-o de qualquer repositório **só por `workflow_dispatch`** (versão digitada, confirmação
`RELEASE`, execução apenas a partir da `main`, *environment* `release` com revisores), nunca por push, merge ou tag:

```yaml
jobs:
  cd:
    uses: samuelalvesg/ci-images/.github/workflows/cd-image.yml@main
    permissions: { contents: read, packages: write, id-token: write, attestations: write }
    with:
      image_name: minha-api
      deploy: true
    secrets:
      COOLIFY_DEPLOY_URL: ${{ secrets.COOLIFY_DEPLOY_URL }}  # webhook de deploy do recurso (aba Webhooks)
      COOLIFY_TOKEN: ${{ secrets.COOLIFY_TOKEN }}            # token da API, se o webhook exigir
```

Entradas: `image_name`, `version`, `ref`, `context`, `dockerfile`, `build_args`, `submodules`, `deploy`, `environment`. Segredos:
`BUILD_ARGS_SECRET` (build args secretos, uma linha `CHAVE=valor` cada), `SUBMODULE_TOKEN`, `COOLIFY_URL`,
`COOLIFY_DEPLOY_URL`, `COOLIFY_TOKEN`. O job de deploy usa o *environment* `production`: configure revisores obrigatórios nele
para exigir aprovação manual. Saídas: `image` e `digest`.

## Licença

Apache-2.0 para os Dockerfiles e scripts deste repositório (ver [`LICENSE`](LICENSE)). O Flutter SDK (BSD-3), o .NET SDK (MIT),
o Rust (MIT/Apache-2.0) e os pacotes Ubuntu dentro das imagens mantêm as licenças próprias.

## Release a partir de uma imagem publicada (`release-from-image.yml`)

Workflow reutilizável: extrai uma pasta da imagem que o `cd-image.yml` acabou de publicar (por exemplo `/app` do backend ou o `web` do frontend),
empacota em `.tar.gz` com `.sha256` e anexa ao GitHub Release do repositório chamador (cria o release se não existir). Assim o binário do release
é exatamente o que está na imagem, sem segundo build. Chame-o só no fluxo manual de release; a tag é criada por esta execução (`gh release create --target <commit>`), não por push de tag.
