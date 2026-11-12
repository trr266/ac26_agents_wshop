FROM rocker/tidyverse:4.6.2

ENV CRAN=https://p3m.dev/cran/__linux__/noble/2026-11-11
ENV DEBIAN_FRONTEND=noninteractive
ARG QUARTO_VERSION=1.11.9
ARG YQ_VERSION=v4.53.6
ARG TARGETARCH

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    libxml2-dev \
    make \
    rsync \
    ssh \
    curl ca-certificates \
    wget \
    sudo \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    case "$TARGETARCH" in \
      amd64) \
        SHA256="64078d1623d9ab89da766591f3410a0756f3737a37efb0897c7e84b863bf092a" ;; \
      arm64) \
        SHA256="17aef0c6b02c93a295483063571b5db3315095fe76f4274f286f1f9e44cdac9e" ;; \
      *) \
        echo "Unsupported architecture: $TARGETARCH" >&2; \
        exit 1 ;; \
    esac; \
    curl -fsSL --retry 3 \
      -o /tmp/quarto.deb \
      "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-${TARGETARCH}.deb"; \
    echo "${SHA256}  /tmp/quarto.deb" | sha256sum -c -; \
    apt-get update; \
    apt-get install -y --no-install-recommends /tmp/quarto.deb; \
    rm -f /tmp/quarto.deb; \
    rm -rf /var/lib/apt/lists/*

RUN quarto --version


RUN wget -qO /usr/local/bin/yq \
        https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${TARGETARCH} \
    && chmod +x /usr/local/bin/yq 

RUN install2.r --error --skipinstalled --ncpus -1 \
    glue \
    logger \
    knitr \
    jsonlite \
    languageserver \
    testthat \
    yaml 

RUN Rscript -e 'install.packages("vscDebugger", repos = c("https://manuelhentschel.r-universe.dev", getOption("repos")))'

RUN echo "rstudio ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/rstudio \
    && chmod 0440 /etc/sudoers.d/rstudio

RUN echo "session-default-working-dir=/workspaces/rda" \
    >> /etc/rstudio/rsession.conf

WORKDIR /workspaces/rda



