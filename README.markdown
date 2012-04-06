# CAST

C parser and abstract syntax tree for Ruby.

## Example

    require 'cast'

    source = File.read('file.c')
    ast = C.parse(source)
    ast.entities.each do |declaration|
      declaration.declarator.each do |declarator|
        puts "#{declarator.name}: declarator.type"
      end
    end

Or in irb:

    irb> ast = C.parse('int main(void) { return 0; }')
     => TranslationUnit
        entities:
            - FunctionDef
                type: Function
                    type: Int
                    params: []
                name: "main"
                def: Block
                    stmts:
                        - Return
                            expr: IntLiteral
                                val: 0

    irb> puts ast
    int main(void) {
        return 0;
    }
     => nil

## Nodes

`C.parse` returns a tree of `Node` objects. Here's the class hierarchy:

<div class="node_classes">
  <style scoped="scoped">
    div.node_classes .node_class_abstract {
      font-weight: bold;
    }
    div.node_classes .column {
      line-height: 120%;
      float: left;
      color: #222;
    }
    div.node_classes .spacer {
      display: float;
      clear: both;
    }
  </style>
  <ul class="column">
    <li class="node_class"><span class="node_class_abstract">Node</span><ul>
      <li class="node_class"><span class="node_class_concrete">TranslationUnit</span></li>
      <li class="node_class"><span class="node_class_concrete">Comment</span></li>
      <li class="node_class"><span class="node_class_concrete">Declaration</span></li>
      <li class="node_class"><span class="node_class_concrete">Declarator</span></li>
      <li class="node_class"><span class="node_class_concrete">FunctionDef</span></li>
      <li class="node_class"><span class="node_class_concrete">Parameter</span></li>
      <li class="node_class"><span class="node_class_concrete">Enumerator</span></li>
      <li class="node_class"><span class="node_class_concrete">MemberInit</span></li>
      <li class="node_class"><span class="node_class_concrete">Member</span></li>
      <li class="node_class"><span class="node_class_abstract">Statement</span><ul>
        <li class="node_class"><span class="node_class_concrete">Block</span></li>
        <li class="node_class"><span class="node_class_concrete">If</span></li>
        <li class="node_class"><span class="node_class_concrete">Switch</span></li>
        <li class="node_class"><span class="node_class_concrete">While</span></li>
        <li class="node_class"><span class="node_class_concrete">For</span></li>
        <li class="node_class"><span class="node_class_concrete">Goto</span></li>
        <li class="node_class"><span class="node_class_concrete">Continue</span></li>
        <li class="node_class"><span class="node_class_concrete">Break</span></li>
        <li class="node_class"><span class="node_class_concrete">Return</span></li>
        <li class="node_class"><span class="node_class_concrete">ExpressionStatement</span></li>
      </ul></li>
      <li class="node_class"><span class="node_class_abstract">Label</span><ul>
        <li class="node_class"><span class="node_class_concrete">PlainLabel</span></li>
        <li class="node_class"><span class="node_class_concrete">Default</span></li>
        <li class="node_class"><span class="node_class_concrete">Case</span></li>
      </ul></li>
      <li class="node_class"><span class="node_class_abstract">Type</span><ul>
        <li class="node_class"><span class="node_class_abstract">IndirectType</span><ul>
          <li class="node_class"><span class="node_class_concrete">Pointer</span></li>
          <li class="node_class"><span class="node_class_concrete">Array</span></li>
          <li class="node_class"><span class="node_class_concrete">Function</span></li>
        </ul></li>
        <li class="node_class"><span class="node_class_abstract">DirectType</span><ul>
          <li class="node_class"><span class="node_class_concrete">Struct</span></li>
          <li class="node_class"><span class="node_class_concrete">Union</span></li>
          <li class="node_class"><span class="node_class_concrete">Enum</span></li>
          <li class="node_class"><span class="node_class_concrete">CustomType</span></li>
          <li class="node_class"><span class="node_class_abstract">PrimitiveType</span><ul>
            <li class="node_class"><span class="node_class_concrete">Void</span></li>
            <li class="node_class"><span class="node_class_concrete">Int</span></li>
            <li class="node_class"><span class="node_class_concrete">Float</span></li>
            <li class="node_class"><span class="node_class_concrete">Char</span></li>
            <li class="node_class"><span class="node_class_concrete">Bool</span></li>
            <li class="node_class"><span class="node_class_concrete">Complex</span></li>
            <li class="node_class"><span class="node_class_concrete">Imaginary</span></li>
          </ul></li>
        </ul></li>
      </ul></li>
    </ul></li>
  </ul>
  <ul class="column">
    <li class="node_class"><span class="node_class_abstract">Node</span><ul>
      <li class="node_class"><span class="node_class_abstract">Expression</span><ul>
        <li class="node_class"><span class="node_class_concrete">Comma</span></li>
        <li class="node_class"><span class="node_class_concrete">Conditional</span></li>
        <li class="node_class"><span class="node_class_concrete">Variable</span></li>
        <li class="node_class"><span class="node_class_abstract">UnaryExpression</span><ul>
          <li class="node_class"><span class="node_class_abstract">PostfixExpression</span><ul>
            <li class="node_class"><span class="node_class_concrete">Index</span></li>
            <li class="node_class"><span class="node_class_concrete">Call</span></li>
            <li class="node_class"><span class="node_class_concrete">Dot</span></li>
            <li class="node_class"><span class="node_class_concrete">Arrow</span></li>
            <li class="node_class"><span class="node_class_concrete">PostInc</span></li>
            <li class="node_class"><span class="node_class_concrete">PostDec</span></li>
          </ul></li>
          <li class="node_class"><span class="node_class_abstract">PrefixExpression</span><ul>
            <li class="node_class"><span class="node_class_concrete">Cast</span></li>
            <li class="node_class"><span class="node_class_concrete">Address</span></li>
            <li class="node_class"><span class="node_class_concrete">Dereference</span></li>
            <li class="node_class"><span class="node_class_concrete">Sizeof</span></li>
            <li class="node_class"><span class="node_class_concrete">Plus</span></li>
            <li class="node_class"><span class="node_class_concrete">Minus</span></li>
            <li class="node_class"><span class="node_class_concrete">PreInc</span></li>
            <li class="node_class"><span class="node_class_concrete">PreDec</span></li>
            <li class="node_class"><span class="node_class_concrete">BitNot</span></li>
            <li class="node_class"><span class="node_class_concrete">Not</span></li>
          </ul></li>
        </ul></li>
        <li class="node_class"><span class="node_class_abstract">BinaryExpression</span><ul>
          <li class="node_class"><span class="node_class_concrete">Add</span></li>
          <li class="node_class"><span class="node_class_concrete">Subtract</span></li>
          <li class="node_class"><span class="node_class_concrete">Multiply</span></li>
          <li class="node_class"><span class="node_class_concrete">Divide</span></li>
          <li class="node_class"><span class="node_class_concrete">Mod</span></li>
          <li class="node_class"><span class="node_class_concrete">Equal</span></li>
          <li class="node_class"><span class="node_class_concrete">NotEqual</span></li>
          <li class="node_class"><span class="node_class_concrete">Less</span></li>
          <li class="node_class"><span class="node_class_concrete">More</span></li>
          <li class="node_class"><span class="node_class_concrete">LessOrEqual</span></li>
          <li class="node_class"><span class="node_class_concrete">MoreOrEqual</span></li>
          <li class="node_class"><span class="node_class_concrete">BitAnd</span></li>
          <li class="node_class"><span class="node_class_concrete">BitOr</span></li>
          <li class="node_class"><span class="node_class_concrete">BitXor</span></li>
          <li class="node_class"><span class="node_class_concrete">ShiftLeft</span></li>
          <li class="node_class"><span class="node_class_concrete">ShiftRight</span></li>
          <li class="node_class"><span class="node_class_concrete">And</span></li>
          <li class="node_class"><span class="node_class_concrete">Or</span></li>
        </ul></li>
      </ul></li>
    </ul></li>
  </ul>
  <ul class="column">
    <li class="node_class"><span class="node_class_abstract">Node</span><ul>
      <li class="node_class"><span class="node_class_abstract">Expression</span><ul>
        <li class="node_class"><span class="node_class_abstract">AssignmentExpression</span><ul>
          <li class="node_class"><span class="node_class_concrete">Assign</span></li>
          <li class="node_class"><span class="node_class_concrete">MultiplyAssign</span></li>
          <li class="node_class"><span class="node_class_concrete">DivideAssign</span></li>
          <li class="node_class"><span class="node_class_concrete">ModAssign</span></li>
          <li class="node_class"><span class="node_class_concrete">AddAssign</span></li>
          <li class="node_class"><span class="node_class_concrete">SubtractAssign</span></li>
          <li class="node_class"><span class="node_class_concrete">ShiftLeftAssign</span></li>
          <li class="node_class"><span class="node_class_concrete">ShiftRightAssign</span></li>
          <li class="node_class"><span class="node_class_concrete">BitAndAssign</span></li>
          <li class="node_class"><span class="node_class_concrete">BitXorAssign</span></li>
          <li class="node_class"><span class="node_class_concrete">BitOrAssign</span></li>
        </ul></li>
        <li class="node_class"><span class="node_class_abstract">Literal</span><ul>
          <li class="node_class"><span class="node_class_concrete">StringLiteral</span></li>
          <li class="node_class"><span class="node_class_concrete">CharLiteral</span></li>
          <li class="node_class"><span class="node_class_concrete">CompoundLiteral</span></li>
          <li class="node_class"><span class="node_class_concrete">IntLiteral</span></li>
          <li class="node_class"><span class="node_class_concrete">FloatLiteral</span></li>
        </ul></li>
      </ul></li>
      <li class="node_class"><span class="node_class_abstract">NodeList</span><ul>
        <li class="node_class"><span class="node_class_concrete">NodeArray</span></li>
        <li class="node_class"><span class="node_class_concrete">NodeChain</span></li>
      </ul></li>
    </ul></li>
  </ul>
  <div class="spacer"></div>
