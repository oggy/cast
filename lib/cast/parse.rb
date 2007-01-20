######################################################################
#
# C.default_parser and the parse_* methods.
#
# Yeah, this could be so much faster.
#
######################################################################

module C
  @@default_parser = Parser.new
  def self.default_parser
    @@default_parser
  end
  def self.default_parser=(val)
    @@default_parser = val
  end

  class Node
    #
    # Return true if `str' is parsed to something `==' to this Node.
    # str is first converted to a String using #to_s, then given to
    # self.class.parse (along with the optional `parser').
    #
    def match?(str, parser=nil)
      node = self.class.parse(str.to_s, parser) rescue (return false)
      self == node
    end
    #
    # Same as #match?.
    #
    def =~(*args)
      match? *args
    end
    private
  end
  class NodeList
    #
    # As defined in Node.
    #
    def match?(arr, parser=nil)
      arr = arr.to_a
      return false if arr.length != self.length
      each_with_index do |node, i|
        node.match?(arr[i], parser) or return false
      end
      return true
    end
  end

  def self.parse(s, parser=nil)
    TranslationUnit.parse(s, parser)
  end

  class TranslationUnit
    def self.parse(s, parser=nil)
      parser ||= C.default_parser
      parser.parse(s)
    end
  end

  class Declaration
    def self.parse(s, parser=nil)
      parser ||= C.default_parser
      ents = parser.parse(s).entities
      if ents.length == 1 &&          # int i; int j;
          ents[0].is_a?(Declaration)  # void f() {}
        return ents[0].detach
      else
        raise ParseError, "invalid Declaration"
      end
    end
  end

  class Parameter
    def self.parse(s, parser=nil)
      parser ||= C.default_parser
      ents = parser.parse("void f(#{s}) {}").entities
      if ents.length == 1              &&  # ) {} void (
          ents[0].is_a?(FunctionDef)   &&  # ); void(
          ents[0].type.params          &&  #
          ents[0].type.params.length <= 1  # x,y
        param = ents[0].type.params[0]
        if param.nil?
          return Parameter.new(Void.new)
        else
          return param.detach
        end
      else
        raise ParseError, "invalid Parameter"
      end
    end
  end

  class Declarator
    def self.parse(s, parser=nil)
      parser ||= C.default_parser
      # if there's a ':', declare in a struct so we can populate num_bits
      if s =~ /:/
        ents = parser.parse("struct {int #{s};};").entities
        if ents.length == 1 &&                              # i:1;}; struct {int i
            ents[0].type.members.length == 1 &&             # i:1; int j
            ents[0].type.members[0].declarators.length == 1 # i:1,j
          return ents[0].type.members[0].declarators[0].detach
        end
      else
        ents = parser.parse("int #{s};").entities
        if ents.length == 1 &&               # f; int f;
            ents[0].declarators.length == 1  # i,j
          return ents[0].declarators[0].detach
        end
      end
      raise ParseError, "invalid Declarator"
    end
  end

  class FunctionDef
    def self.parse(s, parser=nil)
      parser ||= C.default_parser
      ents = parser.parse(s).entities
      if ents.length == 1 &&          # void f(); void g();
          ents[0].is_a?(FunctionDef)  # int i;
        return ents[0].detach
      else
        raise ParseError, "invalid FunctionDef"
      end
    end
  end

  class Enumerator
    def self.parse(s, parser=nil)
      parser ||= C.default_parser
      ents = parser.parse("enum {#{s}};").entities
      if ents.length == 1            &&     # } enum {
          ents[0].is_a?(Declaration) &&     # } f() {
          ents[0].type.members.length == 1  # X, Y
        return ents[0].type.members[0].detach
      else
        raise ParseError, "invalid Enumerator"
      end
    end
  end

  class MemberInit
    def self.parse(s, parser=nil)
      parser ||= C.default_parser
      ents = parser.parse("int f() {struct s x = {#{s}};}").entities
      if ents.length == 1                              &&  # } int f() {
          ents[0].def.stmts.length == 1                &&  # }} f() {{
          ents[0].def.stmts[0].declarators.length == 1 &&  # 1}, y
          ents[0].def.stmts[0].declarators[0].init.member_inits.length == 1 # 1, 2
        return ents[0].def.stmts[0].declarators[0].init.member_inits[0].detach
      else
        raise ParseError, "invalid MemberInit"
      end
    end
  end

  class Member
    def self.parse(s, parser=nil)
      parser ||= C.default_parser
      ents = parser.parse("int f() {struct s x = {.#{s} = 1};}").entities
      if ents.length == 1                              &&  # a = 1};} int f() {struct s x = {a
          ents[0].def.stmts.length == 1                &&  # a = 1}; struct s y = {.a
          #ents[0].def.stmts[0].length == 1            &&  # a = 1}, x = {.a
          ents[0].def.stmts[0].declarators.length == 1 &&  # a = 1}, x = {.a
          ents[0].def.stmts[0].declarators[0].init.member_inits.length == 1 &&        # x = 1, y
          ents[0].def.stmts[0].declarators[0].init.member_inits[0].member   &&        # 1
          ents[0].def.stmts[0].declarators[0].init.member_inits[0].member.length == 1 # a .b
        return ents[0].def.stmts[0].declarators[0].init.member_inits[0].member[0].detach
      else
        raise ParseError, "invalid Member"
      end
    end
  end

  class Statement
    def self.parse(s, parser=nil)
      parser ||= C.default_parser
      ents = parser.parse("void f() {#{s}}").entities
      if ents.length == 1               &&      # } void f() {
          ents[0].def.stmts.length == 1 &&      # ;;
          ents[0].def.stmts[0].is_a?(self)      # int i;
        return ents[0].def.stmts[0].detach
      else
        raise ParseError, "invalid #{self}"
      end
    end
  end

  class Label
    def self.parse(s, parser=nil)
      parser ||= C.default_parser
      ents = parser.parse("void f() {switch (0) #{s};}").entities
      if ents.length == 1                              &&  # } void f() {
          ents[0].def.stmts.length == 1                &&  # ;
          ents[0].def.stmts[0].stmt                    &&  #
          ents[0].def.stmts[0].stmt.labels.length == 1 &&  # x
          ents[0].def.stmts[0].stmt.labels[0].is_a?(self)
        return ents[0].def.stmts[0].stmt.labels[0].detach
      else
        raise ParseError, "invalid #{self}"
      end
    end
  end

  class Expression
    def self.parse(s, parser=nil)
      parser ||= C.default_parser
      ents = parser.parse("void f() {#{s};}").entities
      if ents.length == 1                                 &&  # } void f() {
          ents[0].def.stmts.length == 1                   &&  # ;
          ents[0].def.stmts[0].is_a?(ExpressionStatement) &&  # int i
          ents[0].def.stmts[0].expr.is_a?(self)
        return ents[0].def.stmts[0].expr.detach
      else
        raise ParseError, "invalid #{self}"
      end
    end
  end

  class Type
    def self.parse(s, parser=nil)
      parser ||= C.default_parser
      ents = parser.parse("void f() {(#{s})x;}").entities
      if ents.length == 1                        &&  # 1);} void f() {(int
          ents[0].def.stmts.length == 1          &&  # 1); (int
          ents[0].def.stmts[0].expr.type.is_a?(self)
        return ents[0].def.stmts[0].expr.type.detach
      else
        raise ParseError, "invalid #{self}"
      end
    end
  end

  # Make sure we didn't miss any
  CORE_C_NODE_CLASSES.each do |c|
    c.methods.include? 'parse' or
      raise "#{c}#parse not defined"
  end
end
