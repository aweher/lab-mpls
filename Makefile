.PHONY: all frr-debian frr-ubuntu

all: frr-debian frr-ubuntu

frr-debian:
	$(MAKE) -C frr-debian

frr-ubuntu:
	$(MAKE) -C frr-ubuntu