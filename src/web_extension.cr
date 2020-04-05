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
#       JSCPrimative.new # return JavaScript's undefined
#     else
#       path = params.first.to_s
#       JSCPrimative.new(File.read(path)) rescue JSCPrimative.new nil # Return content of file at *path*, otherwise return null
#     end
#   end
#   JSCContext.set_value("read_file", func)
# end
# ```
# Builds shared library:
# ```bash
# $ crystal build --single-module --link-flags="-shared -fpic" -o <output-path> <source-file>
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
  # Entry point of a Web Extension shared library
  macro initialize_extension
    fun webkit_web_extension_initialize(%ext : LibWebKit2Extension::WebKitWebExtension)
      GC.init
      %arg = "TheEEs<visualbasic2013@hotmail.com>"
      %args = StaticArray(UInt8*, 1).new(%arg.to_unsafe)
      LibCrystalMain.__crystal_main(1, %args.to_unsafe)
      puts "Webkit Extension initialized".colorize(:green)
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
          {{ yield }}
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
end
