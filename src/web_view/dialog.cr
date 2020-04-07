class WebView
  # `Dialog` is the base module for three avaiable kinds of dialog in Alizarin.
  # They includes:
  # 1. `WebView::OpenFileDialog`
  # 2. `WebView::SaveFileDialog`
  # 3. `WebView::SelectFolderDialog`
  module Dialog
    # Adds an `WebView::DialogFileFilter` to the dialog.
    def add_file_filter(filter : DialogFileFilter)
      GtkDialog.add_file_filter @dialog, filter
    end

    # Implicitly adds an `WebView::DialogFileFilter` to the dialog, given its *name* and *pattern*.
    #
    # ```
    # my_dialog.add_file_filter("Crystal", "*.cr")
    # ```
    def add_file_filter(name : String, pattern : String)
      file_filter = GtkDialog.new_file_filter
      GtkDialog.set_file_filter_name file_filter, name
      GtkDialog.add_file_filter_pattern file_filter, pattern
      GtkDialog.add_file_filter @dialog, file_filter
    end

    # Shows the dialog then return corresponding value, in : file path, ..etc...
    def show
      res = GtkDialog.run_dialog @dialog
      if res == 1
        file_name_ptr = GtkDialog.get_file_name @dialog
        unless file_name_ptr.null?
          file_name = String.new file_name_ptr
          LibWebKit.destroy_widget @dialog
          return file_name
        end
      end
      LibWebKit.destroy_widget @dialog
    end
  end
end
