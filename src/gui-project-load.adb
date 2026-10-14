with Gtk.Frame;
with Gtk.Grid;
with Gtk.Enums;
with Gtk.Label;

package body GUI.Project.Load is

   use Gtk.Box;
   use Gtk.Frame;
   use Gtk.Grid;
   use Gtk.Enums;
   use Gtk.Label;

   procedure Create
     (Container : out Gtk.Box.Gtk_Box) is

      Load_Frame : Gtk_Frame;
      Load_Grid  : Gtk_Grid;
      Label      : Gtk_Label;

   begin

      Gtk_New
        (Container,
         Gtk.Enums.Orientation_Vertical,
         6);

      Gtk_New
        (Load_Frame,
         "Profil zużycia");

      Gtk_New (Load_Grid);

      Load_Grid.Set_Row_Spacing (6);
      Load_Grid.Set_Column_Spacing (8);
      Load_Grid.Set_Border_Width (8);

      Add_Entry
        (Load_Grid,
         Row          => 0,
         Caption      => "Zużycie roczne:",
         Default_Text => "",
         Unit_Text    => "kWh");

      Add_Entry
        (Load_Grid,
         Row          => 1,
         Caption      => "Profil:",
         Default_Text => "home");

      Gtk_New
        (Label,
         "[ Wczytaj load.csv ]    [ Generuj ]");

      Load_Grid.Attach
        (Label,
         Left   => 0,
         Top    => 2,
         Width  => 3,
         Height => 1);

      Load_Frame.Add (Load_Grid);

      Container.Pack_Start
        (Load_Frame,
         False,
         True,
         0);


   end Create;

end GUI.Project.Load;
