export GOPATH := $(shell pwd)
GRAFANA_PARENT := src/github.com/grafana
GRAFANA_SOURCE := ${GRAFANA_PARENT}/grafana
GRAFANA_VERSION := 4.1.1
GRAFANA_TAR_SHA256 = 34ecd6c7d3e30b7b0eecf78f57383ad3b4754f5da9da77f031ca4b5866fe9893

all: public vendor conf bin/grafana-server grafana-dashboards

grafana.tar.gz:
	curl -L https://github.com/grafana/grafana/archive/v${GRAFANA_VERSION}.tar.gz > $@

${GRAFANA_SOURCE}/build.go:	grafana.tar.gz
	echo "{GRAFANA_TAR_SHA256}  grafana.tar.gz" | shasum -a256
	tar zxf $<
	mkdir -p ${GRAFANA_PARENT}
	mv grafana-${GRAFANA_VERSION} ${GRAFANA_SOURCE}
	touch $@

bin/grafana-server:	${GRAFANA_SOURCE}/build.go
	cd ${GRAFANA_SOURCE} && go run build.go setup
	cd ${GRAFANA_SOURCE} && go run build.go build
	cd ${GRAFANA_SOURCE} && install bin/grafana-cli bin/grafana-server ${GOPATH}/bin

public:	bin/grafana-server
	cd ${GRAFANA_SOURCE} && npm install
	cd ${GRAFANA_SOURCE} && npm install grunt-cli
	cd ${GRAFANA_SOURCE} && node_modules/grunt-cli/bin/grunt build --force
	mv ${GRAFANA_SOURCE}/public_gen $@

vendor: public
	cp -r ${GRAFANA_SOURCE}/vendor vendor

conf:	public
	cp -r ${GRAFANA_SOURCE}/conf conf

grafana-dashboards:
	git clone https://gitlab.com/gitlab-org/grafana-dashboards.git

.PHONY:	clean
clean:
	rm -rf pkg bin src grafana.tar.gz public vendor conf grafana-dashboards
