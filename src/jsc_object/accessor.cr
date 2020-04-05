struct JSCObject
  class Accessor(T)

    # Accessibility specifics how a JavaScript property can be accessed 
    @[Flags]
    enum Accessibility
      # The type of the property descriptor may be changed and the property may be deleted from the corresponding object.
      Configurable
      # The property shows up during enumeration of the properties on the corresponding object.
      Enumerable
      # The value associated with the property may be changed with an assignment operator.
      Writable
    end

    getter name

    def initialize(@name : String)
    end

    def set(&block : Proc(JSCFunction | JSCObject | JSCPrimative, Nil))
      @setter = block
    end

    def get(&block : -> T)
      @getter = block
    end

    def set
      @setter
    end

    def get
      @getter
    end
  end
end
