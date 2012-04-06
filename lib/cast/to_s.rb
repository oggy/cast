######################################################################
#
# The Node#to_s methods.
#
# Yeah, this could be so so *SO* much faster.
#
######################################################################

module C
  # undef the #to_s methods so we can check that we didn't forget to
  # define any
  Node.send(:undef_method, :to_s)

  INDENT = '    '
  class Node
    private
    def indent(s, levels=1)
      s.gsub(/^/, INDENT*levels)
    end
    def hang(stmt, cont=false)
      if stmt.is_a?(Block) && stmt.labels.empty?
        return " #{stmt.to_s(:hanging)}" << (cont ? ' ' : '')
      else
        return "\n#{stmt.to_s}" << (cont ? "\n" : '')
      end
    end
  end

  class TranslationUnit
    def to_s
      entities.map{|n| n.to_s}.join("\n\n")
    end
  end
  class Declaration
    def to_s
      str = ''
      inline? and str << "inline "
      storage and str << "#{storage} "
      if declarators.empty?
        return str << "#{type};"
      else
        return str << "#{type} " << declarators.join(', ') << ';'
      end
    end
  end
  class Declarator
    def to_s
      (indirect_type ? indirect_type.to_s(name) : name.dup) <<
        (init ? " = #{init}" : '') <<
        (num_bits ? " : #{num_bits}" : '')
    end
  end
  class FunctionDef
    def to_s
      str = ''
      static? and str << 'static '
      inline? and str << 'inline '
      if no_prototype?
        str << "#{type.to_s(name, true)}\n"
        type.params.each do |p|
          str << indent("#{p.to_s};\n")
        end
        str << "#{self.def.to_s(:hanging)}"
      else
        str << "#{type.to_s(name)}#{hang(self.def)}"
      end
    end
  end

  # ------------------------------------------------------------------
  #                             Statements
  # ------------------------------------------------------------------

  class Statement
    def label(str)
      labels.map{|s| "#{s}\n"}.join + indent(str)
    end
  end
  class Block
    def to_s(hanging=false)
      str = stmts.map do |s|
        if s.is_a? Statement
          s.to_s
        else
          indent(s.to_s)
        end
      end.join("\n")
      str << "\n" unless str == ''
      str = "{\n" << str << "}"
      if hanging
        if labels.empty?
          return str
        else
          return "\n" << label(str)
        end
      else
        return label(str)
      end
    end
  end
  class If
    def to_s
      str = "if (#{cond})"
      if self.else.nil?
        str << hang(self.then)
      else
        str << hang(self.then, :cont) << 'else' << hang(self.else)
      end
      return label(str)
    end
  end
  class Switch
    def to_s
      label("switch (#{cond})" << hang(stmt))
    end
  end
  class While
    def to_s
      if do?
        label('do' << hang(stmt, :cont) << "while (#{cond});")
      else
        label("while (#{cond})" << hang(stmt))
      end
    end
  end
  class For
    def to_s
      initstr =
        case init
        when nil
          ';'
        when Declaration
          "#{init}"
        else
          "#{init};"
        end
      condstr = cond ? " #{cond};" : ';'
      iterstr = iter ? " #{iter}"  : ''
      label("for (#{initstr}#{condstr}#{iterstr})" << hang(stmt))
    end
  end
  class Goto
    def to_s
      label("goto #{target};")
    end
  end
  class Continue
    def to_s
      label("continue;")
    end
  end
  class Break
    def to_s
      label("break;")
    end
  end
  class Return
    def to_s
      label("return#{expr ? ' '+expr.to_s : ''};")
    end
  end
  class ExpressionStatement
    def to_s
      label("#{expr};")
    end
  end

  class PlainLabel
    def to_s
      "#{name}:"
    end
  end
  class Default
    def to_s
      'default:'
    end
  end
  class Case
    def to_s
      "case #{expr}:"
    end
  end

  # ------------------------------------------------------------------
  #                            Expressions
  # ------------------------------------------------------------------

  precedence_table = {}
  [[Comma],
    [Assign, MultiplyAssign, DivideAssign, ModAssign, AddAssign,
      SubtractAssign, ShiftLeftAssign, ShiftRightAssign, BitAndAssign,
      BitXorAssign, BitOrAssign],
    [Conditional],
    [Or],
    [And],
    [BitOr],
    [BitXor],
    [BitAnd],
    [Equal, NotEqual],
    [Less, More, LessOrEqual, MoreOrEqual],
    [ShiftLeft, ShiftRight],
    [Add, Subtract],
    [Multiply, Divide, Mod],
    [PreInc, PreDec, Sizeof, Cast, Address, Dereference, Positive, Negative,
      BitNot, Not],
    [Index, Call, Arrow, Dot, PostInc, PostDec],
    [Literal, Variable]
  ].each_with_index do |klasses, prec|
    klasses.each do |klass|
      klass.send(:define_method, :to_s_precedence){|| prec}
    end
  end
  # check all Expression classes have a precedence
  C::Expression.subclasses_recursive do |c|
    next if !C::Node.subclasses_recursive.include? c
    c.instance_methods.include? 'to_s_precedence' or
      raise "#{c}#to_s_precedence not defined"
  end

  # PrefixExpressions
  [ [Cast       , proc{"(#{self.type})"}, false],
    [Address    , proc{"&"             }, true ],
    [Dereference, proc{"*"             }, false],
    [Positive   , proc{"+"             }, true ],
    [Negative   , proc{"-"             }, true ],
    [PreInc     , proc{"++"            }, false],
    [PreDec     , proc{"--"            }, false],
    [BitNot     , proc{"~"             }, false],
    [Not        , proc{"!"             }, false]
  ].each do |c, proc, space_needed|
    c.send(:define_method, :to_s) do | |
      if expr.to_s_precedence < self.to_s_precedence
        return "#{instance_eval(&proc)}(#{expr})"
      elsif space_needed && expr.class == self.class
        return "#{instance_eval(&proc)} #{expr}"
      else
        return "#{instance_eval(&proc)}#{expr}"
      end
    end
  end
  # PostfixExpressions
  [ [Arrow      , proc{"->#{member}"}],
    [Dot        , proc{".#{member}" }],
    [Index      , proc{"[#{index}]" }],
    [PostInc    , proc{"++"         }],
    [PostDec    , proc{"--"         }]
  ].each do |c, proc|
    c.send(:define_method, :to_s) do | |
      if expr.to_s_precedence < self.to_s_precedence
        return "(#{expr})#{instance_eval(&proc)}"
      else
        return "#{expr}#{instance_eval(&proc)}"
      end
    end
  end
  # BinaryExpressions
  [ [Add        , '+' ],
    [Subtract   , '-' ],
    [Multiply   , '*' ],
    [Divide     , '/' ],
    [Mod        , '%' ],
    [Equal      , '=='],
    [NotEqual   , '!='],
    [Less       , '<' ],
    [More       , '>' ],
    [LessOrEqual, '<='],
    [MoreOrEqual, '>='],
    [BitAnd     , '&' ],
    [BitOr      , '|' ],
    [BitXor     , '^' ],
    [ShiftLeft  , '<<'],
    [ShiftRight , '>>'],
    [And        , '&&'],
    [Or         , '||'],
  ].each do |c, op|
    c.send(:define_method, :to_s) do | |
      if expr1.to_s_precedence < self.to_s_precedence
        str1 = "(#{expr1})"
      else
        str1 = "#{expr1}"
      end
      # all binary expressions are left associative
      if expr2.to_s_precedence <= self.to_s_precedence
        str2 = "(#{expr2})"
      else
        str2 = "#{expr2}"
      end
      "#{str1} #{op} #{str2}"
    end
  end
  # AssignmentExpressions
  [ [Assign          , ''  ],
    [MultiplyAssign  , '*' ],
    [DivideAssign    , '/' ],
    [ModAssign       , '%' ],
    [AddAssign       , '+' ],
    [SubtractAssign  , '-' ],
    [ShiftLeftAssign , '<<'],
    [ShiftRightAssign, '>>'],
    [BitAndAssign    , '&' ],
    [BitXorAssign    , '^' ],
    [BitOrAssign     , '|' ]
  ].each do |c, op|
    c.send(:define_method, :to_s) do | |
      if rval.to_s_precedence < self.to_s_precedence
        rvalstr = "(#{rval})"
      else
        rvalstr = "#{rval}"
      end
      if lval.to_s_precedence < self.to_s_precedence
        lvalstr = "(#{lval})"
      else
        lvalstr = "#{lval}"
      end
      "#{lvalstr} #{op}= #{rvalstr}"
    end
  end
  # Other Expressions
  class Sizeof
    def to_s
      "sizeof(#{expr})"
    end
  end
  # DirectTypes
  int_longnesses   = ['short ', '', 'long ', 'long long ']
  float_longnesses = ['float', 'double', 'long double']
  [ [Struct, proc do
        str = 'struct'
        name    and str << " #{name}"
        members and str << " {\n" << indent(members.join("\n")) << "\n}"
        str
      end],
    [Union, proc do
        str = 'union'
        name    and str << " #{name}"
        members and str << " {\n" << indent(members.join("\n")) << "\n}"
        str
      end],
    [Enum, proc do
        str = 'enum'
        name    and str << " #{name}"
        members and str << " {\n" << indent(members.join(",\n")) << "\n}"
        str
      end],
    [CustomType, proc{name.dup    }],
    [Void      , proc{'void'      }],
    [Int       , proc do
        longness_str = int_longnesses[longness+1].dup
        "#{unsigned? ? 'unsigned ' : ''}#{longness_str}int"
      end],
    [Float     , proc{float_longnesses[longness].dup}],
    [Char      , proc{"#{unsigned? ? 'unsigned ' : signed? ? 'signed ' : ''}char"}],
    [Bool      , proc{"_Bool"     }],
    [Complex   , proc{"_Complex #{float_longnesses[longness]}"}],
    [Imaginary , proc{"_Imaginary #{float_longnesses[longness]}"}]
  ].each do |c, x|
    c.send(:define_method, :to_s) do |*args|
      case args.length
      when 0
        namestr = nil
      when 1
        namestr = args[0]
        namestr = nil if namestr == ''
      else
        raise ArgumentError, "wrong number of args (#{args.length} for 1)"
      end
      str = ''
      const?    and str << 'const '
      restrict? and str << 'restrict '
      volatile? and str << 'volatile '
      str << instance_eval(&x) << (namestr ? " #{namestr}" : '')
    end
  end

  class Enumerator
    def to_s
      if val
        "#{name} = #{val}"
      else
        "#{name}"
      end
    end
  end

  class Comma
    def to_s
      exprs.join(', ')
    end
  end

  class Conditional
    def to_s
      strs = [:cond, :then, :else].map do |child|
        val = send(child)
        if val.to_s_precedence <= self.to_s_precedence
          "(#{val})"
        else
          "#{val}"
        end
      end
      "#{strs[0]} ? #{strs[1]} : #{strs[2]}"
    end
  end

  class Call
    def to_s
      argstrs = args.map do |arg|
        if arg.is_a? Comma
          "(#{arg})"
        else
          "#{arg}"
        end
      end
      if expr.to_s_precedence < self.to_s_precedence
        exprstr = "(#{expr})"
      else
        exprstr = "#{expr}"
      end
      "#{exprstr}(#{argstrs.join(', ')})"
    end
  end

  ## IndirectTypes
  class Pointer
    def to_s(name=nil)
      str = '*'
      const?    and str << 'const '
      restrict? and str << 'restrict '
      volatile? and str << 'volatile '
      str =
        case type
        when Function, Array
          "(#{str}#{name})"
        else
          "#{str}#{name}"
        end
      if type
        type.to_s(str)
      else
        str
      end
    end
  end
  class Array
    def to_s(name=nil)
      str = "#{name}[#{length}]"
      if type
        type.to_s(str)
      else
        str
      end
    end
  end
  class Function
    def to_s(name=nil, no_types=false)
      str =
        if params.nil?
          paramstr = ''
        elsif params.empty?
          paramstr = 'void'
        else
          if no_types
            paramstr = params.map{|p| p.name}.join(', ')
          else
            paramstr = params.join(', ')
          end
        end
      var_args? and paramstr << ', ...'
      str = "#{name}(#{paramstr})"
      if type
        type.to_s(str)
      else
        str
      end
    end
  end
  class Parameter
    def to_s
      str = register? ? 'register ' : ''
      if type
        str << type.to_s(name)
      else
        str << name.to_s
      end
    end
  end

  ## Literals
  class StringLiteral
    def to_s
      "\"#{val}\""
    end
  end
  class CharLiteral
    def to_s
      "'#{val}'"
    end
  end
  class CompoundLiteral
    def to_s
      str = ''
      type and
        str << "(#{type}) "
      str << "{\n" << indent(member_inits.join(",\n")) << "\n}"
    end
  end
  class MemberInit
    def to_s
      str = ''
      if member
        memberstr = member.map do |m|
          if m.is_a? Expression
            "[#{m}]"
          else
            ".#{m}"
          end
        end
        str << memberstr.join(' ') << ' = '
      end
      return str << init.to_s
    end
  end
  class Member
    def to_s
      name.dup
    end
  end
  class IntLiteral
    def to_s
      val.to_s
    end
  end
  class FloatLiteral
    def to_s
      val.to_s
    end
  end
  class Variable
    def to_s
      name.dup
    end
  end
  class BlockExpression
    def to_s
      # note that the grammar does not allow the block to have a label
      "(#{block.to_s(:hanging)})"
    end
  end

  # check we didn't miss any
  CORE_C_NODE_CLASSES.each do |c|
    c.method_defined? :to_s or
      raise "#{c}#to_s not defined"
  end
end
