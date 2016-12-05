#!/bin/bash

# Copyright (c) 2016, rockyluke
#
# Permission  to use,  copy, modify,  and/or  distribute this  software for  any
# purpose  with  or without  fee  is hereby  granted,  provided  that the  above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS"  AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO  THIS SOFTWARE INCLUDING  ALL IMPLIED WARRANTIES  OF MERCHANTABILITY
# AND FITNESS.  IN NO EVENT SHALL  THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR  CONSEQUENTIAL DAMAGES OR  ANY DAMAGES WHATSOEVER  RESULTING FROM
# LOSS OF USE, DATA OR PROFITS,  WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER  TORTIOUS ACTION,  ARISING  OUT OF  OR  IN CONNECTION  WITH  THE USE  OR
# PERFORMANCE OF THIS SOFTWARE.

arch='amd64'
oldstable='wheezy'
stable='jessie'
testing='stretch'
version='3.0'


if [ ! -x "$(command -v sudo)" ]
then
    echo "Please install sudo (see README.md)"
    exit 1
fi

if [ ! -x "$(command -v debootstrap)" ]
then
    echo "Please install debootstrap (see README.md)"
    exit 1
fi

function usage()
{
    cat <<EOF

NAME:
   build.sh - Docker images and builders of Debian.

USAGE:
   build.sh -d <dist>

OPTIONS:
   -h, --help           Show help
   -d, --dist		Choose debian distribution (lenny, squeeze, wheezy, jessie, stretch, sid)
   -m, --mirror		Choose your preferred mirror (default: ftp.debian.org)
   -t, --timezone       Choose your preferred timezone (default: Europe/Amsterdam)
   -u, --user		Docker Hub username (or organisation)
   -p, --push		Docker Hub push
   -l, --latest         Force the "latest" (default: jessie)
   -v, --version        Show version

VERSION:
   docker-debian version: ${version}

EOF
} # usage

