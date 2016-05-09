export GOPATH := $(shell pwd)
GRAFANA_PARENT := src/github.com/grafana
GRAFANA_SOURCE := ${GRAFANA_PARENT}/grafana

all: public vendor conf bin/grafana-server

v3.0-beta5.tar.gz:
	curl -LO https://github.com/grafana/grafana/archive/v3.0-beta5.tar.gz
	echo 'db9fcc0f4d90236d0cdaba2ab1ddd06bc59264aff93ead5c3a1b680804c8f8cd  v3.0-beta5.tar.gz' | shasum -a256

${GRAFANA_SOURCE}/build.go:	v3.0-beta5.tar.gz
	tar zxf $<
	mkdir -p ${GRAFANA_PARENT}
	mv grafana-3.0-beta5 ${GRAFANA_SOURCE}

bin/grafana-server:	${GRAFANA_SOURCE}/build.go
	cd ${GRAFANA_SOURCE} && go run build.go setup
	cd ${GRAFANA_SOURCE} && go run build.go build
	cd ${GRAFANA_SOURCE} && install bin/grafana-cli bin/grafana-server ${GOPATH}/bin

public:	bin/grafana-server
	cd ${GRAFANA_SOURCE} && npm install
	cd ${GRAFANA_SOURCE} && npm install grunt-cli
	cd ${GRAFANA_SOURCE} && node_modules/grunt-cli/bin/grunt build
	mv ${GRAFANA_SOURCE}/public_gen $@

vendor: public bin/grafana-server
	cp -r ${GRAFANA_SOURCE}/vendor vendor

conf:	vendor
	cp -r ${GRAFANA_SOURCE}/conf conf

.PHONY:	clean
clean:
	rm -rf pkg bin src v3.0-beta5.tar.gz public vendor conf
