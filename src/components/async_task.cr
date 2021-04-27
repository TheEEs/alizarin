require "./*"

class AsyncTask < JSCObject
  enum States
    Pending
    Finished
    Failed
  end

  @state = States::Pending
  @param : JSC::JSValue = WebExtension.undefined.to_jsc
  getter state
  getter param

  def initialize(callback : JSCFunction)
    super()
    self["callback"] = callback
  end

  def resolve(param)
    @param = param.to_jsc
    @state = States::Finished
  end

  def reject(param)
    @param = param.to_jsc
    @state = States::Failed
  end

  def callback : JSCFunction
    self["callback"].as(JSCFunction)
  end
end
