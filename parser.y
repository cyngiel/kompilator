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
void gencode(const string m, int v1, varmode lv1, int v2, varmode lv2, int v3,varmode lv3);
%}

%token T_ID
%token T_PROGRAM
%token T_VAR
%token T_INTEGER
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
      for(i=0;i<symtable.size();i++)
      std::cout << symtable[i].name << ' ' << symtable[i].type << ' ' << symtable[i].address << ' ' << symtable[i].value << endl;
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
        nextAddress += 4;
      }

      identifier_indexes.clear();
      }
	|
	
	
type: T_INTEGER {$$ = (vartype)$1;}
	
compound_statement: T_BEGIN statement_list T_END '.' {}

statement_list: statement 
  | statement_list ';' statement

statement: T_ID T_ASSIGN expresion {symtable[$1].value = symtable[$3].value; 
                            if(symtable[$3].address == -1)
                              gencode("mov.i", symtable[$3].value, (varmode)value, symtable[$1].address, (varmode)address, symtable[$3].address, (varmode)address);
                            else
                              gencode("mov.i", symtable[$3].address, (varmode)address, symtable[$1].address, (varmode)address, symtable[$3].address, (varmode)address);}
        | T_WRITE '(' T_ID ')' {
                            int v1; 
                            varmode vl1;

                            if(symtable[$3].address < 0)
                              {v1 = symtable[$3].value;
                               vl1 = (varmode)value;
                               }
                            else{
                              v1 = symtable[$3].address;
                              vl1 = (varmode)address;
                              }

                              gencode("write.i", v1, vl1, v1, vl1, v1, vl1);
                              }

