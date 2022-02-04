%{
#include "symtable.h"
#include "parser.hpp"
#include <iostream>
#include <fstream>

int nextAddress = 0;
int nextTempVariable = 0;
enum varmode {address, value};
ofstream outFile;
vector<int> identifier_indexes;
void gencode(const string m, int v1, int v2, int v3, vartype type);
int convertIfNeeded(int v1, vartype type);
%}

%token T_ID
%token T_PROGRAM
%token T_VAR
%token T_INTEGER
%token T_REAL
%token T_BEGIN
%token T_END
%token T_NUM
%token T_ASSIGN
%token T_WRITE
%token T_MOD

%%
start: program {
      outFile << "exit" << endl;
      int i;
      std::cout << "name\t" << "type\t" << "address\t"<< "value\t"  << endl;
      for(i=0;i<symtable.size();i++)
      std::cout << symtable[i].name << '\t' << symtable[i].type << '\t' << symtable[i].address << '\t' << symtable[i].value << endl;
    }
program: T_PROGRAM T_ID '(' start_identifiers ')' ';' 
	declarations 
  compound_statement

start_identifiers: start_identifiers ',' T_ID | T_ID	
	
identifier_list: T_ID {identifier_indexes.push_back($1);}
	| identifier_list ',' T_ID {identifier_indexes.push_back($3);}
	
	
	
declarations: 
	declarations T_VAR identifier_list ':' type ';' { 
      for(int i = 0; i < identifier_indexes.size(); i++){
        symtable[identifier_indexes[i]].type = (vartype)$5; 
        symtable[identifier_indexes[i]].address = nextAddress;
        //gencode("read.i", nextAddress, (varmode)address, 0, (varmode)address, 0, (varmode)address);
        
        if(symtable[identifier_indexes[i]].type == (vartype)real){
          nextAddress += 8;
        } else {
          nextAddress += 4;
        }
        
      }

      identifier_indexes.clear();
      }
	|
	
type: standard_type {$$ = $1;}

standard_type: T_INTEGER {$$ = (vartype)$1;}
              | T_REAL {$$ = (vartype)$1;}
	
compound_statement: T_BEGIN statement_list T_END '.' {}

statement_list: statement 
  | statement_list ';' statement

statement: T_ID T_ASSIGN expresion {symtable[$1].value = symtable[$3].value; 
                            int v3 = $3;  

                            int convIdx1 = convertIfNeeded($3, symtable[$1].type);
                              if(convIdx1 >= 0){
                                v3 = convIdx1;
                              }

                              gencode("mov", v3,$1,$1, symtable[$1].type);

                            }
        | T_WRITE '(' T_ID ')' {
                            
                              gencode("write", $3, $3, $3, symtable[$3].type);
                              }

