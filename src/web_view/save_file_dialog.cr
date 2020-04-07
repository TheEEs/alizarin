class WebView
  # `SaveFileDialog` is used to select a file in file system to which program will write later.
  # When it's done, it returns the path of selected file.
  class SaveFileDialog
    include Dialog

    # Initializes a new `SaveFileDialog`,if *webview* is not `nil`, the dialog will block *webview* until it's done.
    def initialize(@title : String = "Save File", webview : WebView? = nil,
                   save_button_title : String = "Save", cancel_button_title : String = "Cancel")
      @dialog = GtkDialog.new_dialog @title, webview.try(&.gtk_window_handler),
        GtkDialog::FileChooserAction::SAVE_FILE,
        cancel_button_title, 0,
        save_button_title, 1,
        nil
    end

    # Set default file name to save.
    def file_name=(name : String)
      GtkDialog.set_file_name(@dialog, name)
    end
  end
end
