# Heroku + Docker + Haskell = ?

This experiment is triggered by many things:
- I like Haskell
- I like docker too
- And I like how easy is Heroku
- [Haskell Web Server in a 5MB Docker image](https://www.fpcomplete.com/blog/2015/05/haskell-web-server-in-5mb)
- [Introducing 'heroku docker:release': Build &amp; Deploy Heroku Apps with Docker](https://blog.heroku.com/archives/2015/5/5/introducing_heroku_docker_release_build_deploy_heroku_apps_with_docker)

[evening-earth-1057.herokuapp.com](https://evening-earth-1057.herokuapp.com/) - Working example.

## Starting point

Deploying Haskell to heroku isn't simple, there are different buildpacks:
- [Official based on Halcyon](https://github.com/mietek/haskell-on-heroku)
- and [heroku-buildpack-ghc](https://github.com/begriffs/heroku-buildpack-ghc)

With both buildpacks, and Heroku overall, I don't like that building happens in the cloud.
A bit like in the *AWS ELB* blog post, I'd rather build app locally (or on CI machine, or in *build* cloud), and deploy artifacts to Heroku.

There are two approaches!

## inline-build-pack

Using [inline-build-pack](https://github.com/kr/heroku-buildpack-inline), we can build our app locally, bundle artifacts, and push to Heroku.
All three scripts: [`detect`](https://github.com/phadej/heroku-docker-haskell-test/blob/master/bin/detect), [`release`](https://github.com/phadej/heroku-docker-haskell-test/blob/master/bin/release), and [`compile`](https://github.com/phadej/heroku-docker-haskell-test/blob/master/bin/compile) turn out to be no-op.
Looks like that on [cedar14](https://devcenter.heroku.com/articles/cedar-14-migration)
stack, there is `libgmp.so.10`, so we don't need to bundle it anymore, as `heroku-buildpack-ghc` does.
Turns out that [null-buildpack](https://github.com/ryandotsmith/null-buildpack) could be enough too.

Still one problem still exist: how to build a heroku-runnable binary executable on e.g. OSX? Here the docker comes to help!
Using two simple scripts: [`prebuild`](https://github.com/phadej/heroku-docker-haskell-test/blob/master/bin/prebuild) and [`compilewithdocker`](https://github.com/phadej/heroku-docker-haskell-test/blob/master/bin/compilewithdocker) we produce needed executable.

But committing artifacts to the repository is highly unelegant!

## Using heroku docker

We can build an own [`Dockerfile`](https://github.com/phadej/heroku-docker-haskell-test/blob/master/Dockerfile) to build the Haskell binaries. It's actually quite easy.
Unfortunately (maybe for good) Dockerfiles doesn't support multi-inheritance, so we need to install GHC manually.
Fortunately I have previously done [docker ghc image](https://github.com/phadej/docker-ghc), so we can just copy paste GHC installing spells.
After that we install few dependencies&dagger; so we don't need to rebuild everything when deploying.
And finally we build our application and leave it in `/app` directory which is then picked up by heroku deployment.

The first build takes time as then the build image is built, it took about 15 minutes on my machine.
The `heroku docker:release` takes under one minute.

## Conclusion

Using docker deployment you can tweak the build process, which is a huge win.
Heroku infrastructure makes the other parts of deployment process and devops easy too.
The only negative aspect, *with greater power comes greater responsibility*, you can *accidentally* deploy uncommited changes.

---

## Remarks

- &dagger; we could add cabal file to docker and install exact dependencies
- there is [`.dockerignore`](https://github.com/phadej/heroku-docker-haskell-test/blob/master/.dockerignore) to ignore host cabal sandbox one uses for development
- This approach could be used to deploy scala (which takes enormous time to build e.g. play2 app), or to make Clojure deploy using uberjar.
