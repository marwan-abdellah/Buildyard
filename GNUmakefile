#!gmake
.PHONY: debug release clean clobber package tests

ifeq ($(wildcard Makefile), Makefile)
all:
	@$(MAKE) -f Makefile $(MAKECMDGOALS)

clean:
	@$(MAKE) -f Makefile $(MAKECMDGOALS)

.DEFAULT:
	@$(MAKE) -f Makefile $(MAKECMDGOALS)

else

BUILD ?= Debug

normal: $(BUILD)/Makefile
	@$(MAKE) -C $(BUILD)

all: debug release
clean:
	@-$(MAKE) -C Debug clean cleans
	@-$(MAKE) -C Release clean cleans

packages: Release/Makefile
	@$(MAKE) -C Release packages

tests: $(BUILD)/Makefile
	@$(MAKE) -C $(BUILD) tests
endif

clobber:
	rm -rf Debug Release

debug: Debug/Makefile
	@$(MAKE) -C Debug

Debug/Makefile:
	@mkdir -p Debug
	@cd Debug; cmake .. -DCMAKE_BUILD_TYPE=Debug

release: Release/Makefile
	@$(MAKE) -C Release

Release/Makefile:
	@mkdir -p Release
	@cd Release; cmake .. -DCMAKE_BUILD_TYPE=Release

ifneq ($(wildcard Makefile), Makefile)

${BUILD}/projects.make: $(BUILD)/Makefile

include ${BUILD}/projects.make

.DEFAULT:
	@$(MAKE) $(BUILD)/Makefile
	@$(MAKE) -C $(BUILD) $(MAKECMDGOALS)
endif
