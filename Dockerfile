FROM heroku/cedar:14

ENV GHCVER 7.8.4
ENV CABALVER 1.18

RUN apt-get update && apt-get install -y --no-install-recommends software-properties-common \
  && add-apt-repository -y ppa:hvr/ghc \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    cabal-install-$CABALVER \
    ghc-$GHCVER \
  && rm -rf /var/lib/apt/lists/*

ENV PATH /opt/ghc/$GHCVER/bin:/opt/cabal/$CABALVER/bin:$PATH

# Create app user, required? by Heroku
RUN useradd -d /app -m app
USER app
WORKDIR /app

ENV HOME /app
ENV PORT 3000

RUN cabal update
RUN cabal install 'stackage-update ==0.1.1.1'
ENV PATH $HOME/.cabal/bin:$PATH
RUN stackage-update

RUN cabal install 'warp >=3.0' 'wai-app-static >=3.0' 'waitra >=0.0.3'

# Build the app
ONBUILD COPY . /app/src

ONBUILD USER root
ONBUILD RUN chown -R app /app/src
ONBUILD USER app

ONBUILD WORKDIR /app/src
ONBUILD RUN stackage-update
ONBUILD RUN cabal install

ONBUILD RUN mkdir -p /app/target && cp $HOME/.cabal/bin/heroku-docker-haskell-test /app/target/heroku-docker-haskell-test

# Cleanup to make slug smaller
ONBUILD RUN rm -rf /app/src /app/.cabal /app/.ghc

ONBUILD EXPOSE 3000
