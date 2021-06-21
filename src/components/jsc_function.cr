# JSCFunction represents a JavaScript's native function(a function that run native code instead of javascript).
class JSCFunction
  FUNCTIONS = [] of JSCFunction

  include JSObjectUtils
  include Invokable
  @this : JSC::JSValue = JSC::JSValue.null
  @name : String? = nil
  @@global_context : LibWebKit2Extension::WebKitJSContext = Pointer(Void).null
  @box : Pointer(Void) = Pointer(Void).null

  alias CallBack = Array(JSCPrimative | JSCFunction | JSCObject) -> JSCFunction | JSCPrimative | JSCObject

  # #@@box_of_fun = Array(Void*).new

  # :nodoc:
  def self.global_context=(ctx : LibWebKit2Extension::WebKitJSContext)
    @@global_context = ctx
  end

  # Initializes a JavaScript native function.
  # For short, uses `WebExtension.function` macro instead.
  #
  # NOTE: **IMPORTANT**. Does not directly use parameter as return value. The following code won't work.
  # ```
  # WebExtension.function params do
  #   params.first # => Directly returns function parameter(s) is not recommended and may crash program
  # end
  # ```
  def initialize(func : Array(JSCPrimative | JSCFunction | JSCObject) -> _, name : String? = nil, auto_save : Bool = true)
    @box = Box.box(func)
    # @@box_of_fun << box
    @value = JSC.new_function JSCPrimative.global_context,
      name,
      ->(p : JSC::JSCValues*, box : Void*) {
        proc = Box(typeof(func)).unbox box
        proc.call(JSCFunction.parse_args(p.value)).to_jsc
      }, @box, nil, JSC.jsc_value_get_type
    JSCFunction::FUNCTIONS.push(self) if auto_save
  end

  # :nodoc:
  def initialize(@value : JSC::JSValue)
    unless JSC.is_function @value
      JSCFunction.raise "Expected a function handler"
    end
  end

  # :nodoc:
  def self.parse_args(args_struct : JSC::JSCValues)
    len = args_struct.len
    args_prt = args_struct.values
    ret = Array(JSCPrimative | JSCFunction | JSCObject).new
    len.times do |i|
      arg = (args_prt + i).value
      if JSC.is_function arg
        ret << JSCFunction.new(arg)
      elsif JSC.is_object arg
        ret << JSCObject.new(arg)
      else
        ret << JSCPrimative.new(arg)
      end
    end
    ret
  end

  # Calls the function.
  #
  # E.g:
  # ```
  # sum_function.call JSCPrimative.new(1), 2
  # ```
  # NOTE: Calling function this way won't make JS `this` operator usable. In case of
  # invoking object's method, uses `Invokable#invoke` instead.
  def call(*args)
    first_arg = Pointer(JSC::JSValue).malloc(args.size)
    args.size.times do |i|
      (first_arg + i).value = args[i].to_jsc
    end
    ret = JSC.invoke_function @value, args.size, first_arg
    return case JSC
    when .is_function(ret) then JSCFunction.new ret
    when .is_object(ret)   then JSCObject.new ret
    else                        JSCPrimative.new ret
    end
  end

  # :nodoc:
  def to_unsafe
    @value
  end

  # Raises a JavaScript Error with given `message`.
  def self.raise(message : String)
    JSC.throw_exception JSCPrimative.global_context, message
  end

  # :nodoc:
  def self.current_context
    JSC.current_js_context
  end

  def finalize
    puts "JSCFunction #{self.object_id} is garbage collected"
  end
end
