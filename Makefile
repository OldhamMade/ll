define usage
Options:
  build		development build
  test		run test suite
  fulltest	run test suite within a local Travis-CI container
  release	release build, optimised for speed
  clean		remove build artefacts
endef
export usage

@PHONY: release build test clean help

all:
	build && test

release:
	@nimble build --opt:speed -d:release # --passC:-Ofast --threads:off --threadanalysis:off

build:
	@nim c src/ll.nim

test:
	@nimble test

fulltest:
	@docker-compose -f .docker-compose.yml up --build

clean:
	@find . -type d -iname 'nimcache' | xargs rm -rf
	@rm -f ll
	@rm -f src/ll

help:
	@echo "$$usage"
