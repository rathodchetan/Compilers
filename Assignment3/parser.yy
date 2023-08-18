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
   #include "codegen.hh"
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
   
   funcCode localfuncCode;
   int labelNum=0;
   vector<string> removeLocalCode;
   string retCode = "";

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
   extern code assembly;
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
      
      

      return new op_binary_astnode(optype+"_INT",child1,child2,type1);
   }
   exp_astnode* checkTypeArith(string type1,string type2,string optype,exp_astnode* child1,exp_astnode* child2){
      
      return new op_binary_astnode(optype+"_INT",child1,child2,type1);
     
   }
   exp_astnode* checkTypeMul(string type1,string type2,string optype,exp_astnode* child1,exp_astnode* child2){
      
      return new op_binary_astnode(optype+"_INT",child1,child2,type1);
      
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
%nterm< pair< vector<statement_astnode*> ,string> > statement_list
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
            //cout<<"changed "<<$5[i]->offset<<endl;
            tempOff-=$5[i]->size;
         }
         currentOffset = 0;
         idname = "";
      }
      ;

function_definition:
      type_specifier {retType=$1;} fun_declarator compound_statement {
         
         localfuncCode.instr.push_back(".END"+currentFunc+":\n");
         for(int i=0;i<removeLocalCode.size();i++){
            localfuncCode.instr.push_back(removeLocalCode[i]);
         }
         removeLocalCode.clear();
         //localfuncCode.instr.push_back("\tpushl %eax\n");
         //localfuncCode.instr.push_back(retCode);
         //retCode="";
         localfuncCode.instr.push_back("\tleave\n");
         localfuncCode.instr.push_back("\tret\n");
         localfuncCode.instr.push_back("\t.size	"+currentFunc+", .-"+currentFunc+"\n");
         assembly.funcInstr.push_back(localfuncCode);
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
         
         localfuncCode.iden = $1;
         localfuncCode.instr.clear();

         //setting dynamic link;
         localfuncCode.instr.push_back("\tpushl	%ebp\n");
         localfuncCode.instr.push_back("\tmovl	%esp, %ebp\n");

         //assembly.funcInstr.push_back(localfuncCode);


         if(gst.Entries.find(idname)!=gst.Entries.end()){
            error(@$,"The function \"" + idname + "\" has a previous definition");
         }
         

         $$.first = new identifier_astnode($1,"fun","nop","null");
         currentOffset=12;
         while(!paramStack.empty()){
            Entryl* temp = paramStack.top();
            paramStack.pop();
            //cout<<"PrevTest: "<<temp->iden<<" "<<temp->offset<<endl;
            temp->offset = currentOffset; 
            currentOffset += temp->size;
            //cout<<"Test: "<<temp->iden<<" "<<temp->offset<<endl;
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

         localfuncCode.iden = $1;
         localfuncCode.instr.clear();
      
         //setting dynamic link;
         localfuncCode.instr.push_back("\tpushl	%ebp\n");
         localfuncCode.instr.push_back("\tmovl	%esp, %ebp\n");

         //assembly.funcInstr.push_back(localfuncCode);

         if(gst.Entries.find(idname)!=gst.Entries.end()){
            error(@$,"The function \"" + idname + "\" has a previous definition");
         }
        $$.first = new identifier_astnode($1,"fun","nop","null");
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
         $$.first = new seq_astnode($2.first);
         localfuncCode.instr.push_back($2.second);
      }
      | '{' declaration_list '}' {
         $$.first = new seq_astnode();
         $$.second = $2;
      }
      | '{' declaration_list statement_list '}' {
         $$.first = new seq_astnode($3.first);
         $$.second = $2;
         localfuncCode.instr.push_back($3.second);
      }
      ;

statement_list:
      statement{
         //localfuncCode.instr.push_back($1->rcode);
         $$.first.push_back($1);
         $$.second = $1->rcode;
         clearstack();
         
      }
      | statement_list statement{
         //localfuncCode.instr.push_back($2->rcode);
         for(int i=0;i<$1.first.size();i++)$$.first.push_back($1.first[i]);
         $$.first.push_back($2);
         $$.second = $1.second + $2->rcode;
         clearstack();
      }
      ;

statement:
      ';'{
         $$ = new empty_astnode();
      }
      | '{' statement_list '}'{
         $$ = new seq_astnode($2.first,$2.second);
      }
      | selection_statement{
         //localfuncCode.instr.push_back($1->rcode);
         $$ = $1;
      }
      | iteration_statement{
         $$ = $1;
      }
      | assignment_statement{
         //localfuncCode.instr.push_back($1->rcode);
         
         $$ = $1;
      } 
      | procedure_call{
         //localfuncCode.instr.push_back($1->rcode);
         $$ = $1;
      }
      | RETURN expression ';'{
         string typeV = $2->typeExp;

         //localfuncCode.instr.push_back($2->rcode);
         //localfuncCode.instr.push_back("\tpopl %eax\n");
         string code = $2->rcode;
         code += "\tpopl %eax\n";
         code += "\tjmp .END"+currentFunc+"\n";
         //retCode = $2->rcode + "\tpopl %eax\n";
         if(currentFunc==""){
            error(@$,"syntax error");
         }
         string rettype = retType;
         
         $$ = new return_expnode($2,code);
         
         
         
      }
      ;

assignment_expression:
      unary_expression {if(!lvalue)error(@$,"Left operand of assignment should have an lvalue");err = isarr;} '=' {expvalid=true;} expression{
         
         //localfuncCode.instr.push_back($5->rcode);
         //cout<<$1->lloc<<"\n";
         string code = $5->rcode;

         
         code += "\tpopl %eax\n";
         code += "\tmovl %eax, "+$1->lloc+"\n";
         //localfuncCode.instr.push_back(code);

         string type1 = $1->typeExp;
         string type2 = $5->typeExp;
         if(expvalid){
            if(expval == 0)type2 = type1;
         }
         //cout<<"int ae "<<type1<<" "<<type2<<endl;
         if(type1=="INT_TYPE")   type1="int";
         if(type2=="INT_TYPE") type2="int";

   
         
         $$ = new assignE_exp($1,$5,type1,code);
         
         
      }
      ;

assignment_statement:
      assignment_expression ';'{
         $$ = new assignS_astnode($1->getChild1(),$1->getChild2(),$1->rcode);
      }
      ;

procedure_call:
      IDENTIFIER '(' ')' ';'{
         identifier_astnode *iden = new identifier_astnode($1,"proc","nop","null");
         
         string code = "";
         //localfuncCode.instr.push_back("\tcall "+$1 + '\n');
         code += "\tcall "+$1 + '\n';
         if (gst.Entries.find($1)==gst.Entries.end() and predefined.find($1)==predefined.end()){
            if(idname==$1);
            else error(@$,"Procedure \""+$1+"\" not declared");
         }
         if(predefined.find($1)==predefined.end()){
            if(0<orderedParams[$1].size()){
               error(@$,"Procedure \""+$1+"\" called with too few arguments");
            }
         }
         $$ = new proccall_astnode(iden,code);
      }
      |  IDENTIFIER '(' expression_list ')' ';'{

         
         int stCount = 0;
         string code = "";
         for(int i=$3.size()-1;i>=0;i--){
            //localfuncCode.instr.push_back($3[i]->rcode);
            code += $3[i]->rcode;
            stCount++;
         }
   
         if($1=="printf"){
            //space for return value
            int te = assembly.globals.size();
            //localfuncCode.instr.push_back("\tpushl $.LC" + to_string(te-1)+"\n");
            code += "\tpushl $.LC" + to_string(te-1)+"\n"; 
            //stCount++;
         }
         else{

            //localfuncCode.instr.push_back("\tsubl $4,%esp\n");
            code += "\tsubl $4,%esp\n";
         }
         //localfuncCode.instr.push_back("\tcall "+$1 + '\n');
         code += "\tcall "+$1 + '\n';
         if($1!="printf"){

            //localfuncCode.instr.push_back("\taddl $4,%esp\n");
            code += "\taddl $4,%esp\n";
         }
         //localfuncCode.instr.push_back("\taddl	$"+to_string(4*stCount)+", %esp\n");
         code += "\taddl	$"+to_string(4*stCount)+", %esp\n";
         

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
               
               error(@$,"Expected \""+type1+"\" but argument is of type \""+type2+"\"");
            }
         }
         identifier_astnode *iden = new identifier_astnode($1,"proc","nop","null");
         $$ = new proccall_astnode(iden,$3,code);
      }
      ;

