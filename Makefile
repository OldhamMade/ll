PHONY: release build test fulltest clean

all:
	build && test

release:
	@nimble build --opt:speed -d:release # --threads:off --threadanalysis:off

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
