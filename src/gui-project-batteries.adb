with Gtk.Frame;
with Gtk.Grid;
with Gtk.Button;
with Gtk.Check_Button;
with Gtk.Widget;
with Gtk.Enums;
with Gtk.Scrolled_Window;

package body GUI.Project.Batteries is

   use Gtk.Box;
   use Gtk.Frame;
   use Gtk.Grid;
   use Gtk.Button;
   use Gtk.Check_Button;
   use Gtk.Enums;

   Battery_List_Box : Gtk_Box;
   Battery_Count : Natural := 0;

   procedure Add_Battery_Row;

   procedure Add_Battery_Clicked
     (Button : access Gtk.Button.Gtk_Button_Record'Class)
   is
      pragma Unreferenced (Button);
   begin
      Add_Battery_Row;
   end Add_Battery_Clicked;


   procedure Add_Battery_Row is

      Frame : Gtk_Frame;
      Grid  : Gtk_Grid;

      Enabled       : Gtk_Check_Button;
      Remove_Button : Gtk_Button;

   begin

      Battery_Count := Battery_Count + 1;

      Gtk_New
        (Frame,
         "Magazyn " & Natural'Image (Battery_Count));

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
         Default_Text =>
           "Magazyn " & Natural'Image (Battery_Count));

      ---------------------------------------------------------
      -- Enabled
      ---------------------------------------------------------

      Gtk.Check_Button.Gtk_New
        (Enabled,
         "Aktywny");

      Enabled.Set_Active (True);

      Grid.Attach
        (Enabled,
         Left   => 1,
         Top    => 1,
         Width  => 1,
         Height => 1);


      ---------------------------------------------------------
      -- Capacity
      ---------------------------------------------------------

      Add_Entry
        (Grid,
         Row          => 2,
         Caption      => "Pojemność:",
         Default_Text => "",
         Unit_Text    => "kWh");


      ---------------------------------------------------------
      -- Initial SOC
      ---------------------------------------------------------

      Add_Entry
        (Grid,
         Row          => 3,
         Caption      => "SOC początkowy:",
         Default_Text => "0.50");


      ---------------------------------------------------------
      -- Minimum SOC
      ---------------------------------------------------------

      Add_Entry
        (Grid,
         Row          => 4,
         Caption      => "SOC minimalny:",
         Default_Text => "0.10");


      ---------------------------------------------------------
      -- Maximum power
      ---------------------------------------------------------

      Add_Entry
        (Grid,
         Row          => 5,
         Caption      => "Moc maksymalna:",
         Default_Text => "",
         Unit_Text    => "kW");


      ---------------------------------------------------------
      -- Efficiency
      ---------------------------------------------------------

      Add_Entry
        (Grid,
         Row          => 6,
         Caption      => "Sprawność:",
         Default_Text => "0.95");


      ---------------------------------------------------------
      -- Remove
      ---------------------------------------------------------

      Gtk_New
        (Remove_Button,
         "Usuń magazyn");

      Grid.Attach
        (Remove_Button,
         Left   => 1,
         Top    => 7,
         Width  => 1,
         Height => 1);

      Remove_Callbacks.Connect
        (Remove_Button,
         "clicked",
         Remove_Callbacks.To_Marshaller
           (Remove_Row'Access),
         Gtk.Widget.Gtk_Widget (Frame));


      Frame.Add (Grid);

      Battery_List_Box.Pack_Start
        (Frame,
         Expand  => False,
         Fill    => True,
         Padding => 4);

      Frame.Show_All;

   end Add_Battery_Row;


   procedure Create
     (Container : out Gtk.Box.Gtk_Box) is

      Battery_Scrolled : Gtk.Scrolled_Window.Gtk_Scrolled_Window;

      Battery_Frame    : Gtk_Frame;
      Battery_Box : Gtk_Box;
      Add_Battery_Button : Gtk_Button;

   begin

      Gtk_New
        (Container,
         Orientation_Vertical,
         6);

      Gtk_New
        (Battery_Frame,
         "Magazyny energii");

      Gtk_New
        (Battery_Box,
         Orientation_Vertical,
         6);

      Gtk_New
        (Battery_List_Box,
         Orientation_Horizontal,
         6);

      Gtk.Scrolled_Window.Gtk_New (Battery_Scrolled);

      Battery_Scrolled.Set_Policy
        (Gtk.Enums.Policy_Automatic,
         Gtk.Enums.Policy_Never);

      Battery_Scrolled.Add (Battery_List_Box);

      Container.Pack_Start
        (Battery_Scrolled,
         False,
         True,
         0);

      Gtk_New
        (Add_Battery_Button,
         "+ Dodaj magazyn");

      Button_Callbacks.Connect
        (Add_Battery_Button,
         "clicked",
         Button_Callbacks.To_Marshaller
           (Add_Battery_Clicked'Access));

      Container.Pack_Start
        (Add_Battery_Button,
         False,
         False,
         4);

   end Create;

end GUI.Project.Batteries;
