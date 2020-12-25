.PHONY: all release build test profile clean help

all: release

build:  ## development build
	@nim c src/ll.nim

test:  ## run test suite
	@nimble -y test --verbose

profile:  ## run profiler
	@nimble profile

release:  ## release build, optimised for speed
	@nimble -y build --nilseqs:on --verbose --opt:speed -d:release # --passC:-Ofast --threads:off --threadanalysis:off

install: release  ## create a release build and install to /usr/local/bin
	@mv ./ll /usr/local/bin/ll

clean:  ## remove build artefacts
	@find . -type d -iname 'nimcache' | xargs rm -rf
	@rm -f ll
	@rm -f src/ll

help:  ## display this help
	@echo "Options:"
	@grep -E '^[a-zA-Z%_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'
	@grep -E '^[a-zA-Z%_-]+:.*?##@deprecated.*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?##@deprecated "}; {printf "  \033[31m%-18s\033[0m [deprecated] %s\n", $$1, $$2}'

# catch-all
%:
	@:
