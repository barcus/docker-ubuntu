# docker-ubuntu ![License badge][license-img] [![Build Status][build-img]][build-url] [![Docker badge][docker-img]][docker-url]

## Overview

Ubuntu  is a  Debian-based free  operating system  (OS) for  your computer.   An
operating  system is  the set  of basic  programs and  utilities that  make your
computer run.

https://www.ubuntu.com/

## Description

Use this script to build your own base system.

We've included the  last ca-certificates files in the repository  to ensure that
all of our images are accurates.

## Tags

Supported tags.

- 12.04, precise
- 14.04, trusty
- 16.04, xenial
- 16.10, yakkety

## Requirements

On Debian you need sudo permissions and the following packages:

```bash
# if you build on wheezy please use backports version of debootstrap
$ sudo apt-get install debootstrap ubuntu-archive-keyring
```

On Ubuntu you need sudo permissions and the following packages:

```bash
$ sudo apt-get install debootstrap
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

You first  need to choose  which dist  between precise (12.04),  trusty (14.04),
xenial (16.04) and  yakkety (16.10) you want (yakkety will  be the 'latest' tag)
and you need to choose you user (or organization) name on Docker Hub.

Show help.

```bash
$ ./build.sh -h
```

Build your own Ubuntu image (eg. trusty).

```bash
$ ./build.sh -d trusty -u rockyluke
```

Build your own Ubuntu image (eg. xenial) and push it on the Docker Hub.

```bash
$ ./build.sh -d xenial -u rockyluke -p
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
[build-img]: https://travis-ci.org/rockyluke/docker-ubuntu.svg?branch=master
[build-url]: https://travis-ci.org/rockyluke/docker-ubuntu
[docker-img]: https://img.shields.io/docker/pulls/rockyluke/ubuntu.svg
[docker-url]: https://registry.hub.docker.com/u/rockyluke/ubuntu
