%{
// This part goes directly into the generated parser

#include "scanner.hh"
#include "parser.tab.hh"

// YY_DECL is bound to the type of the scanner. The default is 
// #define YY_DECL int Scanner::yylex()
// which is generated anyway.

//If you want the type of the generated scanner to be different, do this

#undef  YY_DECL
#define YY_DECL int IPL::Scanner::yylex( IPL::Parser::semantic_type * const lval, IPL::Parser::location_type *loc )

//We want these to be the first action after a token is recognized. 

#define YY_USER_ACTION loc->step(); loc->columns(yyleng);

// token_type is a short hand for IPL::Parser::token

using token = IPL::Parser::token;
// struct token
//   {
//     enum yytokentype
//     {
//       IDENTIFIER = 258,
//       INT_CONSTANT = 259,
//       FLOAT_CONSTANT = 260,
//       STRING_LITERAL = 261,
//     };
//   };
%}


/* %option debug */
%option nodefault
%option yyclass="Scanner"
%option noyywrap
%option c++

%%

%{ /** Code executed at the beginning of yylex **/

      yylval = lval;

%}
"/*"([^*]|(\*+[^*/]))*\*+\/           //skip
[" "|\t]                           //skip
[\n]                                      loc->lines();
struct                                   return token::STRUCT;
void                                    return token::VOID;
int                                     return token::INT;
float                                   return token::FLOAT;
return                                  return token::RETURN;
while                                   return token::WHILE;
for                                     return token::FOR;
if                                      return token::IF;
else                                    return token::ELSE;

"&&"                                    return token::AND_OP;
"||"                                    return token::OR_OP;
"=="                                    return token::EQ_OP;
"!="                                    return token::NE_OP;
"<="                                    return token::LE_OP;
">="                                    return token::GE_OP;
"++"                                    return token::INC_OP;
"->"                                    return token::PTR_OP;

"("                                     return '(';
")"                                     return ')';
"["                                     return '[';
"]"                                     return ']';
"{"                                     return '{';
"}"                                     return '}';
";"                                     return ';';
"*"                                     return '*';
","                                     return ',';
"="                                     return '=';
"<"                                     return '<';
">"                                     return '>';
"+"                                     return '+';
"-"                                     return '-';
"!"                                     return '!';
"&"                                     return '&';
"/"                                     return '/';
"."                                     return '.';


[a-zA-Z_][a-z|A-Z|0-9|_]*        {                  
                                    yylval->emplace<std::string>(YYText());
                                    // std::cout << "Identifier: " << YYText() << std::endl;
                                    return token::IDENTIFIER;
                              }

[1-9][0-9]*            |
0[bB][01]*             |
0[xX][0-9a-fA-F]*      |
0[0-7]*                       {          
                                    yylval->emplace<std::string>(YYText());
                                    // std::cout << "Integer constant: " << YYText() << std::endl;
                                    return token::INT_CONSTANT;
                              }

[[:digit:]]*[.][[:digit:]]*(([eE][+-][0-9]*|[eE][0-9]*)?)   {    
                                          yylval->emplace<std::string>(YYText());
                                          // std::cout << "Float constant: " << YYText() << std::endl;
                                          return token::FLOAT_CONSTANT;
                                    }    
["]("\\n"|"\\t"|"\\\""|"\\\\"|[^\\"])*["] {
                                                yylval->emplace<std::string>(YYText());
                                                // std::cout << "String literal: " << YYText() << std::endl;                               
                                                return token::STRING_LITERAL;
                                          }


<<EOF>>                                  yyterminate();
.				                          return token::OTHERS;

%%


