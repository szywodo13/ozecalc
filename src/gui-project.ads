with Glib;

with Gtk.Box;
with Gtk.Grid;
with Gtk.Button;
with Gtk.Widget;
with Gtk.Handlers;

package GUI.Project is

   procedure Create
     (Page : out Gtk.Box.Gtk_Box);

private

   package Button_Callbacks is
     new Gtk.Handlers.Callback
       (Gtk.Button.Gtk_Button_Record);

   package Remove_Callbacks is
     new Gtk.Handlers.User_Callback
       (Gtk.Button.Gtk_Button_Record,
        Gtk.Widget.Gtk_Widget);

   procedure Remove_Row
     (Button : access Gtk.Button.Gtk_Button_Record'Class;
      Row    : Gtk.Widget.Gtk_Widget);

   procedure Add_Entry
     (Grid         : Gtk.Grid.Gtk_Grid;
      Row          : Glib.Gint;
      Caption      : String;
      Default_Text : String;
      Unit_Text    : String := "");

end GUI.Project;
