GOSH = $(HOME)/local/gauche/bin/gosh

all: test run

test: test.scm
	@rm -f test.record test.log
	$(GOSH) -I lib test.scm >> test.log
	$(GOSH) -I lib test-pusher.scm >> test.log
	@cat test.record


run:
	$(GOSH) run-makiki.scm
