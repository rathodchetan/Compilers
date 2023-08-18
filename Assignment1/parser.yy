%skeleton "lalr1.cc"
%require  "3.0.1"

%defines 
%define api.namespace {IPL}
%define api.parser.class {Parser}

%define parse.trace

%code requires{
   namespace IPL {
      class Scanner;
   }

  // # ifndef YY_NULLPTR
  // #  if defined __cplusplus && 201103L <= __cplusplus
  // #   define YY_NULLPTR nullptr
  // #  else
  // #   define YY_NULLPTR 0
  // #  endif
  // # endif

}

%printer { std::cerr << $$; } IDENTIFIER
%printer { std::cerr << $$; } INT_CONSTANT
%printer { std::cerr << $$; } FLOAT_CONSTANT
%printer { std::cerr << $$; } STRING_LITERAL


%parse-param { Scanner  &scanner  }
%locations
%code{
   #include <iostream>
   #include <cstdlib>
   #include <fstream>
   #include <string>
   
   
   #include "scanner.hh"
   int nodeCount = 0;

#undef yylex
#define yylex IPL::Parser::scanner.yylex

}




%define api.value.type variant
%define parse.assert

%start translation_unit


%token '\n'
%token STRUCT
%token VOID 
%token INT
%token FLOAT

%token RETURN
%token AND_OP
%token OR_OP
%token EQ_OP
%token NE_OP
%token LE_OP
%token GE_OP
%token INC_OP
%token DEC_OP
%token PTR_OP
%token WHILE
%token FOR
%token IF
%token ELSE

%token <std::string> IDENTIFIER
%token <std::string> INT_CONSTANT
%token <std::string> FLOAT_CONSTANT
%token <std::string> STRING_LITERAL 
%token '(' ')' '[' ']' '{' '}' ';' '*' ',' '=' '<' '>' '+' '-' '!' '&' '/' '.'
%token OTHERS

%nterm<int> translation_unit struct_specifier function_definition declaration_list type_specifier fun_declarator compound_statement parameter_list paramater_declaration declarator_arr declarator statement_list statement selection_statement iteration_statement assignment_statement procedure_call unary_expression expression expression_list assignment_expression logical_and_expression equality_expression relational_expression additive_expression multiplicative_expression postfix_expression unary_operator declaration declarator_list primary_expression

%%

translation_unit:
      struct_specifier{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"translation_unit\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;

      }
      | function_definition{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"translation_unit\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;

      }
      | translation_unit struct_specifier{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"translation_unit\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
         std::cout << $$ << " -> " << $2 << std::endl;
      }
      | translation_unit function_definition{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"translation_unit\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
         std::cout << $$ << " -> " << $2 << std::endl;
      }
      ;
struct_specifier:
      STRUCT IDENTIFIER '{' declaration_list '}' ';'{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"struct_specifier\"]" << std::endl;
      
         ++nodeCount;
         std::cout << nodeCount << "[label=\"struct\"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
         
         ++nodeCount;
         std::cout << nodeCount << "[label=\"" << $2 << "\"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\" { \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         std::cout << $$ << " -> " << $4 << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\" } \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\" ; \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
      }
      ;
function_definition:
      type_specifier fun_declarator compound_statement {
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"function_definition\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
         std::cout << $$ << " -> " << $2 << std::endl;
         std::cout << $$ << " -> " << $3 << std::endl;
      }
      ;
type_specifier:
      VOID {
         $$ = ++nodeCount;
         std::cout <<$$<<"[label=\"type_specifier\"]" << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\" void \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
      }
      | INT {
         $$ = ++nodeCount;
         std::cout <<$$<<"[label=\"type_specifier\"]" << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\" int \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
      }
      | FLOAT {
         $$ = ++nodeCount;
         std::cout <<$$<<"[label=\"type_specifier\"]" << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\" float \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
      }
      | STRUCT IDENTIFIER {
         $$ = ++nodeCount;
         std::cout <<$$<<"[label=\"type_specifier\"]" << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\" struct \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\"" << $2 << "\"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
      }
      ;
fun_declarator:
      IDENTIFIER '(' parameter_list ')' {
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"fun_declarator\"]" << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\"" << $1 << "\"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\" ( \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         std::cout << $$ << " -> " << $3 << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\" ) \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
      }
      | IDENTIFIER '(' ')' {
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"fun_declarator\"]" << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\"" << $1 << "\"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\" ( \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\" ) \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
      }
      ;
