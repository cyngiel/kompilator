test: parser.o lexer.o
	g++ parser.o lexer.o -o test

parser.o: parser.cpp symtable.h
	g++ -c parser.cpp

lexer.o : lexer.cpp parser.hpp symtable.h
	g++ -c lexer.cpp

parser.cpp parser.hpp: parser.y
	bison --debug -t -v -d -oparser.cpp parser.y

lexer.cpp : lexer.l
	flex -olexer.cpp lexer.l

clean:
	-rm *.o
	-rm parser.cpp
	-rm parser.hpp
	-rm parser.output
	-rm lexer.cpp
	-rm test