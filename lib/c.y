class C::Parser
## shift/reduce conflict on "if (c) if (c) ; else ; else ;"
expect 1
rule

## A.2.4 External definitions

## Returns TranslationUnit
translation_unit
  : external_declaration                  {result = TranslationUnit.new_at(val[0].pos, NodeChain[val[0]])}
  | translation_unit external_declaration {result = val[0]; result.entities << val[1]}

## Returns Declaration|FunctionDef
external_declaration
  : function_definition {result = val[0]}
  | declaration         {result = val[0]}

## Returns FunctionDef
function_definition
  : declaration_specifiers declarator declaration_list compound_statement {result = make_function_def(val[0][0], val[0][1], val[1], val[2], val[3])}
  | declaration_specifiers declarator compound_statement                  {result = make_function_def(val[0][0], val[0][1], val[1], nil   , val[2])}

## Returns [Declaration]
declaration_list
  : declaration                  {result = [val[0]]}
  | declaration_list declaration {result = val[0] << val[1]}

## A.2.3 Statements

## Returns Statement
statement
  : labeled_statement    {result = val[0]}
  | compound_statement   {result = val[0]}
  | expression_statement {result = val[0]}
  | selection_statement  {result = val[0]}
  | iteration_statement  {result = val[0]}
  | jump_statement       {result = val[0]}

## Returns Statement
labeled_statement
  : identifier ':' statement                 {val[2].labels.unshift(PlainLabel.new_at(val[0].pos, val[0].val)); result = val[2]}
  | 'case' constant_expression ':' statement {val[3].labels.unshift(Case      .new_at(val[0].pos, val[1]    )); result = val[3]}
  | 'default' ':' statement                  {val[2].labels.unshift(Default   .new_at(val[0].pos            )); result = val[2]}
  ## type names can also be used as labels
  | typedef_name ':' statement               {val[2].labels.unshift(PlainLabel.new_at(val[0].pos, val[0].name)); result = val[2]}

## Returns Block
compound_statement
  : '{' block_item_list '}' {result = Block.new_at(val[0].pos, val[1])}
  | '{'                 '}' {result = Block.new_at(val[0].pos        )}

## Returns NodeChain[Declaration|Statement]
block_item_list
  : block_item                 {result = NodeChain[val[0]]}
  | block_item_list block_item {result = val[0] << val[1]}

## Returns Declaration|Statement
block_item
  : declaration {result = val[0]}
  | statement   {result = val[0]}

## Returns ExpressionStatement
expression_statement
  : expression ';' {result = ExpressionStatement.new_at(val[0].pos, val[0])}
  |            ';' {result = ExpressionStatement.new_at(val[0].pos        )}

## Returns Statement
selection_statement
  : 'if'     '(' expression ')' statement                  {result = If    .new_at(val[0].pos, val[2], val[4]        )}
  | 'if'     '(' expression ')' statement 'else' statement {result = If    .new_at(val[0].pos, val[2], val[4], val[6])}
  | 'switch' '(' expression ')' statement                  {result = Switch.new_at(val[0].pos, val[2], val[4]        )}

## Returns Statement
iteration_statement
  : 'while' '(' expression ')' statement                             {result = While.new_at(val[0].pos, val[2], val[4]              )}
  | 'do' statement 'while' '(' expression ')' ';'                    {result = While.new_at(val[0].pos, val[4], val[1], :do => true )}
  | 'for' '(' expression ';' expression ';' expression ')' statement {result = For.new_at(val[0].pos, val[2], val[4], val[6], val[8])}
  | 'for' '(' expression ';' expression ';'            ')' statement {result = For.new_at(val[0].pos, val[2], val[4], nil   , val[7])}
  | 'for' '(' expression ';'            ';' expression ')' statement {result = For.new_at(val[0].pos, val[2], nil   , val[5], val[7])}
  | 'for' '(' expression ';'            ';'            ')' statement {result = For.new_at(val[0].pos, val[2], nil   , nil   , val[6])}
  | 'for' '('            ';' expression ';' expression ')' statement {result = For.new_at(val[0].pos, nil   , val[3], val[5], val[7])}
  | 'for' '('            ';' expression ';'            ')' statement {result = For.new_at(val[0].pos, nil   , val[3], nil   , val[6])}
  | 'for' '('            ';'            ';' expression ')' statement {result = For.new_at(val[0].pos, nil   , nil   , val[4], val[6])}
  | 'for' '('            ';'            ';'            ')' statement {result = For.new_at(val[0].pos, nil   , nil   , nil   , val[5])}
  | 'for' '(' declaration    expression ';' expression ')' statement {result = For.new_at(val[0].pos, val[2], val[3], val[5], val[7])}
  | 'for' '(' declaration    expression ';'            ')' statement {result = For.new_at(val[0].pos, val[2], val[3], nil   , val[6])}
  | 'for' '(' declaration               ';' expression ')' statement {result = For.new_at(val[0].pos, val[2], nil   , val[4], val[6])}
  | 'for' '(' declaration               ';'            ')' statement {result = For.new_at(val[0].pos, val[2], nil   , nil   , val[5])}

