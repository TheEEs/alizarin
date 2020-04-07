require "./jsc_object/accessor"

# A JSCObject represent a JavaScript object
struct JSCObject
  @value : JSC::JSValue = Pointer(Void).null

  include JSObjectUtils
  include Invokable

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

  # Defines a JavaScript object's property, this is equal to JavaScript `Object.defineProperty`.
  # See `Accessor` for more.
  def mount_accessor(accessor : Accessor)
    globalObject = JSCContext.get_value "Object"
    defineProperty = globalObject["defineProperty"].as(JSCFunction)
    propertyObject = JSCObject.new

    propertyObject["get"] = WebExtension.function p do
      accessor.get.try &.call
    end if accessor.get

    propertyObject["set"] = WebExtension.function p do
      accessor.set.try &.call(p.first)
      nil
    end if accessor.set

    defineProperty.call(@value, accessor.name, propertyObject)
  end

  # Defines a JavaScript object's property, this is equal to JavaScript `Object.defineProperty`.
  def define_property(name, value, flags : Accessor::Accessibility)
    JSC.define_property(@value, name, flags, value.to_jsc)
  end
end
