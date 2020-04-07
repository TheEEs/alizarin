class WebView
  # This module helps filtering files shown in dialogs. E.g: "only show markdown file"
  struct DialogFileFilter
    # Initializes a new `DialogFileFilter`, given its name and pattern
    #
    # ```
    # WebView::DialogFileFilter.new "Markdown", "*.md"
    def initialize(@name : String, @pattern : String)
    end

    # :nodoc:
    def to_unsafe
      file_filter = GtkDialog.new_file_filter
      GtkDialog.set_file_filter_name file_filter, @name
      GtkDialog.add_file_filter_pattern file_filter, @pattern
      file_filter
    end
  end
end