## Returns Statement
jump_statement
  : 'goto' identifier ';'   {result = Goto    .new_at(val[0].pos, val[1].val)}
  | 'continue' ';'          {result = Continue.new_at(val[0].pos            )}
  | 'break' ';'             {result = Break   .new_at(val[0].pos            )}
  | 'return' expression ';' {result = Return  .new_at(val[0].pos, val[1]    )}
  | 'return'            ';' {result = Return  .new_at(val[0].pos            )}
  ## type names can also be used as labels
  | 'goto' typedef_name ';' {result = Goto    .new_at(val[0].pos, val[1].name)}

## A.2.2 Declarations

## Returns Declaration
declaration
  : declaration_specifiers init_declarator_list ';' {result = make_declaration(val[0][0], val[0][1], val[1])}
  | declaration_specifiers                      ';' {result = make_declaration(val[0][0], val[0][1], NodeArray[])}

## Returns {Pos, [Symbol]}
declaration_specifiers
  : storage_class_specifier declaration_specifiers {val[1][1] << val[0][1]; result = val[1]}
  | storage_class_specifier                        {result = [val[0][0], [val[0][1]]]}
  | type_specifier          declaration_specifiers {val[1][1] << val[0][1]; result = val[1]}
  | type_specifier                                 {result = [val[0][0], [val[0][1]]]}
  | type_qualifier          declaration_specifiers {val[1][1] << val[0][1]; result = val[1]}
  | type_qualifier                                 {result = [val[0][0], [val[0][1]]]}
  | function_specifier      declaration_specifiers {val[1][1] << val[0][1]; result = val[1]}
  | function_specifier                             {result = [val[0][0], [val[0][1]]]}

## Returns NodeArray[Declarator]
init_declarator_list
  : init_declarator                          {result = NodeArray[val[0]]}
  | init_declarator_list ',' init_declarator {result = val[0] << val[2]}

## Returns Declarator
init_declarator
  : declarator                 {result = val[0]}
  | declarator '=' initializer {val[0].init = val[2]; result = val[0]}

## Returns [Pos, Symbol]
storage_class_specifier
  : 'typedef'  {result = [val[0].pos, val[0].val]}
  | 'extern'   {result = [val[0].pos, val[0].val]}
  | 'static'   {result = [val[0].pos, val[0].val]}
  | 'auto'     {result = [val[0].pos, val[0].val]}
  | 'register' {result = [val[0].pos, val[0].val]}

## Returns [Pos, Type|Symbol]
type_specifier
  : 'void'                    {result = [val[0].pos, val[0].val]}
  | 'char'                    {result = [val[0].pos, val[0].val]}
  | 'short'                   {result = [val[0].pos, val[0].val]}
  | 'int'                     {result = [val[0].pos, val[0].val]}
  | 'long'                    {result = [val[0].pos, val[0].val]}
  | 'float'                   {result = [val[0].pos, val[0].val]}
  | 'double'                  {result = [val[0].pos, val[0].val]}
  | 'signed'                  {result = [val[0].pos, val[0].val]}
  | 'unsigned'                {result = [val[0].pos, val[0].val]}
  | '_Bool'                   {result = [val[0].pos, val[0].val]}
  | '_Complex'                {result = [val[0].pos, val[0].val]}
  | '_Imaginary'              {result = [val[0].pos, val[0].val]}
  | struct_or_union_specifier {result = [val[0].pos, val[0]    ]}
  | enum_specifier            {result = [val[0].pos, val[0]    ]}
  | typedef_name              {result = [val[0].pos, val[0]    ]}

## Returns Struct|Union
struct_or_union_specifier
  : struct_or_union identifier '{' struct_declaration_list '}' {result = val[0][1].new_at(val[0][0], val[1].val, val[3])}
  | struct_or_union            '{' struct_declaration_list '}' {result = val[0][1].new_at(val[0][0], nil       , val[2])}
  | struct_or_union identifier                                 {result = val[0][1].new_at(val[0][0], val[1].val, nil   )}
  ## type names can also be used as struct identifiers
  | struct_or_union typedef_name '{' struct_declaration_list '}' {result = val[0][1].new_at(val[0][0], val[1].name, val[3])}
  | struct_or_union typedef_name                                 {result = val[0][1].new_at(val[0][0], val[1].name, nil   )}

## Returns [Pos, Class]
struct_or_union
  : 'struct' {result = [val[0].pos, Struct]}
  | 'union'  {result = [val[0].pos, Union ]}

## Returns NodeArray[Declaration]
struct_declaration_list
  : struct_declaration                         {result = NodeArray[val[0]]}
  | struct_declaration_list struct_declaration {val[0] << val[1]; result = val[0]}

## Returns Declaration
struct_declaration
  : specifier_qualifier_list struct_declarator_list ';' {result = make_declaration(val[0][0], val[0][1], val[1])}

## Returns {Pos, [Symbol]}
specifier_qualifier_list
  : type_specifier specifier_qualifier_list {val[1][1] << val[0][1]; result = val[1]}
  | type_specifier                          {result = [val[0][0], [val[0][1]]]}
  | type_qualifier specifier_qualifier_list {val[1][1] << val[0][1]; result = val[1]}
  | type_qualifier                          {result = [val[0][0], [val[0][1]]]}

