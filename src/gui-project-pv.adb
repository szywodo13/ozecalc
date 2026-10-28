with Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with Ada.Text_IO;
with Ada.Containers.Vectors;

with Gtk.Frame;
with Gtk.Grid;
with Gtk.Label;
with Gtk.Button;
with Gtk.Check_Button;
with Gtk.Combo_Box_Text;
with Gtk.Widget;
with Gtk.Enums;
with Gtk.Scrolled_Window;
with Gtk.GEntry;

with OZE;
with OZE.Production;

package body GUI.Project.PV is

   use Gtk.Box;
   use Gtk.Frame;
   use Gtk.Grid;
   use Gtk.Label;
   use Gtk.Button;
   use Gtk.Check_Button;
   use Gtk.Enums;

   use type Gtk.Widget.Gtk_Widget;

   type PV_Row_Data is record
      Frame       : Gtk_Frame;

      Name_Field  : Gtk.GEntry.Gtk_Entry;
      Enabled     : Gtk_Check_Button;

      Peak_Field  : Gtk.GEntry.Gtk_Entry;
      Technology  : Gtk.Combo_Box_Text.Gtk_Combo_Box_Text;

      Tilt_Field    : Gtk.GEntry.Gtk_Entry;
      Azimuth_Field : Gtk.GEntry.Gtk_Entry;
      Loss_Field    : Gtk.GEntry.Gtk_Entry;

      Mounting    : Gtk.Combo_Box_Text.Gtk_Combo_Box_Text;
   end record;

   package PV_Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => PV_Row_Data);

   PV_Rows : PV_Row_Vectors.Vector;

   PV_List_Box   : Gtk_Box;
   PV_Count      : Natural := 0;

   package Real_IO is
     new Ada.Text_IO.Float_IO (OZE.Real);

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


   function Current_Sources
     return OZE.Project.PV_Vectors.Vector
   is
      Result : OZE.Project.PV_Vectors.Vector;
   begin

      for Row of PV_Rows loop

         declare
            Technology_Text : constant String :=
              Row.Technology.Get_Active_Text;

            Mounting_Text : constant String :=
              Row.Mounting.Get_Active_Text;

            Technology_Value : OZE.Production.PV_Technology;
            Mounting_Value   : OZE.Production.Mounting_Type;

         begin

            if Technology_Text = "crystSi" then
               Technology_Value :=
                 OZE.Production.Crystalline_Silicon;

            elsif Technology_Text = "crystSi2025" then
               Technology_Value :=
                 OZE.Production.Crystalline_Silicon_2025;

            elsif Technology_Text = "CIS" then
               Technology_Value :=
                 OZE.Production.CIS;

            elsif Technology_Text = "CdTe" then
               Technology_Value :=
                 OZE.Production.CdTe;

            else
               Technology_Value :=
                 OZE.Production.Unknown;
            end if;


            if Mounting_Text = "building" then
               Mounting_Value :=
                 OZE.Production.Building;
            else
               Mounting_Value :=
                 OZE.Production.Free;
            end if;


            OZE.Project.PV_Vectors.Append
              (Result,
               OZE.Project.PV_Source'
                 (Name =>
                      Ada.Strings.Unbounded.To_Unbounded_String
                    (Row.Name_Field.Get_Text),

                  Enabled =>
                    Row.Enabled.Get_Active,

                  Config =>
                    (Peak_Power =>
                         OZE.Energy'Value
                       (Row.Peak_Field.Get_Text),

                     Technology =>
                       Technology_Value,

                     Tilt =>
                       OZE.Real'Value
                         (Row.Tilt_Field.Get_Text),

                     Azimuth =>
                       OZE.Real'Value
                         (Row.Azimuth_Field.Get_Text),

                     System_Loss =>
                       OZE.Real'Value
                         (Row.Loss_Field.Get_Text),

                     Mounting =>
                       Mounting_Value)));

         end;

      end loop;

      return Result;

   end Current_Sources;

   procedure Add_PV_Row;
   procedure Add_PV_Row (Source : OZE.Project.PV_Source);

   procedure Add_PV_Clicked
     (Button : access Gtk.Button.Gtk_Button_Record'Class)
   is
      pragma Unreferenced (Button);
   begin
      Add_PV_Row;
   end Add_PV_Clicked;

   procedure Remove_PV_Clicked
     (Button : access Gtk.Button.Gtk_Button_Record'Class;
      Frame  : Gtk.Widget.Gtk_Widget)
   is
   begin
      if not PV_Rows.Is_Empty then

         for I in PV_Rows.First_Index .. PV_Rows.Last_Index
         loop
            if Gtk.Widget.Gtk_Widget (PV_Rows (I).Frame) = Frame
            then
               PV_Rows.Delete (I);
               exit;
            end if;
         end loop;

      end if;

      Remove_Row (Button, Frame);
   end Remove_PV_Clicked;


   procedure Add_PV_Row is

      Grid  : Gtk_Grid;

      Label         : Gtk_Label;
      Remove_Button : Gtk_Button;

      Row_Data : PV_Row_Data;

   begin

      PV_Count := PV_Count + 1;

      Gtk_New
        (Row_Data.Frame,
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
         Default_Text => "PV " & Natural'Image (PV_Count),
         Field => Row_Data.Name_Field);

      ---------------------------------------------------------
      -- Enabled
      ---------------------------------------------------------

      Gtk.Check_Button.Gtk_New
        (Row_Data.Enabled,
         "Aktywne");

      Row_Data.Enabled.Set_Active (True);

      Grid.Attach
        (Row_Data.Enabled,
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
         Unit_Text    => "kWp",
         Field => Row_Data.Peak_Field);

      ---------------------------------------------------------
      -- Technology
      ---------------------------------------------------------

      Gtk_New (Label, "Technologia:");
      Label.Set_Halign (Gtk.Widget.Align_Start);

      Gtk.Combo_Box_Text.Gtk_New (Row_Data.Technology);

      Row_Data.Technology.Append_Text ("crystSi");
      Row_Data.Technology.Append_Text ("crystSi2025");
      Row_Data.Technology.Append_Text ("CIS");
      Row_Data.Technology.Append_Text ("CdTe");
      Row_Data.Technology.Append_Text ("Unknown");

      Row_Data.Technology.Set_Active (0);

      Grid.Attach
        (Label,
         Left   => 0,
         Top    => 3,
         Width  => 1,
         Height => 1);

      Grid.Attach
        (Row_Data.Technology,
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
         Unit_Text    => "°",
         Tooltip_Text =>
           "Nachylenie od poziomu: 0° = poziomo, 90° = pionowo",
         Field => Row_Data.Tilt_Field);

      ---------------------------------------------------------
      -- Azimuth
      ---------------------------------------------------------

      Add_Entry
        (Grid,
         Row          => 5,
         Caption      => "Azymut:",
         Default_Text => "0.0",
         Unit_Text    => "°",
         Tooltip_Text =>
           "PVGIS: 0° = południe, +90° = zachód, -90° = wschód",
         Field => Row_Data.Azimuth_Field);

      ---------------------------------------------------------
      -- Loss
      ---------------------------------------------------------

      Add_Entry
        (Grid,
         Row          => 6,
         Caption      => "Straty systemowe:",
         Default_Text => "0.14",
         Field => Row_Data.Loss_Field);

      ---------------------------------------------------------
      -- Mounting
      ---------------------------------------------------------

      Gtk_New (Label, "Montaż:");
      Label.Set_Halign (Gtk.Widget.Align_Start);

      Gtk.Combo_Box_Text.Gtk_New (Row_Data.Mounting);

      Row_Data.Mounting.Append_Text ("building");
      Row_Data.Mounting.Append_Text ("free");

      Row_Data.Mounting.Set_Active (0);

      Grid.Attach
        (Label,
         Left   => 0,
         Top    => 7,
         Width  => 1,
         Height => 1);

      Grid.Attach
        (Row_Data.Mounting,
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
           (Remove_PV_Clicked'Access),
         Gtk.Widget.Gtk_Widget (Row_Data.Frame));

      Row_Data.Frame.Add (Grid);

      PV_List_Box.Pack_Start
        (Row_Data.Frame,
         Expand  => False,
         Fill    => True,
         Padding => 4);

      PV_Rows.Append (Row_Data);
      Row_Data.Frame.Show_All;

   end Add_PV_Row;

   procedure Add_PV_Row
     (Source : OZE.Project.PV_Source)
   is

      Grid  : Gtk_Grid;

      Label         : Gtk_Label;
      Remove_Button : Gtk_Button;

      Row_Data : PV_Row_Data;

   begin
      PV_Count := PV_Count + 1;

      Gtk_New
        (Row_Data.Frame,
         "PV " & Natural'Image (PV_Count));

      Gtk_New (Grid);

      Grid.Set_Row_Spacing (6);
      Grid.Set_Column_Spacing (8);
      Grid.Set_Border_Width (8);

      Add_Entry
        (Grid,
         Row          => 0,
         Caption      => "Nazwa:",
         Default_Text =>
           Ada.Strings.Unbounded.To_String (Source.Name),
         Field => Row_Data.Name_Field);

      Gtk.Check_Button.Gtk_New
        (Row_Data.Enabled,
         "Aktywne");

      Row_Data.Enabled.Set_Active (Source.Enabled);

      Grid.Attach
        (Row_Data.Enabled,
         Left   => 1,
         Top    => 1,
         Width  => 1,
         Height => 1);

      Add_Entry
        (Grid,
         Row          => 2,
         Caption      => "Moc szczytowa:",
         Default_Text => Img (Source.Config.Peak_Power),
         Unit_Text    => "kWp",
         Field => Row_Data.Peak_Field);

      Gtk_New (Label, "Technologia:");
      Label.Set_Halign (Gtk.Widget.Align_Start);

      Gtk.Combo_Box_Text.Gtk_New (Row_Data.Technology);

      Row_Data.Technology.Append_Text ("crystSi");
      Row_Data.Technology.Append_Text ("crystSi2025");
      Row_Data.Technology.Append_Text ("CIS");
      Row_Data.Technology.Append_Text ("CdTe");
      Row_Data.Technology.Append_Text ("Unknown");

      case Source.Config.Technology is
      when OZE.Production.Crystalline_Silicon =>
         Row_Data.Technology.Set_Active (0);

      when OZE.Production.Crystalline_Silicon_2025 =>
         Row_Data.Technology.Set_Active (1);

      when OZE.Production.CIS =>
         Row_Data.Technology.Set_Active (2);

      when OZE.Production.CdTe =>
         Row_Data.Technology.Set_Active (3);

      when OZE.Production.Unknown =>
         Row_Data.Technology.Set_Active (4);
      end case;

      Grid.Attach
        (Label,
         Left   => 0,
         Top    => 3,
         Width  => 1,
         Height => 1);

      Grid.Attach
        (Row_Data.Technology,
         Left   => 1,
         Top    => 3,
         Width  => 2,
         Height => 1);

      Add_Entry
        (Grid,
         Row          => 4,
         Caption      => "Nachylenie:",
         Default_Text => Img (Source.Config.Tilt),
         Unit_Text    => "°",
         Tooltip_Text =>
           "Nachylenie od poziomu: 0° = poziomo, 90° = pionowo",
         Field => Row_Data.Tilt_Field);

      Add_Entry
        (Grid,
         Row          => 5,
         Caption      => "Azymut:",
         Default_Text => Img (Source.Config.Azimuth),
         Unit_Text    => "°",
         Tooltip_Text =>
           "PVGIS: 0° = południe, +90° = zachód, -90° = wschód",
         Field => Row_Data.Azimuth_Field);

      Add_Entry
        (Grid,
         Row          => 6,
         Caption      => "Straty systemowe:",
         Default_Text => Img (Source.Config.System_Loss),
         Field => Row_Data.Loss_Field);

      Gtk_New (Label, "Montaż:");
      Label.Set_Halign (Gtk.Widget.Align_Start);

      Gtk.Combo_Box_Text.Gtk_New (Row_Data.Mounting);

      Row_Data.Mounting.Append_Text ("building");
      Row_Data.Mounting.Append_Text ("free");

      case Source.Config.Mounting is
      when OZE.Production.Building =>
         Row_Data.Mounting.Set_Active (0);

      when OZE.Production.Free =>
         Row_Data.Mounting.Set_Active (1);
      end case;

      Grid.Attach
        (Label,
         Left   => 0,
         Top    => 7,
         Width  => 1,
         Height => 1);

      Grid.Attach
        (Row_Data.Mounting,
         Left   => 1,
         Top    => 7,
         Width  => 2,
         Height => 1);

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
           (Remove_PV_Clicked'Access),
         Gtk.Widget.Gtk_Widget (Row_Data.Frame));

      Row_Data.Frame.Add (Grid);

      PV_List_Box.Pack_Start
        (Row_Data.Frame,
         Expand  => False,
         Fill    => True,
         Padding => 4);

      PV_Rows.Append (Row_Data);
      Row_Data.Frame.Show_All;

   end Add_PV_Row;

   procedure Create
     (Container : out Gtk.Box.Gtk_Box) is

      PV_Frame      : Gtk_Frame;
      Add_PV_Button : Gtk_Button;

      PV_Scrolled : Gtk.Scrolled_Window.Gtk_Scrolled_Window;

   begin

      PV_Count := 0;
      PV_Rows.Clear;

      Gtk_New
        (PV_Frame,
         "Instalacje PV");

      Gtk_New
        (Container,
         Orientation_Vertical,
         6);

      Gtk_New
        (PV_List_Box,
         Orientation_Horizontal,
         6);

      Gtk.Scrolled_Window.Gtk_New (PV_Scrolled);

      PV_Scrolled.Set_Policy
        (Gtk.Enums.Policy_Automatic,
         Gtk.Enums.Policy_Never);

      PV_Scrolled.Add (PV_List_Box);

      if GUI.Project_Loaded then
         declare
            Data : constant OZE.Project.Project_Data :=
              GUI.Current_Project;
         begin
            for Source of Data.PV_Sources loop
               Add_PV_Row (Source);
            end loop;
         end;
      end if;

      Container.Pack_Start
        (PV_Scrolled,
         False,
         True,
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
