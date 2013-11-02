GOSH = env GAUCHE_TEST_REPORT_ERROR=1 gosh
GAUCHE_TEST_RECORD_FILE = test.record

#all: check run

check: test.scm
	@rm -f $(GAUCHE_TEST_RECORD_FILE) test.log
	@$(GOSH) -I lib test.scm >> test.log
	@$(GOSH) -I lib test-ident.scm >> test.log
	@$(GOSH) -I lib test-pusher.scm >> test.log
	@cat $(GAUCHE_TEST_RECORD_FILE) /dev/null
	@$(GOSH) -ugauche.test -Etest-summary-check -Eexit

run:
	$(GOSH) run-makiki.scm
