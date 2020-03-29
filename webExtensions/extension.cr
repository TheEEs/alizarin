require "../src/libs/macros"
include WebExtension

initialize_extension do
  func = function params do
    if params.size != 1
      JSCFunction.raise "Expect only one arguments, #{params.size} given"
      return JSCPrimative.new
    end
    path = params.first.to_s
    bodyHTML = JSCContext.get_value("document")["body"]["innerHTML"]
    File.write path, bodyHTML.to_s
    JSCPrimative.new path
  end

  JSCContext.set_value "writeHTMLBodyToFile", func
end
