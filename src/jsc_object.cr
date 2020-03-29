# A JSCObject represent a JavaScript object
struct JSCObject
  @value : JSC::JSValue = Pointer(Void).null

  include JSObjectUtils

  # :nodoc:
  macro global_context
    JSCPrimative.global_context
  end

  # Initializes a new JSCObject
  def initialize
    @value = JSC.new_object global_context, nil, nil
  end

  # :nodoc:
  def initialize(h : JSC::JSValue)
    @value = h
  end
end
