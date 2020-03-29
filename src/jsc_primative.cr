# A JSCPrimative is a wrapper of 6 JavaScript primative types, includes:
# 1. undefined
# 2. null
# 3. boolean
# 4. number
# 5. string
# 6. array
struct JSCPrimative
  include JSObjectUtils

  @@global_context : LibWebKit2Extension::WebKitJSContext = Pointer(Void).null
  @value : JSC::JSValue = Pointer(Void).null

  # :nodoc:
  def self.global_context=(ctx)
    @@global_context = ctx
  end

  # :nodoc:
  def self.global_context
    @@global_context
  end

  # Initializes a new JavaScript number from a Crystal's Int
  def initialize(value : Int)
    @value = JSC.new_number(@@global_context, value.to_f64)
  end

  # Initializes a new JavaScript number from a Crystal's Float64
  def initialize(value : Float64)
    @value = JSC.new_number(@@global_context, value)
  end

  # Initializes a new JavaScript string from a Crystal's String
  def initialize(value : String)
    @value = JSC.new_string @@global_context, value
  end

  # Initializes a new JavaScript null from a Crystal's Nil
  def initialize(value : Nil)
    @value = JSC.new_null @@global_context
  end

  # Initializes a new JavaScript boolean from a Crystal's Bool
  def initialize(value : Bool)
    @value = JSC.new_bool @@global_context, value
  end

  # :nodoc:
  def initialize(values : Pointer(JSC::JSValue))
    @value = JSC.new_array @@global_context, values
  end

  # Initializes a new JavaScript undefined
  def initialize
    @value = JSC.new_undefined @@global_context
  end

  # :nodoc:
  def initialize(@value : JSC::JSValue)
  end
end