expresion:  expresion '+' expresion { 
                            int retIdx = addtotable("$t" + to_string(nextTempVariable)); 
                            nextTempVariable++;
                            symtable[retIdx].address = nextAddress;
                            nextAddress +=4;
                            symtable[retIdx].value = symtable[$1].value + symtable[$3].value; 

                            $$ = retIdx;

                            int v1, v2; 
                            varmode vl1, vl2;

                            if(symtable[$1].address < 0)
                              {v1 = symtable[$1].value;
                               vl1 = (varmode)value;
                               }
                            else{
                              v1 = symtable[$1].address;
                              vl1 = (varmode)address;
                              }

                            if(symtable[$3].address < 0)
                              {v2 = symtable[$3].value;
                              vl2 = (varmode)value;
                              }
                            else
                              {v2 = symtable[$3].address;
                              vl2 = (varmode)address;
                              }

                            gencode("add.i", v1, vl1, v2, vl2, symtable[retIdx].address, (varmode)address);}
  | expresion '*' expresion { 
                            int retIdx = addtotable("$t" + to_string(nextTempVariable)); 
                            nextTempVariable++;
                            symtable[retIdx].address = nextAddress;
                            nextAddress +=4;
                            symtable[retIdx].value = symtable[$1].value * symtable[$3].value; 

                            $$ = retIdx;

                            int v1, v2; 
                            varmode vl1, vl2;

                            if(symtable[$1].address < 0)
                              {v1 = symtable[$1].value;
                               vl1 = (varmode)value;
                               }
                            else{
                              v1 = symtable[$1].address;
                              vl1 = (varmode)address;
                              }

                            if(symtable[$3].address < 0)
                              {v2 = symtable[$3].value;
                              vl2 = (varmode)value;
                              }
                            else
                              {v2 = symtable[$3].address;
                              vl2 = (varmode)address;
                              }

                            gencode("mul.i", v1, vl1, v2, vl2, symtable[retIdx].address, (varmode)address);}
  | expresion '/' expresion { 
                            int retIdx = addtotable("$t" + to_string(nextTempVariable)); 
                            nextTempVariable++;
                            symtable[retIdx].address = nextAddress;
                            nextAddress +=4;
                            symtable[retIdx].value = symtable[$1].value / symtable[$3].value; 

                            $$ = retIdx;

                            int v1, v2; 
                            varmode vl1, vl2;

                            if(symtable[$1].address < 0)
                              {v1 = symtable[$1].value;
                               vl1 = (varmode)value;
                               }
                            else{
                              v1 = symtable[$1].address;
                              vl1 = (varmode)address;
                              }

                            if(symtable[$3].address < 0)
                              {v2 = symtable[$3].value;
                              vl2 = (varmode)value;
                              }
                            else
                              {v2 = symtable[$3].address;
                              vl2 = (varmode)address;
                              }

                            gencode("div.i", v1, vl1, v2, vl2, symtable[retIdx].address, (varmode)address);}
  | expresion '-' expresion { 
                            int retIdx = addtotable("$t" + to_string(nextTempVariable)); 
                            nextTempVariable++;
                            symtable[retIdx].address = nextAddress;
                            nextAddress +=4;
                            symtable[retIdx].value = symtable[$1].value - symtable[$3].value; 

                            $$ = retIdx;

                            int v1, v2; 
                            varmode vl1, vl2;

                            if(symtable[$1].address < 0)
                              {v1 = symtable[$1].value;
                               vl1 = (varmode)value;
                               }
                            else{
                              v1 = symtable[$1].address;
                              vl1 = (varmode)address;
                              }

                            if(symtable[$3].address < 0)
                              {v2 = symtable[$3].value;
                              vl2 = (varmode)value;
                              }
                            else
                              {v2 = symtable[$3].address;
                              vl2 = (varmode)address;
                              }

                             gencode("sub.i", v1, vl1, v2, vl2, symtable[retIdx].address, (varmode)address);}
  | '-' expresion { 
                            int retIdx = addtotable("$t" + to_string(nextTempVariable)); 
                            nextTempVariable++;
                            symtable[retIdx].address = nextAddress;
                            nextAddress +=4;
                            symtable[retIdx].value = 0 - symtable[$1].value ; 

                            $$ = retIdx;

                            int v1, v2; 
                            varmode vl1, vl2;

                            v1 = 0;
                            vl1 = (varmode)value;

                            if(symtable[$1].address < 0){
                               v2 = symtable[$1].value;
                               vl2 = (varmode)value;
                               }
                            else{
                              v2 = symtable[$1].address;
                              vl2 = (varmode)address;
                              }

                            gencode("sub.i", v1, vl1, v2, vl2, symtable[retIdx].address, (varmode)address);}
  | expresion T_MOD expresion { 
                            int retIdx = addtotable("$t" + to_string(nextTempVariable)); 
                            nextTempVariable++;
                            symtable[retIdx].address = nextAddress;
                            nextAddress +=4;
                            symtable[retIdx].value = 0 - symtable[$1].value ; 

                            $$ = retIdx;

                            int v1, v2; 
                            varmode vl1, vl2;

                            v1 = 0;
                            vl1 = (varmode)value;

                            if(symtable[$1].address < 0){
                               v2 = symtable[$1].value;
                               vl2 = (varmode)value;
                               }
                            else{
                              v2 = symtable[$1].address;
                              vl2 = (varmode)address;
                              }

                            gencode("mod.i", v1, vl1, v2, vl2, symtable[retIdx].address, (varmode)address);}
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

void gencode(const string m, int v1, varmode lv1, int v2, varmode lv2, int v3,varmode lv3){

  string operation = m;
  operation.append("\t");

  if(m == "read.i" || m == "write.i"){
    if(lv1 !=0)
      operation.append("#");
    operation.append(std::to_string(v1));
  }
  else if(m == "mov.i"){
    if(lv1 !=0)
      operation.append("#");
    operation.append(std::to_string(v1) + ", ");

    if(lv2 !=0)
      operation.append("#");
    operation.append(std::to_string(v2));
  }
  else{

    if(lv1 !=0)
      operation.append("#");
    operation.append(std::to_string(v1) + ", ");

    if(lv2 !=0)
      operation.append("#");
    operation.append(std::to_string(v2) + ", ");

    if(lv3 !=0)
      operation.append("#");
    operation.append(std::to_string(v3));
  }

  outFile << operation << endl;
}
