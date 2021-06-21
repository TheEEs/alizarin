# Hah? Now you're wondering how to create Javascript classes. I know it.
# Actually, macro `WebExtension.register_class` had been introduced since version 0.3.1 to help you enroll a plain Crystal' class into JavaScriptCore environment and uses it directly in your JS code.
module JSCClass
  macro included
        INSTANCES = [] of Void*
        @@kconstructor : Pointer(Void)? = nil

        def self.last_created_instance
            Box({{@type}}).unbox(INSTANCES.last)
        end

        def self.constructor 
            @@kconstructor ||= WebExtension.register_class({{@type}})
        end
    end
end