function docker_debootstrap()
{
    # variables
    image="/tmp/image-${distname}-${arch}"
    include="apt-transport-https,apt-utils,ca-certificates,curl,git,locales"
    exclude="debconf-i18n,dmsetup,git-man,info,man-db,manpages"
    components='main contrib non-free'

    if [ "$(id -u)" -ne 0 ]
    then
	sudo='sudo'
    fi

    # clean old image
    ${sudo} rm -fr "${image}"

    # create minimal debootstrap image
    echo "-- debootstrap ${distname}"
    ${sudo} debootstrap \
	    --arch="${arch}" \
	    --include="${include}" \
	    --exclude="${exclude}" \
	    --variant=minbase \
	    "${distname}" \
	    "${image}" \
	    "http://${mirror}/debian" > /dev/null

    # create /etc/default/locale
    echo ' * /etc/default/locale'
    cat <<EOF | ${sudo} tee "${image}/etc/default/locale" > /dev/null
LANG=C
LANGUAGE=C
LC_COLLATE=C
LC_ALL=C
EOF

    # create /etc/timezone
    echo ' * /etc/timezone'
    cat <<EOF | ${sudo} tee "${image}/etc/timezone" > /dev/null
${timezone}
EOF

    # create /etc/resolv.conf
    echo ' * /etc/resolv.conf'
    cat <<EOF | ${sudo} tee "${image}/etc/resolv.conf" > /dev/null
nameserver 8.8.4.4
nameserver 8.8.8.8
EOF

    if [ "${distname}" = 'lenny' ]
    then

	# create /etc/apt/sources.list
	echo ' * /etc/apt/sources.list'
	cat <<EOF | ${sudo} tee "${image}/etc/apt/sources.list" > /dev/null
deb http://archive.debian.org/debian lenny main contrib non-free
deb http://archive.debian.org/debian-backports lenny-backports main contrib non-free
EOF

	# create /etc/apt/apt.conf.d/90ignore-release-date
	# thanks to http://stackoverflow.com/questions/36080756/archive-repository-for-debian-squeeze
	echo ' * /etc/apt/apt.conf.d/ignore-release-date'
	cat <<EOF | ${sudo} tee "${image}/etc/apt/apt.conf.d/ignore-release-date" > /dev/null
Acquire::Check-Valid-Until "false";
EOF

    elif [ "${distname}" = 'squeeze' ]
    then

	# create /etc/apt/sources.list
	echo ' * /etc/apt/sources.list'
	cat <<EOF | ${sudo} tee "${image}/etc/apt/sources.list" > /dev/null
deb http://archive.debian.org/debian squeeze main contrib non-free
deb http://archive.debian.org/debian squeeze-lts main contrib non-free
deb http://archive.debian.org/debian-backports squeeze-backports main contrib non-free
deb http://archive.debian.org/debian-backports squeeze-backports-sloppy main contrib non-free
EOF

	# create /etc/apt/apt.conf.d/90ignore-release-date
	# thanks to http://stackoverflow.com/questions/36080756/archive-repository-for-debian-squeeze
	echo ' * /etc/apt/apt.conf.d/ignore-release-date'
	cat <<EOF | ${sudo} tee "${image}/etc/apt/apt.conf.d/ignore-release-date" > /dev/null
Acquire::Check-Valid-Until "false";
EOF

    else

	# create /etc/apt/sources.list
	echo ' * /etc/apt/sources.list'
	cat <<EOF | ${sudo} tee "${image}/etc/apt/sources.list" > /dev/null
deb http://${mirror}/debian ${distname} ${components}
deb http://${mirror}/debian ${distname}-updates ${components}
EOF

	# create /etc/apt/sources.list.d/backports.list
	echo ' * /etc/apt/sources.list.d/backports.list'
	cat <<EOF | ${sudo} tee "${image}/etc/apt/sources.list.d/backports.list" > /dev/null
deb http://${mirror}/debian ${distname}-backports ${components}
EOF

	# create /etc/apt/sources.list.d/security.list
	echo ' * /etc/apt/sources.list.d/security.list'
	cat <<EOF | ${sudo} tee "${image}/etc/apt/sources.list.d/security.list"  > /dev/null
deb http://security.debian.org/ ${distname}/updates ${components}
EOF

	# create /etc/dpkg/dpkg.cfg.d/disable-doc
	# thanks to http://askubuntu.com/questions/129566/remove-documentation-to-save-hard-drive-space
	cat <<EOF | ${sudo} tee "${image}/etc/dpkg/dpkg.cfg.d/disable-doc" > /dev/null
path-exclude /usr/share/doc/*
path-include /usr/share/doc/*/copyright
path-exclude /usr/share/info/*
path-exclude /usr/share/man/*
EOF

    fi

    # create /etc/apt/apt.conf.d/force-ipv4
    # thanks to https://github.com/cw-ansible/cw.apt/
    echo ' * /etc/apt/apt.conf.d/force-ipv4'
    cat <<EOF | ${sudo} tee "${image}/etc/apt/apt.conf.d/force-ipv4" > /dev/null
Acquire::ForceIPv4 "true";
EOF

    # create /etc/apt/apt.conf.d/disable-auto-install
    # thanks to https://github.com/cw-ansible/cw.apt/
    echo ' * /etc/apt/apt.conf.d/disable-auto-install'
    cat <<EOF | ${sudo} tee "${image}/etc/apt/apt.conf.d/disable-auto-install" > /dev/null
APT::Install-Recommends "0";
APT::Install-Suggests "0";
EOF

    # create /etc/apt/apt.conf.d/disable-cache
    # thanks to https://github.com/docker/docker/blob/master/contrib/mkimage-debootstrap.sh
    echo ' * /etc/apt/apt.conf.d/disable-cache'
    cat <<EOF | ${sudo} tee "${image}/etc/apt/apt.conf.d/disable-cache" > /dev/null
Dir::Cache::pkgcache "";
Dir::Cache::srcpkgcache "";
EOF

    # create /etc/apt/apt.conf.d/force-conf
    # thanks to https://raphaelhertzog.com/2010/09/21/debian-conffile-configuration-file-managed-by-dpkg/
    echo ' * /etc/apt/apt.conf.d/force-conf'
    cat <<EOF | ${sudo} tee "${image}/etc/apt/apt.conf.d/force-conf" > /dev/null
Dpkg::Options {
   "--force-confnew";
   "--force-confmiss";
}
EOF

    # create /etc/apt/apt.conf.d/disable-languages
    # tahnks to https://github.com/docker/docker/blob/master/contrib/mkimage-debootstrap.sh
    echo ' * /etc/apt/apt.conf.d/disable-languages'
    cat <<EOF | ${sudo} tee "${image}/etc/apt/apt.conf.d/disable-languages" > /dev/null
Acquire::Languages "none";
EOF

    # create /usr/bin/apt-clean
    echo ' * /usr/bin/apt-clean'
    cat <<EOF | ${sudo} tee "${image}/usr/bin/apt-clean" > /dev/null
#!/bin/bash

# Copyright (c) 2016, rockyluke
#
# Permission  to use,  copy, modify,  and/or  distribute this  software for  any
# purpose  with  or without  fee  is hereby  granted,  provided  that the  above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS"  AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO  THIS SOFTWARE INCLUDING  ALL IMPLIED WARRANTIES  OF MERCHANTABILITY
# AND FITNESS.  IN NO EVENT SHALL  THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR  CONSEQUENTIAL DAMAGES OR  ANY DAMAGES WHATSOEVER  RESULTING FROM
# LOSS OF USE, DATA OR PROFITS,  WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER  TORTIOUS ACTION,  ARISING  OUT OF  OR  IN CONNECTION  WITH  THE USE  OR
# PERFORMANCE OF THIS SOFTWARE.

# Please read https://wiki.debian.org/ReduceDebian

find /usr/share/doc     -type f ! -name copyright -delete
find /usr/share/i18n    -type f -delete
find /usr/share/locale  -type f -delete
find /usr/share/man     -type f -delete
find /var/cache/apt     -type f -delete
find /var/lib/apt/lists -type f -delete
EOF
    ${sudo} chmod 755 "${image}/usr/bin/apt-clean"

    # mount
    ${sudo} mount --bind /dev     "${image}/dev"
    ${sudo} mount --bind /dev/pts "${image}/dev/pts"
    ${sudo} mount --bind /proc    "${image}/proc"
    ${sudo} mount --bind /sys     "${image}/sys"

    # update root certificates
    ${sudo} mkdir -p "${image}/usr/local/share/"
    ${sudo} cp -r ca-certificates "${image}/usr/local/share/"

    # upgrade
    echo ' * apt-get upgrade'
    ${sudo} chroot "${image}" bash -c \
	    "export DEBIAN_FRONTEND=noninteractive && \
             export LC_ALL=C && \
             update-ca-certificates -f && \
	     apt-get update -qq && \
             apt-get upgrade -qq -y && \
             apt-get dist-upgrade -qq -y && \
             apt-get clean -qq -y && \
             apt-get autoremove -qq -y && \
             apt-get autoclean -qq -y" > /dev/null

    # unmount
    ${sudo} umount "${image}/dev/pts"
    ${sudo} umount "${image}/dev"
    ${sudo} umount "${image}/proc"
    ${sudo} umount "${image}/sys"

    # clean
    ${sudo} find   "${image}/usr/share/doc"     -type f ! -name copyright -delete
    ${sudo} find   "${image}/usr/share/i18n"    -type f -delete
    ${sudo} find   "${image}/usr/share/locale"  -type f -delete
    ${sudo} find   "${image}/usr/share/man"     -type f -delete
    ${sudo} find   "${image}/var/cache/apt"     -type f -delete
    ${sudo} find   "${image}/var/lib/apt/lists" -type f -delete

    # create archive
    if [ -f "${image}.tar" ]
    then
	${sudo} rm "${image}.tar"
    fi
    ${sudo} tar --numeric-owner -cf "${image}.tar" -C "${image}" .
} # docker_debootstrap

function docker_import()
{
    # create image
    echo "-- docker import debian:${distname} (from ${image}.tgz)"
    docker import "${image}.tar" "${user}/debian:${distname}"
    docker run "${user}/debian:${distname}" echo "Successfully build ${user}/debian:${distname}"
    docker tag "${user}/debian:${distname}" "${user}/debian:${distid}"
    docker run "${user}/debian:${distid}" echo "Successfully build ${user}/debian:${distid}"

    # tag {latest,stable,oldstable}
    for import in latest oldstable stable testing
    do
	if [ "${distname}" = "${!import}" ]
	then
	    docker tag "${user}/debian:${distname}" "${user}/debian:${import}"
	    docker run "${user}/debian:${distid}" echo "Successfully build ${user}/debian:${import}"
	fi
    done
} # docker_import

function docker_push()
{
    # push image
    echo "-- docker push debian:${distname}"
    docker push "${user}/debian:${distname}"

    echo "-- docker push debian:${distid}"
    docker push "${user}/debian:${distid}"

    # push {latest,stable,oldstable}
    for push in latest oldstable stable testing
    do
	if [ "${distname}" = "${!push}"  ]
	then
	    echo "-- docker push ${push}"
	    docker push "${user}/debian:${push}"
	fi
    done
} # docker_push

while getopts 'hd:m:t:u:plv' OPTIONS
do
    case ${OPTIONS} in
	h)
	    # -h / --help
	    usage
	    exit 0
	    ;;
	d)
	    # -d / --dist
	    dist=${OPTARG}
	    ;;
	m)
	    # -m / --mirror
	    mirror=${OPTARG}
	    ;;
	t)
	    # -t / --timezone
	    timezone=${OPTARG}
	    ;;
	u)
	    # -u / --user
	    user=${OPTARG}
	    ;;
	p)
	    # -p / --push
	    push='true'
	    ;;
	l)
	    # -l / --latest
	    latest=${OPTARG}
	    ;;
	v)
	    # -v / --version
	    echo "${version}"
	    exit 0
	    ;;
	*)
	    usage
	    exit 1
	    ;;
    esac
done

# -d / --dist
if [ -n "${dist}" ]
then
    case ${dist} in
	lenny|5|5.0)
	    distname='lenny'
	    distid='5'
	    mirror='archive.debian.org'
	    ;;
	squeeze|6|6.0)
	    distname='squeeze'
	    distid='6'
	    mirror='archive.debian.org'
	    ;;
	wheezy|7|7.0)
	    distname='wheezy'
	    distid='7'
	    ;;
	jessie|8|8.0)
	    distname='jessie'
	    distid='8'
	    ;;
	stretch|9|9.0)
	    distname='stretch'
	    distid='9'
	    ;;
	sid)
	    distname='sid'
	    distid='sid'
	    ;;
	*)
	    usage
	    exit 1
	    ;;
    esac
else
    usage
    exit 1
fi

# -m / --mirror
if [ -z "${mirror}" ]
then
    mirror='ftp.debian.org'
fi

# -t / --timezone
if [ -z "${timezone}" ]
then
    timezone='Europe/Amsterdam'
fi

# -u / --user
if [ -z "${user}" ]
then
    user='rockyluke'
fi

# -l / --latest
if [ -z "${latest}" ]
then
    latest='jessie'
fi

# create image
docker_debootstrap

# import image
docker_import

# push image
if [ -n "${push}" ]
then
    docker_push
fi
# EOF
