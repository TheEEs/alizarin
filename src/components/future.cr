require "./*"
include WebExtension

# `Future` is a Promise-like native extension. It provides another option to developers by which
# they can organize their asynchronous code better without worring about callback hells or writing to much
# Crystal code to handle async tasks in JS.
#
# We can use it directly in Crystal ...
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
# ... or in JavaScript
#
# ```
# var future = new Future((resolve, reject)=>{
#   resolve("World");
# });
# future.then((value,resolve,reject)=>{
#   console.log(`Hello {value}`);  //note that you must resolve this callback, otherwise....
# }).then((value)=>{
#   //.... this callback will not be executed
# });
# ```
# NOTE: Be sure to call `Future#resolve` or `Future#reject` inside each callback, otherwise your later callbacks will not run.
class Future < JSCObject
  # :nodoc:
  macro expects_a_callback
    unless JSC.is_function(p.first)
        JSCFunction.raise "Expect a function(resolve,reject)."
        return
    end
  end

  # :nodoc:
  macro expects_n_params(n)
    if p.size != {{n}}
        JSCFunction.raise "Expect {{n}} param(s), #{p.size} given." 
        return 
    end
  end

  # :nodoc:
  include JSCClass

  @sto = JSCContext.get_value("setTimeout").as(JSCFunction)
  @current_callback_to_be_called = 1_u32
  @callback_number = 0_u32
  @rejected = false
  @resolve = false

  # :nodoc:
  def initialize(p)
    expects_n_params 1
    expects_a_callback
    super()

    self["resolve"] = function p do
      if @rejected
        JSCFunction.raise "Future is already rejected!"
        return
      end
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

  # Resolves a callback.
  #
  # This method is the same with the one passed as the second parameter of each *then*'s callback.
  # Let's see the following example:
  # ```
  # var f = new Future((resolve, reject)=>{
  #   // do nothing
  # }).then(value => {
  #     console.log("Hello");
  #     // this callback will not be called because the callback above it did not resolve.
  # });
  # // To get the later callback running, we can invoke method `f.resolve`, e.g:
  # f.resolve(1);
  # ```
  # > Output: Hello
  @[JSCInstanceMethod]
  @[Chainable]
  def resolve(p)
    if @rejected
      JSCFunction.raise "Future is already rejected!"
      return
    end
    expects_n_params 1
    @resolved = true
    self["resolved_value"] = p.first.to_jsc
    next_callback
  end

  # Reject the `Future`.
  #
  # This method is the same with the one passed as the third parameter of each *then*'s callback.
  # When a callback call `reject`, all other then will be skip over and the callback passed to `Future#catch` will be executed.
  # Let's see the following example:
  # ```
  # var f = new Future((resolve, reject)=>{
  #   try{
  #     throw "Oops!";
  #   }
  #   catch{
  #     reject("Future rejected!");   
  #   }
  # }).then(value => {
  #     console.log("Hello");
  #     // this callback will not be called because this `Future` is rejected!
  # }).catch((msg)=>{
  #   console.log(`Rejected message {msg}`)  
  # });
  # // To get the later callback running, we can invoke method `f.resolve`, e.g:
  # f.resolve(1);
  # ```
  # > Output: Hello
  @[JSCInstanceMethod]
  @[Chainable]
  def reject(p)
    expects_n_params 1
    self["rejected_value"] = p.first.to_jsc
    @rejected = true
    next_callback
  end

  def next_callback
    if @rejected
      catch = self["catch"]
      if catch.is_a?(JSCFunction)
        @sto.call catch, 0, self["rejected_value"]
      end
      return
    end
    return if !@resolved
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
