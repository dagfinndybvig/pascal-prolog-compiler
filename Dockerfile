FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        swi-prolog \
        gcc \
        libc6-dev \
        make \
        python3 \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
COPY . /workspace

RUN printf '#!/usr/bin/env bash\nset -euo pipefail\nexec swipl -q -s /workspace/pascal_compiler.pl -- "$@"\n' > /usr/local/bin/pascalc \
    && chmod +x /usr/local/bin/pascalc

ENTRYPOINT ["pascalc"]