expression:
      logical_and_expression{
            $$ = $1;
      }
      |  expression OR_OP logical_and_expression{
            string code = $1->rcode + $3->rcode;
            string newLabel = ".L"+to_string(labelNum);
            labelNum++;
            string orCode="";
            orCode += "\tpopl %edx\n";
            orCode += "\tpopl %eax\n";
            orCode += "\tpushl $1\n";
            orCode += "\tcmp $0,%eax\n";
            orCode += "\tjne "+newLabel+"\n";
            orCode += "\tcmp $0,%edx\n";
            orCode += "\tjne "+newLabel+"\n";
            orCode += "\tpopl %eax\n";
            orCode += "\tpushl $0\n";
            orCode += newLabel+":\n";

            code = code + orCode;

            $$ = new op_binary_astnode("OR_OP",$1,$3,"int",code);
            lvalue = false;
      }
      ;

logical_and_expression:
      equality_expression{
            $$ = $1;
      }
      |  logical_and_expression AND_OP equality_expression{

            string newLabel = ".L"+to_string(labelNum);
            labelNum++;
            string code = $1->rcode + $3->rcode;
            string andCode="";
            andCode += "\tpopl %edx\n";
            andCode += "\tpopl %eax\n";
            andCode += "\tpushl $0\n";
            andCode +="\tcmp $0,%eax\n";
            andCode +="\tje "+newLabel+"\n";
            andCode +="\tcmp $0,%edx\n";
            andCode +="\tje "+newLabel+"\n";
            andCode +="\tpopl %eax\n";
            andCode +="\tpushl $1\n";
            andCode +=newLabel+":\n";

            code = code + andCode;

            $$ = new op_binary_astnode("AND_OP",$1,$3,"int",code);
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

         string code = $1->rcode + $4->rcode;
         code += "\tpopl %eax\n";
         code += "\tpopl %edx\n";
         code += "\tpushl $1\n";
         code += "\tcmp %eax, %edx\n";
         code += "\tje .L" + to_string(labelNum) + "\n";
         code += "\taddl $4,%esp\n";
         code += "\tpushl $0\n .L"+to_string(labelNum)+":\n";
      
         labelNum++;

         //$$ = checkTypeRel(type1,type2,"EQ_OP","==",$1,$4);
         $$ = new op_binary_astnode("EQ_OP_INT",$1,$4,type1,code);
         
         lvalue = false;
         $$->typeExp = "int";
      }
      |  equality_expression NE_OP {expvalid=true;} relational_expression{
         string type1 = $1->typeExp;
         string type2 = $4->typeExp;
         if(expvalid){
            if(expval == 0)type2 = type1;
         }

         string code = $1->rcode + $4->rcode;
         code += "\tpopl %eax\n\tpopl %edx\n\tpushl $1\n\tcmp %eax, %edx\n\tjne .L" + to_string(labelNum) + "\n\taddl $4,%esp\n\tpush $0\n .L"+to_string(labelNum)+":\n";
      
         labelNum++;

         $$ = new op_binary_astnode("NE_OP_INT",$1,$4,type1,code);
         
         lvalue = false;
         $$->typeExp = "int";
      }
      ;

