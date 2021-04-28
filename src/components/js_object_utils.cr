# This module provides common operations that every JavaScript entity can do
module JSObjectUtils
  # Set property `name`
  def []=(name : String, value)
    JSC.set_property @value, name, value.to_jsc
  end

  # Set a value at index `index`
  def []=(index : UInt32, value)
    JSC.set_at_index @value, index, value.to_jsc
  end

  # Gets property `name`
  def [](name : String)
    v = JSC.get_property @value, name
    if JSC.is_function(v)
      JSCFunction.new v
    elsif JSC.is_object(v)
      JSCObject.new v
    else
      JSCPrimative.new v
    end
  end

  # Gets value at index `index`
  def [](index : UInt32)
    v = JSC.get_at_index @value, index
    if JSC.is_function(v)
      JSCFunction.new v
    elsif JSC.is_object(v)
      JSCObject.new v
    else
      JSCPrimative.new v
    end
  end

  # Deletes property *name* of the object
  def delete(name : String)
    JSC.delete_property(@value, name)
  end

  # Perform type checking
  def is_null?
    JSC.is_null @value
  end

  # :ditto:
  def is_undefined?
    JSC.is_undefined @value
  end

  # :ditto:
  def is_number?
    JSC.is_number @value
  end

  # :ditto:
  def is_array?
    JSC.is_array @value
  end

  # :ditto:
  def is_string?
    JSC.is_string @value
  end

  # :ditto:
  def is_bool?
    JSC.is_bool @value
  end

  # JavaScript's `instanceof` operator
  def is_instance_of?(class_name : String)
    JSC.is_instance_of(@value, class_name)
  end

  # Converts JavaScript value to Crystal's `Bool`
  def to_b
    JSC.to_bool @value
  end

  # Converts JavaScript value to Crystal's `String`
  def to_s
    String.new(JSC.to_string @value)
  end

  # Converts JavaScript value to Crystal's `Float64`
  def to_f64
    JSC.to_float64 @value
  end

  # Converts JavaScript value to Crystal's `Int32`
  def to_i32
    JSC.to_int32 @value
  end

  # :nodoc:
  def to_jsc
    @value
  end

  # :nodoc:
  def to_unsafe
    @value
  end
end
