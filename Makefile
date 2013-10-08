GOSH = $(HOME)/local/gauche/bin/gosh

all: test run

test: test.scm
	$(GOSH) -I lib test.scm

run:
	$(GOSH) run-makiki.scm
