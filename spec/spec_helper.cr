require "spec"
require "file_utils"
require "../src/alizarin"

CHANNEL = Channel(JSC::JSValue).new

WEBVIEW = WebView.new
WEBVIEW.extension_dir = "./webExtensions/"
WEBVIEW.when_document_loaded do |webview|
  webview.execute_javascript "writeHTMLBodyToFile('./htmlBody.txt')"
  webview.execute_javascript "document.body.innerHTML"
end
WEBVIEW.when_script_finished do |js_value|
  puts "Script execution finished".colorize(:green)
  CHANNEL.send js_value
end
WEBVIEW.title = "Alizarin"
WEBVIEW.default_size(800, 600)
WEBVIEW.load_url "https://crystal-lang.org"
WEBVIEW.on_close do
end

spawn do
  100.times do |i|
    WEBVIEW.run false do
      Fiber.yield
    end
  end
end
