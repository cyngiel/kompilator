%{
#include "symtable.h"
#include "parser.hpp"
#include <iostream>
#include <sstream>
#include <fstream>
#include <string> 
#define YYERROR_VERBOSE 1

int nextAddress = 0;
int nextAddressLocal = 0;
int nextAddressParameter = 0;
int nextTempVariable = 0;
int lineno;
bool isGlobal = true;
enum varmode {address, value};
enum class InputType {NONE = -1, IDENTIFIER = 0, NUMBER = 1, TEMPORARY = 2, PROCEDURE = 3};
ofstream outFile;
stringstream localCode;
vector<int> identifier_indexes;
vector<int> parameter_indexes;

int relop_true, relop_false = 0;
char* relop;
int relop_counter = 0;
int while_start;
int labCounter = 0;

void gencode(const string m, int v1, int v2, int v3, vartype type);
int convertIfNeeded(int v1, vartype type);
void addlineno();
void updateNextAddress(vartype);
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
%token T_DIV
%token T_PROCEDURE
%token T_FUNCTION
%token T_IF
%token T_THEN
%token T_ELSE
%token T_RELOP
%token T_OR
%token T_AND
%token T_WHILE
%token T_DO
%token T_NOT

%%
start: program {
      outFile << "exit" << endl;
      int i;
      std::cout << "name\t" << "type\t" << "address\t"<< "value\t"  << "global" << endl;
      for(i=0;i<symtable.size();i++)
        std::cout << symtable[i].name << '\t' << symtable[i].type << '\t' << symtable[i].address << '\t' << symtable[i].value << '\t' << symtable[i].global << endl;
    }

program: T_PROGRAM T_ID '(' start_identifiers ')' ';' 
      declarations {isGlobal = false; outFile << endl;}
      subprogram_declarations {
                              isGlobal = true;
                              outFile << endl << "lab" << labCounter << ":" << endl;
                              labCounter++;
                              }
      compound_statement{}
      '.'


start_identifiers: start_identifiers ',' T_ID | T_ID	
	
identifier_list: T_ID {identifier_indexes.push_back($1);}
                | identifier_list ',' T_ID {identifier_indexes.push_back($3);}
	
	
	
declarations: declarations T_VAR identifier_list ':' type ';' { 
            for(int i = 0; i < identifier_indexes.size(); i++){
              symtable[identifier_indexes[i]].type = (vartype)$5; 
              if(isGlobal)
                {
                  symtable[identifier_indexes[i]].address = nextAddress;
                  updateNextAddress(symtable[identifier_indexes[i]].type);
                }
              else
                {
                  updateNextAddress(symtable[identifier_indexes[i]].type);
                  symtable[identifier_indexes[i]].address = nextAddressLocal;
                }
              //gencode("read.i", nextAddress, (varmode)address, 0, (varmode)address, 0, (varmode)address);

              
            }

            identifier_indexes.clear();
            }
            |/* empty */
	
type: standard_type {$$ = $1;}

standard_type: T_INTEGER {$$ = (vartype)$1;}
              | T_REAL {$$ = (vartype)$1;}


subprogram_declarations: subprogram_declarations subprogram_declaration ';'
                        | /* empty */

subprogram_declaration: subprogram_head 
                       declarations { }
                       compound_statement{
                                          outFile << "enter.i\t\t#" << (-1)*nextAddressLocal << endl;  
                                          nextAddressLocal = 0;
                                          outFile << localCode.str();
                                          localCode.str("");
                                          outFile << "leave" << endl;
                                          outFile << "return" << endl << endl;
                                          }


subprogram_head: T_FUNCTION T_ID arguments ':' standard_type ';'{

                  symtable[$2].type = (vartype)$5;
                  symtable[$2].isFunction = true;
                  outFile << symtable[$2].name + ":" << endl;

                  nextAddressParameter = (int) parameter_indexes.size() * 4 + 8;  //BP+8, dla adresu zmiennej tymczasowej wyniku funkcji

                for(int i = 0; i < (int) parameter_indexes.size(); i++){

                   symtable[parameter_indexes[i]].address = nextAddressParameter;
                   nextAddressParameter -= 4;

                   symtable[$2].type_vector.push_back(symtable[parameter_indexes[i]].type);
                   
                 }
                nextAddressParameter = 0;
                symtable[$2].address = 8;
                 parameter_indexes.clear();
                identifier_indexes.clear();


                }
               | T_PROCEDURE T_ID arguments ';' {
                 symtable[$2].type = (vartype)procedure;
                 outFile << symtable[$2].name + ":" << endl;
                 
                 nextAddressParameter = (int) parameter_indexes.size() * 4 + 4; //size *4  + 4 dla adresu powrotu

                 for(int i = 0; i < (int) parameter_indexes.size(); i++){

                   symtable[parameter_indexes[i]].address = nextAddressParameter;
                   nextAddressParameter -= 4;

                   symtable[$2].type_vector.push_back(symtable[parameter_indexes[i]].type);

                   
                 }

                 nextAddressParameter = 0;
                 parameter_indexes.clear();
                identifier_indexes.clear();
               }

arguments: '(' parameter_list ')'
        |

parameter_list: identifier_list ':' type{
                                         for(int i = 0; i < (int) identifier_indexes.size(); i++){
                                           symtable[identifier_indexes[i]].type = (vartype)$3;
                                           symtable[identifier_indexes[i]].global = isGlobal;
                                           parameter_indexes.push_back(identifier_indexes[i]);
                                         } 
                                         identifier_indexes.clear();
                                        }
              | parameter_list ';' identifier_list ':' type {
                                         for(int i = 0; i < (int) identifier_indexes.size(); i++){
                                           symtable[identifier_indexes[i]].type = (vartype)$5;
                                           symtable[identifier_indexes[i]].global = isGlobal;
                                           parameter_indexes.push_back(identifier_indexes[i]);
                                         } 
                                         identifier_indexes.clear();
                                        }

compound_statement: T_BEGIN optional_statements T_END

optional_statements: statement_list
                    |

statement_list: statement 
              | statement_list ';' statement
              

statement: T_ID T_ASSIGN expresion {
                                  if(symtable[$1].type == (vartype)none){
                                    std::ostringstream oss;
                                    oss << "Undeclared variable '" << symtable[$1].name << "'";
                                    std::string error = oss.str();
                                    yyerror(error.c_str());
                                  }

                                  symtable[$1].value = symtable[$3].value; 
                                  int v3 = $3;  

                                  int convIdx1 = convertIfNeeded($3, symtable[$1].type);
                                    if(convIdx1 != -1){
                                      v3 = convIdx1;
                                    }

                                    gencode("mov", v3,$1,$1, symtable[$1].type);
                            }
        | T_WRITE '(' T_ID ')' {gencode("write", $3, $3, $3, symtable[$3].type);}
        | T_WRITE '(' expresion ')' {gencode("write", $3, $3, $3, symtable[$3].type);}
        | procedure_call //wywolanie funkcji nizej dla T_ID bo inaczej nie mozna bylo uzyc w assign
        | T_IF {
          relop_false = addtotable("false");
          symtable[relop_false].type = integer; 
        
          if(isGlobal)
          {
            symtable[relop_false].address = nextAddress;
            updateNextAddress(symtable[relop_false].type);
          }
        else
          {
            updateNextAddress(symtable[relop_false].type);
            symtable[relop_false].address = nextAddressLocal;
          }


          relop_true = addtotable("true");
          symtable[relop_true].type = integer; 
          symtable[relop_true].value = 1; 
        
          if(isGlobal)
          {
            symtable[relop_true].address = nextAddress;
            updateNextAddress(symtable[relop_true].type);
          }
        else
          {
            updateNextAddress(symtable[relop_true].type);
            symtable[relop_true].address = nextAddressLocal;
          }

        }
        expresion
        T_THEN{
          gencode("je", $3, relop_false, $3, (vartype)integer);
        }
        statement { outFile << "jump.i\t\t#lab" << to_string(labCounter+1) << endl;}
        T_ELSE { outFile << endl << "lab" << to_string(labCounter) << ":" << endl; labCounter++;}
        statement { outFile << endl << "lab" << to_string(labCounter) << ":" << endl; labCounter++;}
        
        |T_WHILE{
                while_start = labCounter;

                relop_true = addtotable("true");
                symtable[relop_true].type = integer; 
                symtable[relop_true].value = 1; 
              
                if(isGlobal)
                {
                  symtable[relop_true].address = nextAddress;
                  updateNextAddress(symtable[relop_true].type);
                }
              else
                {
                  updateNextAddress(symtable[relop_true].type);
                  symtable[relop_true].address = nextAddressLocal;
                }


                relop_false = addtotable("false");
                symtable[relop_false].type = integer; 
              
                if(isGlobal)
                {
                  symtable[relop_false].address = nextAddress;
                  updateNextAddress(symtable[relop_false].type);
                }
              else
                {
                  updateNextAddress(symtable[relop_false].type);
                  symtable[relop_false].address = nextAddressLocal;
                }


                  outFile << endl << "lab" << to_string(labCounter + 1) << ":" << endl;
                  labCounter += 2;
                }
            expresion
            T_DO{
                  labCounter -= 2*relop_counter; //wracamy bo expression zwieksza o 2*relop_counter petle
                  labCounter = while_start;
                  gencode("je", $3, relop_false, 0, (vartype)integer);
                }
            statement {
                        outFile << "jump.i\t\t#lab" << to_string(while_start +1) << endl;
                        outFile << endl << "lab" << to_string(while_start) << ":" << endl;
                        labCounter += 2*relop_counter + 2;
                        relop_counter = 0;
                      }





procedure_call: T_ID {
                      if(symtable[$1].type == (vartype)procedure)
                        outFile << "call.i #\t" + symtable[$1].name << endl;
                      else
                        if(symtable[$1].type == (vartype)none){
                          std::ostringstream oss;
                          oss << "Unknown symbol '" << symtable[$1].name << "'";
                          std::string error = oss.str();
                          yyerror(error.c_str());
                        }
                        else{
                          std::ostringstream oss;
                          oss << "'" << symtable[$1].name << "' is not a valid procedure call";
                          std::string error = oss.str();
                          yyerror(error.c_str());
                        }
                          
                        
                      } 
                  | T_ID '(' expression_list ')' {

                                                  if(parameter_indexes.size() != symtable[$1].type_vector.size())
                                                    yyerror("Procedure called with wrong number of arguments");

                                                  for(int i = 0; i < parameter_indexes.size(); i++){
                                                    int v1 = symtable[parameter_indexes[i]].address;

                                                    int convIdx1 = convertIfNeeded(parameter_indexes[i], symtable[$1].type_vector[i]); 
                                                    
                                                    if(convIdx1 != -1){
                                                      v1 = convIdx1;
                                                    }
                                                    localCode << "push.i\t\t#" + to_string(symtable[v1].address) << endl;

                                                  }

                                                  outFile << "call.i\t\t#" + symtable[$1].name << endl;
                                                  outFile << "incsp.i\t\t#" + to_string(parameter_indexes.size()*4) << endl;
                                                  parameter_indexes.clear();
                                                  
                                                }

expression_list: expresion {parameter_indexes.push_back($1);} 
               | expression_list ',' expresion {parameter_indexes.push_back($3);} 

expresion:  expresion '+' expresion { 
                            int retIdx = addtotable("$t" + to_string(nextTempVariable)); 
                            nextTempVariable++;
                                                      
                            symtable[retIdx].value = symtable[$1].value + symtable[$3].value; 

                            if(symtable[$1].type == (vartype)real || symtable[$3].type == (vartype)real){
                              symtable[retIdx].type = (vartype)real;
                            }
                            else{
                              symtable[retIdx].type = (vartype)integer;
                            }

                            if(isGlobal)
                              {
                                symtable[retIdx].address = nextAddress;
                                updateNextAddress(symtable[retIdx].type);
                              }
                            else
                              {
                                updateNextAddress(symtable[retIdx].type);
                                symtable[retIdx].address = nextAddressLocal;
                              }

                            $$ = retIdx;

                            int v1 = $1;
                            int v2 = $3;

                            int convIdx1 = convertIfNeeded($1, symtable[retIdx].type);
                              if(convIdx1 != -1){
                                v1 = convIdx1;
                              }
                            int convIdx2 = convertIfNeeded($3, symtable[retIdx].type);
                              if(convIdx2 != -1){
                                v2 = convIdx2;
                              }

                            gencode("add", v1, v2, retIdx, symtable[retIdx].type);
                            }

  | expresion '*' expresion { 
                            int retIdx = addtotable("$t" + to_string(nextTempVariable)); 
                            nextTempVariable++;
                                                        
                            symtable[retIdx].value = symtable[$1].value * symtable[$3].value; 

                            if(symtable[$1].type == (vartype)real || symtable[$3].type == (vartype)real){
                              symtable[retIdx].type = (vartype)real;
                            }
                            else{
                              symtable[retIdx].type = (vartype)integer;
                            }

                            if(isGlobal)
                              {
                                symtable[retIdx].address = nextAddress;
                                updateNextAddress(symtable[retIdx].type);
                              }
                            else
                              {
                                updateNextAddress(symtable[retIdx].type);
                                symtable[retIdx].address = nextAddressLocal;
                              }

                            $$ = retIdx;
                            int v1 = $1;
                            int v2 = $3;

                            int convIdx1 = convertIfNeeded($1, symtable[retIdx].type);
                              if(convIdx1 != -1){
                                v1 = convIdx1;
                              }
                            int convIdx2 = convertIfNeeded($3, symtable[retIdx].type);
                              if(convIdx2 != -1){
                                v2 = convIdx2;
                              }

                            gencode("mul", v1, v2, retIdx, symtable[retIdx].type);
                            }

  | expresion '/' expresion { 
                            int retIdx = addtotable("$t" + to_string(nextTempVariable)); 
                            nextTempVariable++;
                                                       
                            symtable[retIdx].value = symtable[$1].value / symtable[$3].value; 

                            if(symtable[$1].type == (vartype)real || symtable[$3].type == (vartype)real){
                              symtable[retIdx].type = (vartype)real;
                            }
                            else{
                              symtable[retIdx].type = (vartype)integer;
                            }
                            
                            if(isGlobal)
                              {
                                symtable[retIdx].address = nextAddress;
                                updateNextAddress(symtable[retIdx].type);
                              }
                            else
                              {
                                updateNextAddress(symtable[retIdx].type);
                                symtable[retIdx].address = nextAddressLocal;
                              }

                            $$ = retIdx;
                            int v1 = $1;
                            int v2 = $3;

                            int convIdx1 = convertIfNeeded($1, symtable[retIdx].type);
                              if(convIdx1 != -1){
                                v1 = convIdx1;
                              }
                            int convIdx2 = convertIfNeeded($3, symtable[retIdx].type);
                              if(convIdx2 != -1){
                                v2 = convIdx2;
                              }

                            gencode("div", v1, v2, retIdx, symtable[retIdx].type);
                            }
  | expresion T_DIV expresion { 
                            int retIdx = addtotable("$t" + to_string(nextTempVariable)); 
                            nextTempVariable++;
                                                       
                            symtable[retIdx].value = symtable[$1].value / symtable[$3].value; 

                            if(symtable[$1].type == (vartype)real || symtable[$3].type == (vartype)real){
                              symtable[retIdx].type = (vartype)real;
                            }
                            else{
                              symtable[retIdx].type = (vartype)integer;
                            }

                            if(isGlobal)
                              {
                                symtable[retIdx].address = nextAddress;
                                updateNextAddress(symtable[retIdx].type);
                              }
                            else
                              {
                                updateNextAddress(symtable[retIdx].type);
                                symtable[retIdx].address = nextAddressLocal;
                              }

                            $$ = retIdx;
                            int v1 = $1;
                            int v2 = $3;

                            int convIdx1 = convertIfNeeded($1, symtable[retIdx].type);
                              if(convIdx1 != -1){
                                v1 = convIdx1;
                              }
                            int convIdx2 = convertIfNeeded($3, symtable[retIdx].type);
                              if(convIdx2 != -1){
                                v2 = convIdx2;
                              }

                            gencode("div", v1, v2, retIdx, symtable[retIdx].type);
                            }

  | expresion '-' expresion { 
                            int retIdx = addtotable("$t" + to_string(nextTempVariable)); 
                            nextTempVariable++;
                                                        
                            symtable[retIdx].value = symtable[$1].value - symtable[$3].value; 

                            if(symtable[$1].type == (vartype)real || symtable[$3].type == (vartype)real){
                              symtable[retIdx].type = (vartype)real;
                            }
                            else{
                              symtable[retIdx].type = (vartype)integer;
                            }

                            if(isGlobal)
                              {
                                symtable[retIdx].address = nextAddress;
                                updateNextAddress(symtable[retIdx].type);
                              }
                            else
                              {
                                updateNextAddress(symtable[retIdx].type);
                                symtable[retIdx].address = nextAddressLocal;
                              }

                            $$ = retIdx;
                            int v1 = $1;
                            int v2 = $3;

                            int convIdx1 = convertIfNeeded($1, symtable[retIdx].type);
                              if(convIdx1 != -1){
                                v1 = convIdx1;
                              }
                            int convIdx2 = convertIfNeeded($3, symtable[retIdx].type);
                              if(convIdx2 != -1){
                                v2 = convIdx2;
                              }

                             gencode("sub", v1, v2, retIdx, symtable[retIdx].type);
                             }

  | '-' expresion { 
                            int retIdx = addtotable("$t" + to_string(nextTempVariable)); 
                            nextTempVariable++;
                            
                            
                            symtable[retIdx].value = 0 - symtable[$2].value ; 

                            if(symtable[$2].type == (vartype)real){
                              symtable[retIdx].type = (vartype)real;
                            }
                            else{
                              symtable[retIdx].type = (vartype)integer;
                            }

                            if(isGlobal)
                              {
                                symtable[retIdx].address = nextAddress;
                                updateNextAddress(symtable[retIdx].type);
                              }
                            else
                              {
                                updateNextAddress(symtable[retIdx].type);
                                symtable[retIdx].address = nextAddressLocal;
                              }

                            $$ = retIdx;
                            int v2 = $2;

                            int convIdx2 = convertIfNeeded($2, symtable[retIdx].type);
                              if(convIdx2 != -1){
                                v2 = convIdx2;
                              }

                            gencode("sub", v2, v2, retIdx, symtable[retIdx].type);
                            }

  | expresion T_MOD expresion { 
                            int retIdx = addtotable("$t" + to_string(nextTempVariable)); 
                            nextTempVariable++;
                                                        
                            symtable[retIdx].value = (int)symtable[$1].value % (int)symtable[$3].value; 

                            if(symtable[$1].type == (vartype)real){
                              symtable[retIdx].type = (vartype)real;
                            }
                            else{
                              symtable[retIdx].type = (vartype)integer;
                            }

                            if(isGlobal)
                              {
                                symtable[retIdx].address = nextAddress;
                                updateNextAddress(symtable[retIdx].type);
                              }
                            else
                              {
                                updateNextAddress(symtable[retIdx].type);
                                symtable[retIdx].address = nextAddressLocal;
                              }

                            $$ = retIdx;
                            int v2 = $3;

                            int convIdx1 = convertIfNeeded($3, symtable[retIdx].type);
                              if(convIdx1 != -1){
                                v2 = convIdx1;
                              }

                            gencode("mod", $1, v2, retIdx, symtable[retIdx].type);
                            }
  | '(' expresion ')' {$$ = $2;}
   | T_ID '(' expression_list ')' {
                                    for(int i = 0; i < parameter_indexes.size(); i++){
                                      if(symtable[parameter_indexes[i]].type == (vartype)real || symtable[parameter_indexes[i]].type == (vartype)integer){
                                         int retIdx = addtotable("$t" + to_string(nextTempVariable)); 
                                         symtable[retIdx].type = symtable[$1].type_vector[i];
                                         nextTempVariable++;
                                        if(isGlobal)
                                          {
                                            symtable[retIdx].address = nextAddress;
                                            updateNextAddress(symtable[retIdx].type);
                                          }
                                        else
                                          {
                                            updateNextAddress(symtable[retIdx].type);
                                            symtable[retIdx].address = nextAddressLocal;
                                          }

                                          if(symtable[parameter_indexes[i]].type == (vartype)real && symtable[$1].type_vector[i] == (vartype)integer){
                                            parameter_indexes[i] = addtotable(symtable[parameter_indexes[i]].name);
                                            symtable[parameter_indexes[i]].type = symtable[parameter_indexes[i]].type;
                                            if(isGlobal)
                                          {
                                            symtable[parameter_indexes[i]].address = nextAddress;
                                            updateNextAddress(symtable[parameter_indexes[i]].type);
                                          }
                                        else
                                          {
                                            updateNextAddress(symtable[parameter_indexes[i]].type);
                                            symtable[parameter_indexes[i]].address = nextAddressLocal;
                                          }

                                          }
                                          if(symtable[parameter_indexes[i]].type == (vartype)integer)
                                            symtable[parameter_indexes[i]].type = (vartype)real;


                                          gencode("mov", parameter_indexes[i], retIdx, $1, symtable[retIdx].type);
                                          parameter_indexes[i] = retIdx;
                                      }
                                      
                                      int v2 = parameter_indexes[i];

                                      int convIdx2 = convertIfNeeded(parameter_indexes[i], symtable[$1].type_vector[i]);
                                      if(convIdx2 != -1){
                                        v2 = convIdx2;
                                      }

                                      outFile << "push.i\t\t#" << to_string(symtable[v2].address) << endl;

                                    }

                                    int retIdxFP = 0; //zmienna zwracająca jesli jest funkcja lub procedura
                                    if(symtable[$1].isFunction) {
                                      retIdxFP = addtotable("$t" + to_string(nextTempVariable)); 
                                         symtable[retIdxFP].type = symtable[$1].type;
                                         nextTempVariable++;
                                        if(isGlobal)
                                          {
                                            symtable[retIdxFP].address = nextAddress;
                                            updateNextAddress(symtable[retIdxFP].type);
                                          }
                                        else
                                          {
                                            updateNextAddress(symtable[retIdxFP].type);
                                            symtable[retIdxFP].address = nextAddressLocal;
                                          }
                                    } else {
                                      retIdxFP = addtotable("$t" + to_string(nextTempVariable)); 
                                         symtable[retIdxFP].type = (vartype)real; //zawsze real dla prcedur
                                         nextTempVariable++;
                                        if(isGlobal)
                                          {
                                            symtable[retIdxFP].address = nextAddress;
                                            updateNextAddress(symtable[retIdxFP].type);
                                          }
                                        else
                                          {
                                            updateNextAddress(symtable[retIdxFP].type);
                                            symtable[retIdxFP].address = nextAddressLocal;
                                          }
                                    }

                                    outFile << "push.i\t\t#" << symtable[retIdxFP].address << endl;
                                    outFile << "call.i\t\t#" + symtable[$1].name << endl; 
                                    outFile << "incsp.i\t\t#" + to_string(parameter_indexes.size()*4 + 4) << endl; // tyle ile push + 4 dla wyniku

                                    symtable[$1].address = symtable[retIdxFP].address;
                                    symtable[$1].type = symtable[retIdxFP].type;
                                      
                                      parameter_indexes.clear();
                                      $$ = $1;
                                  }
  | T_ID {
    if(symtable[$1].isFunction){

      int retIdx = addtotable("$t" + to_string(nextTempVariable)); 
      nextTempVariable++;

      if(symtable[$1].type == (vartype)real){
          symtable[retIdx].type = (vartype)real;
        }
        else{
          symtable[retIdx].type = (vartype)integer;
        }

      if(isGlobal)
        {
          symtable[retIdx].address = nextAddress;
          updateNextAddress(symtable[retIdx].type);
        }
      else
        {
          updateNextAddress(symtable[retIdx].type);
          symtable[retIdx].address = nextAddressLocal;
        }

        outFile << "push.i\t\t#" + symtable[$1].address << endl;
        outFile << "call.i\t\t#" + symtable[$1].name << endl;
        outFile << "incsp.i\t\t#4" << endl;
        
        symtable[$1].address = symtable[retIdx].address;
        symtable[$1].type = symtable[retIdx].type;
    }
    
    $$ = $1;
    }
  | T_NUM {$$ = $1;}
  | expresion T_OR expresion{ 
                              int retIdx = addtotable("$t" + to_string(nextTempVariable)); 
                            nextTempVariable++;
                            
                            symtable[retIdx].type = (vartype)integer ; 

                            if(isGlobal)
                              {
                                symtable[retIdx].address = nextAddress;
                                updateNextAddress(symtable[retIdx].type);
                              }
                            else
                              {
                                updateNextAddress(symtable[retIdx].type);
                                symtable[retIdx].address = nextAddressLocal;
                              }

                            $$ = retIdx;

                              gencode("or", $1, $3, retIdx, (vartype)integer);
                            }
  | expresion T_AND expresion{
                                  int retIdx = addtotable("$t" + to_string(nextTempVariable)); 
                            nextTempVariable++;
                            
                            symtable[retIdx].type = (vartype)integer ; 

                            if(isGlobal)
                              {
                                symtable[retIdx].address = nextAddress;
                                updateNextAddress(symtable[retIdx].type);
                              }
                            else
                              {
                                updateNextAddress(symtable[retIdx].type);
                                symtable[retIdx].address = nextAddressLocal;
                              }

                            $$ = retIdx;

                              gencode("and", $1, $3, retIdx, (vartype)integer);
                             }
  | expresion T_RELOP expresion {

                                  if(symtable[$1].type == (vartype)real || symtable[$3].type == (vartype)real)
                                    gencode(relop, $1, $3, 0, (vartype)real);
                                  else
                                    gencode(relop, $1, $3, 0, (vartype)integer);
                                  int retIdx = addtotable("$t" + to_string(nextTempVariable)); 
                                  symtable[retIdx].type = (vartype)integer; 
                                  nextTempVariable++;
                                if(isGlobal)
                                  {
                                    symtable[retIdx].address = nextAddress;
                                    updateNextAddress(symtable[retIdx].type);
                                  }
                                else
                                  {
                                    updateNextAddress(symtable[retIdx].type);
                                    symtable[retIdx].address = nextAddressLocal;
                                  }

                                  //dla wyniku false
                                  gencode("mov", relop_false, retIdx, 0, (vartype)integer);
                                  outFile << "jump.i\t\t#lab" << to_string(labCounter+1) << endl;

                                  //dla wyniky true
                                  outFile << endl << "lab" << to_string(labCounter) << ":" << endl;
                                  gencode("mov", relop_true, retIdx, 0, (vartype)integer);

                                  labCounter++;
                                  outFile << endl << "lab" << to_string(labCounter) << ":" << endl;
                                  labCounter++;

                                  relop_counter += 1;
                                  $$ = retIdx;

                                  }

  | T_NOT expresion {
                      gencode("je", $2, relop_false, 0, (vartype)integer);

                      int retIdx = addtotable("$t" + to_string(nextTempVariable)); 
                      symtable[retIdx].type = (vartype)integer; 
                      nextTempVariable++;
                    if(isGlobal)
                      {
                        symtable[retIdx].address = nextAddress;
                        updateNextAddress(symtable[retIdx].type);
                      }
                    else
                      {
                        updateNextAddress(symtable[retIdx].type);
                        symtable[retIdx].address = nextAddressLocal;
                      }

                      gencode("mov", relop_false, retIdx, 0, (vartype)integer);
                      outFile << "jump.i\t\t#lab" << to_string(labCounter +1) << endl;

                      //true
                      outFile << endl << "lab" << to_string(labCounter) << ":" << endl;
                      gencode("mov", relop_true, retIdx, 0, (vartype)integer);
                      labCounter++;

                      outFile << endl << "lab" << to_string(labCounter) << ":" << endl;
                      gencode("mov", relop_true, retIdx, 0, (vartype)integer);
                      labCounter++;

                      relop_counter++;
                      $$ = retIdx;

                    }

%%

void yyerror(char const *s)
{
  printf("Error: %s in line no: %d\n",s, lineno);
  std::atexit;
  yylex_destroy();
  exit(1);
};

int main()
{
  lineno = 1;
  outFile.open("out.asm");
  outFile << "jump.i\t\t#lab0";
  
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
  if(symtable[i].name==s){
    if(symtable[i].type == (vartype)procedure || symtable[i].isFunction)
      return i;
    if(isGlobal) {
      if(symtable[i].address >=0) {
        return i;
      }
    } 
    else {
       if(symtable[i].address <0) {
        return i;
      }
    }
  }
    
entry d;
d.name=s;
d.type=none;
d.value = 0;
d.address = -1;
d.global = isGlobal;
d.isFunction = false;
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


  if(symtable[v1].address == -1){
    vl1 = symtable[v1].name;
    }
  else{
    vl1 = std::to_string(symtable[v1].address);
    }

  if(symtable[v2].address == -1){
    vl2 = symtable[v2].name;
    }
  else{
    vl2 = std::to_string(symtable[v2].address);
    }

  if(symtable[v3].address == -1){
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
    if(symtable[v1].address == -1)
      operation.append("#");
    else if(symtable[v1].address < -1)
      operation.append("BP");
    operation.append(vl1);
  }
  else if(m == "mov"){
    if(symtable[v1].name == "true")
      operation.append("#1, ");
    else if(symtable[v1].name == "false")
      operation.append("#0, ");
    else {
      if(symtable[v1].address == -1)
      operation.append("#");
    else if(symtable[v1].address < -1)
      operation.append("BP");
    operation.append(vl1 + ", ");
    }
    
    if(symtable[v2].address == -1)
      operation.append("#");
    else if(symtable[v2].address < -1)
      operation.append("BP");
    operation.append(vl2);
  }
  else if(m == "jump"){
    operation.append("#lab");
    operation.append(to_string(labCounter));
  }
  else if(m == "jl" || m == "jg" || m == "jle" || m == "jge" || m == "je" || m == "jne"){
    if(symtable[v1].name == "true")
      operation.append("#1, ");
    else if(symtable[v1].name == "false")
      operation.append("#0, ");
    else {
    
    if(symtable[v1].address == -1)
      operation.append("#");
    else if(symtable[v1].address < -1)
      operation.append("BP");
    operation.append(vl1 + ", ");
    }

    if(symtable[v2].name == "true")
      operation.append("#1");
    else if(symtable[v2].name == "false")
      operation.append("#0");
    else {
    if(symtable[v2].address == -1)
      operation.append("#");
    else if(symtable[v2].address < -1)
      operation.append("BP");
    operation.append(vl2);
    }

    operation.append(", #lab");
    operation.append(to_string(labCounter));
  }
  else{
    if(symtable[v1].address == -1)
      operation.append("#");
    else if(symtable[v1].address < -1)
      operation.append("BP");
    operation.append(vl1 + ", ");

    if(symtable[v2].address == -1)
      operation.append("#");
    else if(symtable[v2].address < -1)
      operation.append("BP");
    operation.append(vl2 + ", ");

    if(symtable[v3].address == -1)
      operation.append("#");
    else if(symtable[v3].address < -1)
      operation.append("BP");
    operation.append(vl3);
  }

  if(isGlobal)
    outFile << operation << endl;
  else
    localCode << operation << endl;

}

int convertIfNeeded(int v1, vartype type){
  int retId = -1;

  if(symtable[v1].type != type){
  string convertion;
  string vl1, vl2, vl3;

  int retIdx = addtotable("$t" + to_string(nextTempVariable)); 
  nextTempVariable++;
  
  symtable[retIdx].value = symtable[v1].value; 
  

  if(type == (vartype)real){
    convertion = "inttoreal.i\t";
  }
  else {
    convertion = "realtoint.r\t";
  }

  if(symtable[v1].address == -1){
    convertion.append("#");
    vl1 = symtable[v1].name;
    }
  else{
    vl1 = std::to_string(symtable[v1].address);
  }
  if(symtable[v1].address < -1)
      convertion.append("BP");
  convertion.append(vl1 + ", ");

  symtable[retIdx].type = type;

  if(isGlobal)
    {
      symtable[retIdx].address = nextAddress;
      updateNextAddress(symtable[retIdx].type);
      }
  else
    {
      updateNextAddress(symtable[retIdx].type);
      symtable[retIdx].address = nextAddressLocal;
  }
  if(!isGlobal)
    convertion.append("BP");

  convertion.append(std::to_string(symtable[retIdx].address));
    if(isGlobal)
      outFile << convertion << endl;
    else
      localCode << convertion << endl;

    retId = retIdx;
  }

  return retId;
}

void updateNextAddress(vartype type){
  if(isGlobal)
    if(type == (vartype)real){
        nextAddress += 8;
      } else {
        nextAddress += 4;
      }
  else
    if(type == (vartype)real){
        nextAddressLocal -= 8;
      } else {
        nextAddressLocal -= 4;
      }
}

void setRelop(char* r){
  relop = r;
}

void addlineno(){
  //std::cout << lineno << "  " << endl; 
  lineno += 1;
}
