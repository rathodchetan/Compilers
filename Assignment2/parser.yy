%skeleton "lalr1.cc"
%require  "3.0.1"

%defines 
%define api.namespace {IPL}
%define api.parser.class {Parser}
%define api.location.type{IPL::location}

%define parse.trace


%code requires{
   #include "ast.hh"
   #include "symtab.hh"
   #include "location.hh"
   namespace IPL {
      class Scanner;
   }
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
   #include <vector>
   #include <map>
   #include <stack>
   #include "scanner.hh"
   
   std::string typeStore = "";
   int pointerSize = 4;
   int variableSize = 4;
   int currentOffset = 0;
   bool err;
   float expval;
   float tempval;
   string currType="";
   bool lvalue;
   bool isarr;
   bool expvalid=true;
   bool isPointer = false;
   bool isVoid = false;
   bool isP = false;
   bool allP;
   bool mustPointer=false;
   stack<Entryl*> paramStack;
   map<string,vector<Entryl*>> localSymtab;
   string currentFunc = "";
   string retType = "";
   string idname="";
   map<string,vector<Entryl*>> orderedParams;
   stack<string> typeStack;


   std::map<string,abstract_astnode*> ast;
   extern SymbTab gst;
   extern std::map<std::string, string> predefined;

   void clearstack(){
      while(!typeStack.empty()){
         typeStack.pop();
      }
      return;
   }
   string typeClean(string type){
      size_t f = type.find('[');
      size_t f2 = type.find('(');
      if(f != string::npos && f2 == string::npos){
         size_t f1 = type.find(']');
         type[f]='(';
         type[f+1]='*';
         type[f1]=')';
         type.erase(type.begin()+f+2,type.begin()+f1);
      }
      f = type.find('[');
      if(f == string::npos){
         f2 = type.find('(');
         if(f2 != string::npos){
            type.erase(type.begin()+f2,type.begin()+f2+1);
            f2 = type.find(')');
            type.erase(type.begin()+f2,type.begin()+f2+1);
         }
      }
      return type;
   }
   string deref(string type){
      size_t f = type.find('[');
      if(f != string::npos){
         size_t f1 = type.find(']');
         type.erase(type.begin()+f,type.begin()+f1+1);
      }
      f = type.find('[');
      if(f == string::npos){
         size_t f1 = type.find('(');
         if(f1 != string::npos){
            type.erase(type.begin()+f1,type.begin()+f1+1);
            f1 = type.find(')');
            type.erase(type.begin()+f1,type.begin()+f1+1);
         }
         else {
            if(type[type.size()-1]=='*')
               type.pop_back();
         }
      }
      typeStack.push(type);
      return type;
   }
   string address(){
      string type = typeStack.top();
      typeStack.pop();
      if(typeStack.empty()){
         size_t f1 = type.find('*');
         if(f1==string::npos) {
            type+="*";
         }
         else{
            type = currType;
            f1 = type.find('[');
            if(f1 == string::npos){
               type+='*';
            }
            else {
               type.insert(f1,"(*)");
            }
         }
      }
      else type = typeStack.top();
      return type;
   }
   exp_astnode* checkTypeRel(string type1,string type2,string optype,string op,exp_astnode* child1,exp_astnode* child2){
      
      int t1=0,t2=0;
      if(type1=="float")   t1 = 2;
      else if(type1=="int") t1=1;
      if(type2=="float")   t2 = 2;
      else if(type2=="int") t2=1;

      if((t1==1 and t2==1))
            return new op_binary_astnode(optype+"_INT",child1,child2,type1);
      else if(t1==2 and t2==2)
            return new op_binary_astnode(optype+"_FLOAT",child1,child2,type1);
      else if(type1==type2)
            return new op_binary_astnode(optype+"_INT",child1,child2,type1);
      else if(t1==2 and t2==1)
            return new op_binary_astnode(optype+"_FLOAT",child1,new op_unary_astnode("TO_FLOAT",child2,type1),type1);
      else if(t1==1 and t2==2)
            return new op_binary_astnode(optype+"_FLOAT",new op_unary_astnode("TO_FLOAT",child1,type2),child2,type2);
      //else if((type1=="void*") and (type2=="int*" or type2=="float*")){
      //   return new op_binary_astnode(optype+"_INT",child1,child2,type2);
      //}
      //else if((type2=="void*") and (type1=="int*" or type1=="float*")){
      //   return new op_binary_astnode(optype+"_INT",child1,child2,type1);
      //}
      else{
         return nullptr;   
      }
      return nullptr;
   }
   exp_astnode* checkTypeArith(string type1,string type2,string optype,exp_astnode* child1,exp_astnode* child2){
      int t1=0,t2=0;
      if(type1=="float")   t1 = 2;
      else if(type1=="int") t1=1;
      if(type2=="float")   t2 = 2;
      else if(type2=="int") t2=1;

      if(t1==1 and t2==1)
            return new op_binary_astnode(optype+"_INT",child1,child2,type1);
      else if(t1==2 and t2==2)
            return new op_binary_astnode(optype+"_FLOAT",child1,child2,type1);
      else if(t1==2 and t2==1)
            return new op_binary_astnode(optype+"_FLOAT",child1,new op_unary_astnode("TO_FLOAT",child2,type1),type1);
      else if(t1==1 and t2==2)
            return new op_binary_astnode(optype+"_FLOAT",new op_unary_astnode("TO_FLOAT",child1,type2),child2,type2);
      else{
         if(type2=="int" && type1 != "string")return new op_binary_astnode(optype+"_INT",child1,child2,type1);
         else if(type1=="int" && type2 != "string")return new op_binary_astnode(optype+"_INT",child1,child2,type2);
         else return nullptr;
      }
      return nullptr;
   }
   exp_astnode* checkTypeMul(string type1,string type2,string optype,exp_astnode* child1,exp_astnode* child2){
      int t1=0,t2=0;
      if(type1=="float")   t1 = 2;
      else if(type1=="int") t1=1;
      if(type2=="float")   t2 = 2;
      else if(type2=="int") t2=1;
      
      if(t1==1 and t2==1)
            return new op_binary_astnode(optype+"_INT",child1,child2,type1);
      else if(t1==2 and t2==2)
            return new op_binary_astnode(optype+"_FLOAT",child1,child2,type1);
      else if(t1==2 and t2==1)
            return new op_binary_astnode(optype+"_FLOAT",child1,new op_unary_astnode("TO_FLOAT",child2,type1),type1);
      else if(t1==1 and t2==2)
            return new op_binary_astnode(optype+"_FLOAT",new op_unary_astnode("TO_FLOAT",child1,type2),child2,type2);
      else{
         return nullptr;
      }
      return nullptr;
   }
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

%nterm<SymbTab*> translation_unit
%nterm<Entryg*> struct_specifier function_definition
%nterm<Entryl*> paramater_declaration declarator_arr declarator
%nterm<vector<Entryl*>> declaration_list parameter_list declaration declarator_list
%nterm<std::string> type_specifier 
%nterm<exp_astnode*> primary_expression expression assignment_expression additive_expression logical_and_expression equality_expression relational_expression  multiplicative_expression unary_expression postfix_expression
%nterm<statement_astnode*> procedure_call selection_statement iteration_statement assignment_statement statement 
%nterm<pair<statement_astnode*,vector<Entryl*>>> compound_statement
%nterm<vector<exp_astnode*> > expression_list
%nterm<vector<statement_astnode*> > statement_list
%nterm<unary_operator_ast*> unary_operator
%nterm<pair<identifier_astnode*,vector<Entryl*>>> fun_declarator

%%

translation_unit:
      struct_specifier{
         $$ = new SymbTab();
         $$->Entries.insert({$1->iden,$1});
         gst = *$$;
      }
      | function_definition{
         $$  = new SymbTab();
         $$->Entries.insert({$1->iden,$1});
         gst = *$$;
      }
      | translation_unit struct_specifier{
         $$ = $1;
         $$->Entries.insert({$2->iden,$2});
         gst = *$$;
      }
      | translation_unit function_definition{
         $$ = $1;
         $$->Entries.insert({$2->iden,$2});
         gst = *$$;
      }
      ;

struct_specifier:
      STRUCT IDENTIFIER '{' {idname=$2;} declaration_list '}' ';'{
         $$ = new Entryg();
         $$->symbtab = new LSymbtab();
         $$->type = "-";
         $$->offset = 0;
         $$->size = -currentOffset;
         $$->scope = "global";
         $$->varfun = "struct";
         $$->iden = "struct " + $2;
         $$->symbtab->Entries = $5;
         int tempOff = 0;
         for(int i=0;i<$5.size();i++){
            localSymtab[$$->iden].push_back($5[i]);
            $5[i]->offset=-tempOff;
            tempOff-=$5[i]->size;
         }
         currentOffset = 0;
         idname = "";
      }
      ;

function_definition:
      type_specifier {retType=$1;} fun_declarator compound_statement {
         for(int i=0;i<$4.second.size();i++) $3.second.push_back($4.second[i]);
         ast[$3.first->getChild()] = $4.first;
         $$ = new Entryg();
         $$->symbtab = new LSymbtab();
         $$->type = $1;
         $$->offset = 0;
         $$->scope = "global";
         $$->varfun = "fun";
         $$->size = 0;
         $$->iden = $3.first->getChild();
         $$->symbtab->Entries = $3.second;
         currentOffset = 0;
         currentFunc="";
         retType="";
         idname="";
      }
      ;

type_specifier:
      VOID {
         $$ = "void";
         typeStore = $$;
         variableSize = 0;
      }
      | INT {
         $$ = "int";
         typeStore = $$;
         variableSize = 4;
      }
      | FLOAT {
         $$ = "float";
         typeStore = $$;
         variableSize = 4;
      }
      | STRUCT IDENTIFIER {
         $$ = "struct " + $2;
         typeStore = $$;
         if(gst.Entries.find($$)==gst.Entries.end()){
            if(idname == $2)mustPointer=true;
            else {error(@$,"\""+$$+"\""+" is not defined");}
         }
         if(idname == $2){variableSize = pointerSize;}
         else variableSize = gst.Entries[$$]->size;
      }
      ;

fun_declarator:
      IDENTIFIER '(' parameter_list ')' {
         idname = $1;
         
         if(gst.Entries.find(idname)!=gst.Entries.end()){
            error(@$,"The function \"" + idname + "\" has a previous definition");
         }

         $$.first = new identifier_astnode($1,"fun");
         currentOffset=12;
         while(!paramStack.empty()){
            Entryl* temp = paramStack.top();
            paramStack.pop();
            temp->offset = currentOffset; 
            currentOffset += temp->size;
         }
         currentFunc=$1;
         currentOffset=0;
         $$.second = $3;
         for(int i=0;i<$3.size();i++){
            localSymtab[currentFunc].push_back($3[i]);
            orderedParams[currentFunc].push_back($3[i]);
         }
      }
      | IDENTIFIER '(' ')' {
         idname = $1;
         if(gst.Entries.find(idname)!=gst.Entries.end()){
            error(@$,"The function \"" + idname + "\" has a previous definition");
         }
        $$.first = new identifier_astnode($1,"fun");
        currentFunc = $1;
      }
      ;

parameter_list: 
      paramater_declaration{
         $1->type = typeStore + $1->type;
         $$.push_back($1);
      }
      | parameter_list ',' paramater_declaration{
         $3->type = typeStore + $3->type;
         $$ = $1;
         $$.push_back($3);
      }
      ;

paramater_declaration:
      type_specifier declarator{
         $2->scope = "param";
         $$ = $2;
         paramStack.push($2);
         if(isPointer)  $2->size *= pointerSize;
         else $2->size *= variableSize;
         isPointer = false;
      }
      ;

compound_statement:
      '{' '}'{
         $$.first = new seq_astnode();
      }
      | '{' statement_list '}' {
         $$.first = new seq_astnode($2);
      }
      | '{' declaration_list '}' {
         $$.first = new seq_astnode();
         $$.second = $2;
      }
      | '{' declaration_list statement_list '}' {
         $$.first = new seq_astnode($3);
         $$.second = $2;
      }
      ;

statement_list:
      statement{
         $$.push_back($1);
         clearstack();
      }
      | statement_list statement{
         for(int i=0;i<$1.size();i++)$$.push_back($1[i]);
         $$.push_back($2);
         clearstack();
      }
      ;

statement:
      ';'{
         $$ = new empty_astnode();
      }
      | '{' statement_list '}'{
         $$ = new seq_astnode($2);
      }
      | selection_statement{
         $$ = $1;
      }
      | iteration_statement{
         $$ = $1;
      }
      | assignment_statement{
         $$ = $1;
      } 
      | procedure_call{
         $$ = $1;
      }
      | RETURN expression ';'{
         string typeV = $2->typeExp;
         if(currentFunc==""){
            error(@$,"syntax error");
         }
         string rettype = retType;
         if(rettype==typeV){
            $$ = new return_expnode($2);
         }
         else if(typeV=="int" and rettype=="float"){
            $$ = new return_expnode(new op_unary_astnode("TO_FLOAT",$2,rettype));
         }
         else if(typeV=="float" and rettype=="int"){
            $$ = new return_expnode(new op_unary_astnode("TO_INT",$2,rettype));
         }
         else{
            error(@$,"Incompatible type \""+typeV+"\" returned, expected \"" + rettype+"\"");
         }
      }
      ;

assignment_expression:
      unary_expression {if(!lvalue)error(@$,"Left operand of assignment should have an lvalue");err = isarr;} '=' {expvalid=true;} expression{
         string type1 = $1->typeExp;
         string type2 = $5->typeExp;
         if(expvalid){
            if(expval == 0)type2 = type1;
         }
         //cout<<"int ae "<<type1<<" "<<type2<<endl;
         if(type1=="INT_TYPE")   type1="int";
         if(type2=="INT_TYPE") type2="int";

         int t1=0,t2=0;
         if(type1=="float")   t1 = 2;
         else if(type1=="int") t1=1;
         if(type2=="float")   t2 = 2;
         else if(type2=="int") t2=1;
         if((t1==1 and t2==1))
               $$ = new assignE_exp($1,$5,type1);
         else if(t1==2 and t2==2)
               $$ = new assignE_exp($1,$5,type1);
         else if(t1==2 and t2==1){
               //cout<<"here\n";
               $$ = new assignE_exp($1,new op_unary_astnode("TO_FLOAT",$5,type1),type1);}
         else if(t1==1 and t2==2)
               $$ = new assignE_exp($1,new op_unary_astnode("TO_INT",$5,type1),type1);
         else if(type1=="void*"){
            size_t f = type2.find('*');
            if(f == string::npos)error(@$,"Incompatible assignment when assigning to type \"" + type1 +"\" from type \""+type2+"\"");
            $$ = new assignE_exp($1,$5,type1);
         }
         else if(type2=="void*"){
            size_t f = type1.find('*');
            if(f != string::npos && !err)$$ = new assignE_exp($1,$5,type1);
            else error(@$,"Incompatible assignment when assigning to type \"" + type1 +"\" from type \""+type2+"\"");
         }
         else 
         {
            string typ1 = type1;
            string typ2 = type2;
            if(err)error(@$,"Incompatible assignment when assigning to type \"" + typ1 +"\" from type \""+typ2+"\"");
            if(type1 == type2){
               if(type1.find('[') == string::npos)
                  $$ = new assignE_exp($1,$5,type1);
               else error(@$,"Incompatible assignment when assigning to type \"" + typ1 +"\" from type \""+typ2+"\"");
            }
            else{
               error(@$,"Incompatible assignment when assigning to type \"" + typ1 +"\" from type \""+typ2+"\"");
            }
         }
      }
      ;

assignment_statement:
      assignment_expression ';'{
         $$ = new assignS_astnode($1->getChild1(),$1->getChild2());
         string type1 = $1->getChild1()->typeExp;
         string type2 = $1->getChild2()->typeExp;
         //cout<<"in as"<<type1<<" "<<type2<<endl;
         if(type1=="INT_TYPE")   type1="int";
         if(type2=="INT_TYPE") type2="int";
         int t1=0,t2=0;
         if(type1=="float")   t1 = 2;
         else if(type1=="int") t1=1;
         if(type2=="float")   t2 = 2;
         else if(type2=="int") t2=1;
         if((t1==1 and t2==1))
               $$ = new assignS_astnode($1->getChild1(),$1->getChild2());
         else if(t1==2 and t2==2)
               $$ = new assignS_astnode($1->getChild1(),$1->getChild2());
         else if((type1 == type2)){
            $$ = new assignS_astnode($1->getChild1(),$1->getChild2());
         }
         else if(t1==2 and t2==1)
               $$ = new assignS_astnode($1->getChild1(),$1->getChild2());
         else if(t1==1 and t2==2)
               $$ = new assignS_astnode($1->getChild1(),$1->getChild2());
         else
         { 
            $$ = new assignS_astnode($1->getChild1(),$1->getChild2());
            expvalid = false;
         }
      }
      ;

procedure_call:
      IDENTIFIER '(' ')' ';'{
         identifier_astnode *iden = new identifier_astnode($1,"proc");
         if (gst.Entries.find($1)==gst.Entries.end() and predefined.find($1)==predefined.end()){
            if(idname==$1);
            else error(@$,"Procedure \""+$1+"\" not declared");
         }
         if(predefined.find($1)==predefined.end()){
            if(0<orderedParams[$1].size()){
               error(@$,"Procedure \""+$1+"\" called with too few arguments");
            }
         }
         $$ = new proccall_astnode(iden);
      }
      |  IDENTIFIER '(' expression_list ')' ';'{
         if (gst.Entries.find($1)==gst.Entries.end() and predefined.find($1)==predefined.end()){
            if(idname == $1);
            else error(@$,"Procedure \""+$1+"\" not declared");
         }
         if(predefined.find($1)==predefined.end()){
            if($3.size()<orderedParams[$1].size()){
               error(@$,"Procedure \""+$1+"\" called with too few arguments");
            }
            if($3.size()>orderedParams[$1].size()){
               error(@$,"Procedure \""+$1+"\" called with too many arguments");
            }
            for(int i=0;i<$3.size();i++){
               string type1=orderedParams[$1][i]->type;
               string type2=$3[i]->typeExp;
               type1 = typeClean(type1);
               if(type1==type2)  continue;
               if((type1=="int") and (type2=="float")){
                  $3[i] = new op_unary_astnode("TO_INT",$3[i],"int");
                  continue;
               }
               if((type1=="float") and (type2=="int")){
                  $3[i] = new op_unary_astnode("TO_FLOAT",$3[i],"float");
                  continue;
               }
               if(type1=="void*" or type2=="void*"){
                  if(type2=="int" or type2=="float") error(@$,"Expected \""+type1+"\" but argument is of type \""+type2+"\"");;
                  if(type1=="int" or type1=="float")error(@$,"Expected \""+type1+"\" but argument is of type \""+type2+"\"");;
                  continue;
               }
               error(@$,"Expected \""+type1+"\" but argument is of type \""+type2+"\"");
            }
         }
         identifier_astnode *iden = new identifier_astnode($1,"proc");
         $$ = new proccall_astnode(iden,$3);
      }
      ;

expression:
      logical_and_expression{
            $$ = $1;
      }
      |  expression OR_OP logical_and_expression{
            $$ = new op_binary_astnode("OR_OP",$1,$3,"int");
            lvalue = false;
      }
      ;

logical_and_expression:
      equality_expression{
            $$ = $1;
      }
      |  logical_and_expression AND_OP equality_expression{
            $$ = new op_binary_astnode("AND_OP",$1,$3,"int");
            lvalue=false;
      }
      ;

equality_expression:
      relational_expression{
         $$ = $1;
      }
      |  equality_expression EQ_OP {expvalid=true;} relational_expression{
         string type1 = $1->typeExp;
         string type2 = $4->typeExp;
         if(expvalid){
            if(expval == 0)type2 = type1;
         }
         $$ = checkTypeRel(type1,type2,"EQ_OP","==",$1,$4);
         if($$ == nullptr){
            if(type1=="void*"){
               size_t f = type2.find('*');
               if(f == string::npos)error(@$,"Invalid operands types for binary == , \""+$1->typeExp+"\" and \""+$4->typeExp+"\"");
               $$ = new op_binary_astnode("EQ_OP_INT",$1,$4,"int");
            }
            else if(type2=="void*"){
               size_t f = type1.find('*');
               if(f == string::npos)error(@$,"Invalid operands types for binary == , \""+$1->typeExp+"\" and \""+$4->typeExp+"\"");
               $$ = new op_binary_astnode("EQ_OP_INT",$1,$4,"int");
            }
            else error(@$,"Invalid operands types for binary == , \""+$1->typeExp+"\" and \""+$4->typeExp+"\"");
         }
         lvalue = false;
         $$->typeExp = "int";
      }
      |  equality_expression NE_OP {expvalid=true;} relational_expression{
         string type1 = $1->typeExp;
         string type2 = $4->typeExp;
         if(expvalid){
            if(expval == 0)type2 = type1;
         }
         $$ = checkTypeRel(type1,type2,"NE_OP","!=",$1,$4);
         if($$ == nullptr){
            if(type1=="void*"){
               size_t f = type2.find('*');
               if(f == string::npos)error(@$,"Invalid operands types for binary != , \""+$1->typeExp+"\" and \""+$4->typeExp+"\"");
               $$ = new op_binary_astnode("NE_OP_INT",$1,$4,"int");
            }
            else if(type2=="void*"){
               size_t f = type1.find('*');
               if(f == string::npos)error(@$,"Invalid operands types for binary != , \""+$1->typeExp+"\" and \""+$4->typeExp+"\"");
               $$ = new op_binary_astnode("NE_OP_INT",$1,$4,"int");
            }
            else error(@$,"Invalid operands types for binary != , \""+$1->typeExp+"\" and \""+$4->typeExp+"\"");
         }
         lvalue = false;
         $$->typeExp = "int";
      }
      ;

relational_expression: 
      additive_expression{
        $$ = $1;
      }
      |  relational_expression '<' additive_expression{
         $$ = checkTypeRel($1->typeExp,$3->typeExp,"LT_OP","<",$1,$3);
         if($$ == nullptr)error(@$,"Invalid operands types for binary < , \""+$1->typeExp+"\" and \""+$3->typeExp+"\"");
         $$->typeExp = "int";
         lvalue = false;
      }
      |  relational_expression '>' additive_expression{
         $$ = checkTypeRel($1->typeExp,$3->typeExp,"GT_OP",">",$1,$3);
         if($$ == nullptr)error(@$,"Invalid operands types for binary > , \""+$1->typeExp+"\" and \""+$3->typeExp+"\"");
         $$->typeExp = "int";
         lvalue = false;
      }
      |  relational_expression LE_OP additive_expression{
         $$ = checkTypeRel($1->typeExp,$3->typeExp,"LE_OP","<=",$1,$3);
         if($$ == nullptr)error(@$,"Invalid operands types for binary <= , \""+$1->typeExp+"\" and \""+$3->typeExp+"\"");
         $$->typeExp = "int";
         lvalue = false;
      }
      |  relational_expression GE_OP additive_expression{
         $$ = checkTypeRel($1->typeExp,$3->typeExp,"GE_OP",">=",$1,$3);
         if($$ == nullptr)error(@$,"Invalid operands types for binary >= , \""+$1->typeExp+"\" and \""+$3->typeExp+"\"");
         $$->typeExp = "int";
         lvalue = false;
      }
      ;

additive_expression:
      multiplicative_expression{
         $$ = $1;
      }
      |  additive_expression {tempval=expval;} '+' multiplicative_expression{
         expval = tempval+expval;
         $$ = checkTypeArith($1->typeExp,$4->typeExp,"PLUS",$1,$4);
         if($$ == nullptr)error(@$,"Invalid operand types for binary + , \""+$1->typeExp+"\" and \"" +$4->typeExp+"\"");
         lvalue = false;
         expvalid = false;
      }
      |  additive_expression {tempval=expval;} '-' multiplicative_expression{
         expval = tempval - expval;
         $$ = checkTypeArith($1->typeExp,$4->typeExp,"MINUS",$1,$4);
         if($$ == nullptr){
            if($1->typeExp == $4->typeExp)$$ = new op_binary_astnode("MINUS_INT",$1,$4,"int");
            else error(@$,"Invalid operand types for binary + , \""+$1->typeExp+"\" and \"" +$4->typeExp+"\"");
         }
         lvalue = false;
         expvalid=false;
      }
      ;

unary_expression: 
      postfix_expression{
         $$ = $1;
         isarr=false;
         if(currType.find('[') != string::npos)
            isarr=true;
      }
      | unary_operator {lvalue=true;} unary_expression{
         string typeV = $3->typeExp;
         if($1->typeExp=="ADDRESS"){
            if(!lvalue)error(@$,"Operand of & should have lvalue");
            lvalue = false;
            typeV = address();
         }
         else if($1->typeExp=="DEREF"){
            size_t f1 = typeV.find('*');
            lvalue=true;
            if(f1==string::npos){
               error(@$,"Invalid operand type \""+typeV+"\""+" of unary *");
            }
            else{
               typeV = deref(typeV);
            }
         }
         else if($1->typeExp=="UMINUS"){
            //cout<<"UMINUS\n";
            lvalue=false;
            if(!(typeV == "int" || typeV=="float")){
               error(@$,"Operand of unary - should be an int or float");
            }
            //typeV="int";
         }
         else if($1->typeExp=="NOT"){
            lvalue=false;
            typeV="int";
         }
         $$ = new op_unary_astnode($1->child1,$3,typeV);
      }
      ;

multiplicative_expression:
      unary_expression{
         $$ = $1;
      }
      |  multiplicative_expression {tempval=expval;} '*' unary_expression{
         expval = tempval*expval;
         $$ = checkTypeMul($1->typeExp,$4->typeExp,"MULT",$1,$4);
         if($$ == nullptr)error(@$,"Invalid operand types for binary * , \""+$1->typeExp+"\" and \"" + $4->typeExp+"\"");
         lvalue = false;
         expvalid=false;
      }
      |  multiplicative_expression {tempval=expval;expvalid=true;} '/' unary_expression{
         if(expvalid){
            if(expval == 0)error(@$,"Division by zero");
         }
         expval = tempval/expval;
         $$ = checkTypeMul($1->typeExp,$4->typeExp,"DIV",$1,$4);
         if($$ == nullptr)error(@$,"Invalid operand types for binary / , \""+$1->typeExp+"\" and \"" + $4->typeExp+"\"");
         lvalue = false;
         expvalid=false;
      }
      ;

postfix_expression:  
      primary_expression{
         $$ = $1;
      }
      | postfix_expression '[' expression ']'{
         string typeV = $1->typeExp;
         lvalue=true;
         if($3->typeExp != "int")error(@$,"Array subscript is not an integer");
         size_t f1 = typeV.find('*');
         if(f1==string::npos) {
            error(@$,"Subscripted value is neither array nor pointer");
         }
         else{
            size_t f = typeV.find('(');
            if(f == string::npos)
               typeV.erase(typeV.begin()+f1,typeV.begin()+f1 + 1);
            else typeV.erase(typeV.begin()+f,typeV.begin()+f+3);
            currType=typeV;
            typeV = typeClean(typeV);
            typeStack.push(typeV);
         }
         $$ = new arrayref_astnode($1,$3,typeV);
      }
      | IDENTIFIER '(' ')'{
         identifier_astnode *iden = new identifier_astnode($1,"fun");
         if (gst.Entries.find($1)==gst.Entries.end() && $1 != idname){
            if(predefined.find($1)==predefined.end()){
               error(@$,"Function \"+$1+\" not declared");
            }
            else{
               string typeV = predefined[$1];
               if(typeV=="INT_TYPE")typeV = "int";
               else typeV = "void";
               $$ = new funcall_astnode(iden,typeV);
            }
         }
         else{
            if(predefined.find($1)==predefined.end()){
               if(orderedParams[$1].size()>0){
                     error(@$,"Procedure \""+$1+"\" called with too few arguments");
               }
            }
            $$ = new funcall_astnode(iden,typeClean(gst.Entries[$1]->type));
         }
      }
      | IDENTIFIER '(' expression_list ')'{
         identifier_astnode *iden = new identifier_astnode($1,"fun");
         if (gst.Entries.find($1)==gst.Entries.end() && $1 != idname){
            if(predefined.find($1)==predefined.end()){
               error(@$,"Function \"+$1+\" not declared");
            }
            else{
               string typeV = predefined[$1];
               if(typeV=="INT_TYPE")   typeV = "int";
               else typeV = "void";
               $$ = new funcall_astnode(iden,$3,typeV);
            }
         }
         else{
            if(predefined.find($1)==predefined.end()){
               if($3.size()<orderedParams[$1].size()){
                  error(@$,"Procedure \""+$1+"\" called with too few arguments");
               }
               if($3.size()>orderedParams[$1].size()){
                  error(@$,"Procedure \""+$1+"\" called with too many arguments");
               }
               for(int i=0;i<$3.size();i++){
                  string type1=orderedParams[$1][i]->type;
                  string type2=$3[i]->typeExp;
                  type1 = typeClean(type1);
                  if(type1==type2)  continue;
                  if((type1=="int") and (type2=="float")){
                     $3[i] = new op_unary_astnode("TO_INT",$3[i],"int");
                     continue;
                  }
                  if((type1=="float") and (type2=="int")){
                     $3[i] = new op_unary_astnode("TO_FLOAT",$3[i],"float");
                     continue;
                  }
                  if(type1=="void*" or type2=="void*"){
                     if(type2=="int" or type2=="float") error(@$,"Expected \""+type1+"\" but argument is of type \""+type2+"\"");;
                     if(type1=="int" or type1=="float")error(@$,"Expected \""+type1+"\" but argument is of type \""+type2+"\"");;
                     continue;
                  }
                  if(type1=="int*" or type1=="float*"){
                     if(type1!=type2)  error(@$,"Expected \""+type1+"\" but argument is of type \""+type2+"\"");
                     continue;
                  }
                  error(@$,"Expected \""+type1+"\" but argument is of type \""+type2+"\"");
               }
            }
            if(gst.Entries.find($1)==gst.Entries.end())
               $$ = new funcall_astnode(iden,$3,typeClean(retType));
            else 
               $$ = new funcall_astnode(iden,$3,typeClean(gst.Entries[$1]->type)); 
         }
      }
      | postfix_expression '.' IDENTIFIER{
         identifier_astnode *iden = new identifier_astnode($3,"member");
         lvalue = true;
         string val = $3;
         string typeV1 = $1->typeExp;
         string typeV2 = "";
         if(typeV1==""){   
            error(@$,"Error");
         }
         if(typeV1.find('*') != string::npos){
            error(@$,"Left operand of \".\" a pointer to structure");
         }
         vector<Entryl*> temp = localSymtab[typeV1];
         for(int i=0;i<temp.size();i++){
            if(temp[i]->iden == val){
               typeV2 = temp[i]->type;
            }
         }
         if(typeV2==""){   
            error(@$,"Struct \"" + $1->typeExp + "\" has no member named \"" + $3 + "\"");
         }
         $$ = new member_astnode($1,iden,typeClean(typeV2));
         clearstack();
         currType = typeV2;
         typeStack.push(typeClean(typeV2));
      }
      | postfix_expression PTR_OP IDENTIFIER{
         identifier_astnode *iden = new identifier_astnode($3,"arrow");
         lvalue = true;
         string typeV = $1->typeExp;
         if(typeV[typeV.size()-1]!='*' || typeV[typeV.size()-2]=='*'){
            error(@$,"Left operand of \"->\" not a pointer to structure");
         }
         string val = $3;
         typeV.pop_back();
         vector<Entryl*> temp = localSymtab[typeV];
         for(int i=0;i<temp.size();i++){
            if(temp[i]->iden == val){
               typeV = temp[i]->type;
            }
         }
         $$ = new arrow_astnode($1,iden,typeClean(typeV));
         clearstack();
         currType = typeV;
         typeStack.push(typeClean(typeV));
      }
      | postfix_expression INC_OP{
         string typeV = $1->typeExp;
         $$ = new op_unary_astnode("PP",$1,typeV);
         currType = typeV;
         typeStack.push(typeClean(typeV));
      }
      ;

primary_expression: 
      INT_CONSTANT
      {
         $$ = new intconst_astnode(stoi($1));
         expval = stoi($1);
         lvalue = false;
      }                  
      | FLOAT_CONSTANT
      {
         $$ = new floatconst_astnode(stof($1));
         expval = stof($1);
         lvalue=false;
         //cout<<$1<<endl;
      }                  
      | STRING_LITERAL
      {
         $$ = new string_astnode($1);
         lvalue = false;
      }                  
      | IDENTIFIER
      {
         //cout<<$1<<endl;
         lvalue = true;
         expvalid = false;
         string typeV="";
         for(int i=0;i<localSymtab[currentFunc].size();i++){
            if(localSymtab[currentFunc][i]->iden == $1){
               typeV = localSymtab[currentFunc][i]->type;
               currType = typeV;
               typeV = typeClean(typeV);
               clearstack();
               typeStack.push(typeV);
            }
         }
         if (typeV=="")   {
            error(@$,"Variable \"" + $1 + "\" not declared");
         }
         $$ = new identifier_astnode($1,typeV);
      }   
      | '(' expression ')'
      {
         $$ = $2;
      }         
      ;

expression_list:
      expression
   {
     $$.push_back($1);
   }                  
   | expression_list ',' expression
   {
      for(int i=0;i<$1.size();i++){
         $$.push_back($1[i]);
      }
     $$.push_back($3);
   }                  
   ;

unary_operator:
      '&'
      {
         $$ = new unary_operator_ast("ADDRESS");
      }                  
      | '*'
      {
         $$ = new unary_operator_ast("DEREF");
      }                                    
      | '-'
      {
         $$ = new unary_operator_ast("UMINUS");
      }                                  
      | '!'
      {
         $$ = new unary_operator_ast("NOT");
      }                  
      ;

selection_statement:
   IF '(' expression ')' statement ELSE statement
   {
      $$ = new if_astnode($3,$5,$7);
   }                  
   ;

iteration_statement:
   WHILE '(' expression ')' statement
   {
     $$ = new while_astnode($3,$5);
   }
   | FOR '(' assignment_expression ';' expression ';' assignment_expression ')' statement
   {
     $$ = new for_astnode($3,$5,$7,$9);
   }
   ;

declaration_list: 
      declaration
      {
         for(int i=0;i<$1.size();i++){
            $$.push_back($1[i]);
            if(currentFunc!="")
               localSymtab[currentFunc].push_back($1[i]);   
         }
      }
      |  declaration_list declaration
      { 
         $$ = $1;
         for(auto i:$2){
            $$.push_back(i);
            if(currentFunc!="")
               localSymtab[currentFunc].push_back(i);
         }
      }
      ;

declaration:
      type_specifier {if($1=="void") isVoid=true; allP=true;} declarator_list ';'
      {
         if($1[0]=='s'){
            if(gst.Entries.find($1) == gst.Entries.end()){
               if(("struct " + idname) == $1 && allP);
               else error(@$,"\"" + $1 + "\"" + "is not defined");
            }
         }
         $$ = $3;
         isVoid = false;
      }
      ;

declarator_list: 
      declarator
      {
         $1->type = typeStore + $1->type;
         if(isPointer)  $1->size *= pointerSize;
         else $1->size *= variableSize;
         $1->scope = "local";
         currentOffset-=$1->size;
         $1->offset = currentOffset;
         $$.push_back($1);
         isPointer = false;
         isP = false;
      }
      |  declarator_list ',' declarator
      {
         $3->type = typeStore + $3->type;
         if(isPointer)  $3->size *= pointerSize;
         else $3->size *= variableSize;
         $3->scope = "local";
         currentOffset-=$3->size;
         $3->offset = currentOffset;
         $$ = $1;
         $$.push_back($3);
         isPointer = false;
      }
      ;

declarator_arr:
      IDENTIFIER{
         vector<Entryl*> temp = localSymtab[currentFunc];
         for(int i=0;i<temp.size();i++){
            if(temp[i]->iden == $1){
               error(@$,"\"" + $1 + "\"" + " has a previous declaration");
            }
         }
         if(!isPointer)allP=false;
         if(isVoid and !isP){
            error(@$,"Cannot declare variable of type \"void\"");
         }
         Entryl* e = new Entryl();
         e->iden = $1;
         e->type = "";
         e->size = 1;
         e->varfun = "var";
         $$ = e;
      }
      | declarator_arr '[' INT_CONSTANT ']'{
         $$ = $1;
         $$->type = $1->type + "[" + $3 + "]";
         $$->size = $1->size * stoi($3);
      }
      ;

declarator:
      declarator_arr{
         $$ = $1;
      }
      | '*' {isP = true;isPointer=true;} declarator{
         $$ = $3;
         $$->type = "*" + $3->type;
         isPointer=true;
      }
      ;

%%
void IPL::Parser::error( const location_type &l, const std::string &err_message )
{
   std::cout << "Error at line "  << l.begin.line <<": "<< err_message
    << "\n";
   exit(1);
}



