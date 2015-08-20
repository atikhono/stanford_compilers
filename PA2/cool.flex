/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

int comm = 0;
bool err = false;
%}

/*
 * Define names for regular expressions here.
 */
DIGIT           [0-9]+
TYPEID          [A-Z]+[a-zA-Z0-9_]*
OBJECTID        [a-zA-Z]+[a-zA-Z0-9_]*

DARROW          =>
ASSIGN          <-
LE              <=

%x IN_COMMENT
%x IN_ONELINE
%x IN_TYPEID
%x IN_STRING

%%

 /*
  *  Nested comments
  */
"(*"    {
                comm++;
                BEGIN (IN_COMMENT);
        }
"--"    BEGIN (IN_ONELINE);
"*)"    {
                cool_yylval.error_msg = "Unmatched *)";
                return ERROR;
        }

<IN_ONELINE>{
\n      {
                curr_lineno++;
                BEGIN (INITIAL);
        }
.
}

<IN_COMMENT>{
"*)"	{
                comm--;
                if (comm == 0)
                        BEGIN(INITIAL);
        }
"(*"    comm++;
\n      curr_lineno++;
<<EOF>> {
                cool_yylval.error_msg = "EOF in comment";
                BEGIN(INITIAL);
                return ERROR;
        }
.		// eat comment in chunks
}


 /*
  *  The multiple-character operators.
  */
{DARROW}        { return (DARROW); }
{ASSIGN}        { return (ASSIGN); }
{LE}            { return (LE); }
{DIGIT}         {
                        cool_yylval.symbol = inttable.add_string(yytext, yyleng);
                        return (INT_CONST);
                }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */


(?i:class)              {
                                // BEGIN (IN_TYPEID);
                                return (CLASS);
                        }
(?i:inherits)           {
                                // BEGIN (IN_TYPEID);
                                return (INHERITS);
                        }
(?i:new)                {
                                // BEGIN (IN_TYPEID);
                                return (NEW);
                        }
<IN_TYPEID>{TYPEID}     {
                                cool_yylval.symbol = idtable.add_string(yytext, yyleng);
                                BEGIN (INITIAL);
                                return (TYPEID);
                        }

(?i:else)       { return (ELSE); }
(?i:fi)         { return (FI); }
(?i:if)         { return (IF); }
(?i:in)         { return (IN); }
(?i:isvoid)     { return (ISVOID); }
(?i:let)        { return (LET); }
(?i:loop)       { return (LOOP); }
(?i:pool)       { return (POOL); }
(?i:then)       { return (THEN); }
(?i:while)      { return (WHILE); }
(?i:case)       { return (CASE); }
(?i:esac)       { return (ESAC); }
(?i:of)         { return (OF); }
(?i:not)        { return (NOT); }

f(?i:alse)      {
                        cool_yylval.boolean = false;
                        return (BOOL_CONST);
                }
t(?i:rue)       {
                        cool_yylval.boolean = true;
                        return (BOOL_CONST);
                }

":"     {
                // BEGIN (IN_TYPEID);
                return ':';
        }
"+"     { return '+'; }
"/"     { return '/'; }
"-"     { return '-'; }
"*"     { return '*'; }
"="     { return '='; }
"<"     { return '<'; }
"."     { return '.'; }
"~"     { return '~'; }
","     { return ','; }
";"     { return ';'; }
"("     { return '('; }
")"     { return ')'; }
"@"     { return '@'; }
"{"     { return '{'; }
"}"     { return '}'; }

{TYPEID}        {
                        cool_yylval.symbol = idtable.add_string(yytext, yyleng);
                        return (TYPEID);
                }
{OBJECTID}      {
                        cool_yylval.symbol = idtable.add_string(yytext, yyleng);
                        return (OBJECTID);
                }

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */


\"              {
                        string_buf_ptr = string_buf;
                        BEGIN (IN_STRING);
                }
<IN_STRING>\"   {
                        BEGIN (INITIAL);
                        *string_buf_ptr = '\0';
                        if (!err) {
                                if (strlen (string_buf) <= MAX_STR_CONST-1) {
                                        cool_yylval.symbol = stringtable.add_string(string_buf,MAX_STR_CONST);
                                        return (STR_CONST);
                                }
                                else {
                                        cool_yylval.error_msg = "String constant too long.";
                                        return ERROR;
                                }
                        }
                }
<IN_STRING>\\\0 {
                        cool_yylval.error_msg = "String contains escaped null character";
                        err = true;
                        return ERROR;
                }
 <IN_STRING>\0  {
                        cool_yylval.error_msg = "String contains null character";
                        err = true; BEGIN (IN_STRING);
                        return ERROR;
                }

<IN_STRING>\\n          {
                                *string_buf_ptr++ = '\n';
                                ++curr_lineno;
                        }
<IN_STRING>\\\n         {
                                *string_buf_ptr++ = '\n';
                                ++curr_lineno;
                        }
<IN_STRING>\\t          { *string_buf_ptr++ = '\t'; }
<IN_STRING>\\b          { *string_buf_ptr++ = '\b'; }
<IN_STRING>\\f          { *string_buf_ptr++ = '\f'; }
<IN_STRING>\\\"         { *string_buf_ptr++ = '"'; }
<IN_STRING><<EOF>>      {
                                BEGIN (INITIAL);
                                cool_yylval.error_msg = "EOF in string constant";
                                return ERROR;
                        }
<IN_STRING>\n           {
                                ++curr_lineno;
                                BEGIN (INITIAL);
                                if (!err) {
                                        cool_yylval.error_msg = "Unterminated string constant";
                                        return ERROR;
                                }
                        }
<IN_STRING>\\.          { *string_buf_ptr++ = yytext[1]; }
<IN_STRING>.            { *string_buf_ptr++ = yytext[0]; }


\n              ++curr_lineno;
[ \f\r\t\v]+
.               {
                        cool_yylval.error_msg = yytext;
                        return (ERROR);
                }
%%
