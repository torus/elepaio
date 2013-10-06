GOSH = $(HOME)/local/gauche/bin/gosh

test: test.scm
	$(GOSH) -I lib test.scm