expresion:  expresion '+' expresion { 
                            int retIdx = addtotable("$t" + to_string(nextTempVariable)); 
                            nextTempVariable++;
                            symtable[retIdx].address = nextAddress;
                            
                            symtable[retIdx].value = symtable[$1].value + symtable[$3].value; 

                            if(symtable[$1].type == (vartype)real || symtable[$3].type == (vartype)real){
                              symtable[retIdx].type = (vartype)real;
                            }
                            else{
                              symtable[retIdx].type = (vartype)integer;
                            }

                            if(symtable[retIdx].type == (vartype)real){
                                nextAddress += 8;
                              } else {
                                nextAddress += 4;
                              }

                            $$ = retIdx;

                            int v1 = $1;
                            int v2 = $3;

                            int convIdx1 = convertIfNeeded($1, symtable[retIdx].type);
                              if(convIdx1 >= 0){
                                v1 = convIdx1;
                              }
                            int convIdx2 = convertIfNeeded($3, symtable[retIdx].type);
                              if(convIdx2 >= 0){
                                v2 = convIdx2;
                              }

                            gencode("add", v1, v2, retIdx, symtable[retIdx].type);
                            }

  | expresion '*' expresion { 
                            int retIdx = addtotable("$t" + to_string(nextTempVariable)); 
                            nextTempVariable++;
                            symtable[retIdx].address = nextAddress;
                            
                            symtable[retIdx].value = symtable[$1].value * symtable[$3].value; 

                            if(symtable[$1].type == (vartype)real || symtable[$3].type == (vartype)real){
                              symtable[retIdx].type = (vartype)real;
                            }
                            else{
                              symtable[retIdx].type = (vartype)integer;
                            }

                            if(symtable[retIdx].type == (vartype)real){
                                nextAddress += 8;
                              } else {
                                nextAddress += 4;
                              }

                            $$ = retIdx;
                            int v1 = $1;
                            int v2 = $3;

                            int convIdx1 = convertIfNeeded($1, symtable[retIdx].type);
                              if(convIdx1 >= 0){
                                v1 = convIdx1;
                              }
                            int convIdx2 = convertIfNeeded($3, symtable[retIdx].type);
                              if(convIdx2 >= 0){
                                v2 = convIdx2;
                              }

                            gencode("mul", v1, v2, retIdx, symtable[retIdx].type);
                            }

  | expresion '/' expresion { 
                            int retIdx = addtotable("$t" + to_string(nextTempVariable)); 
                            nextTempVariable++;
                            symtable[retIdx].address = nextAddress;
                           
                            symtable[retIdx].value = symtable[$1].value / symtable[$3].value; 

                            if(symtable[$1].type == (vartype)real || symtable[$3].type == (vartype)real){
                              symtable[retIdx].type = (vartype)real;
                            }
                            else{
                              symtable[retIdx].type = (vartype)integer;
                            }

                            if(symtable[retIdx].type == (vartype)real){
                                nextAddress += 8;
                              } else {
                                nextAddress += 4;
                              }

                            $$ = retIdx;
                            int v1 = $1;
                            int v2 = $3;

                            int convIdx1 = convertIfNeeded($1, symtable[retIdx].type);
                              if(convIdx1 >= 0){
                                v1 = convIdx1;
                              }
                            int convIdx2 = convertIfNeeded($3, symtable[retIdx].type);
                              if(convIdx2 >= 0){
                                v2 = convIdx2;
                              }

                            gencode("div", v1, v2, retIdx, symtable[retIdx].type);
                            }

  | expresion '-' expresion { 
                            int retIdx = addtotable("$t" + to_string(nextTempVariable)); 
                            nextTempVariable++;
                            symtable[retIdx].address = nextAddress;
                            
                            symtable[retIdx].value = symtable[$1].value - symtable[$3].value; 

                            if(symtable[$1].type == (vartype)real || symtable[$3].type == (vartype)real){
                              symtable[retIdx].type = (vartype)real;
                            }
                            else{
                              symtable[retIdx].type = (vartype)integer;
                            }

                            if(symtable[retIdx].type == (vartype)real){
                                nextAddress += 8;
                              } else {
                                nextAddress += 4;
                              }

                            $$ = retIdx;
                            int v1 = $1;
                            int v2 = $3;

                            int convIdx1 = convertIfNeeded($1, symtable[retIdx].type);
                              if(convIdx1 >= 0){
                                v1 = convIdx1;
                              }
                            int convIdx2 = convertIfNeeded($3, symtable[retIdx].type);
                              if(convIdx2 >= 0){
                                v2 = convIdx2;
                              }

                             gencode("sub", v1, v2, retIdx, symtable[retIdx].type);
                             }

  | '-' expresion { 
                            int retIdx = addtotable("$t" + to_string(nextTempVariable)); 
                            nextTempVariable++;
                            symtable[retIdx].address = nextAddress;
                            
                            symtable[retIdx].value = 0 - symtable[$2].value ; 

                            if(symtable[$2].type == (vartype)real){
                              symtable[retIdx].type = (vartype)real;
                            }
                            else{
                              symtable[retIdx].type = (vartype)integer;
                            }

                            if(symtable[retIdx].type == (vartype)real){
                                nextAddress += 8;
                              } else {
                                nextAddress += 4;
                              }

                            $$ = retIdx;
                            int v2 = $2;

                            int convIdx2 = convertIfNeeded($2, symtable[retIdx].type);
                              if(convIdx2 >= 0){
                                v2 = convIdx2;
                              }

                            gencode("sub", v2, v2, retIdx, symtable[retIdx].type);
                            }

  | expresion T_MOD expresion { 
                            int retIdx = addtotable("$t" + to_string(nextTempVariable)); 
                            nextTempVariable++;
                            symtable[retIdx].address = nextAddress;
                            
                            symtable[retIdx].value = 0 - symtable[$1].value ; 

                            if(symtable[$1].type == (vartype)real){
                              symtable[retIdx].type = (vartype)real;
                            }
                            else{
                              symtable[retIdx].type = (vartype)integer;
                            }

                            if(symtable[retIdx].type == (vartype)real){
                                nextAddress += 8;
                              } else {
                                nextAddress += 4;
                              }

                            $$ = retIdx;
                            int v1 = $1;

                            int convIdx1 = convertIfNeeded($1, symtable[retIdx].type);
                              if(convIdx1 >= 0){
                                v1 = convIdx1;
                              }

                            gencode("mod", v1, v1, retIdx, symtable[retIdx].type);
                            }

  | '(' expresion ')' {$$ = $2;}
  | T_ID {$$ = $1;}
  | T_NUM {$$ = $1;}

