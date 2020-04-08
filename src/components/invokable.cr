# `Invokable` supports calling member function of a JavaScript's Object. In short, it make `this` usable.
# ```
# my_object["function"].as(JSCFunction).call(args...) # in this case, JavaScript `this` will be undefined.
# # uses Invokeable#invoke instead.
# my_object.invoke "function", arg1, arg2, ...
# ```
module Invokable
  def invoke(name : String, *args)
    first_arg = Pointer(JSC::JSValue).malloc(args.size)
    args.size.times do |i|
      first_arg[i] = args[i].to_jsc
    end
    ret = JSC.invoke_member_function @value, name, args.size, first_arg
    return case JSC
    when .is_object(ret)   then JSCObject.new ret
    when .is_function(ret) then JSCFunction.new ret
    else                        JSCPrimative.new ret
    end
  end
end