parameter_list: 
      paramater_declaration{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"parameter_list\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
      }
      | parameter_list ',' paramater_declaration{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"parameter_list\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\",\"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         std::cout << $$ << " -> " << $3 << std::endl;
      }
      ;
paramater_declaration:
      type_specifier declarator{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"parameter_declaration\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;

         std::cout << $$ << " -> " << $2 << std::endl;
      }
      ;
declarator_arr:
      IDENTIFIER{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"declarator_arr\"]" << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\"" << $1 <<"\"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
      }
      | declarator_arr '[' INT_CONSTANT ']'{

         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"declarator_arr\"]" << std::endl;

         std::cout << $$ << " -> " << $1 << std::endl;
         
         ++nodeCount;
         std::cout << nodeCount << "[label=\" [ \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\"" << $3 <<"\"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\" ] \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
      }
      ;
declarator:
      declarator_arr{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"declarator\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
      }
      | '*' declarator{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"declarator\"]" << std::endl;
         ++nodeCount;
         std::cout << nodeCount << "[label=\" * \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         std::cout << $$ << " -> " << $2 << std::endl;
      }
      ;

compound_statement:
      '{' '}'{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"compound_statement\"]" << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\" { \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\" } \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
      }
      | '{' statement_list '}'{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"compound_statement\"]" << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\" { \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         std::cout << $$ << " -> " << $2 << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\" } \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
      }
      | '{' declaration_list statement_list '}'{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"compound_statement\"]" << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\" { \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
         std::cout << $$ << " -> " << $2 << std::endl;
         std::cout << $$ << " -> " << $3 << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\" } \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
      }
      ;
statement_list:
      statement{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"statement_list\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
      }
      | statement_list statement{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"statement_list\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
         std::cout << $$ << " -> " << $2 << std::endl;
      }
      ;

statement:
      ';'{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"statement\"]" << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\" ; \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
      }
      | '{' statement_list '}'{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"statement\"]" << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\" { \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         std::cout << $$ << " -> " << $2 << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\" } \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
      }
      | selection_statement{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"statement\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
      }
      | iteration_statement{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"statement\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
      }
      | assignment_statement{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"statement\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
      } 
      | procedure_call{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"statement\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
      }
      | RETURN expression ';'{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"statement\"]" << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\" return \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         std::cout << $$ << " -> " << $2 << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\" ; \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
      }
      ;
assignment_expression:
      unary_expression '=' expression{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"assignment_expression\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\" = \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         std::cout << $$ << " -> " << $3 << std::endl;
      }
      ;
assignment_statement:
      assignment_expression ';'{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"assignment_statement\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\" ; \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
      }
      ;
