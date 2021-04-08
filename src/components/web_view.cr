LibWebKit.gtk_init(nil, nil)

# A `WebView` is a class which represents a WebKit2GTK browser window.
# It allows developers to display HTML contents, execute JavaScript code.
class WebView
  # :nodoc:
  macro ipc_socket_file_path(path)
    "/tmp/alizarin#{ {{path}} }.sock"
  end

  @script_finish_callback = Pointer(Void).null
  @document_loaded_callback = Pointer(Void).null
  @extension_dir : String = ""
  @server : UNIXServer? = nil
  @on_ipc_message_received : (String -> Nil) | Nil = nil

  alias Callback = WebView -> Void

  # Get extension directory
  getter extension_dir

  # Get this `WebView`'s UUID. This is helpful in case of communicating between Web Process and Render Process
  getter uuid

  # Specifies whether if `WebView` is running on IPC mode or not.
  getter? ipc

  # Initializes a new instance of `WebView`, whether this `WebView` should use *ipc* mode or not.
  def initialize(@ipc : Bool = false)
    @window = LibWebKit.new_window LibWebKit::GTKWindowType::TOP_LEVEL
    @scroll_panel = LibWebKit.new_scrollable_container nil, nil
    @browser = LibWebKit.create_web_view
    @settings = LibWebKit.get_webview_settings @browser
    @uuid = UUID.random
    @server = UNIXServer.new ipc_socket_file_path(@uuid.hexstring) if @ipc
    LibWebKit.add_view_to_parent @window, @scroll_panel
    LibWebKit.add_view_to_parent @scroll_panel, @browser
  end

  # Specifies *directory* where the webview should look for WebExtension.
  #
  # ```
  # webview = WebView.new
  # webview.extension_dir = "<your-path-to-directory-which-contains-web-extensions>"
  # ```
  # NOTE: If this method is used, it should be executed as soon as possible. A good practice is to place it right after `.new`.
  def extension_dir=(directory : String)
    @extension_dir = directory
    boxed_data = Box.box({@extension_dir, @uuid.hexstring})
    LibWebKit.connect_signal LibWebKit.get_default_web_context, "initialize-web-extensions", (->(user_data : Void*, data : Void*, data1 : Void*) {
      default_ctx = LibWebKit.get_default_web_context
      unboxed_data = Box({String, String}).unbox(user_data)
      extension_dir = unboxed_data[0]
      uuid = unboxed_data[1]
      LibWebKit.set_extensions_directory default_ctx, extension_dir
      LibWebKit.set_extension_init_data default_ctx,
        LibWebKit.g_variant_new_string uuid
    }), boxed_data, nil, LibWebKit::GtkGConnectFlags::All
  end

  # Set size of browser window
  #
  # ```
  # webview.window_size 800, 600
  # ```
  def window_size(width : UInt32, height : UInt32)
    LibWebKit.set_default_window_size @window, width, height
  end

  # Set title of browser window
  #
  # ```
  # webview.title = "Alizarin App"
  # ```
  def title=(title : String)
    LibWebKit.set_title(@window, title)
  end

  # Set properties for WebKitSettings. See [WebKitSettings](https://webkitgtk.org/reference/webkit2gtk/stable/WebKitSettings.html).
  #
  # ```
  # webview["enable-developer-extras"] = true    # This allows developers to use WebInspector(DevTools)
  # webview["enable-html5-local-storage"] = true # This enables localStorage features in JavaScript
  # ```
  def []=(name : String, value)
    LibWebKit.g_object_set @settings, name, value, nil
  end

  # Loads a webpage located at *url*
  #
  # ```
  # webview.load_url "https://google.com"
  # ```
  def load_url(url : String)
    LibWebKit.webview_load_uri @browser, url
  end

  # Loads raw *html*
  #
  # If *base_url* is a `String`, all relative paths in *html* will be resolved against *base_url*.
  # All absolute paths will also have to start with *base_url* because of security reasons. If not, Web Process might crash.
  def load_html(html : String, base_url : String? = nil)
    LibWebKit.webview_load_html @browser, html, base_url
  end

  # Specifies callback called when browser window close. Usually useds to close process.
  #
  # ```
  # webview.on_close do |webview|
  #   puts "WebView(#{webview}) is going to shutdown"
  #   exit 0
  # end
  # ```
  def on_close(&b : Callback)
    box = Box.box({self, b})
    LibWebKit.connect_signal @browser, "destroy", ->(data1 : Void*, data2 : Void*, data3 : Void*) {
      data = Box({WebView, Callback}).unbox(data1)
      webview = data[0]
      callback = data[1]
      webview.destroy_browser
      webview.close_ipc_socket if webview.ipc?
      callback.call webview
    }, box, nil, LibWebKit::GtkGConnectFlags::All
  end

  # :nodoc:
  protected def close_ipc_socket
    @server.try &.close
  end

  # Stops ipc listening on the `WebView`
  def stop_ipc
    self.close_ipc_socket
  end

  # Shows WebKit's WebInspector.
  def show_inspector
    inspector = LibWebKit.get_web_inspector @browser
    LibWebKit.show_inspector inspector
  end

  # Runs browser window. This method puts the main process into a loop which blocks until callback specified in `#on_close` called.
  #
  # ```
  # webview.run
  # puts "Good bye" # This line will only be executed after webview main loop is destroyed.
  # ```
  def run
    if ipc?
      LibWebKit.show_window @window
      spawn {
        while connection = @server.try &.accept?
          spawn self.handle_connection(connection)
        end
      }
      while LibWebKit.start_gtk_main_iter(false)
        Fiber.yield
      end
    else
      LibWebKit.show_window @window
      LibWebKit.start_gtk_main_loop
    end
  end

  # Specifies a callback which will be called eachtime a IPC message is send from Render Process (e.g : via JavaScript)
  def when_ipc_message_received(&block : String -> Nil)
    @on_ipc_message_received = block
  end

  # Run browser window. This method receives a *block* which lets developers do some logics at each webview's iteration.
  # If *blocking* is truthy, *block* will only be called when an iteration is done.
  #
  # ```
  # count = 0
  # webview.run blocking: false do |webview|
  # #If blocking: set to `true`. This printing process will be significally slowed down.
  # #This is because `#run(blocking,&block)` has to wait for the current iteration finish.
  #   puts a
  #   a += 1
  # end
  # ```
  # NOTE: **IMPORTANT** : Uses this method carefully when `WebView` is running on IPC mode.
  # Some concurrent operations such as `Channel#receive` may cause the `WebView` blocked infinitely.
  def run(blocking : Bool, &block : WebView -> Nil)
    LibWebKit.show_window @window
    spawn {
      while connection = @server.try &.accept?
        spawn self.handle_connection(connection)
      end
    } if ipc?
    while LibWebKit.start_gtk_main_iter(blocking)
      Fiber.yield if ipc?
      block.call self
    end
  end

  # :nodoc:
  def gtk_window_handler
    @window
  end

  # :nodoc:
  private def handle_connection(connection)
    while message = connection.gets
      @on_ipc_message_received.try &.call(message)
    end
  end

  # Set WebView's fullscreen state, passing `true` makes the webview fullscreen, otherwise.
  def full_screen(state : Bool)
    if state
      LibWebKit.full_screen @window
    else
      LibWebKit.unfull_screen @window
    end
  end

  # Asynchronously executes *js_code*. After *js_code* has been successfully executed, the callback passed to `#when_script_finished` will be called.
  #
  # ```
  # webview.when_document_loaded |w|
  #   w.execute_javascript "alert('LOL')"
  # end
  # ```
  def execute_javascript(js_code : String)
    LibWebKit.eval_js @browser, js_code, nil,
      LibWebKit::GAsyncReadyCallback.new { |object, result, user_data|
        res = LibWebKit.script_finish_result object, result, nil
        if res.null?
          puts "JavaScript execution has cause error(s)".colorize(:red).on(:black)
          next
        end
        jsc_value = LibWebKit.get_jsc_from_js_result res
        webview = Box(WebView).unbox(user_data)
        webview.run_script_finish_callback jsc_value
      }, Box.box(self)
  end

  # Asynchronously executes *js_code*, *block* will be called instead of the callback passed to `#when_script_finished`.
  #
  # This method is useful in situations in which one needs to evaluate returned value of specific JavaScript code, for example:
  # ```
  # webview.when_document_loaded do
  #   webview.execute_javascript "document.title" do |value|
  #     webview.title = String.new(JSC.to_string value)
  #   end
  # end
  # ```
  # NOTE: *block* receives a `Pointer(Void)` as its argument, so it's considered unsafe.
  def execute_javascript(js_code : String, &block : JSC::JSValue -> Nil)
    LibWebKit.eval_js @browser, js_code, nil,
      LibWebKit::GAsyncReadyCallback.new { |object, result, user_data|
        res = LibWebKit.script_finish_result object, result, nil
        if res.null?
          puts "JavaScript execution has cause error(s)".colorize(:red).on(:black)
          next
        end
        jsc_value = LibWebKit.get_jsc_from_js_result res
        data = Box(JSC::JSValue -> Nil).unbox(user_data)
        b = data
        b.call jsc_value
      }, Box.box(block)
  end

  # Loads the previous web page.
  def go_back
    LibWebKit.go_back @browser
  end

  # Loads the next web page.
  def go_forward
    LibWebKit.go_forward @browser
  end

  # Reloads current content of this `WebView`.
  def reload
    LibWebKit.reload @browser
  end

  # Reloads current content of this `WebView` without re-using any cached data.
  def reload_without_cache
    LibWebKit.reload_without_cache @browser
  end

  # Specifies a callback called each time `WebView` load progress changes.
  #
  # E.g:
  # ```
  # webview.on_load_process_changed do |progress|
  #   # progress ranges from 0.0 to 1.0
  #   puts "Loading #{(progress * 100).round(2).colorize(:green)}"
  # end
  # ```
  def on_load_process_changed(&block : Float64 -> _)
    data = Box.box({@browser, block})
    LibWebKit.connect_signal @browser,
      "notify::estimated-load-progress",
      (->(data : Void*, data1 : Void*, data2 : Void*) {
        user_data = Box({LibWebKit::GtkWebKitWebView, typeof(block)}).unbox data
        webview = user_data[0]
        cb = user_data[1]
        cb.call LibWebKit.webkit_web_view_get_estimated_load_progress webview
      }), data, nil, LibWebKit::GtkGConnectFlags::All
  end

  # Specifies a callback which will be called each time a script executed by `#execute_javascript` finishes.
  # The callback *b* receives a `Pointer(Void)` as parameter that points to result of the executed JS code.
  # For example:
  #
  # ```
  # webview.when_script_finished do |js_value|
  #   puts JSC.is_number jsc_value
  # end
  # webview.execute_javascript "1 + 2"          # => js_value in the block above should be true
  # webview.execute_javascript "alert('Hello')" # => js_value should be false
  # ```
  # NOTE: Because the passed block receives a Pointer as its parameter, it's considered unsafe. It's not recommended to manipulate this pointer directly
  # using JavaScriptCore API. Uses `WebExtension` instead.
  def when_script_finished(&b : JSC::JSValue -> Nil)
    @script_finish_callback = Box.box(b)
  end

  # Specifies a callback which will be called after webview has fully loaded a webpage.
  # This is equal to JQuery's `$(window).ready`.
  # This method is the right place to do some logic, for example `#execute_javascript`.
  #
  # ```
  # webview.on_document_loaded do |webview|
  #   webview.execute_javascript "alert('Hello')"
  # end
  # ```
  def when_document_loaded(&b : WebView -> Nil)
    @document_loaded_callback = Box.box({self, b})
    LibWebKit.connect_signal @browser, "load-changed",
      LibWebKit::GtkCallback.new { |udata, event, webview|
        if event.address == 3
          data = Box({WebView, (WebView -> Nil)}).unbox udata
          webview = data[0]
          callback = data[1]
          callback.call webview
        end
      }, @document_loaded_callback, nil, LibWebKit::GtkGConnectFlags::All
  end

  protected def run_script_finish_callback(js_value : JSC::JSValue)
    unless @script_finish_callback.null?
      callback = Box(JSC::JSValue -> Nil).unbox @script_finish_callback
      callback.call js_value
    end
  end

  protected def destroy_browser
    LibWebKit.destroy_widget @browser
    LibWebKit.destroy_widget @window
  end
end
