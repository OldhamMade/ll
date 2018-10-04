define usage
Options:
  build		development build
  test		run test suite
  fulltest	run test suite within a local Travis-CI container
  release	release build, optimised for speed
  clean		remove build artefacts
endef
export usage

.PHONY: all release build test profile clean help

all: test

build:
	@nim c src/ll.nim

test:
	@nimble test

profile:
	@nimble profile

fulltest:
	@docker-compose -f .docker-compose.yml up --build

release:
	@nimble build --nilseqs:on --verbose --opt:speed -d:release # --passC:-Ofast --threads:off --threadanalysis:off

clean:
	@find . -type d -iname 'nimcache' | xargs rm -rf
	@rm -f ll
	@rm -f src/ll

help:
	@echo "$$usage"