## Returns NodeArray[Declarator]
struct_declarator_list
  : struct_declarator                            {result = NodeArray[val[0]]}
  | struct_declarator_list ',' struct_declarator {result = val[0] << val[2]}

## Returns Declarator
struct_declarator
  : declarator                         {result = val[0]}
  | declarator ':' constant_expression {result = val[0]; val[0].num_bits = val[2]}
  |            ':' constant_expression {result = Declarator.new_at(val[0].pos, :num_bits => val[1])}

## Returns Enum
enum_specifier
  : 'enum' identifier '{' enumerator_list '}'     {result = Enum.new_at(val[0].pos, val[1].val, val[3])}
  | 'enum'            '{' enumerator_list '}'     {result = Enum.new_at(val[0].pos, nil       , val[2])}
  | 'enum' identifier '{' enumerator_list ',' '}' {result = Enum.new_at(val[0].pos, val[1].val, val[3])}
  | 'enum'            '{' enumerator_list ',' '}' {result = Enum.new_at(val[0].pos, nil       , val[2])}
  | 'enum' identifier                             {result = Enum.new_at(val[0].pos, val[1].val, nil   )}
  ## type names can also be used as enum names
  | 'enum' typedef_name '{' enumerator_list '}'     {result = Enum.new_at(val[0].pos, val[1].name, val[3])}
  | 'enum' typedef_name '{' enumerator_list ',' '}' {result = Enum.new_at(val[0].pos, val[1].name, val[3])}
  | 'enum' typedef_name                             {result = Enum.new_at(val[0].pos, val[1].name, nil   )}

## Returns NodeArray[Enumerator]
enumerator_list
  : enumerator                     {result = NodeArray[val[0]]}
  | enumerator_list ',' enumerator {result = val[0] << val[2]}

## Returns Enumerator
enumerator
  : enumeration_constant                         {result = Enumerator.new_at(val[0].pos, val[0].val, nil   )}
  | enumeration_constant '=' constant_expression {result = Enumerator.new_at(val[0].pos, val[0].val, val[2])}

## Returns [Pos, Symbol]
type_qualifier
  : 'const'    {result = [val[0].pos, val[0].val]}
  | 'restrict' {result = [val[0].pos, val[0].val]}
  | 'volatile' {result = [val[0].pos, val[0].val]}

## Returns [Pos, Symbol]
function_specifier
  : 'inline' {result = [val[0].pos, val[0].val]}

## Returns Declarator
declarator
  : pointer direct_declarator {result = add_decl_type(val[1], val[0])}
  |         direct_declarator {result = val[0]}

## Returns Declarator
direct_declarator
  : identifier                                                                   {result = Declarator.new_at(val[0].pos, nil, val[0].val)}
  | '(' declarator ')'                                                           {result = val[1]}
  | direct_declarator '[' type_qualifier_list          assignment_expression ']' {result = add_decl_type(val[0], Array.new_at(val[0].pos             ))}  # TODO
  | direct_declarator '[' type_qualifier_list                                ']' {result = add_decl_type(val[0], Array.new_at(val[0].pos             ))}  # TODO
  | direct_declarator '['                              assignment_expression ']' {result = add_decl_type(val[0], Array.new_at(val[0].pos, nil, val[2]))}
  | direct_declarator '['                                                    ']' {result = add_decl_type(val[0], Array.new_at(val[0].pos             ))}
  | direct_declarator '[' 'static' type_qualifier_list assignment_expression ']' {result = add_decl_type(val[0], Array.new_at(val[0].pos             ))}  # TODO
  | direct_declarator '[' 'static'                     assignment_expression ']' {result = add_decl_type(val[0], Array.new_at(val[0].pos             ))}  # TODO
  | direct_declarator '[' type_qualifier_list 'static' assignment_expression ']' {result = add_decl_type(val[0], Array.new_at(val[0].pos             ))}  # TODO
  | direct_declarator '[' type_qualifier_list          '*'                   ']' {result = add_decl_type(val[0], Array.new_at(val[0].pos             ))}  # TODO
  | direct_declarator '['                              '*'                   ']' {result = add_decl_type(val[0], Array.new_at(val[0].pos             ))}  # TODO
  | direct_declarator '(' parameter_type_list ')'                                {result = add_decl_type(val[0], Function.new_at(val[0].pos, nil, param_list(*val[2]), :var_args => val[2][1]))}
  | direct_declarator '(' identifier_list     ')'                                {result = add_decl_type(val[0], Function.new_at(val[0].pos, nil,             val[2]))}
  | direct_declarator '('                     ')'                                {result = add_decl_type(val[0], Function.new_at(val[0].pos                         ))}

## Returns Pointer
pointer
  : '*' type_qualifier_list         {result = add_type_quals(Pointer.new_at(val[0].pos), val[1][1])                                         }
  | '*'                             {result =                Pointer.new_at(val[0].pos)                                                     }
  | '*' type_qualifier_list pointer {p      = add_type_quals(Pointer.new_at(val[0].pos), val[1][1]); val[2].direct_type = p; result = val[2]}
  | '*'                     pointer {p      =                Pointer.new_at(val[0].pos)            ; val[1].direct_type = p; result = val[1]}

