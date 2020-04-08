# :nodoc:
struct Nil
  def to_jsc
    JSC.new_null JSCPrimative.global_context
  end
end

# :nodoc:
class String
  def to_jsc
    JSC.new_string JSCPrimative.global_context, self
  end
end

# :nodoc:
struct Bool
  def to_jsc
    JSC.new_bool JSCPrimative.global_context, self
  end
end

# :nodoc:
struct Float32
  def to_jsc
    JSC.new_number JSCPrimative.global_context, self.to_f64
  end
end

# :nodoc:
struct Float64
  def to_jsc
    JSC.new_number JSCPrimative.global_context, self
  end
end

# :nodoc:
struct StaticArray(T, N)
  def to_jsc
    new_s_array = self.map &.to_jsc
    g_pointer = JSC::JSCValues.new
    g_pointer.values = new_s_array.to_unsafe
    g_pointer.len = new_s_array.size
    JSC.new_array JSCPrimative.global_context, pointerof(g_pointer)
  end
end

# :nodoc:
struct Pointer(T)
  def to_jsc
    self
  end
end

{% for bits in {8, 16, 32, 64} %}
    {% for prefix in {:UInt, :Int} %}
        # :nodoc:
        struct {{prefix.id}}{{bits}}
            def to_jsc 
                JSC.new_number JSCPrimative.global_context, self.to_f64
            end 
        end
    {% end %}
{% end %}

# :nodoc:
struct NamedTuple
  def to_jsc
    ret = JSCObject.new
    self.each do |k, v|
      value = v.to_jsc
      ret[k.to_s] = value
    end
    ret.to_jsc
  end
end