relational_expression: 
      additive_expression{
        $$ = $1;
      }
      |  relational_expression '<' additive_expression{
         //$$ = checkTypeRel($1->typeExp,$3->typeExp,"LT_OP","<",$1,$3);

         
         string code = $1->rcode + $3->rcode;
         code += "\tpopl %eax\n\tpopl %edx\n\tpushl $1\n\tcmp %eax, %edx\n\tjl .L" + to_string(labelNum) + "\n\taddl $4,%esp\n\tpush $0\n .L"+to_string(labelNum)+":\n";
      
         labelNum++;
         $$ = new op_binary_astnode("LT_OP_INT",$1,$3,$1->typeExp,code);
         $$->typeExp = "int";
         lvalue = false;
      }
      |  relational_expression '>' additive_expression{
         //$$ = checkTypeRel($1->typeExp,$3->typeExp,"GT_OP",">",$1,$3);
         //if($$ == nullptr)error(@$,"Invalid operands types for binary > , \""+$1->typeExp+"\" and \""+$3->typeExp+"\"");
         
         string code = $1->rcode + $3->rcode;
         code += "\tpopl %eax\n\tpopl %edx\n\tpushl $1\n\tcmp %eax, %edx\n\tjg .L" + to_string(labelNum) + "\n\taddl $4,%esp\n\tpush $0\n .L"+to_string(labelNum)+":\n";
      
         labelNum++;
         $$ = new op_binary_astnode("GT_OP_INT",$1,$3,$1->typeExp,code);

         $$->typeExp = "int";
         lvalue = false;
      }
      |  relational_expression LE_OP additive_expression{
         
         string code = $1->rcode + $3->rcode;
         code += "\tpopl %eax\n\tpopl %edx\n\tpushl $1\n\tcmp %eax, %edx\n\tjle .L" + to_string(labelNum) + "\n\taddl $4,%esp\n\tpush $0\n .L"+to_string(labelNum)+":\n";
      
         labelNum++;
         $$ = new op_binary_astnode("LE_OP",$1,$3,$1->typeExp,code);

         $$->typeExp = "int";
         lvalue = false;
      }
      |  relational_expression GE_OP additive_expression{
         string code = $1->rcode + $3->rcode;
         code += "\tpopl %eax\n\tpopl %edx\n\tpushl $1\n\tcmp %eax, %edx\n\tjge .L" + to_string(labelNum) + "\n\taddl $4,%esp\n\tpush $0\n .L"+to_string(labelNum)+":\n";
      
         labelNum++;
         $$ = new op_binary_astnode("GE_OP",$1,$3,$1->typeExp,code);
         $$->typeExp = "int";
         lvalue = false;
      }
      ;