## Returns {Pos, [Symbol]}
type_qualifier_list
  : type_qualifier                     {result = [val[0][0], [val[0][1]]]}
  | type_qualifier_list type_qualifier {val[0][1] << val[1][1]; result = val[0]}

## Returns [NodeArray[Parameter], var_args?]
parameter_type_list
  : parameter_list           {result = [val[0], false]}
  | parameter_list ',' '...' {result = [val[0], true ]}

## Returns NodeArray[Parameter]
parameter_list
  : parameter_declaration                    {result = NodeArray[val[0]]}
  | parameter_list ',' parameter_declaration {result = val[0] << val[2]}

## Returns Parameter
parameter_declaration
  : declaration_specifiers declarator          {ind_type = val[1].indirect_type and ind_type.detach
                                                result = make_parameter(val[0][0], val[0][1], ind_type, val[1].name)}
  | declaration_specifiers abstract_declarator {result = make_parameter(val[0][0], val[0][1], val[1]  , nil        )}
  | declaration_specifiers                     {result = make_parameter(val[0][0], val[0][1], nil     , nil        )}

## Returns NodeArray[Parameter]
identifier_list
  : identifier                     {result = NodeArray[Parameter.new_at(val[0].pos, nil, val[0].val)]}
  | identifier_list ',' identifier {result = val[0] << Parameter.new_at(val[2].pos, nil, val[2].val)}

## Returns Type
type_name
  : specifier_qualifier_list abstract_declarator {val[1].direct_type = make_direct_type(val[0][0], val[0][1]); result = val[1]}
  | specifier_qualifier_list                     {result             = make_direct_type(val[0][0], val[0][1])                 }

## Returns Type
abstract_declarator
  : pointer                            {result = val[0]}
  | pointer direct_abstract_declarator {val[1].direct_type = val[0]; result = val[1]}
  |         direct_abstract_declarator {result = val[0]}

## Returns Type
direct_abstract_declarator
  : '(' abstract_declarator ')'                              {result = val[1]}
  | direct_abstract_declarator '[' assignment_expression ']' {val[0].direct_type = Array.new_at(val[0].pos, nil, val[2]); result = val[0]}
  | direct_abstract_declarator '['                       ']' {val[0].direct_type = Array.new_at(val[0].pos, nil, nil   ); result = val[0]}
  |                            '[' assignment_expression ']' {result = Array.new_at(val[0].pos, nil, val[1])}
  |                            '['                       ']' {result = Array.new_at(val[0].pos             )}
  | direct_abstract_declarator '[' '*' ']'                   {val[0].direct_type = Array.new_at(val[0].pos); result = val[0]}  # TODO
  |                            '[' '*' ']'                   {result = Array.new_at(val[0].pos)}  # TODO
  | direct_abstract_declarator '(' parameter_type_list ')'   {val[0].direct_type = Function.new_at(val[0].pos, nil, param_list(*val[2]), val[2][1]); result = val[0]}
  | direct_abstract_declarator '('                     ')'   {val[0].direct_type = Function.new_at(val[0].pos                                       ); result = val[0]}
  |                            '(' parameter_type_list ')'   {result = Function.new_at(val[0].pos, nil, param_list(*val[1]), val[1][1])}
  |                            '('                     ')'   {result = Function.new_at(val[0].pos                                     )}

## Returns CustomType
typedef_name
  #: identifier -- insufficient since we must distinguish between type
  #                names and var names (otherwise we have a conflict)
  : TYPE_ID {result = CustomType.new_at(val[0].pos, val[0].val)}

## Returns Expression
initializer
  : assignment_expression        {result = val[0]}
  | '{' initializer_list '}'     {result = CompoundLiteral.new_at(val[0].pos, nil, val[1])}
  | '{' initializer_list ',' '}' {result = CompoundLiteral.new_at(val[0].pos, nil, val[1])}

## Returns NodeArray[MemberInit]
initializer_list
  :                      designation initializer {result = NodeArray[MemberInit.new_at(val[0][0] , val[0][1], val[1])]}
  |                                  initializer {result = NodeArray[MemberInit.new_at(val[0].pos, nil      , val[0])]}
  | initializer_list ',' designation initializer {result = val[0] << MemberInit.new_at(val[2][0] , val[2][1], val[3])}
  | initializer_list ','             initializer {result = val[0] << MemberInit.new_at(val[2].pos, nil      , val[2])}

## Returns {Pos, NodeArray[Expression|Token]}
designation
  : designator_list '=' {result = val[0]}

## Returns {Pos, NodeArray[Expression|Token]}
designator_list
  : designator                 {result = val[0]; val[0][1] = NodeArray[val[0][1]]}
  | designator_list designator {result = val[0]; val[0][1] << val[1][1]}

## Returns {Pos, Expression|Member}
designator
  : '[' constant_expression ']' {result = [val[1].pos, val[1]    ]}
  | '.' identifier              {result = [val[1].pos, Member.new_at(val[1].pos, val[1].val)]}

### A.2.1 Expressions

## Returns Expression
primary_expression
  : identifier         {result = Variable.new_at(val[0].pos, val[0].val)}
  | constant           {result = val[0]}
  | string_literal     {result = val[0]}
  | '(' expression ')' {result = val[1]}

