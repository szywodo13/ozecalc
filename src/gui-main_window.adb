with Gtk.Window;
with Gtk.Notebook;
with Gtk.Label;
with Gtk.Widget;
with Gtk.Box;
with Gtk.Enums;
with Gtk.Main;

with GUI;
with GUI.Project;
with GUI.EMS;
with GUI.Storage;

package body GUI.Main_Window is

   use Gtk.Window;
   use Gtk.Notebook;
   use Gtk.Label;
   use Gtk.Widget;

   procedure Window_Destroyed
     (Widget : access Gtk_Widget_Record'Class)
   is
      pragma Unreferenced (Widget);
   begin
      Gtk.Main.Main_Quit;
   end Window_Destroyed;


   procedure Create is

      Window   : Gtk_Window;
      Notebook : Gtk_Notebook;

      Project_Page : Gtk.Box.Gtk_Box;
      EMS_Page     : Gtk.Box.Gtk_Box;
      Storage_Page : Gtk.Box.Gtk_Box;

      Tab_Project : Gtk_Label;
      Tab_EMS     : Gtk_Label;
      Tab_Storage : Gtk_Label;

   begin

      Gtk_New
        (Window,
         Gtk.Enums.Window_Toplevel);

      Window.Set_Title
        ("OZE - " & GUI.Project_Directory);

      Window.Set_Default_Size (1000, 750);

      Window.Set_Resizable (True);

      Window.On_Destroy (Window_Destroyed'Access);

      Gtk_New (Notebook);

      GUI.Project.Create (Project_Page);

      Gtk_New
        (Tab_Project,
         "Projekt");

      Notebook.Append_Page
        (Project_Page,
         Tab_Project);

      GUI.EMS.Create (EMS_Page);

      Gtk_New
        (Tab_EMS,
         "EMS + raportowanie");

      Notebook.Append_Page
        (EMS_Page,
         Tab_EMS);

      GUI.Storage.Create
        (Storage_Page);

      Gtk_New
        (Tab_Storage,
         "Magazyn + raportowanie");

      Notebook.Append_Page
        (Storage_Page,
         Tab_Storage);

      Window.Add (Notebook);

      Window.Show_All;

   end Create;

end GUI.Main_Window;
