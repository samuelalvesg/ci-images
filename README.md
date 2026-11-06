# Imagens de CI (Flutter, Rust, .NET)

Imagens Docker prontas para CI e builds: o toolchain já vem instalado, sem baixar o Flutter SDK, compilar
`flutter_rust_bridge_codegen` ou instalar `dotnet-ef` a cada execução. Servem como `container:` de jobs do GitHub Actions
e como `FROM` de qualquer Dockerfile (Coolify, Docker, Podman).

## Imagens

| Imagem | O que traz | Tags |
|---|---|---|
| `ghcr.io/samuelalvesg/flutter` | Ubuntu 24.04, Flutter SDK oficial (web habilitado), `clang`, `cmake`, `ninja` | `3.47.5`, `3.47`, `latest` |
| `ghcr.io/samuelalvesg/flutter-rust` | a imagem `flutter` + Rust (stable e nightly fixa com `wasm32` e `rust-src`), `flutter_rust_bridge_codegen`, `wasm-pack` | `3.47.5`, `3.47`, `latest` (mesma versão do Flutter) |
| `ghcr.io/samuelalvesg/rust` | Ubuntu 24.04, Rust (stable e nightly fixa com `wasm32`), `clippy`, `rustfmt`, `flutter_rust_bridge_codegen`, `wasm-pack` | `1.0.0`, `1.0`, `latest` |
| `ghcr.io/samuelalvesg/dotnet` | SDK .NET 10, `dotnet-ef`, `python3`, `jq` | `10.0.0`, `10.0`, `latest` |

**Tags:** `X.Y.Z` é fixa (não muda de conteúdo para outra versão); `X.Y` e `latest` seguem a publicação mais nova;
`X.Y-sha-<commit>` identifica o commit de origem. Para build reproduzível, use o digest:
`ghcr.io/samuelalvesg/flutter@sha256:...`.

**Arquitetura:** `linux/amd64`. **Não cobertas:** Android, iOS, macOS e Windows (precisam de SDK Android/JDK ou de runner próprio).

Cada imagem traz labels OCI (`org.opencontainers.image.*`) com versão, licença e origem, mais `dev.flutter.version`,
`dev.rust.stable`, `dev.rust.nightly` e `dev.frb.version`, e vem com SBOM e proveniência assinada.

## Usar no GitHub Actions

```yaml
jobs:
  web:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/samuelalvesg/flutter-rust:3.47.5
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
FROM ghcr.io/samuelalvesg/flutter-rust:3.47.5 AS build-env
WORKDIR /app
COPY . .
RUN flutter build web --release --wasm
```

## Variáveis e caminhos

- **flutter / flutter-rust:** `FLUTTER_ROOT=/sdks/flutter`, `PUB_CACHE=/root/.pub-cache`, `CI=true`.
- **rust / flutter-rust:** `RUSTUP_HOME=/usr/local/rustup`, `CARGO_HOME=/usr/local/cargo`. A nightly fixa é
  `nightly-2026-06-01` (use `cargo +nightly-2026-06-01 ...` ou `rustup run`).
- **dotnet:** `NUGET_PACKAGES=/usr/local/nuget/packages`, `DOTNET_CLI_HOME=/usr/local/dotnet-home`; `dotnet-ef` no `PATH`.

## Licença

Apache-2.0 para os Dockerfiles e scripts deste repositório (ver [`LICENSE`](LICENSE)). O Flutter SDK (BSD-3), o .NET SDK (MIT),
o Rust (MIT/Apache-2.0) e os pacotes Ubuntu dentro das imagens mantêm as licenças próprias.
