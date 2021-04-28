# JSCContext represents a JavaScript execution context
module JSCContext
  @@context : LibWebKit2Extension::WebKitJSContext = Pointer(Void).null

  # :nodoc:
  def self.global_context=(ctx : LibWebKit2Extension::WebKitJSContext)
    @@context = ctx
  end

  # :nodoc:
  def self.global_context
    @@context
  end

  # Set a property of the context's global object, in this case `window`
  #
  # ```
  # JSCContext.set_value "hello", JSCPrimative.new "world"
  # ```
  def self.set_value(name : String, value)
    JSC.context_set_value @@context, name, value.to_jsc
  end

  # Equivalent to JavaScript `window[name]`
  #
  # ```
  # json = JSCContext.get_value "JSON"
  # # Do somethings with JSON object, e.g: json["parse"].call(JSCPrimative.new "{a:2}")
  # ```
  def self.get_value(name : String)
    v = JSC.context_get_value @@context, name
    if JSC.is_function(v)
      JSCFunction.new v
    elsif JSC.is_object(v)
      JSCObject.new v
    else
      JSCPrimative.new v
    end
  end
end
