export GOPATH := $(shell pwd)
INFLUXDB_PARENT := src/github.com/influxdata
INFLUXDB_SOURCE := ${INFLUXDB_PARENT}/influxdb
VERSION = 0.12.2
ARCHIVE = v${VERSION}.tar.gz
ARCHIVE_SHA256 = fb2f918794db07c2a05388fd583591bb3084b2af37a64e98be4b4c73302a8742

all: bin/influxd influxdb-management/.bundle-done

${ARCHIVE}:
	curl -LO https://github.com/influxdata/influxdb/archive/$@
	echo "${ARCHIVE_SHA256}  $@" | shasum -a256 -c

${INFLUXDB_SOURCE}/Godeps:	${ARCHIVE}
	tar zxf $<
	mkdir -p ${INFLUXDB_PARENT}
	mv influxdb-${VERSION} ${INFLUXDB_SOURCE}
	touch $@

bin/gdm:
	go get github.com/sparrc/gdm

bin/influxd: bin/gdm ${INFLUXDB_SOURCE}/Godeps
	cd ${INFLUXDB_SOURCE} && ${GOPATH}/bin/gdm restore
	cd ${INFLUXDB_SOURCE} && go install ./...

influxdb-management/.bundle-done: influxdb-management
	cd influxdb-management && bundle install
	touch $@

influxdb-management:
	git clone https://gitlab.com/gitlab-org/influxdb-management.git

.PHONY:	clean
clean:
	rm -rf bin pkg src ${ARCHIVE} influxdb-management
