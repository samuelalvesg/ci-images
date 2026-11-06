# Imagem do Flutter para build web

Substitui `ghcr.io/cirruslabs/flutter`, que parou na 3.44.0 (a 3.47.x não existe lá). Ubuntu 24.04 + Flutter SDK
oficial + toolchain nativa (`build-essential`, `clang`, `cmake`, `ninja`) para o cargokit e para o fallback Rust do
`Dockerfile` do app. Só a plataforma web está habilitada; Android e iOS não fazem parte desta imagem.

## Licença

Os arquivos **deste diretório** (Dockerfile, `test.sh`) e os workflows de imagens são Apache-2.0 (`LICENSE`).
O Flutter SDK (BSD-3), o Dart e os pacotes Ubuntu dentro da imagem mantêm as próprias licenças. O restante do
repositório não é coberto por esta licença.

## Construir e testar localmente

```bash
docker build -t flutter:3.47.5 --build-arg FLUTTER_VERSION=3.47.5 docker/flutter-image
docker/flutter-image/test.sh flutter:3.47.5 3.47.5
```

O build baixa o manifesto de releases do Google, **confere o SHA-256** do arquivo antes de extrair e falha se a versão
não existir no canal `stable`. `FLUTTER_VERSION` aceita qualquer versão do canal `stable`.

## Publicar, usar no CI/Coolify e tags

Ver [README](../../README.md): tags (`3.47.5`, `3.47`, `latest`), uso como `container:` do GitHub Actions e como
`FROM` no Coolify, visibilidade pública do pacote e as imagens irmãs `flutter-rust`, `rust` e `dotnet`.

A migração do app para a 3.47 segue a receita do item `preparar-codigo-antes-do-upgrade-flutter-3-47` do repositório de
docs; esta imagem só remove o bloqueio da imagem base.
