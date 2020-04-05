lib LibWebKit2Extension
  alias WebKitExtensionBase = Void*
  alias WebKitWebPage = Void*
  alias WebKitWebExtension = Void*
  alias WebKitWebFrame = Void*
  alias WebKitScriptWorld = Void*
  alias WebKitJSContext = Void*
  alias SignalCallback = Void*, Void*, Void* -> Nil

  fun get_default_script_world = webkit_script_world_get_default : WebKitScriptWorld
  fun get_global_js_context = webkit_frame_get_js_context_for_script_world(frame : WebKitWebFrame, script_world : WebKitScriptWorld) : WebKitJSContext
  fun get_main_frame = webkit_web_page_get_main_frame(page : WebKitWebPage) : WebKitWebFrame
  # fun connect_signal = g_signal_connect_data(widget : WebKitExtensionBase, event : LibC::Char*, callback : SignalCallback,
  #                                           data : Pointer(Void), destroy_data : Void*, flags : GtkGConnectFlags)
  fun g_variant_get_string(gvariant : Void*, size : LibC::ULong*) : LibC::Char*
end
