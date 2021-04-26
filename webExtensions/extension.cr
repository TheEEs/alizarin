require "../src/alizarin"
include WebExtension

class XAML::MyFileReader < File
  INSTANCES = [] of Void*

  def self.new(params : Array(JSCFunction | JSCObject | JSCPrimative))
    File.new(params.first.to_s)
  end

  @[JSCInstanceMethod]
  def read_content(params)
    self.gets_to_end
  end
end

class Person
  INSTANCES = [] of Void*
  @name = ""

  def self.new(params)
    super()
  end

  @[JSCInstanceMethod]
  @[Chainable]
  def set_name(p)
    @name = p.first.to_s
    Box.box(self)
  end

  @[JSCInstanceMethod]
  def greet(p)
    "Hello #{@name}"
  end
end

initialize_extension do
  IPC.init

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

  puts func.is_instance_of?("Function")

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

  puts object.properties

  my_birthday_code = new(JSCContext.get_value("Number"), 7498)

  JSCContext.set_value "my_birthday_code", my_birthday_code

  ipc = function p do
    IPC.send p.first.to_s
    true
  end

  JSCContext.set_value "ipc", ipc

  test_eval = function p do
    WebExtension.eval "1 + 1"
  end

  JSCContext.set_value "test_eval", test_eval

  JSCContext.set_value "namedTupleToJSC", (function p do
    {
      age:   21,
      songs: StaticArray[
        {
          name: "A song of ice and fire",
        },
      ],
    }
  end)

  do_it_later = function p do
    sto = JSCContext.get_value("setTimeout").as(JSCFunction)
    cb = p.first
    o = JSCObject.new
    o["c"] = cb
    sto.call(
      function pp do
        o["c"].as(JSCFunction).call
      end, 0)
  end

  JSCContext.set_value "do_it_later", do_it_later

  JSCContext.set_value "MyFileReader", register_class(XAML::MyFileReader)
  JSCContext.set_value "Person", register_class(Person)
end
