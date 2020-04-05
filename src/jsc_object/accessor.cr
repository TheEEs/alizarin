struct JSCObject
  # An `Accessor` represents a JavaScript object's property which is defined via JS `Object.defineProperty`
  # An `Accessor` can define its own setter or getter via `Accessor#get(&block)` and `Accessor#set(&block)`.
  # An `Accessor` can have both setter and getter, either, or even none.
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

    # :nodoc:
    getter name

    # Initializes a new `Accessor`, given it *name*.
    def initialize(@name : String)
    end

    # Specifies `Accessor`'s setter.
    def set(&block : Proc(JSCFunction | JSCObject | JSCPrimative, Nil))
      @setter = block
    end

    # Specifies `Accessor`'s getter
    def get(&block : -> T)
      @getter = block
    end

    # :nodoc:
    def set
      @setter
    end

    # :nodoc:
    def get
      @getter
    end
  end
end
