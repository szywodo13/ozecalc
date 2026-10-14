with Gtk.Frame;
with Gtk.Grid;
with Gtk.Label;
with Gtk.Enums;

package body GUI.Project.Tariffs is

   use Gtk.Box;
   use Gtk.Frame;
   use Gtk.Grid;
   use Gtk.Label;

   procedure Create
     (Container : out Gtk.Box.Gtk_Box) is

      Tariff_Frame     : Gtk_Frame;
      Tariff_Grid      : Gtk_Grid;
      Label            : Gtk_Label;

   begin

      Gtk_New
        (Container,
         Gtk.Enums.Orientation_Vertical,
         6);

      Gtk_New
        (Tariff_Frame,
         "Taryfa");

      Gtk_New (Tariff_Grid);

      Tariff_Grid.Set_Row_Spacing (6);
      Tariff_Grid.Set_Column_Spacing (8);
      Tariff_Grid.Set_Border_Width (8);

      Add_Entry
        (Tariff_Grid,
         Row          => 0,
         Caption      => "Profil:",
         Default_Text => "G11");

      Add_Entry
        (Tariff_Grid,
         Row          => 1,
         Caption      => "Cena zakupu:",
         Default_Text => "");

      Add_Entry
        (Tariff_Grid,
         Row          => 2,
         Caption      => "Cena sprzedaży:",
         Default_Text => "");

      Gtk_New
        (Label,
         "[ Wczytaj tariffs.csv ]    [ Generuj ]");

      Tariff_Grid.Attach
        (Label,
         Left   => 0,
         Top    => 3,
         Width  => 3,
         Height => 1);

      Tariff_Frame.Add (Tariff_Grid);

      Container.Pack_Start
        (Tariff_Frame,
         False,
         False,
         0);


   end Create;

end GUI.Project.Tariffs;
