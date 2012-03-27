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
	@$(MAKE) -C $(BUILD) $(MAKECMDGOALS)

all: debug release
clean:
	@-$(MAKE) -C Debug clean
	@-$(MAKE) -C Release clean

package: Release/Makefile
	@$(MAKE) -C Release clean
	@$(MAKE) -C Release package

tests: $(BUILD)/Makefile
	@$(MAKE) -C $(BUILD) tests

.DEFAULT: $(BUILD)/Makefile
	@$(MAKE) -C $(BUILD) $(MAKECMDGOALS)
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

