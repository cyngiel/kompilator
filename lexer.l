%{
#include "symtable.h"
#include "parser.hpp"
%}

%option noyywrap

ID	            [a-z][a-z0-9]*
DIGIT           [0-9]
NUM             {DIGIT}+
ASSIGN          ":="

%%
[ \t\r\n]+      {}
program         {return T_PROGRAM;}
begin           {return T_BEGIN;}
end             {return T_END;}
write           {return T_WRITE;}
mod             {return T_MOD;}
integer	        {yylval = (vartype)integer; return T_INTEGER;}
var             {return T_VAR;}
{ID}	        {yylval=addtotable(string(yytext));return T_ID;}
{NUM}           {yylval=addtotable(string(yytext));symtable[yylval].value = stoi(yytext);return T_NUM;}
{ASSIGN}        {return T_ASSIGN;}

.	            {return yytext[0];}
%%
