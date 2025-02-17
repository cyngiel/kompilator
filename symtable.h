#include <string>
#include <vector>
#include <iostream>

using namespace std;
enum vartype {none, integer, real, procedure, function};
struct entry {
string name;
vartype type;
bool isFunction;
int address;
float value;
bool global;
bool isArgument;
vector <vartype> type_vector;
};

typedef vector<entry> symtable_t;

extern symtable_t symtable;

int addtotable(const string& s);
int findintable(const string& s);
void addlineno();
void setRelop(char* r);
int yylex();
int yylex_destroy();
void yyerror(char const *);
