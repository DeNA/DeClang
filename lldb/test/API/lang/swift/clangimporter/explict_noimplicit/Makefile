SWIFT_SOURCES := main.swift
SWIFTFLAGS_EXTRAS := -I.
LD_EXTRAS = -L$(BUILDDIR) -lDylib

all: libDylib a.out

include Makefile.rules

# Note that this is being built with implicit modules!
libDylib: Dylib.swift
	$(call MKDIR_P,$(BUILDDIR)/$(shell basename $< .swift))
	"$(MAKE)" MAKE_DSYM=YES CC=$(CC) SWIFTC=$(SWIFTC) \
		ARCH=$(ARCH) DSYMUTIL=$(DSYMUTIL) \
		SWIFT_ENABLE_EXPLICIT_MODULES=NO \
		DYLIB_NAME=Dylib DYLIB_SWIFT_SOURCES=Dylib.swift \
		VPATH=$(SRCDIR) SWIFTFLAGS_EXTRAS=-I$(SRCDIR) \
		-f $(MAKEFILE_RULES) all
