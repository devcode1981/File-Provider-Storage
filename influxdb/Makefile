export GOPATH := $(shell pwd)
INFLUXDB_PARENT := src/github.com/influxdata
INFLUXDB_SOURCE := ${INFLUXDB_PARENT}/influxdb

all: bin/influxd

v0.12.2.tar.gz:
	curl -LO https://github.com/influxdata/influxdb/archive/v0.12.2.tar.gz
	echo 'fb2f918794db07c2a05388fd583591bb3084b2af37a64e98be4b4c73302a8742  v0.12.2.tar.gz' | shasum -a256

${INFLUXDB_SOURCE}/Godeps:	v0.12.2.tar.gz
	tar zxf $<
	mkdir -p ${INFLUXDB_PARENT}
	mv influxdb-0.12.2 ${INFLUXDB_SOURCE}
	touch $@

bin/gdm:
	go get github.com/sparrc/gdm

bin/influxd: bin/gdm ${INFLUXDB_SOURCE}/Godeps
	cd ${INFLUXDB_SOURCE} && ${GOPATH}/bin/gdm restore
	cd ${INFLUXDB_SOURCE} && go install ./...

.PHONY:	clean
clean:
	rm -rf bin pkg src v0.12.2.tar.gz