## Returns Expression
postfix_expression
  : primary_expression                                  {result = val[0]}
  | postfix_expression '[' expression ']'               {result = Index          .new_at(val[0].pos, val[0], val[2])}
  | postfix_expression '(' argument_expression_list ')' {result = Call           .new_at(val[0].pos, val[0], val[2]     )}
  | postfix_expression '('                          ')' {result = Call           .new_at(val[0].pos, val[0], NodeArray[])}
  | postfix_expression '.'  identifier                  {result = Dot            .new_at(val[0].pos, val[0], Member.new(val[2].val))}
  | postfix_expression '->' identifier                  {result = Arrow          .new_at(val[0].pos, val[0], Member.new(val[2].val))}
  | postfix_expression '++'                             {result = PostInc        .new_at(val[0].pos, val[0]        )}
  | postfix_expression '--'                             {result = PostDec        .new_at(val[0].pos, val[0]        )}
  | '(' type_name ')' '{' initializer_list '}'          {result = CompoundLiteral.new_at(val[0].pos, val[1], val[4])}
  | '(' type_name ')' '{' initializer_list ',' '}'      {result = CompoundLiteral.new_at(val[0].pos, val[1], val[4])}

## Returns [Expression|Type] -- allow type names here too -- TODO: add an option to disallow this
argument_expression_list
  : argument_expression                              {result = NodeArray[val[0]]}
  | argument_expression_list ',' argument_expression {result = val[0] << val[2]}

## Returns Expression|Type
argument_expression
  : assignment_expression {result = val[0]}
  | type_name             {result = val[0]}

## Returns Expression
unary_expression
  : postfix_expression             {result = val[0]}
  | '++' unary_expression          {result = PreInc.new_at(val[0].pos, val[1])}
  | '--' unary_expression          {result = PreDec.new_at(val[0].pos, val[1])}
  | unary_operator cast_expression {result = val[0][0].new_at(val[0][1], val[1])}
  | 'sizeof' unary_expression      {result = Sizeof.new_at(val[0].pos, val[1])}
  | 'sizeof' '(' type_name ')'     {result = Sizeof.new_at(val[0].pos, val[2])}

## Returns [Class, Pos]
unary_operator
  : '&' {result = [Address    , val[0].pos]}
  | '*' {result = [Dereference, val[0].pos]}
  | '+' {result = [Positive   , val[0].pos]}
  | '-' {result = [Negative   , val[0].pos]}
  | '~' {result = [BitNot     , val[0].pos]}
  | '!' {result = [Not        , val[0].pos]}

## Returns Expression
cast_expression
  : unary_expression                  {result = val[0]}
  | '(' type_name ')' cast_expression {result = Cast.new_at(val[0].pos, val[1], val[3])}

## Returns Expression
multiplicative_expression
  : cast_expression                               {result = val[0]}
  | multiplicative_expression '*' cast_expression {result = Multiply.new_at(val[0].pos, val[0], val[2])}
  | multiplicative_expression '/' cast_expression {result = Divide  .new_at(val[0].pos, val[0], val[2])}
  | multiplicative_expression '%' cast_expression {result = Mod     .new_at(val[0].pos, val[0], val[2])}

## Returns Expression
additive_expression
  : multiplicative_expression                         {result = val[0]}
  | additive_expression '+' multiplicative_expression {result = Add     .new_at(val[0].pos, val[0], val[2])}
  | additive_expression '-' multiplicative_expression {result = Subtract.new_at(val[0].pos, val[0], val[2])}

## Returns Expression
shift_expression
  : additive_expression                       {result = val[0]}
  | shift_expression '<<' additive_expression {result = ShiftLeft .new_at(val[0].pos, val[0], val[2])}
  | shift_expression '>>' additive_expression {result = ShiftRight.new_at(val[0].pos, val[0], val[2])}

## Returns Expression
relational_expression
  : shift_expression                            {result = val[0]}
  | relational_expression '<'  shift_expression {result = Less.new_at(val[0].pos, val[0], val[2])}
  | relational_expression '>'  shift_expression {result = More.new_at(val[0].pos, val[0], val[2])}
  | relational_expression '<=' shift_expression {result = LessOrEqual.new_at(val[0].pos, val[0], val[2])}
  | relational_expression '>=' shift_expression {result = MoreOrEqual.new_at(val[0].pos, val[0], val[2])}

## Returns Expression
equality_expression
  : relational_expression                          {result = val[0]}
  | equality_expression '==' relational_expression {result = Equal   .new_at(val[0].pos, val[0], val[2])}
  | equality_expression '!=' relational_expression {result = NotEqual.new_at(val[0].pos, val[0], val[2])}

## Returns Expression
and_expression
  : equality_expression                    {result = val[0]}
  | and_expression '&' equality_expression {result = BitAnd.new_at(val[0].pos, val[0], val[2])}

## Returns Expression
exclusive_or_expression
  : and_expression                             {result = val[0]}
  | exclusive_or_expression '^' and_expression {result = BitXor.new_at(val[0].pos, val[0], val[2])}

## Returns Expression
inclusive_or_expression
  : exclusive_or_expression                             {result = val[0]}
  | inclusive_or_expression '|' exclusive_or_expression {result = BitOr.new_at(val[0].pos, val[0], val[2])}

