SWIFT_SOURCES := main.swift

all: a.out cas-config

include Makefile.rules

cas-config:
	echo "{\"CASPath\": \"$(BUILDDIR)/cas\"}" > .cas-config