</div>

The <span class="node_class_abstract">highlighted</span> ones are abstract.

The last 2 (`NodeList`s) represent lists of `Node`s. They quack like
standard ruby `Arrays`. `NodeChain` is a doubly linked list;
`NodeArray` is an array.

### Node Methods

 * `parent`: return the parent in the tree (a `Node` or nil).
 * `pos`, `pos=`: the position in the source file (a `Node::Pos`).
 * `to_s`: return the code for the tree (a `String`).
 * `inspect`: return a pretty string for inspection, makes irb fun.
 * `match?(str)`, `=~(str)`: return true iff str parses as a `Node`
   equal to this one.
 * `detach`: remove this node from the tree (parent becomes nil) and
   return it.
 * `detached?`, `attached?`: return true if parent is nil or non-nil
   respectively.
 * `replace_with(node)`: replace this node with node in the tree.
 * `swap_with(node)`: exchange this node with node in their trees.
 * `insert_prev(*nodes)`, `insert_next(*nodes)`: insert nodes before
   this node in the parent list. Parent must be a `NodeList`! Useful
   for adding statements before a node in a block, for example.
 * `Foo?`: (where `Foo` is a module name) return `self.is_a?(Foo)`.
   This is a convienience for a common need. Example:

   <pre>
   \# print all global variables
   ast.entities.each do |node|
     node.Declaration? or next
     node.declarators.each do |decl|
       unless decl.type.Function?
         puts "#{decl.name}: #{decl.type}"
       end
     end
   end
   </pre>

