require "./web_extension/stdlib/jsc_class"
require "./web_extension/**"

# According to architecture of WebKit2GTK, JavaScript code runs in a separeted process called Render Process.
# That's why extending JavaScript can not be done in the same process which manages the `WebView`.
# Instead WebKit2GTK proposes a new way to extend JavaScript with native code called WebExtension.
# A WebExtension is a shared library which will be loaded at runtime by Render Process.
# This module provides some simple macros to reduce redundant works in making a webExtension.
# The following code shows an simple example which provides a JS function. It reads given file on filesystem.
# ```
# require "alizarin"
# include WebExtension
# initialize_extension do
#   # code inside this block will be executed when this Web Extension is loaded by Render Process
#   func = function params do
#     if params.size != 1
#       JSCFunction.raise "#{params.size} parameter(s) provided, expect 1"
#       undefined
#     else
#       path = params.first.to_s
#       File.read(path) rescue nil # Return content of file at *path*, otherwise return JS's null
#     end
#   end
#   JSCContext.set_value("read_file", func)
# end
# ```
# Builds shared library:
# ```bash
# $ crystal build -Dpreview_mt --single-module --link-flags="-shared -fpic" -o <output-path> <source-file>
# ```
# NOTE: The shared library should be placed in the directory provided with `WebView#extension_dir=`
#
# In main process (which manages an instance of `WebView`), opens WebInspector's console and types:
# ```javascript
# read_file("/a-file-located-some-where")
# ```
# See more:
# 1. `JSCContext`
# 2. `JSCFunction`
# 3. `JSCPrimative`
# 4. `JSCObject`
# 5. `JSObjectUtils`
module WebExtension
  @@uuid = ""

  # :nodoc:
  protected def self.set_uuid(uuid)
    @@uuid = uuid
  end

  # Gets UUID hex string of the `WebView` which loads this extension
  def self.uuid
    @@uuid
  end

  # Entry point of a Web Extension shared library
  macro initialize_extension
    fun webkit_web_extension_initialize_with_user_data(%ext : LibWebKit2Extension::WebKitWebExtension, user_data : Void*)
      GC.init
      %arg = "TheEEs<visualbasic2013@hotmail.com>"
      %args = StaticArray(UInt8*, 1).new(%arg.to_unsafe)
      LibCrystalMain.__crystal_main(1, %args.to_unsafe)
      puts "Webkit Extension initialized".colorize(:green)
      %uuid_ptr = LibWebKit2Extension.g_variant_get_string(user_data, nil)
      WebExtension.set_uuid String.new(%uuid_ptr)
      LibWebKit.connect_signal %ext, "page-created", (->(%ext : Void*, %page : Void*, %data : Void*) {
        puts "WebkitWebPage is loaded".colorize(:green)  
        %script_world = LibWebKit2Extension.get_default_script_world
        %main_frame = LibWebKit2Extension.get_main_frame(%page)
        LibWebKit.connect_signal %script_world, "window-object-cleared", (->(%w : LibWebKit2Extension::WebKitScriptWorld, %p : LibWebKit2Extension::WebKitWebPage, %f : LibWebKit2Extension::WebKitWebFrame) {
          puts "window object is ready".colorize(:green)
          %context = LibWebKit2Extension.get_global_js_context %f, LibWebKit2Extension.get_default_script_world
          ::JSCPrimative.global_context = %context
          ::JSCFunction.global_context = %context 
          ::JSCContext.global_context = %context
          {% for cls in JSCClass.resolve.includers %}
            ::JSCContext.set_value {{cls}}.name, {{cls}}.constructor
          {% end %}
          {{ yield }}
          nil
        }), nil, nil, LibWebKit::GtkGConnectFlags::All
      }), nil, nil, LibWebKit::GtkGConnectFlags::All
    end
  end

  # This macro initializes an anonymous JavaScript function.
  #
  # ```
  # func = function p do
  #   puts typeof(p) # => Array(JSCFunction|JSCObject|JSCPrimative)
  #   # Developers can return anything as long as it has method to_jsc() : JSC::JSValue
  #   if p.size != 0
  #     JSCPrimative.new true
  #   else
  #     false
  #   else
  #   # return type is (JSCPrimative|Bool), it's ok because both JSCPrimative and Bool have method to_jsc()
  # end
  # ```
  macro function(arg_name)
    JSCFunction.new ->({{arg_name}} : Array(JSCPrimative | JSCFunction | JSCObject)) { 
      {{ yield }}
    }
  end

  # JavaScript `undefined`
  macro undefined
    JSCPrimative.new 
  end

  # :nodoc:
  def self.js_new(constructor, *args)
    params = Pointer(JSC::JSValue).malloc(args.size)
    args.size.times do |i|
      params[i] = args[i].to_jsc
    end
    ret = JSC.jsc_value_constructor_callv(constructor.to_jsc, args.size, params)
    return begin
      if JSC.is_function(ret)
        JSCFunction.new ret
      elsif JSC.is_object(ret)
        JSCObject.new ret
      else
        JSCPrimative.new ret
      end
    end
  end

  # JavaScript's `new` operator, returns `JSCPrimative | JSCFunction | JSCObject`
  #
  # ```
  # include WebExtension
  # promise = JSCContext.get_value("Promise")
  # new Promise, function p {
  #   resolve = p.first.as(JSCFunction)
  #   spawn do
  #     1000.times{ sleep 0.1 }
  #     resolve.call true
  #   end
  # }
  macro new(constructor, *args)
    WebExtension.js_new {{constructor}},{{*args}}
  end

  # Evaluates *js* and gets the result back.
  def self.eval(js : String)
    v = JSC.eval_js JSCContext.global_context, js, -1
    if JSC.is_function(v)
      JSCFunction.new v
    elsif JSC.is_object(v)
      JSCObject.new v
    else
      JSCPrimative.new v
    end
  end

  # Exposes a Crystal's Class so it can be used in JavaScript
  #
  # Example:
  # * webextension.cr:
  # ```
  # class File
  #   INSTANCES = [] of Void*
  #   def initialize(p : [] of (JSCFunction | JSCObject | JSCPrimative))
  #     super(p.first.to_s)
  #   end
  #
  #   @[JSCInstanceMethod]
  #   def content(p)
  #     self.seek(0)
  #     self.gets_to_end
  #   end
  # end
  # JSCContext.set_value "File", WebExtension.register_class(File)
  #
  # ```
  # * index.js
  # ```js
  # var content = new File("./LICENSE").content();
  # ```
  # See more at `JSCClass`.
  macro register_class(type)
    %kclass = JSC.jsc_register_class(
      JSCContext.global_context,
      {{type.stringify}},
      Pointer(Void).null,
      Pointer(Void).null,
      ->(instance : Void*){
        {{type}}::INSTANCES.delete(instance)
      }
    )

    %constructor = JSC.jsc_class_add_constructor(
      %kclass,
      Pointer(UInt8).null,
      ->(params : JSC::JSCValues*, user_data : Void*){
        instance = {{type}}.new JSCFunction.parse_args(params.value)
        boxed_instance = Box.box(instance)
        {{type}}::INSTANCES.push(boxed_instance)
        boxed_instance
      },
      Pointer(Void).null,
      ->(a : Void*){ },
      JSC::POINTER_TYPE
    )

    {% for method in type.resolve.methods %}
      {% if method.annotation(JSCInstanceMethod) %}
        {% if method.args.size != 1 %}
          {% raise "method #{type}\##{method.name} must have only one parameter" %}
        {% end %}
        JSC.jsc_class_define_method(
          %kclass,
          {{method.name.stringify}},
          ->(this : Void*, params : JSC::JSCValues* , user_data : Void*){
            unboxed_instance = Box({{type}}).unbox(this)
            %ret = unboxed_instance.{{method.name}}(JSCFunction.parse_args(params.value))
            {% if method.annotation(Chainable) %}
              this
            {% else %}
              %ret.to_jsc
            {% end %}
          },
          Pointer(Void).null,
          ->(p : Void*){ },
          {% unless method.annotation(Chainable) %}
            JSC.jsc_value_get_type
          {% else %}
            JSC::POINTER_TYPE
          {% end %}
        )
      {% end %}
    {% end %}

    %constructor
  end
end
