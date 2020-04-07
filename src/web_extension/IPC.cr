# Since `Alizarin` version **2.0.0**, `IPC` module was added to provide ability to communicate between `WebExtension` and `WebView`.
# This implmentation uses Unix socket as the primary ipc method since it's cheap, well supported in Crystal.
# It's better to look at a certain situation.
# The following example will create an JavaScript function. When it's called , an instruction will be transferred to Web Process.
# Based on the value of IPC message, `WebView` can decide what to do next.
# #### extension.cr
# ```
# require "alizarin"
# include WebExtension
# initialize_extension do
#   WebExtension::IPC.init
#   ipc = function p do
#     WebExtension::IPC.send p.first.to_s
#   end
#   JSCContext.set_value "ipc", ipc
# end
# ```
# #### main.cr
# ```
# require "alizarin"
# webview = WebView.new ipc: true # makes sure to set `ipc: true` to make WebView run in IPC mode
# webview.when_ipc_message_received do |message|
#   case message
#   when ...
#   when ... # and so on
#   end
# end
# webview.load_html <<-HTML
#   <h1>Hello</h1>
# HTML
# webview.run
# ```
module WebExtension::IPC
  @@ipc : UNIXSocket? = nil

  # :nodoc:
  macro ipc_socket_file(uuid)
    "/tmp/alizarin#{ {{uuid}} }.sock"
  end

  # Initializes `IPC`. This method must be called before any call to `#send`.
  def self.init
    @@ipc = UNIXSocket.new(ipc_socket_file WebExtension.uuid) rescue nil
  end

  # Send *message* to the `WebView` which loads this `WebExtension`.
  def self.send(message)
    @@ipc.try &.puts(message)
  end
end
