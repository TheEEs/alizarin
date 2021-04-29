require "./*"
include WebExtension

# `Future` is a Promise-like native extension. It provides another option to developers by which
# they can organize their asynchronous code better without worring about callback hells or writing to much
# Crystal code to handle async tasks in JS.
#
# 1. extension.cr
# ```
# require "alizarin"
# include WebExtension
# initialize_extension do
#   read_file_async = function p do
#     file_path = p.first.to_s
#     new JSCContext.get_value("Future"), (function p do
#       resolve = p.first.as(JSCFunction)
#       resolve.call File.read(file_path)
#     end)
#   end
#   JSCContext.set_value "read_file_async", read_file_async
# end
# ```
class Future < JSCObject
  macro expects_a_callback
    unless JSC.is_function(p.first)
        JSCFunction.raise "Expect a function(resolve,reject)."
        return
    end
  end

  macro expects_n_params(n)
    if p.size != {{n}}
        JSCFunction.raise "Expect {{n}} param(s), #{p.size} given." 
        return 
    end
  end

  INSTANCES = [] of JSC::JSValue

  @sto = JSCContext.get_value("setTimeout").as(JSCFunction)
  @current_callback_to_be_called = 1_u32
  @callback_number = 0_u32
  @rejected = false
  @resolve = false

  def initialize(p)
    expects_n_params 1
    expects_a_callback
    super()

    self["resolve"] = function p do
      expects_n_params 1
      @resolved = true
      self["resolved_value"] = p.first.to_jsc
    end

    self["reject"] = function p do
      expects_n_params 1
      self["rejected_value"] = p.first.to_jsc
      @rejected = true
    end

    @callback_number = 0_u32
    self[@callback_number.not_nil!] = p.first
    @sto.call function params do
      callback = self[params.first.to_i32.to_u32].as(JSCFunction)
      callback.call(self["resolve"], self["reject"])
      self.next_callback
    end, 0, @callback_number
  end

  def next_callback
    if @rejected
      catch = self["catch"]
      if catch.is_a?(JSCFunction)
        @sto.call catch, 0, self["rejected_value"]
      end
      return
    end
    unless @current_callback_to_be_called > @callback_number
      @resolved = false
      resolved_value = self["resolved_value"]
      self["resolved_value"] = undefined
      @sto.call function p do
        cb = self[p.first.to_i32.to_u32].as(JSCFunction)
        cb.call resolved_value, self["resolve"], self["reject"]
        @current_callback_to_be_called += 1
        next_callback
      end, 0, @current_callback_to_be_called
    end
  end

  @[JSCInstanceMethod]
  @[Chainable]
  def then(p)
    expects_n_params 1
    expects_a_callback
    @callback_number += 1
    self[@callback_number] = p.first
    if @resolved
      next_callback
    end
  end

  @[JSCInstanceMethod]
  @[Chainable]
  def catch(p)
    expects_n_params 1
    expects_a_callback
    self["catch"] = p.first
  end
end
