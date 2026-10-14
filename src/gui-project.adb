with Gtk.Frame;
with Gtk.Scrolled_Window;
with Gtk.Label;
with Gtk.GEntry;
with Gtk.Enums;

with GUI.Project.PV;
with GUI.Project.Batteries;
with GUI.Project.Load;
with GUI.Project.Tariffs;

package body GUI.Project is

   use Gtk.Box;
   use Gtk.Frame;
   use Gtk.Grid;
   use Gtk.Label;
   use Gtk.Button;
   use Gtk.GEntry;
   use Gtk.Enums;

   ------------------------------------------------------------
   --  CALLBACKS
   ------------------------------------------------------------

   procedure Remove_Row
     (Button : access Gtk.Button.Gtk_Button_Record'Class;
      Row    : Gtk.Widget.Gtk_Widget)
   is
      pragma Unreferenced (Button);
   begin
      Row.Destroy;
   end Remove_Row;

   ------------------------------------------------------------
   --  HELPER: LABEL + ENTRY
   ------------------------------------------------------------

   procedure Add_Entry
     (Grid         : Gtk_Grid;
      Row          : Glib.Gint;
      Caption      : String;
      Default_Text : String;
      Unit_Text    : String := "")
   is
      Label : Gtk_Label;
      Field : Gtk_Entry;
      Unit  : Gtk_Label;
   begin

      Gtk_New (Label, Caption);
      Label.Set_Halign (Gtk.Widget.Align_Start);

      Gtk_New (Field);
      Field.Set_Text (Default_Text);
      Field.Set_Width_Chars (12);

      Grid.Attach
        (Label,
         Left   => 0,
         Top    => Row,
         Width  => 1,
         Height => 1);

      Grid.Attach
        (Field,
         Left   => 1,
         Top    => Row,
         Width  => 1,
         Height => 1);

      if Unit_Text /= "" then

         Gtk_New (Unit, Unit_Text);
         Unit.Set_Halign (Gtk.Widget.Align_Start);

         Grid.Attach
           (Unit,
            Left   => 2,
            Top    => Row,
            Width  => 1,
            Height => 1);

      end if;

   end Add_Entry;

   ------------------------------------------------------------
   --  CREATE PAGE
   ------------------------------------------------------------

   procedure Create
     (Page : out Gtk.Box.Gtk_Box)
   is
      Scrolled : Gtk.Scrolled_Window.Gtk_Scrolled_Window;
      Content  : Gtk.Box.Gtk_Box;

      Project_Frame    : Gtk_Frame;
      Production_Frame : Gtk_Frame;

      Project_Grid : Gtk_Grid;

      Button_Box : Gtk_Box;

      PV_Container      : Gtk.Box.Gtk_Box;
      Battery_Container : Gtk.Box.Gtk_Box;
      Load_Container    : Gtk.Box.Gtk_Box;
      Tariffs_Container : Gtk.Box.Gtk_Box;

   begin

      Gtk_New
        (Page,
         Orientation_Vertical,
         0);

      Gtk.Scrolled_Window.Gtk_New (Scrolled);

      Scrolled.Set_Policy
        (Gtk.Enums.Policy_Automatic,
         Gtk.Enums.Policy_Automatic);

      Gtk_New
        (Content,
         Orientation_Vertical,
         12);

      Content.Set_Border_Width (12);

      Scrolled.Add (Content);

      Page.Pack_Start
        (Scrolled,
         Expand  => True,
         Fill    => True,
         Padding => 0);

      ---------------------------------------------------------
      -- PROJECT GENERAL DATA
      ---------------------------------------------------------

      Gtk_New
        (Project_Frame,
         "Projekt");

      Gtk_New (Project_Grid);

      Project_Grid.Set_Row_Spacing (6);
      Project_Grid.Set_Column_Spacing (8);
      Project_Grid.Set_Border_Width (8);

      Add_Entry
        (Project_Grid,
         Row          => 0,
         Caption      => "Nazwa projektu:",
         Default_Text => "Nowy projekt");

      Add_Entry
        (Project_Grid,
         Row          => 1,
         Caption      => "Szerokość geograficzna:",
         Default_Text => "");

      Add_Entry
        (Project_Grid,
         Row          => 2,
         Caption      => "Długość geograficzna:",
         Default_Text => "");

      Add_Entry
        (Project_Grid,
         Row          => 3,
         Caption      => "Strefa czasowa:",
         Default_Text => "Europe/Warsaw");

      Add_Entry
        (Project_Grid,
         Row          => 4,
         Caption      => "Limit mocy sieci:",
         Default_Text => "",
         Unit_Text    => "kW");

      Project_Frame.Add (Project_Grid);

      Content.Pack_Start
        (Project_Frame,
         False,
         False,
         0);

      ---------------------------------------------------------
      -- PV
      ---------------------------------------------------------

      GUI.Project.PV.Create (PV_Container);

      Content.Pack_Start
        (PV_Container,
         False,
         True,
         0);

      ---------------------------------------------------------
      -- BATTERIES
      ---------------------------------------------------------

      GUI.Project.Batteries.Create (Battery_Container);

      Content.Pack_Start
        (Battery_Container,
         False,
         True,
         0);

      ---------------------------------------------------------
      -- LOAD
      ---------------------------------------------------------

      GUI.Project.Load.Create (Load_Container);

      Content.Pack_Start
        (Load_Container,
         False,
         True,
         0);

      ---------------------------------------------------------
      -- TARIFF
      ---------------------------------------------------------

      GUI.Project.Tariffs.Create (Tariffs_Container);

      Content.Pack_Start
        (Tariffs_Container,
         False,
         True,
         0);

      ---------------------------------------------------------
      -- PRODUCTION
      ---------------------------------------------------------

      Gtk_New
        (Production_Frame,
         "Produkcja");

      Gtk_New
        (Button_Box,
         Orientation_Horizontal,
         8);

      declare
         Load_Button     : Gtk_Button;
         Generate_Button : Gtk_Button;
      begin

         Gtk_New
           (Load_Button,
            "Wczytaj production.csv");

         Gtk_New
           (Generate_Button,
            "Generuj production");

         Button_Box.Pack_Start
           (Load_Button,
            False,
            False,
            0);

         Button_Box.Pack_Start
           (Generate_Button,
            False,
            False,
            0);

      end;

      Production_Frame.Add (Button_Box);

      Content.Pack_Start
        (Production_Frame,
         False,
         False,
         0);

   end Create;

end GUI.Project;
