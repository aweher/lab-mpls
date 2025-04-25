.PHONY: all frr-debian frr-ubuntu influxdb

all: frr-debian frr-ubuntu influxdb

frr-debian:
	$(MAKE) -C frr-debian

frr-ubuntu:
	$(MAKE) -C frr-ubuntu

influxdb:
	$(MAKE) -C influxdb
