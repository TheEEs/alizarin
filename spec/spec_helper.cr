require "spec"
require "file_utils"
require "../src/alizarin"

macro wait_for_page_fully_loaded
  ACK.receive
end

macro eval_js(js)
  COMMAND_CHANNEL.send {{js}}
end

macro script_result
  RESULT_CHANNEL.receive
end

RESULT_CHANNEL  = Channel(JSC::JSValue).new
COMMAND_CHANNEL = Channel(String).new
ACK             = Channel(Nil).new
IPC_CHANNEL     = Channel(String).new

WEBVIEW = WebView.new(ipc: true)

WEBVIEW.extension_dir = "./webExtensions/"

WEBVIEW.when_document_loaded do |webview|
  ACK.send(nil)
end

WEBVIEW.when_script_finished do |js_value|
  RESULT_CHANNEL.send js_value
end

WEBVIEW.on_load_process_changed do |progress|
  puts "Loading #{progress.colorize(:green)}"
end

WEBVIEW.when_ipc_message_received do |message|
  IPC_CHANNEL.send(message)
end

WEBVIEW.title = "Alizarin"
WEBVIEW.window_size(800, 600)
WEBVIEW.on_close do
end

spawn do
  loop do
    command = COMMAND_CHANNEL.receive
    WEBVIEW.execute_javascript command
  end
end

# WEBVIEW.full_screen true

spawn do
  WEBVIEW["enable-developer-extras"] = true
  WEBVIEW.show_inspector
  WEBVIEW.run
end