## Returns Expression
logical_and_expression
  : inclusive_or_expression                             {result = val[0]}
  | logical_and_expression '&&' inclusive_or_expression {result = And.new_at(val[0].pos, val[0], val[2])}

## Returns Expression
logical_or_expression
  : logical_and_expression                            {result = val[0]}
  | logical_or_expression '||' logical_and_expression {result = Or.new_at(val[0].pos, val[0], val[2])}

## Returns Expression
conditional_expression
  : logical_or_expression                                           {result = val[0]}
  | logical_or_expression '?' expression ':' conditional_expression {result = Conditional.new_at(val[0].pos, val[0], val[2], val[4])}

## Returns Expression
assignment_expression
  : conditional_expression                                     {result = val[0]}
  | unary_expression assignment_operator assignment_expression {result = val[1].new_at(val[0].pos, val[0], val[2])}

## Returns Class
assignment_operator
  : '='   {result =           Assign}
  | '*='  {result =   MultiplyAssign}
  | '/='  {result =     DivideAssign}
  | '%='  {result =        ModAssign}
  | '+='  {result =        AddAssign}
  | '-='  {result =   SubtractAssign}
  | '<<=' {result =  ShiftLeftAssign}
  | '>>=' {result = ShiftRightAssign}
  | '&='  {result =     BitAndAssign}
  | '^='  {result =     BitXorAssign}
  | '|='  {result =      BitOrAssign}

## Returns Expression
expression
  : assignment_expression                {result = val[0]}
  | expression ',' assignment_expression {
    if val[0].is_a? Comma
      if val[2].is_a? Comma
        val[0].exprs.push(*val[2].exprs)
      else
        val[0].exprs << val[2]
      end
      result = val[0]
    else
      if val[2].is_a? Comma
        val[2].exprs.unshift(val[0])
        val[2].pos = val[0].pos
        result = val[2]
      else
        result = Comma.new_at(val[0].pos, NodeArray[val[0], val[2]])
      end
    end
  }

## Returns Expression
constant_expression
    : conditional_expression {result = val[0]}

### A.1.1 -- Lexical elements
##
## token
##   : keyword        (raw string)
##   | identifier     expanded below
##   | constant       expanded below
##   | string_literal expanded below
##   | punctuator     (raw string)
##
## preprocessing-token (skip)

## Returns Token
identifier
  : ID {result = val[0]}

## Returns Literal
constant
  : INT     {result =   IntLiteral.new_at(val[0].pos, val[0].val)}
  | FLOAT   {result = FloatLiteral.new_at(val[0].pos, val[0].val)}
  #| enumeration_constant -- these are parsed as identifiers at all
  #                          places the `constant' nonterminal appears
  | CHAR    {result =  CharLiteral.new_at(val[0].pos, val[0].val)}

## Returns Token
enumeration_constant
  : ID {result = val[0]}

## Returns StringLiteral
string_literal
  : STRING  {result = StringLiteral.new_at(val[0].pos, val[0].val)}

---- inner
  ## A.1.9 -- Preprocessing numbers -- skip
  ## A.1.8 -- Header names -- skip

  ## A.1.7 -- Puncuators -- we don't bother with {##,#,%:,%:%:} since
  ## we don't do preprocessing
  @@punctuators = %r'\+\+|-[->]|&&|\|\||\.\.\.|(?:<<|>>|[<>=!*/%+\-&^|])=?|[\[\](){}.~?:;,]'
  @@digraphs    = %r'<[:%]|[:%]>'

  ## A.1.6 -- String Literals -- simple for us because we don't decode
  ## the string (and indeed accept some illegal strings)
  @@string_literal = %r'L?"(?:[^\\]|\\.)*?"'m

  ## A.1.5 -- Constants
  @@decimal_floating_constant     = %r'(?:(?:\d*\.\d+|\d+\.)(?:e[-+]?\d+)?|\d+e[-+]?\d+)[fl]?'i
  @@hexadecimal_floating_constant = %r'0x(?:(?:[0-9a-f]*\.[0-9a-f]+|[0-9a-f]+\.)|[0-9a-f]+)p[-+]?\d+[fl]?'i

  @@integer_constant     = %r'(?:[1-9][0-9]*|0x[0-9a-f]+|0[0-7]*)(?:ul?l?|ll?u?)?'i
  @@floating_constant    = %r'#{@@decimal_floating_constant}|#{@@hexadecimal_floating_constant}'
  @@enumeration_constant = %r'[a-zA-Z_\\][a-zA-Z_\\0-9]*'
  @@character_constant   = %r"L?'(?:[^\\]|\\.)+?'"
  ## (note that as with string-literals, we accept some illegal
  ## character-constants)

  ## A.1.4 -- Universal character names -- skip

  ## A.1.3 -- Identifiers -- skip, since an identifier is lexically
  ## identical to an enumeration constant

  ## A.1.2 Keywords
  keywords = %w'auto break case char const continue default do