%%

void yyerror(char const *s)
{
  printf("%s\n",s);
  std::atexit;
  yylex_destroy();
  exit(1);
};

int main()
{
  outFile.open("out.asm");
  outFile << "jump.i  #lab0" << endl;
  outFile << "lab0:" << endl;
  yyparse();
  outFile.close();
  symtable.clear();
  identifier_indexes.clear();
  std::atexit;
  yylex_destroy();
exit(1);
};

symtable_t symtable;
//int nextAddress = 0;

int addtotable(const string& s)
{
int i;
for(i=0;i<symtable.size();i++)
  if(symtable[i].name==s)
    return i;
entry d;
d.name=s;
d.type=none;
d.value = 0;
d.address = -1;
symtable.push_back(d);
return i;
};

int findintable(const string& s)
{
int i;
for(i=0;i<symtable.size();i++)
  if(symtable[i].name==s)
    return i;
return -1;
};


void gencode(const string m, int v1, int v2, int v3, vartype type){

  string vl1, vl2, vl3;


  if(symtable[v1].address < 0){
    vl1 = symtable[v1].name;
    }
  else{
    vl1 = std::to_string(symtable[v1].address);
    }

  if(symtable[v2].address < 0){
    vl2 = symtable[v2].name;
    }
  else{
    vl2 = std::to_string(symtable[v2].address);
    }

  if(symtable[v3].address < 0){
    vl3 = symtable[v3].name;
    }
  else{
    vl3 = std::to_string(symtable[v3].address);
    }

  string operation = m;
  if(type == (vartype)real){
    operation.append(".r");
  } else {
    operation.append(".i");
  }

  operation.append("\t\t");


  if(m == "read" || m == "write"){
    if(symtable[v1].address < 0)
      operation.append("#");
    operation.append(vl1);
  }
  else if(m == "mov"){
    if(symtable[v1].address < 0)
      operation.append("#");
    operation.append(vl1 + ", ");

    if(symtable[v2].address < 0)
      operation.append("#");
    operation.append(vl2);
  }
  else{
    if(symtable[v1].address < 0)
      operation.append("#");
    operation.append(vl1 + ", ");

    if(symtable[v2].address < 0)
      operation.append("#");
    operation.append(vl2 + ", ");

    if(symtable[v3].address < 0)
      operation.append("#");
    operation.append(vl3);
  }

  outFile << operation << endl;
}

int convertIfNeeded(int v1, vartype type){
  int retId = -1;

  if(symtable[v1].type != type){
  string convertion;
  string vl1, vl2, vl3;

  int retIdx = addtotable("$t" + to_string(nextTempVariable)); 
  nextTempVariable++;
  symtable[retIdx].address = nextAddress;
  symtable[retIdx].value = symtable[v1].value ; 
                      

  if(type == (vartype)real){
    convertion = "inttoreal.i\t";
  }
  else {
    convertion = "realtoint.r\t";
  }

  if(symtable[v1].address < 0){
    convertion.append("#");
    vl1 = symtable[v1].name;
    }
  else{
    vl1 = std::to_string(symtable[v1].address);
  }
  convertion.append(vl1 + ", ");

  convertion.append(std::to_string(symtable[retIdx].address));

  symtable[retIdx].type = type;

  if(symtable[retIdx].type == (vartype)real){
      nextAddress += 8;
    } else {
      nextAddress += 4;
    }

    outFile << convertion << endl;

    retId = retIdx;
  }

  return retId;
}