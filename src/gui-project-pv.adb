with Gtk.Frame;
with Gtk.Grid;
with Gtk.Label;
with Gtk.Button;
with Gtk.Check_Button;
with Gtk.Combo_Box_Text;
with Gtk.Widget;
with Gtk.Enums;

package body GUI.Project.PV is

   use Gtk.Box;
   use Gtk.Frame;
   use Gtk.Grid;
   use Gtk.Label;
   use Gtk.Button;
   use Gtk.Check_Button;
   use Gtk.Enums;

   PV_List_Box   : Gtk_Box;
   PV_Count      : Natural := 0;

   procedure Add_PV_Row;

   procedure Add_PV_Clicked
     (Button : access Gtk.Button.Gtk_Button_Record'Class)
   is
      pragma Unreferenced (Button);
   begin
      Add_PV_Row;
   end Add_PV_Clicked;


   procedure Add_PV_Row is

      Frame : Gtk_Frame;
      Grid  : Gtk_Grid;

      Enabled : Gtk_Check_Button;

      Technology : Gtk.Combo_Box_Text.Gtk_Combo_Box_Text;
      Mounting   : Gtk.Combo_Box_Text.Gtk_Combo_Box_Text;

      Label         : Gtk_Label;
      Remove_Button : Gtk_Button;

   begin

      PV_Count := PV_Count + 1;

      Gtk_New
        (Frame,
         "PV " & Natural'Image (PV_Count));

      Gtk_New (Grid);

      Grid.Set_Row_Spacing (6);
      Grid.Set_Column_Spacing (8);
      Grid.Set_Border_Width (8);

      ---------------------------------------------------------
      -- Name
      ---------------------------------------------------------

      Add_Entry
        (Grid,
         Row          => 0,
         Caption      => "Nazwa:",
         Default_Text => "PV " & Natural'Image (PV_Count));

      ---------------------------------------------------------
      -- Enabled
      ---------------------------------------------------------

      Gtk.Check_Button.Gtk_New
        (Enabled,
         "Aktywne");

      Enabled.Set_Active (True);

      Grid.Attach
        (Enabled,
         Left   => 1,
         Top    => 1,
         Width  => 1,
         Height => 1);


      ---------------------------------------------------------
      -- Peak power
      ---------------------------------------------------------

      Add_Entry
        (Grid,
         Row          => 2,
         Caption      => "Moc szczytowa:",
         Default_Text => "",
         Unit_Text    => "kWp");


      ---------------------------------------------------------
      -- Technology
      ---------------------------------------------------------

      Gtk_New (Label, "Technologia:");
      Label.Set_Halign (Gtk.Widget.Align_Start);

      Gtk.Combo_Box_Text.Gtk_New (Technology);

      Technology.Append_Text ("crystSi");
      Technology.Append_Text ("crystSi2025");
      Technology.Append_Text ("CIS");
      Technology.Append_Text ("CdTe");
      Technology.Append_Text ("Unknown");

      Technology.Set_Active (1);

      Grid.Attach
        (Label,
         Left   => 0,
         Top    => 3,
         Width  => 1,
         Height => 1);

      Grid.Attach
        (Technology,
         Left   => 1,
         Top    => 3,
         Width  => 2,
         Height => 1);


      ---------------------------------------------------------
      -- Tilt
      ---------------------------------------------------------

      Add_Entry
        (Grid,
         Row          => 4,
         Caption      => "Nachylenie:",
         Default_Text => "35.0",
         Unit_Text    => "°");

      ---------------------------------------------------------
      -- Azimuth
      ---------------------------------------------------------

      Add_Entry
        (Grid,
         Row          => 5,
         Caption      => "Azymut:",
         Default_Text => "0.0",
         Unit_Text    => "°");


      ---------------------------------------------------------
      -- Loss
      ---------------------------------------------------------

      Add_Entry
        (Grid,
         Row          => 6,
         Caption      => "Straty systemowe:",
         Default_Text => "0.14");


      ---------------------------------------------------------
      -- Mounting
      ---------------------------------------------------------

      Gtk_New (Label, "Montaż:");
      Label.Set_Halign (Gtk.Widget.Align_Start);

      Gtk.Combo_Box_Text.Gtk_New (Mounting);

      Mounting.Append_Text ("building");
      Mounting.Append_Text ("free");

      Mounting.Set_Active (0);

      Grid.Attach
        (Label,
         Left   => 0,
         Top    => 7,
         Width  => 1,
         Height => 1);

      Grid.Attach
        (Mounting,
         Left   => 1,
         Top    => 7,
         Width  => 2,
         Height => 1);


      ---------------------------------------------------------
      -- Remove
      ---------------------------------------------------------

      Gtk_New
        (Remove_Button,
         "Usuń PV");

      Grid.Attach
        (Remove_Button,
         Left   => 1,
         Top    => 8,
         Width  => 1,
         Height => 1);

      Remove_Callbacks.Connect
        (Remove_Button,
         "clicked",
         Remove_Callbacks.To_Marshaller
           (Remove_Row'Access),
         Gtk.Widget.Gtk_Widget (Frame));


      Frame.Add (Grid);

      PV_List_Box.Pack_Start
        (Frame,
         Expand  => False,
         Fill    => True,
         Padding => 4);

      Frame.Show_All;

   end Add_PV_Row;

   procedure Create
     (Container : out Gtk.Box.Gtk_Box) is

      PV_Frame      : Gtk_Frame;
      Add_PV_Button : Gtk_Button;

   begin

      Gtk_New
        (PV_Frame,
         "Instalacje PV");

      Gtk_New
        (Container,
         Orientation_Vertical,
         6);

      Gtk_New
        (PV_List_Box,
         Orientation_Vertical,
         6);

      Container.Pack_Start
        (PV_List_Box,
         False,
         False,
         0);

      Gtk_New
        (Add_PV_Button,
         "+ Dodaj PV");

      Button_Callbacks.Connect
        (Add_PV_Button,
         "clicked",
         Button_Callbacks.To_Marshaller
           (Add_PV_Clicked'Access));

      Container.Pack_Start
        (Add_PV_Button,
         False,
         False,
         4);

   end Create;

end GUI.Project.PV;