double else enum extern float for goto if inline int long register
restrict return short signed sizeof static struct switch typedef union
 unsigned void volatile while _Bool _Complex _Imaginary'
  @@keywords = %r"#{keywords.join('|')}"

  def initialize
    @type_names = ::Set.new

    @warning_proc = lambda{}
    @pos          = C::Node::Pos.new(nil, 1, 0)
  end
  def initialize_copy x
    @pos        = x.pos.dup
    @type_names = x.type_names.dup
  end
  attr_accessor :pos, :type_names

  def parse str
    if str.respond_to? :read
      str = str.read
    end
    @str = str
    begin
      return do_parse
    rescue ParseError => e
      e.set_backtrace(caller)
      raise
    end
  end

  ### Obsolete?  Todo?  What was I thinking?
  def on_error error_token_id, error_value, value_stack
    if error_value == '$'
      parse_error @pos, "unexpected EOF"
    else
      parse_error(error_value.pos,
                  "parse error on #{error_value.val.inspect}")
    end
  end

  private

  class Token
    attr_accessor :pos, :val
    def initialize pos, val
      @pos = pos
      @val = val
    end
  end
  def eat str
    lines = str.split(/\r\n|[\r\n]/, -1)
    if lines.length == 1
      @pos.col_num += lines[0].length
    else
      @pos.line_num += lines.length - 1
      @pos.col_num = lines[-1].length
    end
  end
  def next_token
    return nil if @str == ''
    case @str
    when %r'\A\s+'
      ## whitespace
      eat $&
      @str[0...$&.length] = ''
      return next_token
    when %r'\A/\*.*?\*/'m
      ## comment
      eat $&
      @str[0...$&.length] = ''
      return next_token
    when %r'\A#{@@keywords}\b'
      ## keyword
      ret = [$&, $&.to_sym]
    when %r'\A#{@@enumeration_constant}'
      ## identifier, enumeration_constant, or typedef_name
      case
      when @type_names.include?($&)
        ret = [:TYPE_ID, $&]
      else
        ret = [:ID, $&]
      end
    when %r'\A#{@@floating_constant}'
      ## floating-constant
      ret = [:FLOAT, $&.to_f]
    when %r'\A#{@@integer_constant}'
      ## integer-constant
      ret = [:INT, $&.to_i]
    when %r'\A#{@@character_constant}'
      ## character constant
      ret = [:CHAR, $&[1...-1]]
    when %r'\A#{@@string_literal}'
      ## string-literal
      ret = [:STRING, $&[1...-1]]
    when %r'\A#{@@punctuators}'
      ## punctuator
      ret = [$&, $&]
    when %r'\A#{@@digraphs}'
      ## digraph
      case $&
      when '<:'
        ret = ['[', '[']
      when ':>'
        ret = [']', ']']
      when '<%'
        ret = ['{', '{']
      when '%>'
        ret = ['}', '}']
      else
        raise 'bug'
      end
    else
      if @str.length > 40
        s = @str[0...37] << '...'
      else
        s = @str
      end
      raise ParseError, "#{@pos}: invalid token: #{s.inspect}"
    end
    ret[1] = Token.new(@pos.dup, ret[1])
    eat $&
    @str[0...$&.length] = ''
    return ret
  end

  private

  #### Helper methods

  ## Make a Declaration from the given specs and declarators.
  def make_declaration pos, specs, declarators
    specs.all?{|x| x.is_a?(Symbol) || x.is_a?(Type)} or raise specs.map{|x| x.class}.inspect
    decl = Declaration.new_at(pos, nil, declarators)

    ## set storage class
    storage_classes = specs.find_all do |x|
      [:typedef, :extern, :static, :auto, :register].include? x
    end
    ## 6.7.1p2: at most, one storage-class specifier may be given in
    ## the declaration specifiers in a declaration
    storage_classes.length <= 1 or
      begin
        if declarators.length == 0
          for_name = ''
        else
          for_name = "for `#{declarators[0].name}'"
        end
        parse_error pos, "multiple or duplicate storage classes given #{for_name}'"
      end
    decl.storage = storage_classes[0]

    ## set type (specifiers, qualifiers)
    decl.type = make_direct_type(pos, specs)

    ## set function specifiers
    decl.inline = specs.include?(:inline)

    ## look for new type names
    if decl.typedef?
      decl.declarators.each do |d|
        if d.name
          @type_names << d.name
        end
      end
    end

    return decl
  end

  def make_function_def pos, specs, func_declarator, decl_list, defn
    add_decl_type(func_declarator, make_direct_type(pos, specs))

    ## get types from decl_list if necessary
    function = func_declarator.indirect_type
    function.is_a? Function or
      parse_error pos, "non function type for function `#{func_declarator.name}'"
    params = function.params
    if decl_list
      params.all?{|p| p.type.nil?} or
        parse_error pos, "both prototype and declaration list given for `#{func_declarator.name}'"
      decl_list.each do |declaration|
        declaration.declarators.each do |declarator|
          param = params.find{|p| p.name == declarator.name} or
            parse_error pos, "no parameter named #{declarator.name}"
          if declarator.indirect_type
            param.type = declarator.indirect_type
            param.type.direct_type = declaration.type.dup
          else
            param.type = declaration.type.dup
          end
        end
      end
      params.all?{|p| p.type} or
        begin
          s = params.find_all{|p| p.type.nil?}.map{|p| "`#{p.name}'"}.join(' and ')
          parse_error pos, "types missing for parameters #{s}"
        end
    end

    fd = FunctionDef.new_at(pos,
                            function.detach,
                            func_declarator.name,
                            defn,
                            :no_prototype => !decl_list.nil?)

    ## set storage class
    ## 6.9.1p4: only extern or static allowed
    specs.each do |s|
      [:typedef, :auto, :register].include?(s) and
        "`#{s}' illegal for function"
    end
    storage_classes = specs.find_all do |s|
      s == :extern || s == :static
    end
    ## 6.7.1p2: at most, one storage-class specifier may be given in
    ## the declaration specifiers in a declaration
    storage_classes.length <= 1 or
      "multiple or duplicate storage classes given for `#{declarator.name}'"
    fd.storage = storage_classes[0] if storage_classes[0]

    ## set function specifiers
    ## 6.7.4p5 'inline' can be repeated
    fd.inline = specs.include?(:inline)

    return fd
  end

  ## Make a direct type from the list of type specifiers and type
  ## qualifiers.
  def make_direct_type pos, specs
    specs_order = [:signed, :unsigned, :short, :long, :double, :void,
      :char, :int, :float, :_Bool, :_Complex, :_Imaginary]

    type_specs = specs.find_all do |x|
      specs_order.include?(x) || !x.is_a?(Symbol)
    end
    type_specs.sort! do |a, b|
      (specs_order.index(a)||100) <=> (specs_order.index(b)||100)
    end

    ## set type specifiers
    ## 6.7.2p2: the specifier list should be one of these
    type =
      case type_specs
      when [:void]
        Void.new
      when [:char]
        Char.new
      when [:signed, :char]
        Char.new :signed => true
      when [:unsigned, :char]
        Char.new :signed => false
      when [:short], [:signed, :short], [:short, :int],
        [:signed, :short, :int]
        Int.new :longness => -1
      when [:unsigned, :short], [:unsigned, :short, :int]
        Int.new :unsigned => true, :longness => -1
      when [:int], [:signed], [:signed, :int]
        Int.new
      when [:unsigned], [:unsigned, :int]
        Int.new :unsigned => true
      when [:long], [:signed, :long], [:long, :int],
        [:signed, :long, :int]
        Int.new :longness => 1
      when [:unsigned, :long], [:unsigned, :long, :int]
        Int.new :longness => 1, :unsigned => true
      when [:long, :long], [:signed, :long, :long],
        [:long, :long, :int], [:signed, :long, :long, :int]
        Int.new :longness => 2
      when [:unsigned, :long, :long], [:unsigned, :long, :long, :int]
        Int.new :longness => 2, :unsigned => true
      when [:float]
        Float.new
      when [:double]
        Float.new :longness => 1
      when [:long, :double]
        Float.new :longness => 2
      when [:_Bool]
        Bool.new
      when [:float, :_Complex]
        Complex.new
      when [:double, :_Complex]
        Complex.new :longness => 1
      when [:long, :double, :_Complex]
        Complex.new :longness => 2
      when [:float, :_Imaginary]
        Imaginary.new
      when [:double, :_Imaginary]
        Imaginary.new :longness => 1
      when [:long, :double, :_Imaginary]
        Imaginary.new :longness => 2
      else
        if type_specs.length == 1 &&
            [CustomType, Struct, Union, Enum].any?{|c| type_specs[0].is_a? c}
          type_specs[0]
        else
          if type_specs == []
            parse_error pos, "no type specifiers given"
          else
            parse_error pos, "invalid type specifier combination: #{type_specs.join(' ')}"
          end
        end
      end
    type.pos ||= pos

    ## set type qualifiers
    ## 6.7.3p4: type qualifiers can be repeated
    type.const    = specs.any?{|x| x.equal? :const   }
    type.restrict = specs.any?{|x| x.equal? :restrict}
    type.volatile = specs.any?{|x| x.equal? :volatile}

    return type
  end

  def make_parameter pos, specs, indirect_type, name
    type = indirect_type
    if type
      type.direct_type = make_direct_type(pos, specs)
    else
      type = make_direct_type(pos, specs)
    end
    [:typedef, :extern, :static, :auto, :inline].each do |sym|
      specs.include? sym and
        parse_error pos, "parameter `#{declarator.name}' declared `#{sym}'"
    end
    return Parameter.new_at(pos, type, name,
                            :register => specs.include?(:register))
  end

  def add_type_quals type, quals
    type.const    = quals.include?(:const   )
    type.restrict = quals.include?(:restrict)
    type.volatile = quals.include?(:volatile)
    return type
  end

  ## Add te given type as the "most direct" type to the given
  ## declarator.  Return the declarator.
  def add_decl_type declarator, type
    if declarator.indirect_type
      declarator.indirect_type.direct_type = type
    else
      declarator.indirect_type = type
    end
    return declarator
  end

  def param_list params, var_args
    if params.length == 1 &&
        params[0].type.is_a?(Void) &&
        params[0].name.nil?
      return NodeArray[]
    elsif params.empty?
      return nil
    else
      return params
    end
  end

  def parse_error pos, str
    raise ParseError, "#{pos}: #{str}"
  end

---- header

require 'set'

#### Error classes
module C
  class ParseError < StandardError; end
end

### Local variables:
###   mode: ruby
### end:
