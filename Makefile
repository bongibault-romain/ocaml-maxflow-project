.PHONY: all build format edit demo clean

src?=0
dst?=5
graph?=graph1.txt

all: build

build:
	@echo "\n   🚨  COMPILING  🚨 \n"
	dune build src/ftest.exe
	ls src/*.exe > /dev/null && ln -fs src/*.exe .

format:
	ocp-indent --inplace src/*

edit:
	code . -n

demo: build
	@echo "\n   ⚡  EXECUTING  ⚡\n"
	./ftest.exe graphs/${graph} -f $(src) $(dst) -o outfile
	@echo "\n   🥁  RESULT (content of outfile)  🥁\n"
	# @cat outfile

clean:
	find -L . -name "*~" -delete
	rm -f *.exe
	rm -rf ./example/*.dot ./example/*.png ./example/*.svg
	dune clean
