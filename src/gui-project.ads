with Glib;

with Gtk.Box;
with Gtk.Grid;
with Gtk.Button;
with Gtk.Widget;
with Gtk.Handlers;
with Gtk.GEntry;

with OZE.Project;

package GUI.Project is

   function Current_Data
     return OZE.Project.Project_Data;

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
      Unit_Text    : String := "";
      Tooltip_Text : String := "");

   procedure Add_Entry
     (Grid         : Gtk.Grid.Gtk_Grid;
      Row          : Glib.Gint;
      Caption      : String;
      Default_Text : String;
      Field        : out Gtk.GEntry.Gtk_Entry;
      Unit_Text    : String := "";
      Tooltip_Text : String := "");

end GUI.Project;
