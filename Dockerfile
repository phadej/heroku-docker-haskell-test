FROM heroku/cedar:14

# Dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bzip2 \
    ca-certificates \
    curl \
    gcc \
    libc6-dev \
    libgmp-dev \
    libgmp10 \
    make \
    patch \
    zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*

# GHC
RUN mkdir -p /usr/src/ghc
WORKDIR /usr/src/ghc

RUN curl --silent -O https://downloads.haskell.org/~ghc/7.10.1/ghc-7.10.1-x86_64-unknown-linux-deb7.tar.bz2 \
  && echo '3f513c023dc644220ceaba15e5a5089516968b6553b5227e402f079178acba0a  ghc-7.10.1-x86_64-unknown-linux-deb7.tar.bz2' | sha256sum -c - \
  && tar --strip-components=1 -xjf ghc-7.10.1-x86_64-unknown-linux-deb7.tar.bz2 \
  && rm ghc-7.10.1-x86_64-unknown-linux-deb7.tar.bz2 \
  && ./configure --prefix=/opt/ghc \
  && make install \
  && rm -rf /usr/src/ghc \
  && /opt/ghc/bin/ghc --version

ENV PATH /opt/ghc/bin:$PATH

# Cabal
RUN mkdir -p /usr/src/cabal
WORKDIR /usr/src/cabal

RUN curl --silent -O https://www.haskell.org/cabal/release/cabal-install-1.22.2.0/cabal-install-1.22.2.0.tar.gz \
  && echo '25bc2ea88f60bd0f19bf40984ea85491461973895480b8633d87f54aa7ae6adb  cabal-install-1.22.2.0.tar.gz' | sha256sum -c - \
  && tar --strip-component=1 -xzf cabal-install-1.22.2.0.tar.gz \
  && rm cabal-install-1.22.2.0.tar.gz \
  && /usr/src/cabal/bootstrap.sh \
  && cp /root/.cabal/bin/cabal /opt/ghc/bin \
  && for pkg in `ghc-pkg --user list  --simple-output`; do ghc-pkg unregister --force $pkg; done \
  && rm -rf /root/.cabal \
  && rm -rf /usr/src/cabal \
  && cabal --version

# Create app user, required? by Heroku
RUN useradd -d /app -m app
USER app
WORKDIR /app

ENV HOME /app
ENV PORT 3000

RUN cabal update && cabal install 'warp >=3.0' 'wai-app-static >=3.0' 'waitra >=0.0.3'

# Build the app
ONBUILD COPY . /app/src

ONBUILD USER root
ONBUILD RUN chown -R app /app/src
ONBUILD USER app

ONBUILD WORKDIR /app/src
ONBUILD RUN cabal update
ONBUILD RUN cabal install

ONBUILD RUN mkdir -p /app/target && cp $HOME/.cabal/bin/heroku-docker-haskell-test /app/target/heroku-docker-haskell-test

# Cleanup to make slug smaller
ONBUILD RUN rm -rf /app/src /app/.cabal /app/.ghc

ONBUILD EXPOSE 3000
