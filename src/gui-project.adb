with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with Gtk.Frame;
with Gtk.Scrolled_Window;
with Gtk.Label;
with Gtk.Enums;
with Gtk.Image;
with Gtk.Text_View;
with Gtk.Text_Buffer;
with Gtk.Text_Iter;

with OZE;

with GUI.Project.PV;
with GUI.Project.Batteries;
with GUI.Project.Load;
with GUI.Project.Tariffs;
with GUI.Project.Production;

package body GUI.Project is

   use Gtk.Box;
   use Gtk.Frame;
   use Gtk.Grid;
   use Gtk.Label;
   use Gtk.GEntry;
   use Gtk.Enums;

   Name_Field       : Gtk.GEntry.Gtk_Entry;
   Latitude_Field   : Gtk.GEntry.Gtk_Entry;
   Longitude_Field  : Gtk.GEntry.Gtk_Entry;
   Timezone_Field   : Gtk.GEntry.Gtk_Entry;
   Grid_Limit_Field : Gtk.GEntry.Gtk_Entry;
   Tariff_Profile_Field : Gtk.GEntry.Gtk_Entry;

   Description_Buffer : Gtk.Text_Buffer.Gtk_Text_Buffer;

   package Real_IO is
     new Ada.Text_IO.Float_IO (OZE.Real);

   ------------------------------------------------------------
   --  HELPERS
   ------------------------------------------------------------

   function Img (Value : OZE.Real) return String is
      Buffer : String (1 .. 32);
   begin
      Real_IO.Put
        (To   => Buffer,
         Item => Value,
         Aft  => 2,
         Exp  => 0);

      return Ada.Strings.Fixed.Trim
        (Buffer, Ada.Strings.Both);
   end Img;


   function Img (Value : OZE.Energy) return String is
   begin
      return Img (OZE.Real (Value));
   end Img;

   function Description_Text return String is
      First : Gtk.Text_Iter.Gtk_Text_Iter;
      Last  : Gtk.Text_Iter.Gtk_Text_Iter;
   begin
      Description_Buffer.Get_Bounds (First, Last);

      return Description_Buffer.Get_Text
        (First,
         Last,
         Include_Hidden_Chars => True);
   end Description_Text;

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
     (Grid         : Gtk.Grid.Gtk_Grid;
      Row          : Glib.Gint;
      Caption      : String;
      Default_Text : String;
      Field        : out Gtk.GEntry.Gtk_Entry;
      Unit_Text    : String := "";
      Tooltip_Text : String := "")
   is
      Label : Gtk_Label;
      Unit  : Gtk_Label;
   begin
      Gtk_New (Label, Caption);
      Label.Set_Halign (Gtk.Widget.Align_Start);

      Gtk.GEntry.Gtk_New (Field);
      Field.Set_Text (Default_Text);

      if Tooltip_Text /= "" then
         Field.Set_Tooltip_Text (Tooltip_Text);
      end if;

      Grid.Attach (Label, 0, Row, 1, 1);
      Grid.Attach (Field, 1, Row, 1, 1);

      if Unit_Text /= "" then
         Gtk_New (Unit, Unit_Text);
         Unit.Set_Halign (Gtk.Widget.Align_Start);
         Grid.Attach (Unit, 2, Row, 1, 1);
      end if;
   end Add_Entry;

   procedure Add_Entry
     (Grid         : Gtk.Grid.Gtk_Grid;
      Row          : Glib.Gint;
      Caption      : String;
      Default_Text : String;
      Unit_Text    : String := "";
      Tooltip_Text : String := "")
   is
      Field : Gtk.GEntry.Gtk_Entry;
   begin
      Add_Entry
        (Grid         => Grid,
         Row          => Row,
         Caption      => Caption,
         Default_Text => Default_Text,
         Field        => Field,
         Unit_Text    => Unit_Text,
         Tooltip_Text => Tooltip_Text);
   end Add_Entry;

   ------------------------------------------------------------
   --  CURRENT DATA FUNCTION
   ------------------------------------------------------------

   function Current_Data
     return OZE.Project.Project_Data
   is
      Result : OZE.Project.Project_Data;
   begin

      if GUI.Project_Loaded then
         Result.Version := GUI.Current_Project.Version;
      else
         Result.Version := 1;
      end if;

      Result.Name :=
        Ada.Strings.Unbounded.To_Unbounded_String
          (Name_Field.Get_Text);

      Result.Description :=
        Ada.Strings.Unbounded.To_Unbounded_String
          (Description_Text);

      Result.Location.Site.Latitude :=
        OZE.Real'Value
          (Latitude_Field.Get_Text);

      Result.Location.Site.Longitude :=
        OZE.Real'Value
          (Longitude_Field.Get_Text);

      Result.Location.Timezone :=
        Ada.Strings.Unbounded.To_Unbounded_String
          (Timezone_Field.Get_Text);

      Result.Grid_Limit :=
        OZE.Energy'Value
          (Grid_Limit_Field.Get_Text);

      Result.Tariff_Profile :=
        Ada.Strings.Unbounded.To_Unbounded_String
          (Tariff_Profile_Field.Get_Text);

      Result.PV_Sources :=
        GUI.Project.PV.Current_Sources;

      Result.Batteries :=
        GUI.Project.Batteries.Current_Batteries;

      return Result;

   end Current_Data;

   ------------------------------------------------------------
   --  CREATE PAGE
   ------------------------------------------------------------

   procedure Create
     (Page : out Gtk.Box.Gtk_Box)
   is
      Scrolled : Gtk.Scrolled_Window.Gtk_Scrolled_Window;
      Content  : Gtk.Box.Gtk_Box;

      Top_Box : Gtk.Box.Gtk_Box;

      Description_Label  : Gtk_Label;
      Description_View   : Gtk.Text_View.Gtk_Text_View;
      Description_Scroll : Gtk.Scrolled_Window.Gtk_Scrolled_Window;

      Right_Box : Gtk.Box.Gtk_Box;
      Logo      : Gtk.Image.Gtk_Image;

      Project_Frame    : Gtk_Frame;

      Project_Grid : Gtk_Grid;

      PV_Container         : Gtk.Box.Gtk_Box;
      Battery_Container    : Gtk.Box.Gtk_Box;
      Load_Container       : Gtk.Box.Gtk_Box;
      Tariffs_Container    : Gtk.Box.Gtk_Box;
      Production_Container : GTk.Box.Gtk_Box;

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

      Gtk_New
        (Top_Box,
         Gtk.Enums.Orientation_Horizontal,
         12);

      Gtk_New
        (Right_Box,
         Gtk.Enums.Orientation_Vertical,
         12);

      Gtk.Image.Gtk_New_From_Resource
        (Logo,
         "/ozecalc/logo_gui.png");

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

      Gtk_New
        (Description_Label,
         "Opis:");

      Description_Label.Set_Halign
        (Gtk.Widget.Align_Start);

      Gtk.Text_View.Gtk_New (Description_View);

      Description_Buffer :=
        Description_View.Get_Buffer;

      if GUI.Project_Loaded then
         Description_Buffer.Set_Text
           (Ada.Strings.Unbounded.To_String
              (GUI.Current_Project.Description));
      else
         Description_Buffer.Set_Text("...");
      end if;

      Gtk.Scrolled_Window.Gtk_New
        (Description_Scroll);

      Description_Scroll.Set_Policy
        (Gtk.Enums.Policy_Never,
         Gtk.Enums.Policy_Automatic);

      Description_Scroll.Set_Shadow_Type
        (Gtk.Enums.Shadow_In);

      Description_Scroll.Add
        (Description_View);

      Description_View.Set_Wrap_Mode
        (Gtk.Enums.Wrap_Word_Char);

      Description_View.Set_Hexpand (False);
      Description_Scroll.Set_Hexpand (False);
      Description_Scroll.Set_Halign
        (Gtk.Widget.Align_Start);

      Description_Scroll.Set_Size_Request (400, 80);

      if GUI.Project_Loaded then

         declare
            Data : constant OZE.Project.Project_Data :=
              GUI.Current_Project;
         begin

            Add_Entry
              (Project_Grid,
               Row          => 0,
               Caption      => "Nazwa projektu:",
               Default_Text =>
                 Ada.Strings.Unbounded.To_String (Data.Name),
               Field        => Name_Field);

            Add_Entry
              (Project_Grid,
               Row          => 1,
               Caption      => "Szerokość geograficzna:",
               Default_Text =>
                 Img (Data.Location.Site.Latitude),
               Unit_Text    => "°N",
               Field        => Latitude_Field);

            Add_Entry
              (Project_Grid,
               Row          => 2,
               Caption      => "Długość geograficzna:",
               Default_Text =>
                 Img (Data.Location.Site.Longitude),
               Unit_Text    => "°E",
               Field        => Longitude_Field);

            Add_Entry
              (Project_Grid,
               Row          => 3,
               Caption      => "Strefa czasowa:",
               Default_Text =>
                 Ada.Strings.Unbounded.To_String
                   (Data.Location.Timezone),
               Field        => Timezone_Field);

            Add_Entry
              (Project_Grid,
               Row          => 4,
               Caption      => "Limit mocy sieci:",
               Default_Text => Img (Data.Grid_Limit),
               Unit_Text    => "kW",
               Field        => Grid_Limit_Field);

            Add_Entry
              (Grid         => Project_Grid,
               Row          => 5,
               Caption      => "Profil taryfowy:",
               Default_Text => Ada.Strings.Unbounded.To_String
                 (Data.Tariff_Profile),
               Field        => Tariff_Profile_Field);

         end;

      else

         Add_Entry
           (Grid         => Project_Grid,
            Row          => 0,
            Caption      => "Nazwa projektu:",
            Default_Text => "Nowy projekt",
            Field        => Name_Field);

         Add_Entry
           (Grid         => Project_Grid,
            Row          => 1,
            Caption      => "Szerokość geograficzna:",
            Default_Text => "",
            Field        => Latitude_Field,
            Unit_Text    => "°N");

         Add_Entry
           (Grid         => Project_Grid,
            Row          => 2,
            Caption      => "Długość geograficzna:",
            Default_Text => "",
            Field        => Longitude_Field,
            Unit_Text    => "°E");

         Add_Entry
           (Grid         => Project_Grid,
            Row          => 3,
            Caption      => "Strefa czasowa:",
            Default_Text => "Europe/Warsaw",
            Field        => Timezone_Field);

         Add_Entry
           (Grid         => Project_Grid,
            Row          => 4,
            Caption      => "Limit mocy sieci:",
            Default_Text => "",
            Field        => Grid_Limit_Field,
            Unit_Text    => "kW");

         Add_Entry
           (Grid         => Project_Grid,
            Row          => 5,
            Caption      => "Profil taryfowy:",
            Default_Text => "",
            Field        => Tariff_Profile_Field);

      end if;

      Project_Grid.Attach
        (Description_Label,
         Left   => 3,
         Top    => 0,
         Width  => 1,
         Height => 1);

      Project_Grid.Attach
        (Description_Scroll,
         Left   => 3,
         Top    => 1,
         Width  => 2,
         Height => 4);

      Project_Frame.Add (Project_Grid);

      Top_Box.Pack_Start
        (Project_Frame,
         Expand  => True,
         Fill    => True,
         Padding => 0);

      ---------------------------------------------------------
      -- TARIFF
      ---------------------------------------------------------

      GUI.Project.Tariffs.Create (Tariffs_Container);

      Right_Box.Pack_Start
        (Logo,
         Expand  => False,
         Fill    => False,
         Padding => 0);

      Right_Box.Pack_Start
        (Tariffs_Container,
         Expand  => False,
         Fill    => True,
         Padding => 0);

      Top_Box.Pack_Start
        (Right_Box,
         Expand  => True,
         Fill    => True,
         Padding => 0);

      Content.Pack_Start
        (Top_Box,
         Expand  => False,
         Fill    => True,
         Padding => 0);


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
      -- PRODUCTION
      ---------------------------------------------------------

      GUI.Project.Production.Create
        (Production_Container);

      Content.Pack_Start
        (Production_Container,
         Expand  => False,
         Fill    => True,
         Padding => 4);

      ---------------------------------------------------------
      -- LOAD
      ---------------------------------------------------------

      GUI.Project.Load.Create (Load_Container);

      Content.Pack_Start
        (Load_Container,
         False,
         True,
         0);

   end Create;

end GUI.Project;
