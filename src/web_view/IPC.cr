require "socket"

class WebView
    module IPC 
        def init_ipc
            @socket = UNIXSocket.new("#{self.uuid}.alizarin")
            
        end
    end
end