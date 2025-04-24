.PHONY: all frr-debian frr-ubuntu-ng influxdb

all: frr-debian frr-ubuntu-ng influxdb

frr-debian:
	$(MAKE) -C frr-debian

frr-ubuntu-ng:
	$(MAKE) -C frr-ubuntu-ng

influxdb:
	$(MAKE) -C influxdb
