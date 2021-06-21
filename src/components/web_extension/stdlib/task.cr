include WebExtension

alias JSCTypes = JSCFunction | JSCPrimative | JSCObject | JSC::JSValue

class StdLib::Task < Channel(JSCTypes)
  include JSCClass

  def initialize(p)
    super 0
  end

  def send(p)
    super(p.to_jsc)
    true
  end

  @[JSCInstanceMethod]
  def wait(p)
    while true
      i, m = Channel.non_blocking_select(self.receive_select_action)
      if m.is_a?(JSCTypes)
        return m 
      end
    end
  end

  @[JSCInstanceMethod]
  def await(p)
    select
    when m = self.receive
      return m
    else
      return nil
    end
  end

  @[JSCInstanceMethod]
  def yield(p)
    Fiber.yield
  end
end
