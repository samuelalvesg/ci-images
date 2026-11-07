# Contribuindo

## Construir e testar localmente

```bash
docker build -t flutter:3.47.5 --build-arg FLUTTER_VERSION=3.47.5 docker/flutter-image && docker/flutter-image/test.sh flutter:3.47.5 3.47.5
docker build -t flutter-rust:3.47.5 --build-arg BASE=flutter:3.47.5 --build-arg WITH_APP_TOOLS=true docker/rust-image && docker/rust-image/test.sh flutter-rust:3.47.5 flutter
docker build -t dotnet:10.0 --build-arg DOTNET_VERSION=10.0 docker/dotnet-image && docker/dotnet-image/test.sh dotnet:10.0 10
```

Build args: `FLUTTER_VERSION` (qualquer versão do canal `stable`; o SHA-256 do tarball é conferido contra o manifesto do
Google), `RUST_STABLE`, `RUST_NIGHTLY`, `FRB_VERSION`, `WASM_PACK_VERSION`, `DOTNET_VERSION`, `DOTNET_EF_VERSION`.

`FRB_VERSION` precisa ser a mesma do `flutter_rust_bridge` do app consumidor (`pubspec.yaml`, `Cargo.toml` e o código gerado):
o runtime recusa um código gerado por outra versão. Ao subir a versão no app, suba aqui também.

O Renovate (`renovate.json`) propõe a subida de `RUST_STABLE` e `WASM_PACK_VERSION`: o `ARG` leva um comentário
`# renovate: datasource=... depName=...` na linha de cima. Para o Renovate acompanhar outra versão, acrescente o mesmo comentário.
`FRB_VERSION` fica de fora de propósito (segue o app). O Dependabot continua com `github-actions` e com os digests das bases.
## Resumo de cada build

Cada job de imagem escreve um resumo na aba do run (resultado, origem, base e digest, tamanho, tempo e as versões das
ferramentas dentro da imagem). O que aparece em "Inside the image" vem da entrada `versions` do job em
`.github/workflows/flutter-image.yml`: uma linha `Rótulo=comando` por ferramenta, executada dentro da imagem (vale a
primeira linha da saída; comando que falha vira `n/a`). Ao criar uma imagem nova, declare a lista dela. O gerador é
`.github/scripts/build-summary.sh` e dá para testá-lo à mão: `NAME=x VERSION=1 IMAGE=<imagem local> VERSIONS=$'A=comando' bash
.github/scripts/build-summary.sh`. Ele só informa: nunca derruba o build. A varredura de vulnerabilidades continua no log do passo
dela.

## Pull requests

Pull requests constroem e testam as imagens, sem publicar. O `flutter-rust` só roda ao publicar, porque constrói sobre a
`flutter` publicada; o job `rust` valida o mesmo Dockerfile.

## Publicação (mantenedores)

Cada imagem publicada leva também a tag `content-<hash>` (hash dos arquivos do contexto, dos argumentos, da versão e, no
`flutter-rust`, do digest da base `flutter`). Num push em `main` ou num PR, se essa tag já existe, o build, os testes e o push dessa imagem são
pulados (ela já foi construída e testada com exatamente essas entradas). O hash também cobre o comando de teste e o próprio
`_build-image.yml`, então mexer neles reconstrói tudo. Execução manual sempre reconstrói (é o que pega atualizações da imagem
base, que o hash não enxerga).

As camadas ficam em cache no próprio registro (tag `buildcache` de cada pacote), e não no cache do Actions, que tem limite de
10 GB por repositório. Uma imagem que mudou reaproveita as camadas já publicadas e só refaz as que mudaram; só execuções que
conseguem escrever no registro (não forks, não Dependabot) atualizam esse cache.

Push em `docker/**` na `main`, ou *Actions → CI images → Run workflow* com as versões do Flutter e do .NET. As tags
`X.Y.Z` anteriores continuam disponíveis. Pacotes novos do GHCR nascem privados: *Package settings → Change visibility → Public*.
