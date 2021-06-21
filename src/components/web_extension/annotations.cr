module WebExtension
  # Alizarin allows us to create custom JavaScript classes using plain Crystal classes.
  # All we need to do is to register our classes using `WebExtension.register_class` macro.
  # Note that if we need to expose any method of our Crystal's class so we can call it in JavaScript later, we **must** annotate it with this annotation.
  annotation JSCInstanceMethod; end

  # When a Crystal instance method is annotated with `Chainable`, it means that the method will return the instance itself instead of a `JSC::JSValue`.
  # It does not matter what type of data the method returns, it will always return the instance which call the method.
  annotation Chainable; end
end