The `=~` method lets you do:

    if declarator.type =~ 'const int *'
      puts "Ooh, a const int pointer!"
    end

This is not the same as `declarator.type.to_s == 'const int *'`;
that'd require you to guess how `to_s` formats its strings (most
notably, the whitespace).

### Fields and Children

The big table down below lists the *fields* of each `Node`. A field is
an attribute which:

 * is used in equality checks (`==` and `eql?`).
 * are copied recursively by `dup` and `clone`.

Fields listed as *children* form the tree structure. They only have a
`Node` or `nil` value, and are yielded/returned/affected by the
traversal methods:

 * `next`, `prev`: return the next/prev sibling.
 * `list_next`, `list_prev`: like `next`/`prev`, but also requires the
   parent to be `NodeList`. I'll be honest; I don't remember why I
   added these methods. They may well suddenly disappear.
 * `each`, `reverse_each`: Yield all (non-nil) children. `Node`
   includes `Enumerable`, so, you know.
 * `depth_first`, `reverse_depth_first`: Walk the tree in that order,
   yielding two args (event, node) at each node. event is `:down` on
   the way down, `:up` on the way up. If the block throws `:prune`, it
   won't descend any further.
 * `preorder`, `reverse_preorder`, `postorder`, `reverse_postorder`:
   Walk the tree depth first, yielding nodes in the given order. For
   the preorders, if the block throws `:prune`, it won't descend any
   further.
 * `node_after(child)`, `node_before(child)`: return the node
   before/after child (same as `child.next`).
 * `remove_node(child)`: remove child from this node (same as
   `child.detach`).
 * `replace_node(child, new_child)`: replace child with yeah you
   guessed it (same as `child.replace_with(newchild)`).

Note: don't modify the tree during traversal!

Other notes about the table:

 * Field names that end in '?' are always true-or-false.
 * If no default is listed:
   * it is false if the field name ends in a '?'
   * it is a `NodeArray` if it is a `NodeList`.
   * it is `nil` otherwise.