additive_expression:
      multiplicative_expression{
         $$ = $1;
      }
      |  additive_expression {tempval=expval;} '+' multiplicative_expression{
         
         string code = $1->rcode + $4->rcode;
         //eax edx
         string addCode = "\tpopl %eax\n\tpopl %edx\n\taddl %edx,%eax\n\tpushl %eax\n";
         code = code + addCode;
         
         expval = tempval+expval;
   
         string type1 = $1->typeExp;
         string type2 = $4->typeExp;
         if(type1=="int" and type2=="int")
            $$ = new op_binary_astnode("PLUS_INT",$1,$4,type1,code);
         else{
            if(type2=="int" && type1 != "string")$$ = new op_binary_astnode("ADD_INT",$1,$4,type1,code);
            else if(type1=="int" && type2 != "string")$$ = new op_binary_astnode("ADD_INT",$1,$4,type2,code);
            
         }  

         lvalue = false;
         expvalid = false;
      }
      |  additive_expression {tempval=expval;} '-' multiplicative_expression{
         expval = tempval - expval;

         string code = $1->rcode + $4->rcode;
         //eax edx
         string subCode = "\tpopl %edx\n\tpopl %eax\n\tsubl %edx,%eax\n\tpushl %eax\n";
         code = code + subCode;

         
         string type1 = $1->typeExp;
         string type2 = $4->typeExp;
         if(type1=="int" and type2=="int")
            $$ = new op_binary_astnode("MINUS_INT",$1,$4,type1,code);
         else{
            if(type2=="int" && type1 != "string")$$ = new op_binary_astnode("MINUS_INT",$1,$4,type1,code);
            else if(type1=="int" && type2 != "string")$$ = new op_binary_astnode("MINUS_INT",$1,$4,type2,code);
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
         string code = "";
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
            code = $3->rcode;
            code += "\tpopl %eax\n";
            code += "\timull $-1, %eax\n";
            code += "\tpushl %eax\n";
            //typeV="int";

            
         }
         else if($1->typeExp=="NOT"){
            lvalue=false;
            typeV="int";
            code = $3->rcode;
            code += "\tpopl %eax\n";
            code += "\tpushl $1\n";
            code += "\tcmp $0, %eax\n";
            code += "\tje .L" + to_string(labelNum)+"\n";
            code += "\tpopl %eax\n";
            code += "\tpushl $0\n";
            code += ".L"+to_string(labelNum)+":\n";
            labelNum++;
         }
         $$ = new op_unary_astnode($1->child1,$3,typeV,code);
      }
      ;

