CXX   = g++-8
EXE = ipl_parser
CXXDEBUG = -g -Wall
CXXSTD = -std=c++11


.PHONY: all parser lexer clean
all: parser lexer 	
	$(CXX) $(CXXDEBUG) -o iplC driver.cpp parser.o scanner.o 

parser: parser.yy scanner.hh
	bison -d -v $<
	$(CXX) $(CXXDEBUG) -c parser.tab.cc -o parser.o 

lexer: scanner.l scanner.hh parser.tab.hh parser.tab.cc	
	flex++ --outfile=scanner.yy.cc  $<
	$(CXX)  $(CXXDEBUG) -c scanner.yy.cc -o scanner.o

clean: 
	rm -rf parser.tab.hh
	rm -rf position.hh
	rm -rf stack.hh
	rm -rf iplC
	rm -rf location.hh
	rm -rf parser.output
	rm -rf *.o
	rm -rf *.cc
	