<table class="node_desc" cellspacing="0">
  <style>
    table.node_desc tr.first_field td {
      border-top: 1px solid black;
    }

    table.node_desc tr.first_field table td {
      border: none;
    }
    
    table.node_desc td {
      padding: 3px;
      vertical-align: top;
    {

    table.node_desc table td {
      padding: 0px;
    {
  </style>

  <tr>
    <th align="center">Class</th>
    <th align="center">Field</th>
    <th align="center">Type / values</th>
    <th align="center">Default</th>
    <th align="center">Comments</th>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="1"><tt>TranslationUnit</tt></td>
    <td class="nd_field"><tt>entities *</tt></td>
    <td class="nd_values"><tt>NodeList</tt></td>
    <td class="nd_default"><tt>NodeChain[]</tt></td>
    <td class="nd_comments" rowspan="1">
      The root of a parsed file.
    </td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="4"><tt>Declaration</tt></td>
    <td class="nd_field"><tt>storage</tt></td>
    <td class="nd_values"><tt>:typedef</tt>, <tt>:extern</tt>, <tt>:static</tt>, <tt>:auto</tt>, <tt>:register</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="4">
      Also:
      <ul>
        <li><tt>#typedef? </tt> -- true iff <tt>storage == :typedef </tt></li>
        <li><tt>#extern?  </tt> -- true iff <tt>storage == :extern  </tt></li>
        <li><tt>#static?  </tt> -- true iff <tt>storage == :static  </tt></li>
        <li><tt>#auto?    </tt> -- true iff <tt>storage == :auto    </tt></li>
        <li><tt>#register?</tt> -- true iff <tt>storage == :register</tt></li>
      </ul>
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>type *</tt></td>
    <td class="nd_values"><tt>DirectType</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>declarators *</tt></td>
    <td class="nd_values"><tt>NodeList</tt></td>
    <td class="nd_default"><tt>NodeArray[]</tt></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>inline?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="4"><tt>Declarator</tt></td>
    <td class="nd_field"><tt>indirect_type *</tt></td>
    <td class="nd_values"><tt>IndirectType</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="4">
      What's a "declarator?" Consider "<tt>int i, *ip;</tt>".  This is
      a <tt>Declaration</tt> with two <tt>Declarator</tt>s:
      <pre>
    Declaration
        type: Int
        declarators: 
            - Declarator
                name: "i"
            - Declarator
                indirect_type: Pointer
                name: "ip"
      </pre>
      The <tt>indirect_type</tt> of the <tt>ip</tt>
      <tt>Declarator</tt> is a <tt>Pointer</tt> to <tt>nil</tt>.
      To get the complete type of the variable use:
      <ul>
        <li>
          <tt>#type</tt> -- return the complete type. This is a clone;
          modifying it won't modify the tree.
        </li>
      </ul>
      So calling <tt>#type</tt> on the <tt>ip</tt> <tt>Declarator</tt>
      gives:
      <pre>
    Pointer
      type: Int
      </pre>
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>name</tt></td>
    <td class="nd_values"><tt>String</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>init *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>num_bits *</tt></td>
    <td class="nd_values"><tt>Integer</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="6"><tt>FunctionDef</tt></td>
    <td class="nd_field"><tt>storage</tt></td>
    <td class="nd_values"><tt>:extern</tt>, <tt>:static</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="6">
      Also:
      <ul>
        <li><tt>#extern?</tt> -- return true iff <tt>storage == :extern</tt></li>
        <li><tt>#static?</tt> -- return true iff <tt>storage == :static</tt></li>
        <li><tt>#prototype?</tt> -- same as !no_prototype?</li>
        <li><tt>#prototype=(val)</tt> -- same as no_prototype = !val</li>
      </ul>
      <tt>no_prototype?</tt> means that no prototype was given.  That means parameter types weren't given in the parens, but in the "old-style" declaration list.  Example:
      <table>
        <tr><td style="padding: 0px 25px">
          <pre>
int main(argc, argv)
    int argc;
    char **argv;
{
    return 0;
}</pre>
        </td><td style="padding: 0px 25px">
          <pre>
int main(int argc, char **argv) {
    return 0;
}</pre>
        </td></tr>
        <tr>
          <th>No prototype</th>
          <th>Prototype</th>
        </tr>
      </table>
      Everyone tells you to use prototypes.  That's because no type
      checking is done when calling a function declared without a
      prototype.
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>inline?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>type *</tt></td>
    <td class="nd_values"><tt>Type</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>name</tt></td>
    <td class="nd_values"><tt>String</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>def *</tt></td>
    <td class="nd_values"><tt>Block</tt></td>
    <td class="nd_default"><tt>Block.new</tt></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>no_prototype?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="3"><tt>Parameter</tt></td>
    <td class="nd_field"><tt>register?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="3">
      Used in <tt>Function</tt>s.
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>type *</tt></td>
    <td class="nd_values"><tt>Type</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>name</tt></td>
    <td class="nd_values"><tt>String</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>Enumerator</tt></td>
    <td class="nd_field"><tt>name</tt></td>
    <td class="nd_values"><tt>String</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
      Used in <tt>Enum</tt>s.
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>val *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>MemberInit</tt></td>
    <td class="nd_field"><tt>member *</tt></td>
    <td class="nd_values"><tt>NodeList</tt> of (<tt>Member</tt> or <tt>Expression</tt>)</td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
      Used in <tt>CompoundLiteral</tt>s.
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>init *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="1"><tt>Member</tt></td>
    <td class="nd_field"><tt>name</tt></td>
    <td class="nd_values"><tt>String</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="1">
      Used in <tt>MemberInit</tt>s.
    </td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>Block</tt></td>
    <td class="nd_field"><tt>labels *</tt></td>
    <td class="nd_values"><tt>NodeList</tt> of <tt>Label</tt></td>
    <td class="nd_default"><tt>NodeArray[]</tt></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>stmts *</tt></td>
    <td class="nd_values"><tt>NodeList</tt> of (<tt>Statement</tt> or <tt>Declaration</tt> or <tt>Comment</tt>)</td>
    <td class="nd_default"><tt>NodeArray[]</tt></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="4"><tt>If</tt></td>
    <td class="nd_field"><tt>labels *</tt></td>
    <td class="nd_values"><tt>NodeList</tt> of <tt>Label</tt></td>
    <td class="nd_default"><tt>NodeArray[]</tt></td>
    <td class="nd_comments" rowspan="4">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>cond *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>then *</tt></td>
    <td class="nd_values"><tt>Statement</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>else *</tt></td>
    <td class="nd_values"><tt>Statement</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="3"><tt>Switch</tt></td>
    <td class="nd_field"><tt>labels *</tt></td>
    <td class="nd_values"><tt>NodeList</tt> of <tt>Label</tt></td>
    <td class="nd_default"><tt>NodeArray[]</tt></td>
    <td class="nd_comments" rowspan="3">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>cond *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>stmt *</tt></td>
    <td class="nd_values"><tt>Statement</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="4"><tt>While</tt></td>
    <td class="nd_field"><tt>labels *</tt></td>
    <td class="nd_values"><tt>NodeList</tt> of <tt>Label</tt></td>
    <td class="nd_default"><tt>NodeArray[]</tt></td>
    <td class="nd_comments" rowspan="4">
      <tt>do?</tt> means it's a do-while loop.
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>do?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>cond *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>stmt *</tt></td>
    <td class="nd_values"><tt>Statement</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="5"><tt>For</tt></td>
    <td class="nd_field"><tt>labels *</tt></td>
    <td class="nd_values"><tt>NodeList</tt> of <tt>Label</tt></td>
    <td class="nd_default"><tt>NodeArray[]</tt></td>
    <td class="nd_comments" rowspan="5">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>init *</tt></td>
    <td class="nd_values"><tt>Expression</tt> or <tt>Declaration</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>cond *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>iter *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>stmt *</tt></td>
    <td class="nd_values"><tt>Statement</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>Goto</tt></td>
    <td class="nd_field"><tt>labels *</tt></td>
    <td class="nd_values"><tt>NodeList</tt> of <tt>Label</tt></td>
    <td class="nd_default"><tt>NodeArray[]</tt></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>target</tt></td>
    <td class="nd_values"><tt>String</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="1"><tt>Continue</tt></td>
    <td class="nd_field"><tt>labels *</tt></td>
    <td class="nd_values"><tt>NodeList</tt> of <tt>Label</tt></td>
    <td class="nd_default"><tt>NodeArray[]</tt></td>
    <td class="nd_comments" rowspan="1">
    </td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="1"><tt>Break</tt></td>
    <td class="nd_field"><tt>labels *</tt></td>
    <td class="nd_values"><tt>NodeList</tt> of <tt>Label</tt></td>
    <td class="nd_default"><tt>NodeArray[]</tt></td>
    <td class="nd_comments" rowspan="1">
    </td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>Return</tt></td>
    <td class="nd_field"><tt>labels *</tt></td>
    <td class="nd_values"><tt>NodeList</tt> of <tt>Label</tt></td>
    <td class="nd_default"><tt>NodeArray[]</tt></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>expr *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>ExpressionStatement</tt></td>
    <td class="nd_field"><tt>labels *</tt></td>
    <td class="nd_values"><tt>NodeList</tt> of <tt>Label</tt></td>
    <td class="nd_default"><tt>NodeArray[]</tt></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>expr *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="1"><tt>PlainLabel</tt></td>
    <td class="nd_field"><tt>name</tt></td>
    <td class="nd_values"><tt>String</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="1">
    </td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="1"><tt>Default</tt></td>
    <td class="nd_field"></td>
    <td class="nd_values"></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="1">
    </td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="1"><tt>Case</tt></td>
    <td class="nd_field"><tt>expr *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="1">
    </td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="1"><tt>Comma</tt></td>
    <td class="nd_field"><tt>exprs *</tt></td>
    <td class="nd_values"><tt>NodeList</tt> of <tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="1">
    </td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="3"><tt>Conditional</tt></td>
    <td class="nd_field"><tt>cond *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="3">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>then *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>else *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="1"><tt>Variable</tt></td>
    <td class="nd_field"><tt>name</tt></td>
    <td class="nd_values"><tt>String</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="1">
    </td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>Index</tt></td>
    <td class="nd_field"><tt>expr *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>index *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>Call</tt></td>
    <td class="nd_field"><tt>expr *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>args *</tt></td>
    <td class="nd_values"><tt>NodeList</tt> of (<tt>Expression</tt> or <tt>Type</tt>)</td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>Dot</tt></td>
    <td class="nd_field"><tt>expr *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>member *</tt></td>
    <td class="nd_values"><tt>String</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>Arrow</tt></td>
    <td class="nd_field"><tt>expr *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>member *</tt></td>
    <td class="nd_values"><tt>String</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="1"><tt>PostInc</tt></td>
    <td class="nd_field"><tt>expr *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="1">
    </td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="1"><tt>PostDec</tt></td>
    <td class="nd_field"><tt>expr *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="1">
    </td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>Cast</tt></td>
    <td class="nd_field"><tt>type *</tt></td>
    <td class="nd_values"><tt>Type</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>expr *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="1"><tt>Address</tt></td>
    <td class="nd_field"><tt>expr *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="1">
    </td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="1"><tt>Dereference</tt></td>
    <td class="nd_field"><tt>expr *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="1">
    </td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="1"><tt>Sizeof</tt></td>
    <td class="nd_field"><tt>expr *</tt></td>
    <td class="nd_values"><tt>Type</tt> or <tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="1">
    </td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="1"><tt>Positive</tt></td>
    <td class="nd_field"><tt>expr *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="1">
    </td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="1"><tt>Negative</tt></td>
    <td class="nd_field"><tt>expr *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="1">
    </td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="1"><tt>PreInc</tt></td>
    <td class="nd_field"><tt>expr *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="1">
    </td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="1"><tt>PreDec</tt></td>
    <td class="nd_field"><tt>expr *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="1">
    </td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="1"><tt>BitNot</tt></td>
    <td class="nd_field"><tt>expr *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="1">
    </td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="1"><tt>Not</tt></td>
    <td class="nd_field"><tt>expr *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="1">
    </td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>Add</tt></td>
    <td class="nd_field"><tt>expr1 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>expr2 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>Subtract</tt></td>
    <td class="nd_field"><tt>expr1 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>expr2 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>Multiply</tt></td>
    <td class="nd_field"><tt>expr1 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>expr2 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>Divide</tt></td>
    <td class="nd_field"><tt>expr1 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>expr2 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>Mod</tt></td>
    <td class="nd_field"><tt>expr1 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>expr2 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>Equal</tt></td>
    <td class="nd_field"><tt>expr1 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>expr2 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>NotEqual</tt></td>
    <td class="nd_field"><tt>expr1 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>expr2 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>Less</tt></td>
    <td class="nd_field"><tt>expr1 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>expr2 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>More</tt></td>
    <td class="nd_field"><tt>expr1 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>expr2 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>LessOrEqual</tt></td>
    <td class="nd_field"><tt>expr1 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>expr2 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>MoreOrEqual</tt></td>
    <td class="nd_field"><tt>expr1 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>expr2 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>BitAnd</tt></td>
    <td class="nd_field"><tt>expr1 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>expr2 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>BitOr</tt></td>
    <td class="nd_field"><tt>expr1 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>expr2 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>BitXor</tt></td>
    <td class="nd_field"><tt>expr1 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>expr2 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>ShiftLeft</tt></td>
    <td class="nd_field"><tt>expr1 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>expr2 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>ShiftRight</tt></td>
    <td class="nd_field"><tt>expr1 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>expr2 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>And</tt></td>
    <td class="nd_field"><tt>expr1 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>expr2 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>Or</tt></td>
    <td class="nd_field"><tt>expr1 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>expr2 *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>Assign</tt></td>
    <td class="nd_field"><tt>lval *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>rval *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>MultiplyAssign</tt></td>
    <td class="nd_field"><tt>lval *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>rval *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>DivideAssign</tt></td>
    <td class="nd_field"><tt>lval *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>rval *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>ModAssign</tt></td>
    <td class="nd_field"><tt>lval *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>rval *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>AddAssign</tt></td>
    <td class="nd_field"><tt>lval *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>rval *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>SubtractAssign</tt></td>
    <td class="nd_field"><tt>lval *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>rval *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>ShiftLeftAssign</tt></td>
    <td class="nd_field"><tt>lval *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>rval *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>ShiftRightAssign</tt></td>
    <td class="nd_field"><tt>lval *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>rval *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>BitAndAssign</tt></td>
    <td class="nd_field"><tt>lval *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>rval *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>BitXorAssign</tt></td>
    <td class="nd_field"><tt>lval *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>rval *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>BitOrAssign</tt></td>
    <td class="nd_field"><tt>lval *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>rval *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="1"><tt>StringLiteral</tt></td>
    <td class="nd_field"><tt>val</tt></td>
    <td class="nd_values"><tt>String</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="1">
      The <tt>String</tt> in <tt>val</tt> is the literal string entered.  <tt>"\n"</tt>
      isn't converted to a newline, for instance.
    </td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="1"><tt>CharLiteral</tt></td>
    <td class="nd_field"><tt>val</tt></td>
    <td class="nd_values"><tt>String</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="1">
      The <tt>String</tt> in <tt>val</tt> is the literal string entered.  <tt>'\n'</tt>
      isn't converted to a newline, for instance.
    </td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>CompoundLiteral</tt></td>
    <td class="nd_field"><tt>type *</tt></td>
    <td class="nd_values"><tt>Type</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
      <p>Here's an example:</p>
      <pre>(struct S){1, .x = 2, .y [3] .z = 4}</pre>
      <p>parses as:</p>
      <pre>CompoundLiteral
    type: Struct
        name: "S"
    member_inits: 
        - MemberInit
            init: IntLiteral
                val: 1
        - MemberInit
            member: 
                - Member
                    name: "x"
            init: IntLiteral
                val: 2
        - MemberInit
            member: 
                - Member
                    name: "y"
                - IntLiteral
                    val: 3
                - Member
                    name: "z"
            init: IntLiteral
                val: 4</pre>
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>member_inits *</tt></td>
    <td class="nd_values"><tt>NodeList</tt> of <tt>MemberInit</tt></td>
    <td class="nd_default"><tt>NodeArray[]</tt></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="2"><tt>IntLiteral</tt></td>
    <td class="nd_field"><tt>val</tt></td>
    <td class="nd_values"><tt>Integer</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="2">
      <p>Also:</p>
      <ul>
        <li><tt>#dec?</tt> -- return true iff <tt>format == :dec</tt></li>
        <li><tt>#hex?</tt> -- return true iff <tt>format == :hex</tt></li>
        <li><tt>#oct?</tt> -- return true iff <tt>format == :oct</tt></li>
      </ul>
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>format</tt></td>
    <td class="nd_values"><tt>:dec</tt>, <tt>:hex</tt>, <tt>:oct</tt></td>
    <td class="nd_default"><tt>:dec</tt></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="1"><tt>FloatLiteral</tt></td>
    <td class="nd_field"><tt>val</tt></td>
    <td class="nd_values"><tt>Float</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="1">
    </td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="4"><tt>Pointer</tt></td>
    <td class="nd_field"><tt>const?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="4">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>restrict?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>volatile?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>type *</tt></td>
    <td class="nd_values"><tt>Type</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="5"><tt>Array</tt></td>
    <td class="nd_field"><tt>const?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="5">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>restrict?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>volatile?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>type *</tt></td>
    <td class="nd_values"><tt>Type</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>length *</tt></td>
    <td class="nd_values"><tt>Expression</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="6"><tt>Function</tt></td>
    <td class="nd_field"><tt>const?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="6">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>restrict?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>volatile?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>type *</tt></td>
    <td class="nd_values"><tt>Type</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>params *</tt></td>
    <td class="nd_values"><tt>NodeList</tt> of <tt>Parameter</tt></td>
    <td class="nd_default"><tt>NodeArray[]</tt></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>var_args?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="5"><tt>Struct</tt></td>
    <td class="nd_field"><tt>const?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="5">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>restrict?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>volatile?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>name</tt></td>
    <td class="nd_values"><tt>String</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>members *</tt></td>
    <td class="nd_values"><tt>NodeList</tt> of <tt>Member</tt></td>
    <td class="nd_default"><tt>NodeArray[]</tt></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="5"><tt>Union</tt></td>
    <td class="nd_field"><tt>const?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="5">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>restrict?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>volatile?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>name</tt></td>
    <td class="nd_values"><tt>String</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>members *</tt></td>
    <td class="nd_values"><tt>NodeList</tt> of <tt>Member</tt></td>
    <td class="nd_default"><tt>NodeArray[]</tt></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="5"><tt>Enum</tt></td>
    <td class="nd_field"><tt>const?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="5">
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>restrict?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>volatile?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>name</tt></td>
    <td class="nd_values"><tt>String</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>members *</tt></td>
    <td class="nd_values"><tt>NodeList</tt> of <tt>Enumerator</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="4"><tt>CustomType</tt></td>
    <td class="nd_field"><tt>const?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="4">
      For <tt>typedef</tt>'d names.
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>restrict?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>volatile?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>name</tt></td>
    <td class="nd_values"><tt>String</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="3"><tt>Void</tt></td>
    <td class="nd_field"><tt>const?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="3">
      <tt>const</tt> is for things like <tt>const void *</tt>.
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>restrict?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>volatile?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="5"><tt>Int</tt></td>
    <td class="nd_field"><tt>const?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="5">
      Also:
      <ul>
        <li><tt>#short?</tt> -- return true iff <tt>longness == -1</tt></li>
        <li><tt>#plain?</tt> -- return true iff <tt>longness == 0</tt></li>
        <li><tt>#long?</tt> -- return true iff <tt>longness == 1</tt></li>
        <li><tt>#long_long?</tt> -- return true iff <tt>longness == 2</tt></li>
        <li><tt>#signed?</tt> -- same as <tt>!unsigned?</tt></li>
        <li><tt>#signed=(val)</tt> -- same as <tt>unsigned = !val</tt></li>
      </ul>
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>restrict?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>volatile?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>longness</tt></td>
    <td class="nd_values"><tt>-1</tt>, <tt>0</tt>, <tt>1</tt>, <tt>2</tt></td>
    <td class="nd_default"><tt>0</tt></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>unsigned?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="4"><tt>Float</tt></td>
    <td class="nd_field"><tt>const?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="4">
      Also:
      <ul>
        <li><tt>#plain?</tt> -- return true iff <tt>longness == 0</tt></li>
        <li><tt>#double?</tt> -- return true iff <tt>longness == 1</tt></li>
        <li><tt>#long_double?</tt> -- return true iff <tt>longness == 2</tt></li>
      </ul>
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>restrict?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>volatile?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>longness</tt></td>
    <td class="nd_values"><tt>0</tt>, <tt>1</tt>, <tt>2</tt></td>
    <td class="nd_default"><tt>0</tt></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="4"><tt>Char</tt></td>
    <td class="nd_field"><tt>const?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="4">
      Also:
      <ul>
        <li><tt>#signed?</tt> -- return true iff <tt>signed == true</tt></li>
        <li><tt>#unsigned?</tt> -- return true iff <tt>signed == false</tt></li>
        <li><tt>#plain?</tt> -- return true iff <tt>signed == nil</tt></li>
      </ul>
      Yes, C99 says that <tt>char</tt>, <tt>signed char</tt>, and
      <tt>unsigned char</tt> are 3 distinct types (unlike with
      <tt>int</tt> -- go figure).  Like Martian chalk and Venusian
      cheese: completely different, but you can fit 'em each in one
      byte.
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>restrict?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>volatile?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>signed</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt>, <tt>nil</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="3"><tt>Bool</tt></td>
    <td class="nd_field"><tt>const?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="3">
      This is the rarely seen <tt>_Bool</tt> type.
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>restrict?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>volatile?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="4"><tt>Complex</tt></td>
    <td class="nd_field"><tt>const?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="4">
      <p>This is the rarely seen <tt>_Complex</tt> type.</p>
      <ul>
        <li><tt>#plain?</tt> -- return true iff <tt>longness == 0</tt></li>
        <li><tt>#double?</tt> -- return true iff <tt>longness == 1</tt></li>
        <li><tt>#long_double?</tt> -- return true iff <tt>longness == 2</tt></li>
      </ul>
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>restrict?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>volatile?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>longness</tt></td>
    <td class="nd_values"><tt>0</tt>, <tt>1</tt>, <tt>2</tt></td>
    <td class="nd_default"><tt>0</tt></td>
  </tr>

  <tr class="first_field">
    <td class="nd_class" rowspan="4"><tt>Imaginary</tt></td>
    <td class="nd_field"><tt>const?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
    <td class="nd_comments" rowspan="4">
      <p>This is the rarely seen <tt>_Imaginary</tt> type.</p>
      <ul>
        <li><tt>#plain?</tt> -- return true iff <tt>longness == 0</tt></li>
        <li><tt>#double?</tt> -- return true iff <tt>longness == 1</tt></li>
        <li><tt>#long_double?</tt> -- return true iff <tt>longness == 2</tt></li>
      </ul>
    </td>
  </tr>
  <tr>
    <td class="nd_field"><tt>restrict?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>volatile?</tt></td>
    <td class="nd_values"><tt>true</tt>, <tt>false</tt></td>
    <td class="nd_default"></td>
  </tr>
  <tr>
    <td class="nd_field"><tt>longness</tt></td>
    <td class="nd_values"><tt>0</tt>, <tt>1</tt>, <tt>2</tt></td>
    <td class="nd_default"><tt>0</tt></td>
  </tr>
  <tr class="first_field">
    <td class="nd_class" rowspan="1"><tt>BlockExpression</tt></td>
    <td class="nd_field"><tt>block *</tt></td>
    <td class="nd_values"><tt>Block</tt></td>
    <td class="nd_default"><tt>Block.new</tt></td>
    <td class="nd_comments" rowspan="1">
      Only if the <tt>block_expressions</tt> extension is enabled.
      See "Extensions" section below.
    </td>
  </tr>
</tbody></table>

## Parser

`C.parse` will use the default parser (`C.default_parser`), but you
can also manage your own parser(s) if you need finer control over
state. Parser state consists of:

 * `type_names`: a Set of Strings. As a parser eats `typedef`s, this
   grows.
 * `pos`: the `Node::Pos` this parser will start parsing at.

A `Node::Pos` has three read-write attributes: `filename`, `line_num`,
`col_num`. Default is nil, 1, 0.

Note that the type names the parser has seen affects the parser! For
example, consider:

    a * b;

 * If only `a` is a type, this is a declaration.
 * If neither `a` nor `b` are types, this is a multiplication
   statement.
 * Otherwise, it's a syntax error.

You may append type names implicitly, by parsing `typedef`s, or
explicitly like this:

    parser.type_names << 'Thing' << 'OtherThing'

### Parsing Snippets

`C.parse` will parse the toplevel C construct, a `C::TranslationUnit`,
but you can also parse other snippets of C:

    C::Statement.parse('while (not_looking) { paint_car(); }')
    C::Type.parse('void *(*)(int *(*)[][2], ...)')

This works for both concrete and abstract `Node` subclasses. A
`Parser` may be given as an optional second argument.

### Extensions to C99

 * `Type`s are allowed as function arguments. This is needed to parse
   C99 macros like `va_arg()`.
 * `Block`s in parentheses are allowed as expressions ([a gcc
   extension][gcc-block-expressions]). You need to call
   `parser.enable_block_expressions` first. They appear as
   `BlockExpression` nodes.

[gcc-block-expressions]: http://gcc.gnu.org/onlinedocs/gcc-4.2.1/gcc/Statement-Exprs.html#Statement-Exprs

## Parsing Full Programs

This can be tricky for a number of reasons. Here are the issues you'll
likely encounter.

### Preprocessing

Directives that start with `#` are not handled by the `Parser`, as
they're external to the C grammar. CAST ships with a `Preprocessor`,
which wraps the preprocessor used to build your Ruby interpreter.

    cpp = C::Preprocessor.new
    cpp.include_path << '/usr/include' << /usr/local/include'
    cpp.macros['DEBUG'] = '1'
    cpp.macros['max(a, b)'] = '((a) > (b) ? (a) : (b))'
    cpp.preprocess(code)

Note however, that preprocessors tend to leave vendor-specific
extensions in their output. GNU `cpp`, for example, leaves
"linemarkers" (lines that begin with `#`) in the output which you'll
need to filter out manually before feeding it to a `Parser`.

### Built-in types

Mac OS 10.5's system `cpp` for instance assumes the compiler will
recognize types such as `__darwin_va_list`.

### Syntactic Extensions

Some code may take advantage of compiler-specific extensions to the
syntax. For example, `gcc` supports inline assembly via directives
like:

    asm("movl %1, %%eax;
        "movl %%eax, %0;"
        :"=r"(y)
        :"r"(x)
        :"%eax");

Such code is fairly rare, so there is no direct support in CAST for
this. You'll need to manually massage such constructs out of the
`Parser` input. Or send me patches. Delicious patches.

## Contributing

 * [Bug reports](http://github.com/oggy/cast/issues)
 * [Source](http://github.com/oggy/cast)
 * Patches: Fork on Github, send pull request.
   * Include tests where practical.
   * Leave the version alone, or bump it in a separate commit.

## Copyright

Copyright (c) George Ogata. See LICENSE for details.
