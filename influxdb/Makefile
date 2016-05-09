export GOPATH := $(shell pwd)
INFLUXDB_PARENT := src/github.com/influxdata
INFLUXDB_SOURCE := ${INFLUXDB_PARENT}/influxdb

all: bin/influxd

v0.12.2.zip:
	curl -LO https://github.com/influxdata/influxdb/archive/v0.12.2.zip

src/github.com/influxdata/influxdb:	v0.12.2.zip
	unzip -q $<
	mkdir -p ${INFLUXDB_PARENT}
	mv influxdb-0.12.2 ${INFLUXDB_SOURCE}

bin/gdm:
	go get github.com/sparrc/gdm

bin/influxd: bin/gdm ${INFLUXDB_SOURCE}
	cd ${INFLUXDB_SOURCE} && ${GOPATH}/bin/gdm restore
	cd ${INFLUXDB_SOURCE} && go install ./...

.PHONY:	clean
clean:
	rm -rf bin pkg src
