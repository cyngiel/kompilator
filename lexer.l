%{
#include "symtable.h"
#include "parser.hpp"
%}

%option noyywrap

ID	            [a-z][a-z0-9]*
DIGIT           [0-9]
NUM             {DIGIT}+
NUMREAL         {DIGIT}+(.{DIGIT}+)?
ASSIGN          ":="


%%
[ \t\r]+        {}
\n              {addlineno();}
program         {return T_PROGRAM;}
begin           {return T_BEGIN;}
end             {return T_END;}
write           {return T_WRITE;}
read            {return T_READ;}
div             {return T_DIV;}
mod             {return T_MOD;}

real            {yylval = (vartype)real; return T_REAL;}
integer	        {yylval = (vartype)integer; return T_INTEGER;}
procedure       {return T_PROCEDURE;}
function        {return T_FUNCTION;}
if              {return T_IF;}
then            {return T_THEN;}
else            {return T_ELSE;}
"<"			    {setRelop( (char*) "jl"); return T_RELOP;}
">"			    {setRelop( (char*) "jg"); return T_RELOP;}
"<="			{setRelop( (char*) "jle"); return T_RELOP;}
">="			{setRelop( (char*) "jge"); return T_RELOP;}
"="			    {setRelop( (char*) "je"); return T_RELOP;}
"<>"			{setRelop( (char*) "jne"); return T_RELOP;}
or              {return T_OR;}
and             {return T_AND;}
not             {return T_NOT;}
do              {return T_DO;}
while           {return T_WHILE;}

var             {return T_VAR;}
{ID}	        {yylval=addtotable(string(yytext));return T_ID;}
{NUM}           {yylval=addtotable(string(yytext));symtable[yylval].value = stof(yytext);symtable[yylval].type = (vartype) integer; return T_NUM;}
{NUMREAL}       {yylval=addtotable(string(yytext));symtable[yylval].value = stof(yytext);symtable[yylval].type = (vartype) real; return T_NUM;}
{ASSIGN}        {return T_ASSIGN;}

.	            {return yytext[0];}
%%
