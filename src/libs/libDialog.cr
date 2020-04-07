@[Link("gtk+-3.0")]
lib GtkDialog
  enum FileChooserAction
    OPEN_FILE
    SAVE_FILE
    SELECT_FOLDER
  end

  enum ButtonID
    ACCEPT
    OK
    YES
    APPLY
  end

  fun new_dialog = gtk_file_chooser_dialog_new(
    title : LibC::Char*,
    parent_window : Pointer(Void),
    action : FileChooserAction,
    first_button_text : LibC::Char*,
    ...
  ) : Void*
  fun run_dialog = gtk_dialog_run(dialog : Void*) : Int32
  fun get_file_name = gtk_file_chooser_get_filename(dialog : Void*) : LibC::Char*
  fun add_file_filter = gtk_file_chooser_add_filter(dialog : Void*, filter : Void*)
  fun set_file_name = gtk_file_chooser_set_current_name(dialog : Void*, file_name : LibC::Char*)

  fun new_file_filter = gtk_file_filter_new : Void*
  fun set_file_filter_name = gtk_file_filter_set_name(filter : Void*, name : LibC::Char*)
  fun add_file_filter_pattern = gtk_file_filter_add_pattern(filter : Void*, pattern : LibC::Char*)
end
