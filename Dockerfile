FROM alpine:latest as builder

WORKDIR /app/esy

RUN apk add pkgconfig opam yarn make m4 git gcc g++ musl-dev perl perl-utils

RUN opam init -y --disable-sandboxing --bare && \
    opam switch create esy-local-switch 4.10.1+musl+static+flambda -y && \
    opam repository add duniverse https://github.com/dune-universe/opam-repository.git#duniverse

COPY esy.opam /app/esy

RUN opam install . --deps-only -y

COPY . /app/esy

RUN git -C /app/esy/esy-solve-cudf apply static-linking.patch && \
    git -C /app/esy apply static-linking.patch

RUN opam exec -- dune build -p esy
RUN opam exec -- dune build @install
RUN opam exec -- dune install --prefix /usr/local

RUN esy i --ocaml-pkg-name ocaml --ocaml-version 4.10.1002-musl.static.flambda && \
    esy b --ocaml-pkg-name ocaml --ocaml-version 4.10.1002-musl.static.flambda && \
    esy release --static  --ocaml-pkg-name ocaml --ocaml-version 4.10.1002-musl.static.flambda

RUN opam exec -- dune uninstall --prefix /usr/local
RUN yarn global --prefix=/usr/local --force add $PWD/_release
RUN mv _release /app/_release

FROM alpine:latest

COPY --from=builder /usr/local /usr/local
COPY --from=builder /app/_release /app/_release
