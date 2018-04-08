PHONY: build test clean

all:
	build && test

build:
	@nimble build

test:
	@nimble test

clean:
	@find . -type d -iname 'nimcache' | xargs rm -rf
