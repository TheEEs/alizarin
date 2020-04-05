require "../src/alizarin"
include WebExtension

initialize_extension do
  
  puts WebExtension.uuid
  
  func = function params do
    if params.size != 1
      JSCFunction.raise "Expect only one arguments, #{params.size} given"
      return JSCPrimative.new
    end
    path = params.first.to_s
    bodyHTML = JSCContext.get_value("document")["body"]["innerHTML"]
    File.write path, bodyHTML.to_s
    !path.empty? ? path : nil
  end

  JSCContext.set_value "writeHTMLBodyToFile", func

  func = function params do
    StaticArray[1, 2, 3, 5]
  end

  JSCContext.set_value "getArray", func

  propertyNumber = 0

  object = JSCObject.new

  accessor = JSCObject::Accessor(Int32?).new "number"

  accessor.get do
    propertyNumber
  end

  accessor.set do |value|
    if value.is_number?
      propertyNumber = value.to_i32
    else
      propertyNumber = nil
    end
  end

  object.mount_accessor accessor

  object.define_property "string", "hello", JSCObject::Accessor::Accessibility::All

  JSCContext.set_value "my_object", object

  my_birthday_code = new(JSCContext.get_value("Number"), 7498)

  JSCContext.set_value "my_birthday_code", my_birthday_code
end
