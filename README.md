# docker-debian ![License badge][license-img] [![Build Status][build-img]][build-url] [![Docker badge][docker-img]][docker-url]

## Overview

Debian is a free operating system (OS) for your computer. An operating system is
the set of basic programs and utilities that make your computer run.

https://www.debian.org/

## Description

Use this script to build your own base system.

We've included the  last ca-certificates files in the repository  to ensure that
all of our images are accurates.

## Tags

Supported tags.

- 5, lenny
- 6, squeeze
- 7, wheezy, oldstable
- 8, jessie, stable, latest
- 9, stretch, testing
- sid

## Requirements

On Debian you need sudo permissions and the following packages:

```bash
$ sudo apt-get install debootstrap
```

On Ubuntu you need sudo permissions and the following packages:

```bash
$ sudo apt-get install debian-keyring debian-archive-keyring debootstrap
```

You also need to be in the docker group to use Docker.

```bash
$ sudo usermod -a -G docker USERNAME
```

Finally you need to login on Docker Hub.

```bash
$ docker login
```

## Usage

You first  need to choose which  dist between lenny, squeeze,  wheezy,jessie and
stretch you want  (jessie will be the  'latest' tag) and you need  to choose you
user (or organization) name on Docker Hub.

Show help.

```bash
$ ./build.sh -h
```

Build your own Debian image (eg. wheezy).

```bash
$ ./build.sh -d wheezy -u rockyluke
```

Build your own Debian image (eg. jessie) and push it on the Docker Hub.

```bash
$ ./build.sh -d jessie -u rockyluke -p
```

## Development

Feel free to contribute on GitHub.

```
    ╚⊙ ⊙╝
  ╚═(███)═╝
 ╚═(███)═╝
╚═(███)═╝
 ╚═(███)═╝
  ╚═(███)═╝
   ╚═(███)═╝
```

[license-img]: https://img.shields.io/badge/license-ISC-blue.svg
[build-img]: https://travis-ci.org/rockyluke/docker-debian.svg?branch=master
[build-url]: https://travis-ci.org/rockyluke/docker-debian
[docker-img]: https://img.shields.io/docker/pulls/rockyluke/debian.svg
[docker-url]: https://registry.hub.docker.com/u/rockyluke/debian
