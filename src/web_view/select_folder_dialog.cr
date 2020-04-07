class WebView
  # `OpenFileDialog` is used to select a file in file system.
  # When it's done, it returns the path of selected file.
  class SelectFolderDialog
    include Dialog

    # Initializes a new `SelectFolderDialog`, if *webview* is not `nil`, the dialog will block *webview* until it's done.
    def initialize(@title : String = "Select Folder", webview : WebView? = nil,
                   select_button_title : String = "OK", cancel_button_title : String = "Cancel")
      @dialog = GtkDialog.new_dialog @title, webview.try(&.gtk_window_handler),
        GtkDialog::FileChooserAction::OPEN_FILE,
        cancel_button_title, 0,
        select_button_title, 1,
        nil
    end
  end
end
