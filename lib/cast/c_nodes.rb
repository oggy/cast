######################################################################
#
# All those Node classes.
#
######################################################################

module C

  # ------------------------------------------------------------------
  #                         Class declarations
  # ------------------------------------------------------------------

  class Statement            < Node           ; abstract; end
  class Label                < Node           ; abstract; end
  class Expression           < Node           ; abstract; end
  class UnaryExpression      < Expression     ; abstract; end
  class PostfixExpression    < UnaryExpression; abstract; end
  class PrefixExpression     < UnaryExpression; abstract; end
  class BinaryExpression     < Expression     ; abstract; end
  class AssignmentExpression < Expression     ; abstract; end
  class Literal              < Expression     ; abstract; end
  class Type                 < Node           ; abstract; end
  class IndirectType         < Type           ; abstract; end
  class DirectType           < Type           ; abstract; end
  class PrimitiveType        < DirectType     ; abstract; end

  class TranslationUnit      < Node                ; end
  class Declaration          < Node                ; end
  class Declarator           < Node                ; end
  class FunctionDef          < Node                ; end
  class Parameter            < Node                ; end
  class Enumerator           < Node                ; end
  class MemberInit           < Node                ; end
  class Member               < Node                ; end

  class Block                < Statement           ; end
  class If                   < Statement           ; end
  class Switch               < Statement           ; end
  class While                < Statement           ; end
  class For                  < Statement           ; end
  class Goto                 < Statement           ; end
  class Continue             < Statement           ; end
  class Break                < Statement           ; end
  class Return               < Statement           ; end
  class ExpressionStatement  < Statement           ; end

  class PlainLabel           < Label               ; end
  class Default              < Label               ; end
  class Case                 < Label               ; end

  class Comma                < Expression          ; end
  class Conditional          < Expression          ; end
  class Variable             < Expression          ; end
  class BlockExpression      < Expression          ; end

  class Index                < PostfixExpression   ; end
  class Call                 < PostfixExpression   ; end
  class Dot                  < PostfixExpression   ; end
  class Arrow                < PostfixExpression   ; end
  class PostInc              < PostfixExpression   ; end
  class PostDec              < PostfixExpression   ; end

  class Cast                 < PrefixExpression    ; end
  class Address              < PrefixExpression    ; end
  class Dereference          < PrefixExpression    ; end
  class Sizeof               < PrefixExpression    ; end
  class Positive             < PrefixExpression    ; end
  class Negative             < PrefixExpression    ; end
  class PreInc               < PrefixExpression    ; end
  class PreDec               < PrefixExpression    ; end
  class BitNot               < PrefixExpression    ; end
  class Not                  < PrefixExpression    ; end

  class Add                  < BinaryExpression    ; end
  class Subtract             < BinaryExpression    ; end
  class Multiply             < BinaryExpression    ; end
  class Divide               < BinaryExpression    ; end
  class Mod                  < BinaryExpression    ; end
  class Equal                < BinaryExpression    ; end
  class NotEqual             < BinaryExpression    ; end
  class Less                 < BinaryExpression    ; end
  class More                 < BinaryExpression    ; end
  class LessOrEqual          < BinaryExpression    ; end
  class MoreOrEqual          < BinaryExpression    ; end
  class BitAnd               < BinaryExpression    ; end
  class BitOr                < BinaryExpression    ; end
  class BitXor               < BinaryExpression    ; end
  class ShiftLeft            < BinaryExpression    ; end
  class ShiftRight           < BinaryExpression    ; end
  class And                  < BinaryExpression    ; end
  class Or                   < BinaryExpression    ; end

  class Assign               < AssignmentExpression; end
  class MultiplyAssign       < AssignmentExpression; end
  class DivideAssign         < AssignmentExpression; end
  class ModAssign            < AssignmentExpression; end
  class AddAssign            < AssignmentExpression; end
  class SubtractAssign       < AssignmentExpression; end
  class ShiftLeftAssign      < AssignmentExpression; end
  class ShiftRightAssign     < AssignmentExpression; end
  class BitAndAssign         < AssignmentExpression; end
  class BitXorAssign         < AssignmentExpression; end
  class BitOrAssign          < AssignmentExpression; end

  class StringLiteral        < Literal             ; end
  class CharLiteral          < Literal             ; end
  class CompoundLiteral      < Literal             ; end
  class IntLiteral           < Literal             ; end
  class FloatLiteral         < Literal             ; end

  class Pointer              < IndirectType        ; end
  class Array                < IndirectType        ; end
  class Function             < IndirectType        ; end

  class Struct               < DirectType          ; end
  class Union                < DirectType          ; end
  class Enum                 < DirectType          ; end
  class CustomType           < DirectType          ; end

  class Void                 < PrimitiveType       ; end
  class Int                  < PrimitiveType       ; end
  class Float                < PrimitiveType       ; end
  class Char                 < PrimitiveType       ; end
  class Bool                 < PrimitiveType       ; end
  class Complex              < PrimitiveType       ; end
  class Imaginary            < PrimitiveType       ; end

  # ------------------------------------------------------------------
  #                       Class implementations
  # ------------------------------------------------------------------

  class Node
    initializer
  end

  class TranslationUnit
    child :entities, lambda{NodeChain.new}
    initializer :entities
  end

  class Declaration
    field :storage
    child :type
    child :declarators, lambda{NodeArray.new}
    field :inline?
    initializer :type, :declarators
    def typedef?
      storage.equal? :typedef
    end
    def extern?
      storage.equal? :extern
    end
    def static?
      storage.equal? :static
    end
    def auto?
      storage.equal? :auto
    end
    def register?
      storage.equal? :register
    end
  end

  class Declarator
    child :indirect_type
    field :name
    child :init
    child :num_bits
    initializer :indirect_type, :name, :init, :num_bits
    def declaration
      parent and parent.parent
    end
    #
    # Return (a copy of) the type of the variable this Declarator
    # declares.
    #
    def type
      if indirect_type
        ret = indirect_type.clone
        ret.direct_type = declaration.type.clone
        return ret
      else
        declaration.type.clone
      end
    end
  end

  class FunctionDef
    field :storage
    field :inline?
    child :type
    field :name
    child :def, lambda{Block.new}
    field :no_prototype?
    initializer :type, :name, :def
    def extern?
      storage.equal? :extern
    end
    def static?
      storage.equal? :static
    end
    def prototype=(val)
      self.no_prototype = !val
    end
    def prototype?
      !no_prototype?
    end
  end

  class Parameter
    field :register?
    child :type
    field :name
    initializer :type, :name
  end

  class Enumerator
    field :name
    child :val
    initializer :name, :val
  end

  class MemberInit
    # member is a _NodeList_ of:
    #   -- Member (for struct/union members)
    #   -- Expression (for array members)
    child :member
    child :init
    initializer :member, :init
  end

  class Member
    field :name
    initializer :name
  end

  # ------------------------------------------------------------------
  #                             Statements
  # ------------------------------------------------------------------

  class Block
    child :labels, lambda{NodeArray.new}
    child :stmts, lambda{NodeChain.new}
    initializer :stmts
  end

  class If
    child :labels, lambda{NodeArray.new}
    child :cond
    child :then
    child :else
    initializer :cond, :then, :else
  end

  class Switch
    child :labels, lambda{NodeArray.new}
    child :cond
    child :stmt
    initializer :cond, :stmt
  end

  class While
    child :labels, lambda{NodeArray.new}
    field :do?
    child :cond
    child :stmt
    initializer :cond, :stmt, :do?
  end

  class For
    child :labels, lambda{NodeArray.new}
    child :init
    child :cond
    child :iter
    child :stmt
    initializer :init, :cond, :iter, :stmt
  end

  class Goto
    child :labels, lambda{NodeArray.new}
    field :target
    initializer :target
  end

  class Continue
    child :labels, lambda{NodeArray.new}
  end

  class Break
    child :labels, lambda{NodeArray.new}
  end

  class Return
    child :labels, lambda{NodeArray.new}
    child :expr
    initializer :expr
  end

  class ExpressionStatement
    child :labels, lambda{NodeArray.new}
    child :expr
    initializer :expr
  end

  # ------------------------------------------------------------------
  #                               Labels
  # ------------------------------------------------------------------

  class PlainLabel
    field :name
    initializer :name
  end

  class Default
  end

  class Case
    child :expr
    initializer :expr
  end

  # ------------------------------------------------------------------
  #                            Expressions
  # ------------------------------------------------------------------

  class Comma
    child :exprs, lambda{NodeArray.new}
    initializer :exprs
  end

  class Conditional
    child :cond
    child :then
    child :else
    initializer :cond, :then, :else
  end

  class Variable
    field :name
    initializer :name
  end

  class BlockExpression
    child :block, lambda{Block.new}
    initializer :block
  end

  # ------------------------------------------------------------------
  #                         PrefixExpressions
  # ------------------------------------------------------------------

  class Cast
    child :type
    child :expr
    initializer :type, :expr
  end

  class Address
    child :expr
    initializer :expr
  end

  class Dereference
    child :expr
    initializer :expr
  end

  class Sizeof
    child :expr
    initializer :expr
  end

  class Positive
    child :expr
    initializer :expr
  end

  class Negative
    child :expr
    initializer :expr
  end

  class PreInc
    child :expr
    initializer :expr
  end

  class PreDec
    child :expr
    initializer :expr
  end

  class BitNot
    child :expr
    initializer :expr
  end

  class Not
    child :expr
    initializer :expr
  end

  # ------------------------------------------------------------------
  #                         PostfixExpressions
  # ------------------------------------------------------------------

  class Index
    child :expr
    child :index
    initializer :expr, :index
  end

  class Call
    child :expr
    child :args, lambda{NodeArray.new}
    initializer :expr, :args
  end

  class Dot
    child :expr
    child :member
    initializer :expr, :member
  end

  class Arrow
    child :expr
    child :member
    initializer :expr, :member
  end

  class PostInc
    child :expr
    initializer :expr
  end

  class PostDec
    child :expr
    initializer :expr
  end

  # ------------------------------------------------------------------
  #                         BinaryExpressions
  # ------------------------------------------------------------------

  class BinaryExpression
    class << self
      #
      # The operator (a String) pertaining to the class (e.g.,
      # Add.operator is '+').
      #
      attr_accessor :operator
    end
  end

  class Add
    child :expr1
    child :expr2
    initializer :expr1, :expr2
    self.operator = '+'
  end

  class Subtract
    child :expr1
    child :expr2
    initializer :expr1, :expr2
    self.operator = '-'
  end

  class Multiply
    child :expr1
    child :expr2
    initializer :expr1, :expr2
    self.operator = '*'
  end

  class Divide
    child :expr1
    child :expr2
    initializer :expr1, :expr2
    self.operator = '/'
  end

  class Mod
    child :expr1
    child :expr2
    initializer :expr1, :expr2
    self.operator = '%'
  end

  class Equal
    child :expr1
    child :expr2
    initializer :expr1, :expr2
    self.operator = '=='
  end

  class NotEqual
    child :expr1
    child :expr2
    initializer :expr1, :expr2
    self.operator = '!='
  end

  class Less
    child :expr1
    child :expr2
    initializer :expr1, :expr2
    self.operator = '<'
  end

  class More
    child :expr1
    child :expr2
    initializer :expr1, :expr2
    self.operator = '>'
  end

  class LessOrEqual
    child :expr1
    child :expr2
    initializer :expr1, :expr2
    self.operator = '<='
  end

  class MoreOrEqual
    child :expr1
    child :expr2
    initializer :expr1, :expr2
    self.operator = '>='
  end

  class BitAnd
    child :expr1
    child :expr2
    initializer :expr1, :expr2
    self.operator = '&'
  end

  class BitOr
    child :expr1
    child :expr2
    initializer :expr1, :expr2
    self.operator = '|'
  end

  class BitXor
    child :expr1
    child :expr2
    initializer :expr1, :expr2
    self.operator = '^'
  end

  class ShiftLeft
    child :expr1
    child :expr2
    initializer :expr1, :expr2
    self.operator = '<<'
  end

  class ShiftRight
    child :expr1
    child :expr2
    initializer :expr1, :expr2
    self.operator = '>>'
  end

  class And
    child :expr1
    child :expr2
    initializer :expr1, :expr2
    self.operator = '&&'
  end

  class Or
    child :expr1
    child :expr2
    initializer :expr1, :expr2
    self.operator = '||'
  end

  # ------------------------------------------------------------------
  #                       AssignmentExpressions
  # ------------------------------------------------------------------

  class AssignmentExpression
    class << self
      #
      # The operator (a String) pertaining to the class (e.g.,
      # Assign.operator is '=').
      #
      attr_accessor :operator
    end
  end

  class Assign
    child :lval
    child :rval
    initializer :lval, :rval
    self.operator = '='
  end

  class MultiplyAssign
    child :lval
    child :rval
    initializer :lval, :rval
    self.operator = '*='
  end

  class DivideAssign
    child :lval
    child :rval
    initializer :lval, :rval
    self.operator = '/='
  end

  class ModAssign
    child :lval
    child :rval
    initializer :lval, :rval
    self.operator = '%='
  end

  class AddAssign
    child :lval
    child :rval
    initializer :lval, :rval
    self.operator = '+='
  end

  class SubtractAssign
    child :lval
    child :rval
    initializer :lval, :rval
    self.operator = '-='
  end

  class ShiftLeftAssign
    child :lval
    child :rval
    initializer :lval, :rval
    self.operator = '<<='
  end

  class ShiftRightAssign
    child :lval
    child :rval
    initializer :lval, :rval
    self.operator = '>>='
  end

  class BitAndAssign
    child :lval
    child :rval
    initializer :lval, :rval
    self.operator = '&='
  end

  class BitXorAssign
    child :lval
    child :rval
    initializer :lval, :rval
    self.operator = '^='
  end

  class BitOrAssign
    child :lval
    child :rval
    initializer :lval, :rval
    self.operator = '|='
  end

  # ------------------------------------------------------------------
  #                              Literals
  # ------------------------------------------------------------------

  class StringLiteral
    field :prefix
    field :val
    initializer :val, :prefix
    def wide?
      prefix == 'L'
    end
    def wide=(val)
      return if wide? == !!val
      self.prefix = val ? 'L' : nil
    end
  end

  class CharLiteral
    field :prefix
    field :val
    initializer :val, :prefix
    def wide?
      prefix == 'L'
    end
    def wide=(val)
      return if wide? == !!val
      self.prefix = val ? 'L' : nil
    end
  end

  class CompoundLiteral
    child :type
    child :member_inits, lambda{NodeArray.new}
    initializer :type, :member_inits
  end

  class IntLiteral
    field :format, :dec
    field :val
    field :suffix
    initializer :val
    def dec?
      format.equal? :dec
    end
    def hex?
      format.equal? :hex
    end
    def oct?
      format.equal? :oct
    end
  end

  class FloatLiteral
    field :format, :dec
    field :val
    field :suffix
    initializer :val
  end

  # ------------------------------------------------------------------
  #                               Types
  # ------------------------------------------------------------------

  class DirectType
    def direct_type
      self
    end
    def indirect_type
      nil
    end
  end

  class IndirectType
    def direct_type
      if type.is_a? IndirectType
        type.direct_type
      else
        type
      end
    end
    def direct_type=(val)
      if type.is_a? IndirectType
        type.direct_type = val
      else
        self.type = val
      end
    end
    def indirect_type
      ret = self.clone
      t = ret
      while t.type.is_a? IndirectType
        t = t.type
      end
      t.type = nil
      return ret
    end
  end

  class Pointer
    field :const?
    field :restrict?
    field :volatile?
    child :type
    initializer :type
  end

  class Array
    field :const?
    field :restrict?
    field :volatile?
    child :type
    child :length
    initializer :type, :length
  end

  class Function
    field :const?
    field :restrict?
    field :volatile?
    child :type
    child :params
    field :var_args?
    initializer :type, :params
  end

  class Struct
    field :const?
    field :restrict?
    field :volatile?
    field :name
    child :members
    initializer :name, :members
  end

  class Union
    field :const?
    field :restrict?
    field :volatile?
    field :name
    child :members
    initializer :name, :members
  end

  class Enum
    field :const?
    field :restrict?
    field :volatile?
    field :name
    child :members
    initializer :name, :members
  end

  class CustomType
    field :const?
    field :restrict?
    field :volatile?
    field :name
    initializer :name
  end

  class Void
    field :const?
    field :restrict?
    field :volatile?
  end

  class Int
    field :const?
    field :restrict?
    field :volatile?
    field :longness, 0
    field :unsigned?, false
    initializer :longness
    def signed?
      !unsigned?
    end
    def signed=(val)
      self.unsigned = !val
    end
    def short?
      longness.equal? -1
    end
    def plain?
      longness.equal? 0
    end
    def long?
      longness.equal? 1
    end
    def long_long?
      longness.equal? 2
    end
  end

  class Float
    field :const?
    field :restrict?
    field :volatile?
    field :longness, 0
    initializer :longness
    def plain?
      longness.equal? 0
    end
    def double?
      longness.equal? 1
    end
    def long_double?
      longness.equal? 2
    end
  end

  class Char
    field :const?
    field :restrict?
    field :volatile?
    # 6.2.5p15: `char', `signed char', and `unsigned char' are
    # distinct types
    field :signed
    def signed?
      signed.equal? true
    end
    def unsigned?
      signed.equal? false
    end
    def plain?
      signed.nil?
    end
  end

  class Bool
    field :const?
    field :restrict?
    field :volatile?
  end

  class Complex
    field :const?
    field :restrict?
    field :volatile?
    field :longness, 0
    initializer :longness
    def plain?
      longness.equal? 0
    end
    def double?
      longness.equal? 1
    end
    def long_double?
      longness.equal? 2
    end
  end

  class Imaginary
    field :const?
    field :restrict?
    field :volatile?
    field :longness, 0
    initializer :longness
    def plain?
      longness.equal? 0
    end
    def double?
      longness.equal? 1
    end
    def long_double?
      longness.equal? 2
    end
  end

  # ------------------------------------------------------------------
  #                            Tag classes
  # ------------------------------------------------------------------

  # classify the node classes by including modules
  tagger = lambda do |included, *includers|
    includers.each{|mod| mod.send(:include, included)}
  end

  # expression classes
  module ArithmeticExpression; end
  module BitwiseExpression   ; end
  module LogicalExpression   ; end
  module RelationalExpression; end
  module ShiftExpression     ; end
  #
  tagger.call(ArithmeticExpression,
              PostInc, PostDec, Positive, Negative, PreInc, PreDec, Add,
              Subtract, Multiply, Divide, Mod)
  tagger.call(BitwiseExpression,
              BitNot, BitAnd, BitOr, BitXor)
  tagger.call(LogicalExpression,
              Not, And, Or)
  tagger.call(RelationalExpression,
              Equal, NotEqual, Less, More, LessOrEqual, MoreOrEqual)
  tagger.call(ShiftExpression,
              ShiftLeft, ShiftRight)

  # ------------------------------------------------------------------
  #                        CORE_C_NODE_CLASSES
  # ------------------------------------------------------------------

  CORE_C_NODE_CLASSES = [
    TranslationUnit,
    Declaration,
    Declarator,
    FunctionDef,
    Parameter,
    Enumerator,
    MemberInit,
    Member,

    Block,
    If,
    Switch,
    While,
    For,
    Goto,
    Continue,
    Break,
    Return,
    ExpressionStatement,

    PlainLabel,
    Default,
    Case,

    Comma,
    Conditional,
    Variable,
    BlockExpression,

    Index,
    Call,
    Dot,
    Arrow,
    PostInc,
    PostDec,

    Cast,
    Address,
    Dereference,
    Sizeof,
    Positive,
    Negative,
    PreInc,
    PreDec,
    BitNot,
    Not,

    Add,
    Subtract,
    Multiply,
    Divide,
    Mod,
    Equal,
    NotEqual,
    Less,
    More,
    LessOrEqual,
    MoreOrEqual,
    BitAnd,
    BitOr,
    BitXor,
    ShiftLeft,
    ShiftRight,
    And,
    Or,

    Assign,
    MultiplyAssign,
    DivideAssign,
    ModAssign,
    AddAssign,
    SubtractAssign,
    ShiftLeftAssign,
    ShiftRightAssign,
    BitAndAssign,
    BitXorAssign,
    BitOrAssign,

    StringLiteral,
    CharLiteral,
    CompoundLiteral,
    IntLiteral,
    FloatLiteral,

    Pointer,
    Array,
    Function,

    Struct,
    Union,
    Enum,
    CustomType,

    Void,
    Int,
    Float,
    Char,
    Bool,
    Complex,
    Imaginary
  ]

  # check we didn't miss any
  expected_classes = Node.subclasses_recursive.sort_by{|c| c.name}
  expected_classes -= NodeList.subclasses_recursive
  expected_classes -= [NodeList]
  expected_classes -= [
    Statement,
    Label,
    Expression,
    UnaryExpression,
    PostfixExpression,
    PrefixExpression,
    BinaryExpression,
    AssignmentExpression,
    Literal,
    Type,
    IndirectType,
    DirectType,
    PrimitiveType
  ]
  #
  CORE_C_NODE_CLASSES.sort_by{|c| c.name} == expected_classes or raise
end