multiplicative_expression:
      unary_expression{
         $$ = $1;
      }
      |  multiplicative_expression {tempval=expval;} '*' unary_expression{
         expval = tempval*expval;

         string code = $1->rcode + $4->rcode;
         //eax edx
         string mulCode = "\tpopl %eax\n\tpopl %edx\n\timull %edx,%eax\n\tpushl %eax\n";
         code = code + mulCode;

         $$ = new op_binary_astnode("MULT_INT",$1,$4,$1->typeExp,code);
         
         if($$ == nullptr)error(@$,"Invalid operand types for binary * , \""+$1->typeExp+"\" and \"" + $4->typeExp+"\"");
         lvalue = false;
         expvalid=false;
      }
      |  multiplicative_expression {tempval=expval;expvalid=true;} '/' unary_expression{
         
         
         string code =  $1->rcode + $4->rcode;
         code += "\tpopl %ebx\n";
         code += "\tpopl %eax\n";
         code += "\tmovl $0,%edx\n";
         code += "\tcltd\n";
         code += "\tidivl %ebx\n";
         code += "\tpushl %eax\n";
      
         if(expvalid){
            if(expval == 0)error(@$,"Division by zero");
         }
         expval = tempval/expval;
         $$ = new op_binary_astnode("DIV_INT",$1,$4,$1->typeExp,code);
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
         identifier_astnode *iden = new identifier_astnode($1,"fun","nop","null");

         string code = "\tsubl $4,%esp\n";
         code += "\tcall "+$1 + "\n";
         code += "\taddl $4,%esp\n";
         code += "\tpushl %eax\n";

         if (gst.Entries.find($1)==gst.Entries.end() && $1 != idname){
            if(predefined.find($1)==predefined.end()){
               error(@$,"Function \"+$1+\" not declared");
            }
            else{
               string typeV = predefined[$1];
               if(typeV=="INT_TYPE")typeV = "int";
               else typeV = "void";
               $$ = new funcall_astnode(iden,typeV,code);
            }
         }
         else{
            if(predefined.find($1)==predefined.end()){
               if(orderedParams[$1].size()>0){
                     error(@$,"Procedure \""+$1+"\" called with too few arguments");
               }
            }
            $$ = new funcall_astnode(iden,typeClean(gst.Entries[$1]->type),code);
         }
      }
      | IDENTIFIER '(' expression_list ')'{
         identifier_astnode *iden = new identifier_astnode($1,"fun","nop","null");
         
         string paramCode = "";

         int stCount = 0;
         //cout<<$3.size()<<endl;
         for(int i=0;i<$3.size();i++){
            //localfuncCode.instr.push_back($3[i]->rcode);
            paramCode+=$3[i]->rcode;
            stCount++;
         }

         string code = "\tsubl $4,%esp\n";
         code += "\tcall "+$1 + "\n";

         code += "\taddl $4,%esp\n";
         code += "\taddl $"+to_string(4*stCount)+", %esp\n";
         code += "\tpushl %eax\n";
         code = paramCode + code;
         
         if (gst.Entries.find($1)==gst.Entries.end() && $1 != idname){
            if(predefined.find($1)==predefined.end()){
               error(@$,"Function \"+$1+\" not declared");
            }
            else{
               string typeV = predefined[$1];
               if(typeV=="INT_TYPE")   typeV = "int";
               else typeV = "void";
               $$ = new funcall_astnode(iden,$3,typeV,code);
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
               $$ = new funcall_astnode(iden,$3,typeClean(retType),code);
            else 
               $$ = new funcall_astnode(iden,$3,typeClean(gst.Entries[$1]->type),code); 
         }
      }
      | postfix_expression '.' IDENTIFIER{


         string typeV1 = $1->typeExp;
         string typeV2 = "";
         
         int structOff = $1->offset;
         string code = "";
         string lloc="";
         //cout<<localSymtab[typeV1][1]->iden<<" "<< ;
         //cout<<localSymtab[typeV1][1]->offset<<" "<<structOff<<endl;
         
         for(int i=0;i<localSymtab[typeV1].size();i++){
            
            if(localSymtab[typeV1][i]->iden == $3){

               structOff = $1->offset + localSymtab[typeV1][i]->offset;
               if(localSymtab[typeV1][i]->type == "int"){
                  code += "\tpushl "+to_string(structOff) + "(%ebp)\n";
                  lloc = to_string(structOff) + "(%ebp)";
                  //cout<<"Variables Set: "<<code<<" | "<<lloc;
               }
            }
         }
         identifier_astnode *iden = new identifier_astnode($3,"member","nop","null");
         lvalue = true;
         string val = $3;
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
         $$ = new member_astnode($1,iden,typeClean(typeV2),code,lloc,structOff);
         //cout<<"assi: "<<lloc<<"\n";
         clearstack();
         currType = typeV2;
         typeStack.push(typeClean(typeV2));
      }
      | postfix_expression PTR_OP IDENTIFIER{
         identifier_astnode *iden = new identifier_astnode($3,"arrow","nop","null");
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

         string code = "";
         code = $1->rcode;
         code += "\tpopl %eax\n";
         code += "\tpushl %eax\n";
         code += "\taddl $1,%eax\n";
         code += "\tmovl %eax, "+$1->lloc+"\n";
         string typeV = $1->typeExp;
         $$ = new op_unary_astnode("PP",$1,typeV,code);
         currType = typeV;
         typeStack.push(typeClean(typeV));
      }
      ;

primary_expression: 
      INT_CONSTANT
      {

         string code = "\tpushl $"+$1+"\n";

         $$ = new intconst_astnode(stoi($1),code);
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
         assembly.globals.push_back($1);

      }                  
      | IDENTIFIER
      {
         string rcode = "";
         string lloc = "";
         int structOff = 0;
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
               if(typeV[0]!='s') {
                  rcode = "\tpushl "+to_string(localSymtab[currentFunc][i]->offset) + "(%ebp)"+"\n";
                  lloc = to_string(localSymtab[currentFunc][i]->offset) + "(%ebp)";
               }
               else{
                  structOff = localSymtab[currentFunc][i]->offset;
               }
               //cout<<"offset of "<<$1<<": "<<localSymtab[currentFunc][i]->offset<<"\n";
               //cout<<"rcode:"<<rcode<<"\n";
            }
         }
         if (typeV=="")   {
            error(@$,"Variable \"" + $1 + "\" not declared");
         }
         $$ = new identifier_astnode($1,typeV,rcode,lloc,structOff);
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

      
      string code = $3->rcode;
      string label1 = ".L"+to_string(labelNum);
      
      code += "\tpopl %eax\n";
      code += "\tcmp $0, %eax\n";
      code += "\tje "+label1+"\n";

      labelNum++;
      string label2 = ".L"+to_string(labelNum);
      labelNum++;
      code += $5->rcode;
      
      code += "\tjmp "+label2+"\n";
      code+=label1 +":\n";
      code += $7->rcode;
      code+=label2+":\n";
      

      $$ = new if_astnode($3,$5,$7,code);
   }                  
   ;

iteration_statement:
   WHILE '(' expression ')' statement
   {

     string code = "";
     string label1 = ".L"+to_string(labelNum);
     labelNum++;
     string label2 = ".L" + to_string(labelNum);
     labelNum++;

      code += label1 + ":\n";
      code += $3->rcode;
      code+= "\tpopl %eax\n";
      code+= "\tcmp $0, %eax\n";
      code += "\tje "+ label2 + "\n";
      code += $5->rcode;
      code += "\tjmp "+label1 +"\n";
      code += label2 + ":\n";

     $$ = new while_astnode($3,$5,code);

   }
   | FOR '(' assignment_expression ';' expression ';' assignment_expression ')' statement
   {

      string code = "";
      string label1 = ".L"+to_string(labelNum);
      labelNum++;
      string label2 = ".L" + to_string(labelNum);
      labelNum++;
      code += $3->rcode;
      code += label1 + ":\n";
      code += $5->rcode;
      code += "\tpopl %eax\n";
      code += "\tcmp $0, %eax\n";
      code += "\tje "+label2+"\n";
      code += $9->rcode;
      code += $7->rcode;
      code += "\tjmp "+label1+"\n";
      code += label2 +":\n";
     $$ = new for_astnode($3,$5,$7,$9,code);
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
         int localSS=0;
         for(int i=0;i<$3.size();i++){
            localSS+=$3[i]->size;
         }
         
         localfuncCode.instr.push_back("\tsubl $"+to_string(localSS)+", %esp\n");
         
         removeLocalCode.push_back("\taddl $"+to_string(localSS)+", %esp\n");
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
{}



