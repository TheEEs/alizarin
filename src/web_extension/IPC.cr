module WebExtension::IPC
  @@ipc : UNIXSocket? = nil

  macro ipc_socket_file(uuid)
        "/tmp/alizarin#{ {{uuid}} }.sock"
    end

  def self.init
    @@ipc = UNIXSocket.new(ipc_socket_file WebExtension.uuid) rescue nil
  end

  def self.send(message)
    @@ipc.try &.puts(message)
  end
end
