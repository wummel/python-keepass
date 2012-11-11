# This Makefile is only used by developers.
PYVER:=2.7
PYTHON:=python$(PYVER)
ifeq ($(shell uname),Darwin)
  NUMPROCESSORS:=$(shell sysctl -a | grep machdep.cpu.core_count | cut -d " " -f 2)
  CHMODMINUSMINUS:=
else
  NUMPROCESSORS:=$(shell grep -c processor /proc/cpuinfo)
  CHMODMINUSMINUS:=--
endif
# Pytest options:
# - use multiple processors
# - write test results in file
# - run all tests found in the "tests" subdirectory
PYTESTOPTS:=-n $(NUMPROCESSORS) --resultlog=testresults.txt

DEBUILD_AREA:=$(HOME)/src/build-area

PY_FILES:=\
	setup.py \
	keepassc \
	keepasslib/__init__.py \
	keepasslib/baker.py \
	keepasslib/decorators.py \
	keepasslib/header.py \
	keepasslib/hier.py \
	keepasslib/infoblock.py \
	keepasslib/kpdb.py

PY2APPOPTS?=

MANIFEST: MANIFEST.in setup.py
	$(PYTHON) setup.py sdist --manifest-only

chmod:
	-chmod -R a+rX,u+w,go-w $(CHMODMINUSMINUS) *
	find . -type d -exec chmod 755 {} \;

dist: MANIFEST chmod
	$(PYTHON) setup.py sdist --formats=bztar

app: chmod
	$(PYTHON) setup.py py2app $(PY2APPOPTS)

doc/keepassc.1.html: doc/keepassc.1
	man2html -r $< | tail -n +2 | sed 's/Time:.*//g' | sed 's@/:@/@g' > $@

doccheck:
	py-check-docstrings --force $(PY_FILES)

check:
	check-copyright
	py-tabdaddy
	$(MAKE) doccheck
	-$(MAKE) pyflakes
	$(PYTHON) setup.py check --restructuredtext

pyflakes:
	pyflakes $(PY_FILES)

test:
	$(PYTHON) -m pytest $(PYTESTOPTS) $(TESTOPTS) $(TESTS)

deb:
	git-buildpackage --git-export-dir=$(DEBUILD_AREA) --git-upstream-branch=master --git-debian-branch=debian  --git-ignore-new

.PHONY: dist chmod check pyflakes doccheck test deb
