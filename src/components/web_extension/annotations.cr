module WebExtension
  # Alizarin allows us to create custom JavaScript classes using plain Crystal classes.
  # All we need to do is to register our classes using `WebExtension.register_class` macro.
  # Note that if we need to expose any method of our Crystal's class so we can call it in JavaScript later, we **must** annotate it with this annotation, `JSCInstanceMethod`.
  #
  # The example bellow demonstrates how to create a custom JavaScript class which allow us to read content of given file on disk.
  # * extension.cr
  # ```
  # require 'alizarin'
  # include WebExtension
  # class File #here we do not have to construct a new class from scratch, just extend existing one.
  #   def initialize(params : [] of JSCObject | JSCFunction | JSCPrimative)
  #       super(params.first.to_s)
  #   end
  #
  #   @[JSCInstanceMethod]
  #   def content(p)
  #     self.seek(0)
  #     self.gets_to_end
  #   end
  # end
  #
  # initialize_extension do
  #     JSCContext.set_value "File", register_class(File)
  # end
  # ```
  # * index.js
  # ```javascript
  # var file_content = new File("./LICENSE").content();
  # console.log(file_content);
  # ```
  annotation JSCInstanceMethod; end

  # When a Crystal instance method is annotated with `Chainable`, it means that the method will return the instance itself instead of a `JSC::JSValue`.
  # It does not matter what type of data the method returns, it will always return the current instance which call the method.
  # * extension.cr
  # ```
  # require 'alizarin'
  # include WebExtension
  # class File #here we do not have to construct a new class from scratch, just extend existing one.
  #   def initialize(params : [] of JSCObject | JSCFunction | JSCPrimative)
  #       super(params.first.to_s)
  #   end
  #
  #   @content = ""
  #
  #   @[JSCInstanceMethod]
  #   @[Chainable]
  #   def read(p)
  #     self.seek(0)
  #     @content = self.gets_to_end
  #   end
  #
  #   @[JSCInstanceMethod]
  #   def content(p)
  #     @content
  #   end
  # end
  #
  # initialize_extension do
  #     JSCContext.set_value "File", register_class(File)
  # end
  # ```
  # * index.js
  # ```javascript
  # var file_content = new File("./LICENSE").read().content();
  # console.log(file_content);
  # ```
  annotation Chainable; end
end
