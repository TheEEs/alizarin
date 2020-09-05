require "./libWebkit2Extension"

@[Link("webkit2gtk-4.0")]
lib JSC
  struct JSCValues
    values : Pointer(JSValue)
    len : LibC::UInt
  end

  @[Flags]
  enum JSCValuePropertyFlags
    CONFIGURABLE
    ENUMERABLE
    WRITABLE
  end

  RETURN_TYPE = jsc_value_get_type

  alias JSValue = Void*
  alias JSFunctionCallback = JSCValues*, Void* -> JSValue

  alias JSContext = LibWebKit2Extension::WebKitJSContext

  fun jsc_value_get_type : LibC::ULong
  fun current_js_context = jsc_context_get_current : JSContext
  fun get_window_from_context = jsc_context_get_global_object(context : JSContext) : JSValue
  fun get_context = jsc_value_get_context(js_value : JSValue) : JSContext
  fun new_undefined = jsc_value_new_undefined(js_context : JSContext) : JSValue
  fun is_undefined = jsc_value_is_undefined(js_value : JSValue) : Bool
  fun new_null = jsc_value_new_null(js_context : JSContext) : JSValue
  fun is_null = jsc_value_is_null(js_value : JSValue) : Bool
  fun new_number = jsc_value_new_number(js_context : JSContext, number : Float64) : JSValue
  fun is_number = jsc_value_is_number(js_value : JSValue) : Bool
  fun to_float64 = jsc_value_to_double(js_value : JSValue) : Float64
  fun to_int32 = jsc_value_to_int32(js_value : JSValue) : Int32
  fun new_bool = jsc_value_new_boolean(js_context : JSContext, is_true : Bool) : JSValue
  fun is_bool = jsc_value_is_boolean(js_value : JSValue) : Bool
  fun to_bool = jsc_value_to_boolean(js_value : JSValue) : Bool
  fun new_string = jsc_value_new_string(js_context : JSContext, string : LibC::Char*) : JSValue
  fun is_string = jsc_value_is_string(js_value : JSValue) : Bool
  fun to_string = jsc_value_to_string(js_value : JSValue) : LibC::Char*
  fun new_array = jsc_value_new_array_from_garray(js_context : JSContext, values : JSCValues*) : JSValue
  fun is_array = jsc_value_is_array(js_value : JSValue) : Bool
  fun new_object = jsc_value_new_object(context : JSContext, instance : Void*, jsc_class : Void*) : JSValue
  fun is_object = jsc_value_is_object(js_value : JSValue) : Bool
  fun is_instance_of = jsc_value_object_is_instance_of(js_value : JSValue, name : LibC::Char*) : Bool
  fun set_property = jsc_value_object_set_property(js_value : JSValue, name : LibC::Char*, property : JSValue)
  fun get_property = jsc_value_object_get_property(js_value : JSValue, name : LibC::Char*) : JSValue
  fun set_at_index = jsc_value_object_set_property_at_index(js_value : JSValue, index : UInt32, value : JSValue)
  fun get_at_index = jsc_value_object_get_property_at_index(js_value : JSValue, index : UInt32) : JSValue
  fun has_property = jsc_value_object_has_property(js_value : JSValue, name : LibC::Char*) : Bool
  fun delete_property = jsc_value_object_delete_property(js_value : JSValue, name : LibC::Char*) : Bool
  fun properties = jsc_value_object_enumerate_properties(js_value : JSValue) : LibC::Char**
  fun invoke_member_function = jsc_value_object_invoke_methodv(js_value : JSValue, method_name : LibC::Char*, n_params : UInt32, params : Pointer(JSValue)) : JSValue
  fun new_function = jsc_value_new_function_variadic(context : JSContext, name : LibC::Char*,
                                                     callback : JSFunctionCallback,
                                                     userdata : Void*, destroy_notify : Void*, return_type : LibC::ULong) : JSValue
  fun is_function = jsc_value_is_function(value : JSValue) : Bool
  fun invoke_function = jsc_value_function_callv(func : JSValue, n_params : UInt32, params : Pointer(JSValue)) : JSValue
  fun throw_exception = jsc_context_throw(context : JSContext, message : LibC::Char*)
  fun context_set_value = jsc_context_set_value(context : JSContext, name : LibC::Char*, value : JSValue)
  fun context_get_value = jsc_context_get_value(context : JSContext, name : LibC::Char*) : JSValue
  fun define_accessor = jsc_value_object_define_property_accessor(
    object : JSValue, property_name : LibC::Char*, flag : JSCValuePropertyFlags,
    property_type : LibC::ULong,
    getter : Void* -> JSValue,
    setter : Void* -> Void,
    userdata : Void*, destroy_notify : Void*
  )
  fun define_property = jsc_value_object_define_property_data(
    object : JSValue,
    property_name : LibC::Char*,
    flags : Int32, # JSCValuePropertyFlags,
    value : JSValue
  )
  fun eval_js = jsc_context_evaluate(context : JSContext, code : UInt8*, size : LibC::Long) : JSValue
  fun jsc_value_constructor_callv(constructor : JSValue, n_params : UInt32, params : JSValue*) : JSValue
end