procedure_call:
      IDENTIFIER '(' ')' ';'{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"procedure_call\"]" << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\"" << $1 << "\"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\" ( \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\" ) \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\" ; \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
      }
      |  IDENTIFIER '(' expression_list ')' ';'{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"procedure_call\"]" << std::endl;

         ++nodeCount;
         std::cout << nodeCount << "[label=\"" << $1 << "\"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         std::cout << ++nodeCount << "[label=\" ( \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         std::cout << $$ << " -> " << $3 << std::endl;
         
         std::cout << ++nodeCount << "[label=\" ) \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         std::cout << ++nodeCount << "[label=\" ; \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
      }
      ;
expression:
      logical_and_expression{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"expression\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
      }
      |  expression OR_OP logical_and_expression{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"expression\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
         std::cout << ++nodeCount << "[label=\" || \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         std::cout << $$ << " -> " << $3 << std::endl;
      }
      ;
logical_and_expression:
      equality_expression{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"logical_and_expression\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
      }
      |  logical_and_expression AND_OP equality_expression{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"logical_and_expression\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
         std::cout << ++nodeCount << "[label=\" && \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         std::cout << $$ << " -> " << $3 << std::endl;
      }
      ;
equality_expression:
      relational_expression{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"equality_expression\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
      }
      |  equality_expression EQ_OP relational_expression{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"equality_expression\"]" << std::endl;

         std::cout << $$ << " -> " << $1 << std::endl;

         std::cout << ++nodeCount << "[label=\" == \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         std::cout << $$ << " -> " << $3 << std::endl;
      }
      |  equality_expression NE_OP relational_expression{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"equality_expression\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;

         std::cout << ++nodeCount << "[label=\" != \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         std::cout << $$ << " -> " << $3 << std::endl;
      }
      ;
relational_expression: 
      additive_expression{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"relational_expression\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
      }
      |  relational_expression '<' additive_expression{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"relational_expression\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;

         std::cout << ++nodeCount << "[label=\" < \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         std::cout << $$ << " -> " << $3 << std::endl;
      }
      |  relational_expression '>' additive_expression{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"relational_expression\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
         std::cout << ++nodeCount << "[label=\" > \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
         std::cout << $$ << " -> " << $3 << std::endl;
      }
      |  relational_expression LE_OP additive_expression{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"relational_expression\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
         std::cout << ++nodeCount << "[label=\" <= \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
         std::cout << $$ << " -> " << $3 << std::endl;
      }
      |  relational_expression GE_OP additive_expression{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"relational_expression\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
         std::cout << ++nodeCount << "[label=\" >= \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
         std::cout << $$ << " -> " << $3 << std::endl;
      }
      ;
additive_expression:
      multiplicative_expression{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"additive_expression\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
      }
      |  additive_expression '+' multiplicative_expression{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"additive_expression\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;

         std::cout << ++nodeCount << "[label=\" + \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         std::cout << $$ << " -> " << $3 << std::endl;
      }
      |  additive_expression '-' multiplicative_expression{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"additive_expression\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
         std::cout << ++nodeCount << "[label=\" - \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
         std::cout << $$ << " -> " << $3 << std::endl;
      }
      ;
unary_expression: 
      postfix_expression{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"unary_expression\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
      }
      | unary_operator unary_expression{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"unary_expression\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
         std::cout << $$ << " -> " << $2 << std::endl;
      }
      ;
multiplicative_expression:
      unary_expression{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"multiplicative_expression\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
      }
      |  multiplicative_expression '*' unary_expression{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"multiplicative_expression\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
         std::cout << ++nodeCount << "[label=\" * \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
         std::cout << $$ << " -> " << $3 << std::endl;
      }
      |  multiplicative_expression '/' unary_expression{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"multiplicative_expression\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
         std::cout << ++nodeCount << "[label=\" / \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
         std::cout << $$ << " -> " << $3 << std::endl;
      }
      ;
postfix_expression:  
      primary_expression{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"postfix_expression\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
      }
      | postfix_expression '[' expression ']'{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"postfix_expression\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
         std::cout << ++nodeCount << "[label=\" [ \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
         std::cout << $$ << " -> " << $3 << std::endl;
         std::cout << ++nodeCount << "[label=\" ] \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
      }
      | IDENTIFIER '(' ')'{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"postfix_expression\"]" << std::endl;
         std::cout << ++nodeCount << "[label=\"" << $1 << "\"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
         std::cout << ++nodeCount << "[label=\" ( \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
         std::cout << ++nodeCount << "[label=\" ) \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
      }
      | IDENTIFIER '(' expression_list ')'{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"postfix_expression\"]" << std::endl;


         std::cout << ++nodeCount << "[label=\"" << $1 << "\"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;

         std::cout << ++nodeCount << "[label=\" ( \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
         std::cout << $$ << " -> " << $3 << std::endl;
         std::cout << ++nodeCount << "[label=\" ) \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
      }
      | postfix_expression '.' IDENTIFIER{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"postfix_expression\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
         std::cout << ++nodeCount << "[label=\" . \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
         std::cout << ++nodeCount << "[label=\"" << $3 << "\"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
      }
      | postfix_expression PTR_OP IDENTIFIER{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"postfix_expression\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
         std::cout << ++nodeCount << "[label=\" -> \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
         std::cout << ++nodeCount << "[label=\"" << $3 << "\"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
      }
      | postfix_expression INC_OP{
         $$ = ++nodeCount;
         std::cout << $$ << "[label=\"postfix_expression\"]" << std::endl;
         std::cout << $$ << " -> " << $1 << std::endl;
         std::cout << ++nodeCount << "[label=\" ++ \"]" <<std::endl;
         std::cout << $$ << " -> " << nodeCount << std::endl;
      }
      ;

primary_expression: 
      INT_CONSTANT
   {
     $$ = ++nodeCount;
     std::cout << $$ << "[label=\"primary_expression\"]" << std::endl;
     std::cout << ++nodeCount << "[label=\"" << $1 << "\"]" << std::endl;
     std::cout << $$ << " -> " << nodeCount << std::endl;
   }                  
   | FLOAT_CONSTANT
   {
     $$ = ++nodeCount;
     std::cout << $$ << "[label=\"primary_expression\"]" << std::endl;
     std::cout << ++nodeCount << "[label=\"" << $1 << "\"]" << std::endl;
     std::cout << $$ << " -> " << nodeCount << std::endl;
   }                  
   | STRING_LITERAL
   {
     $$ = ++nodeCount;
     std::cout << $$ << "[label=\"primary_expression\"]" << std::endl;
     std::cout << ++nodeCount << "[label= \"\\\"\" + " << $1 << " + \"\\\"\"]" << std::endl;
     std::cout << $$ << " -> " << nodeCount << std::endl;
   }                  
   | IDENTIFIER
   {
     $$ = ++nodeCount;
     std::cout << $$ << "[label=\"primary_expression\"]" << std::endl;
     std::cout << ++nodeCount << "[label=\"" << $1 << "\"]" << std::endl;
     std::cout << $$ << " -> " << nodeCount << std::endl;
   }   
   | '(' expression ')'
   {
     $$ = ++nodeCount;
     std::cout << $$ << "[label=\"primary_expression\"]" << std::endl;
     std::cout << ++nodeCount << "[label=\" ( \"]" <<std::endl;
     std::cout << $$ << " -> " << nodeCount << std::endl;
     std::cout << $$ << " -> " << $2 << std::endl;
     std::cout << ++nodeCount << "[label=\" ) \"]" <<std::endl;
     std::cout << $$ << " -> " << nodeCount << std::endl;
   }         
   ;
expression_list:
      expression
   {
     $$ = ++nodeCount;
     std::cout << $$ << "[label=\"expression_list\"]" << std::endl;
     std::cout << $$ << " -> " << $1 << std::endl;
   }                  
   | expression_list ',' expression
   {
     $$ = ++nodeCount;
     std::cout << $$ << "[label=\"expression_list\"]" << std::endl;
     std::cout << $$ << " -> " << $1 << std::endl;
     std::cout << ++nodeCount << "[label=\" , \"]" <<std::endl;
     std::cout << $$ << " -> " << nodeCount << std::endl;
     std::cout << $$ << " -> " << $3 << std::endl;
   }                  
   ;
unary_operator:
      '&'
   {
     $$ = ++nodeCount;
     std::cout << $$ << "[label=\"unary_operator\"]" << std::endl;
     std::cout << ++nodeCount << "[label=\" & \"]" <<std::endl;
     std::cout << $$ << " -> " << nodeCount << std::endl;
   }                  
   | '*'
   {
     $$ = ++nodeCount;
     std::cout << $$ << "[label=\"unary_operator\"]" << std::endl;
     std::cout << ++nodeCount << "[label=\" * \"]" <<std::endl;
     std::cout << $$ << " -> " << nodeCount << std::endl;
   }                                    
   | '-'
   {
     $$ = ++nodeCount;
     std::cout << $$ << "[label=\"unary_operator\"]" << std::endl;
     std::cout << ++nodeCount << "[label=\" - \"]" <<std::endl;
     std::cout << $$ << " -> " << nodeCount << std::endl;
   }                                  
   | '!'
   {
     $$ = ++nodeCount;
     std::cout << $$ << "[label=\"unary_operator\"]" << std::endl;
     std::cout << ++nodeCount << "[label=\" ! \"]" <<std::endl;
     std::cout << $$ << " -> " << nodeCount << std::endl;
   }                  
   ;
selection_statement:
   IF '(' expression ')' statement ELSE statement
   {
     $$ = ++nodeCount;
     std::cout << $$ << "[label=\"selection_statement\"]" << std::endl;
     std::cout << ++nodeCount << "[label=\" if \"]" <<std::endl;
     std::cout << $$ << " -> " << nodeCount << std::endl;
     std::cout << ++nodeCount << "[label=\" ( \"]" <<std::endl;
     std::cout << $$ << " -> " << nodeCount << std::endl;
     std::cout << $$ << " -> " << $3 << std::endl;
     std::cout << ++nodeCount << "[label=\" ) \"]" <<std::endl;
     std::cout << $$ << " -> " << nodeCount << std::endl;
     std::cout << $$ << " -> " << $5 << std::endl;
     std::cout << ++nodeCount << "[label=\" else \"]" <<std::endl;
     std::cout << $$ << " -> " << nodeCount << std::endl;
     std::cout << $$ << " -> " << $7 << std::endl;
   }                  
   ;
iteration_statement:
   WHILE '(' expression ')' statement
   {
     $$ = ++nodeCount;
     std::cout << $$ << "[label=\"iteration_statement\"]" << std::endl;
     std::cout << ++nodeCount << "[label=\" while \"]" <<std::endl;
     std::cout << $$ << " -> " << nodeCount << std::endl;
     std::cout << ++nodeCount << "[label=\" ( \"]" <<std::endl;
     std::cout << $$ << " -> " << nodeCount << std::endl;

     std::cout << $$ << " -> " << $3 << std::endl;

     std::cout << ++nodeCount << "[label=\" ) \"]" <<std::endl;
     std::cout << $$ << " -> " << nodeCount << std::endl;
     std::cout << $$ << " -> " << $5 << std::endl;
   }
   | FOR '(' assignment_expression ';' expression ';' assignment_expression ')' statement
   {
     $$ = ++nodeCount;
     std::cout << $$ << "[label=\"iteration_statement\"]" << std::endl;
     std::cout << ++nodeCount << "[label=\" for \"]" <<std::endl;
     std::cout << $$ << " -> " << nodeCount << std::endl;
     std::cout << ++nodeCount << "[label=\" ( \"]" <<std::endl;
     std::cout << $$ << " -> " << nodeCount << std::endl;
     std::cout << $$ << " -> " << $3 << std::endl;
     std::cout << ++nodeCount << "[label=\" ; \"]" <<std::endl;
     std::cout << $$ << " -> " << nodeCount << std::endl;
     std::cout << $$ << " -> " << $5 << std::endl;
     std::cout << ++nodeCount << "[label=\" ; \"]" <<std::endl;
     std::cout << $$ << " -> " << nodeCount << std::endl;
     std::cout << $$ << " -> " << $7 << std::endl;
     std::cout << ++nodeCount << "[label=\" ) \"]" <<std::endl;
     std::cout << $$ << " -> " << nodeCount << std::endl;
     std::cout << $$ << " -> " << $9 << std::endl;
   }
   ;
declaration_list: 
   declaration
   {
     $$ = ++nodeCount;
     std::cout << $$ << "[label=\"declaration_list\"]" << std::endl;
     std::cout << $$ << " -> " << $1 << std::endl;
   }
   |  declaration_list declaration
   {
     $$ = ++nodeCount;
     std::cout << $$ << "[label=\"declaration_list\"]" << std::endl;
     std::cout << $$ << " -> " << $1 << std::endl;
     std::cout << $$ << " -> " << $2 << std::endl;
   }
   ;
declaration:
   type_specifier declarator_list ';'
   {
     $$ = ++nodeCount;
     std::cout << $$ << "[label=\"declaration\"]" << std::endl;
     std::cout << $$ << " -> " << $1 << std::endl;
     std::cout << $$ << " -> " << $2 << std::endl;
     std::cout << ++nodeCount << "[label=\" ; \"]" <<std::endl;
     std::cout << $$ << " -> " << nodeCount << std::endl;
   }
   ;
declarator_list: 
   declarator
   {
     $$ = ++nodeCount;
     std::cout << $$ << "[label=\"declarator_list\"]" << std::endl;
     std::cout << $$ << " -> " << $1 << std::endl;
   }
   |  declarator_list ',' declarator
   {
     $$ = ++nodeCount;
     std::cout << $$ << "[label=\"declarator_list\"]" << std::endl;
     std::cout << $$ << " -> " << $1 << std::endl;
     std::cout << ++nodeCount << "[label=\" , \"]" <<std::endl;
     std::cout << $$ << " -> " << nodeCount << std::endl;
     std::cout << $$ << " -> " << $3 << std::endl;
   }
   ;

%%
void IPL::Parser::error( const location_type &l, const std::string &err_message )
{
   std::cerr << "Error: " << err_message << " at " << l << "\n";
}



