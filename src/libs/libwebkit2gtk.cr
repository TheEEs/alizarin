require "./libJSC2"
@[Link("gtk+-3.0")]
@[Link("webkit2gtk-4.0")]
@[Link(ldflags: "-fPIC")]
lib LibWebKit
  fun webkit_frame_get_js_context(frame : Void*) : Void*

  @[Flags]
  enum GtkGConnectFlags
    CONNECT_AFTER
    CONNECT_SWAPPED
  end

  enum GTKWindowType
    TOP_LEVEL
    POPUP
  end

  alias WebKitJavaScriptResult = Pointer(Void)
  alias GtkWidget = Pointer(Void)
  alias GtkWindow = Pointer(Void)
  alias GtkWebKitWebView = Pointer(Void)
  alias GtkWebContext = Pointer(Void)
  alias GtkWebExtension = Pointer(Void)
  alias GtkWebSettings = Pointer(Void)
  alias GtkWebInspector = Pointer(Void)

  alias GtkCallback = Void*, Void*, Void* -> Nil
  alias GAsyncReadyCallback = Void*, Void*, Void* -> Nil

  fun g_object_set(g_object : Void*, property : UInt8*, ...)
  fun g_object_get(g_object : Void*, property : UInt8*, ...)
  fun gtk_init(argc : Int32*, argv : Pointer(LibC::Char**))
  fun new_window = gtk_window_new(type : GTKWindowType) : GtkWindow
  fun new_scrollable_container = gtk_scrolled_window_new(hadj : Void*, vadj : Void*) : GtkWidget # (hadj : Void*, vadj : Void *) : GtkWidget
  fun set_default_window_size = gtk_window_set_default_size(window : GtkWindow, width : Int32, height : Int32)
  fun create_web_view = webkit_web_view_new : GtkWebKitWebView
  fun add_view_to_parent = gtk_container_add(parent : GtkWidget, child : GtkWidget)
  fun connect_signal = g_signal_connect_data(widget : GtkWidget, event : LibC::Char*, callback : GtkCallback,
                                             data : Pointer(Void), destroy_data : Void*, flags : GtkGConnectFlags)

  fun set_title = gtk_window_set_title(w : GtkWindow, t : UInt8*)
  fun webview_load_uri = webkit_web_view_load_uri(webview : GtkWebKitWebView, uri : LibC::Char*)
  fun webview_load_html = webkit_web_view_load_html(webview : GtkWebKitWebView, html : LibC::Char*, base_url : LibC::Char*)
  fun widget_focus = gtk_widget_grab_focus(widget : GtkWidget)
  fun get_webview_settings = webkit_web_view_get_settings(webview : GtkWebKitWebView) : GtkWebSettings
  fun get_web_inspector = webkit_web_view_get_inspector(webview : GtkWebKitWebView) : GtkWebInspector
  fun show_inspector = webkit_web_inspector_show(inspector : GtkWebInspector)
  fun show_window = gtk_widget_show_all(window : GtkWindow)
  fun start_gtk_main_loop = gtk_main
  fun start_gtk_main_iter = gtk_main_iteration(blocking : Bool) : Bool
  fun stop_gtk_main_loop = gtk_main_quit
  fun destroy_widget = gtk_widget_destroy(widget : GtkWidget)
  fun get_default_web_context = webkit_web_context_get_default : GtkWebContext
  fun set_extensions_directory = webkit_web_context_set_web_extensions_directory(context : GtkWebContext, path : LibC::Char*)
  fun eval_js = webkit_web_view_run_javascript(webview : GtkWebKitWebView, script : LibC::Char*, cancellable : Void*, callback : GAsyncReadyCallback, user_data : Void*)
  fun script_finish_result = webkit_web_view_run_javascript_finish(webview : GtkWebKitWebView, result : Void*, errors : Void**) : WebKitJavaScriptResult
  fun get_jsc_from_js_result = webkit_javascript_result_get_js_value(result : WebKitJavaScriptResult) : JSC::JSValue
  fun full_screen = gtk_window_fullscreen(window : GtkWindow)
  fun unfull_screen = gtk_window_unfullscreen(window : GtkWindow)
  fun go_back = webkit_web_view_go_back(webview : GtkWebKitWebView)
  fun go_forward = webkit_web_view_go_forward(webview : GtkWebKitWebView)
  fun reload = webkit_web_view_reload(webview : GtkWebKitWebView)
  fun reload_without_cache = webkit_web_view_reload_bypass_cache(webview : GtkWebKitWebView)
  fun webkit_web_view_get_estimated_load_progress(webview : GtkWebKitWebView) : Float64
end
