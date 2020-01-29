# dimg

A simple BASH script for building, publishing, and running Docker containers. The `dimg` script uses a self-describing YAML file, the `container.yaml`, to help flesh out the execution of `docker` from a single source of information.

## Installing

Just put the `dimg` script in your path. Nothing fancy.

## The container.yaml file and Dockerfile

The `dimg` script is ideal for quickly prototyping docker containers locally with a parameterized `Dockerfile` and a simple `container.yaml` file.

The `container.yaml` file might look something like this:

```
repository: jvanzyl
image: concord-alpine
version: 0.0.4
buildArgs:
  user: concord
  uid: 456
  group: concord
  gid: 456
run:
  shell: /bin/sh
  mounts:
    tmp: "/tmp:/tmp"
```  


And the `Dockerfile` might looks something like this:

```
FROM alpine:3.9.4
MAINTAINER "Jason van Zyl" <jason@vanzyl.ca>

ARG user
ARG uid
ARG group
ARG gid

RUN addgroup -g ${gid} ${group}
RUN adduser -D ${user} -u ${uid} -G ${group}

# We need the standard certs in order to connect over TLS with the world
RUN apk update
RUN apk add ca-certificates
RUN rm -rf /var/cache/apk/*

# Setup the path to include the new binaries we have mounted in the workspace
ENV PATH="/workspace/concord/bin:${PATH}"

USER ${user}
```

As you might gather from the structure of the files, the parameters specified in the `container.yaml` are made available to the `Dockerfile` by being fed into the `docker` command.

## Available options

```
bash-3.2$ dimg -h
dimg [OPTIONS...]
-h, --help          Show help
-f, --file          Use the specified container yaml file (default: container.yaml)
-s, --show          Show variables to be used for docker image
-b, --build         Build docker image (default if no other command specified)
-p, --publish       Publish docker image
-r, --run           Run docker image
-rs, --shell        Run docker image with shell
-d, --delete        Delete docker image
-t, --test          Test mode: Only display the command that will be executed
```

The most convenient way to see what command will be executed, without the command actually being executed, is by using the `--test` option. If you wanted to see what configuration and `docker` command will be generated for publishing you would do the following:

```
bash-3.2$ dimg --test --publish

repository: jvanzyl
image: concord-alpine
version: 0.0.4

Build-args:
  gid: 456
  group: concord
  uid: 456
  user: concord

docker push jvanzyl/concord-alpine:latest
docker push jvanzyl/concord-alpine:0.0.4
```

This will display the command that will push the container image to the specified repository with the `latest` tag and the `version` tag specified in the `container.yaml`.

### Building

Build a docker image using a `Dockerfile` and `container.yaml` file in the current directory:

`dimg`

Build a docker image using a `Dockerfile` and a customer `custom-container.yaml` file in the current directory:

`dimg -f custom-container.yaml`

### Publishing

Publish a docker image using a `Dockerfile` and `container.yaml` file in the current directory:

`dimg -p`

### Running

Run a docker image using a `Dockerfile` and `container.yaml` file in the current directory:

`dimg -r`

Also note that the mounts you have specified in your `container.yaml` file will be mounted into the container. So in our example above the local `/tmp` directory will be mounted into the container at `/tmp`.


### Running with a shell

Often you will want to just shell into a container to see if the structure is as you expect or you're debugging something. Note that the shell specified in your `container.yaml` is the shell started up when you run the container. Note that the mounts specified are handled the same way as above.

`dimg -rs`


## Support for Maven POMs

If you normally use a Maven project for building your docker containers but want to use `dimg` for hacking around, you cna have the version extracted from the `pom.xml` file in the local directory using `{{maven.version}}` in your `container.yaml` file. So you may have a `pom.xml` file like the following:

```
<project>
  <modelVersion>4.0.0</modelVersion>
  <groupId>ca.vanzyl</groupId>
  <artifactId>concord-alpine</artifactId>
  <version>1.0.0</version>
</project>
```

And a `container.yaml` like the following:

```
repository: jvanzyl
image: concord-alpine
version: {{maven.version}}
buildArgs:
  user: concord
  uid: 456
  group: concord
  gid: 456
run:
  shell: /bin/sh
```

If you run `dimg -p -t` you will see the following:

```
repository: jvanzyl
image: concord-alpine
version: 1.0.0

Build-args:
  gid: 456
  group: concord
  uid: 456
  user: concord

docker push jvanzyl/concord-alpine:latest
docker push jvanzyl/concord-alpine:1.0.0
```

Where the version has been extracted from the `pom.xml` file.

NOTE: The Maven project version is extracted using [mpv](https://github.com/jvanzyl/mpv).


## Running Tests

If you want run the tests you need to install [BATS](https://github.com/bats-core/bats-core). BATS is a testing tool for BASH scripts/functions.

Running the tests should produce something like the following:

```
bash-3.2$ ./dimg-tests-runner
 ✓ Display help for the dimg command
 ✓ Show the variables that will be used to build the container
 ✓ Build docker container using container.yaml
 ✓ Publish docker container using container.yaml
 ✓ Run docker container using container.yaml
 ✓ Run docker container using container-with-ports.yaml
 ✓ Run docker container using container-with-network.yaml
 ✓ Run docker container using container-with-host.yaml
 ✓ Run docker container with shell using container.yaml
 ✓ Delete docker container using container.yaml
 ✓ Push docker container using container-with-registry.yaml
 ✓ Publish docker container using container-with-maven-version.yaml

12 tests, 0 failures
```
