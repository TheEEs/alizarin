class WebView
  # `OpenFileDialog` is used to select a file in file system.
  # When it's done, it returns the path of selected file.
  class OpenFileDialog
    include Dialog

    # Initializes a new `OpenFileDialog`, if *webview* is not `nil`, the dialog will block *webview* until it's done.
    def initialize(@title : String = "Open File", webview : WebView? = nil,
                   open_button_title : String = "Open", cancel_button_title : String = "Cancel")
      @dialog = GtkDialog.new_dialog @title, webview.try(&.gtk_window_handler),
        GtkDialog::FileChooserAction::OPEN_FILE,
        cancel_button_title, 0,
        open_button_title, 1,
        nil
    end
  end
end
