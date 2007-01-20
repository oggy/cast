######################################################################
#
# Node#inspect.
#
######################################################################

module C
  class Node
    INSPECT_TAB = '    '
    def inspect
      return Node.inspect1(self)
    end

    def Node.inspect1(x, prefix='', indent=0, is_child=true)
      case x
      when NodeList
        if x.empty?
          return "#{INSPECT_TAB*indent}#{prefix}[]\n"
        else
          str = "#{INSPECT_TAB*indent}#{prefix}\n"
          x.each do |el|
            str << inspect1(el, "- ", indent+1)
          end
          return str
        end
      when Node
        classname = x.class.name.gsub(/^C::/, '')
        str = "#{INSPECT_TAB*indent}#{prefix}#{classname}"

        fields = x.fields
        bools, others = fields.partition{|field| field.reader.to_s[-1] == ??}
        bools.delete_if{|field| !x.send(field.reader)}
        bools.map!{|field| field.init_key}

        unless bools == []
          str << " (#{bools.join(' ')})"
        end
        str << "\n"

        others.each do |field|
          val = x.send(field.reader)
          next if val == field.make_default ||
            # don't bother with non-child Nodes, since they may cause
            # loops in the tree
            (val.is_a?(Node) && !field.child?)
          str << inspect1(val, "#{field.reader}: ", indent+1, field.child?)
        end
        return str
      when Symbol
        return "#{INSPECT_TAB*indent}#{prefix}#{x}\n"
      else
        return "#{INSPECT_TAB*indent}#{prefix}#{x.inspect}\n"
      end
      return s.string
    end
  end
end
