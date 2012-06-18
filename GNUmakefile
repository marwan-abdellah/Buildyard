#!gmake
.PHONY: debug release clean clobber package tests

MYMAKE=${MAKE} --no-print-directory

ifeq ($(wildcard Makefile), Makefile)
all:
	@$(MYMAKE) -f Makefile $(MAKECMDGOALS)

clean:
	@$(MYMAKE) -f Makefile $(MAKECMDGOALS)

.DEFAULT:
	@$(MYMAKE) -f Makefile $(MAKECMDGOALS)

else

BUILD ?= Debug

normal: $(BUILD)/Makefile
	@$(MYMAKE) -C $(BUILD)

all: debug release
clean:
	@-$(MYMAKE) -C Debug clean cleans
	@-$(MYMAKE) -C Release clean cleans

packages: Release/Makefile
	@$(MYMAKE) -C Release packages

tests: $(BUILD)/Makefile
	@$(MYMAKE) -C $(BUILD) tests
endif

clobber:
	rm -rf Debug Release

debug: Debug/Makefile
	@$(MYMAKE) -C Debug

Debug/Makefile:
	@mkdir -p Debug
	@cd Debug; cmake .. -DCMAKE_BUILD_TYPE=Debug

release: Release/Makefile
	@$(MYMAKE) -C Release

Release/Makefile:
	@mkdir -p Release
	@cd Release; cmake .. -DCMAKE_BUILD_TYPE=Release

ifneq ($(wildcard Makefile), Makefile)

${BUILD}/projects.make: $(BUILD)/Makefile

include ${BUILD}/projects.make

.DEFAULT:
	@$(MYMAKE) $(BUILD)/Makefile
	@$(MYMAKE) -C $(BUILD) $(MAKECMDGOALS)
endif
