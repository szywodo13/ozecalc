with Ada.Text_IO;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Containers.Vectors;

with Gtk.Frame;
with Gtk.Grid;
with Gtk.Button;
with Gtk.Check_Button;
with Gtk.Widget;
with Gtk.Enums;
with Gtk.Scrolled_Window;
with Gtk.GEntry;

with OZE;
with OZE.EMS;

package body GUI.Project.Batteries is

   use Gtk.Box;
   use Gtk.Frame;
   use Gtk.Grid;
   use Gtk.Button;
   use Gtk.Check_Button;
   use Gtk.Enums;
   use type Gtk.Widget.Gtk_Widget;

   type Battery_Row_Data is record
      Frame             : Gtk_Frame;

      Name_Field        : Gtk.GEntry.Gtk_Entry;
      Enabled           : Gtk_Check_Button;

      Capacity_Field    : Gtk.GEntry.Gtk_Entry;
      Initial_SOC_Field : Gtk.GEntry.Gtk_Entry;
      Minimum_SOC_Field : Gtk.GEntry.Gtk_Entry;
      Power_Field       : Gtk.GEntry.Gtk_Entry;
      Efficiency_Field  : Gtk.GEntry.Gtk_Entry;
   end record;

   package Battery_Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Battery_Row_Data);

   Battery_Rows : Battery_Row_Vectors.Vector;

   Battery_List_Box : Gtk_Box;
   Battery_Count : Natural := 0;

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


   function Current_Batteries
     return OZE.Project.Battery_Vectors.Vector
   is
      Result : OZE.Project.Battery_Vectors.Vector;
   begin

      for Row of Battery_Rows loop

         OZE.Project.Battery_Vectors.Append
           (Result,
            OZE.Project.Battery'
              (Name =>
                   Ada.Strings.Unbounded.To_Unbounded_String
                 (Row.Name_Field.Get_Text),

               Enabled =>
                 Row.Enabled.Get_Active,

               Config =>
                 (Capacity =>
                      OZE.Energy'Value
                    (Row.Capacity_Field.Get_Text),

                  Initial_SOC =>
                    OZE.EMS.State_Of_Charge'Value
                      (Row.Initial_SOC_Field.Get_Text),

                  Minimum_SOC =>
                    OZE.EMS.State_Of_Charge'Value
                      (Row.Minimum_SOC_Field.Get_Text),

                  P_Max =>
                    OZE.Energy'Value
                      (Row.Power_Field.Get_Text),

                  Efficiency =>
                    OZE.Efficiency'Value
                      (Row.Efficiency_Field.Get_Text))));

      end loop;

      return Result;

   end Current_Batteries;

   procedure Add_Battery_Row;
   procedure Add_Battery_Row(Battery : OZE.Project.Battery);

   procedure Add_Battery_Clicked
     (Button : access Gtk.Button.Gtk_Button_Record'Class)
   is
      pragma Unreferenced (Button);
   begin
      Add_Battery_Row;
   end Add_Battery_Clicked;

   procedure Remove_Battery_Clicked
     (Button : access Gtk.Button.Gtk_Button_Record'Class;
      Frame  : Gtk.Widget.Gtk_Widget)
   is
   begin
      if not Battery_Rows.Is_Empty then

         for I in Battery_Rows.First_Index .. Battery_Rows.Last_Index
         loop
            if Gtk.Widget.Gtk_Widget (Battery_Rows (I).Frame) = Frame
            then
               Battery_Rows.Delete (I);
               exit;
            end if;
         end loop;

      end if;

      Remove_Row (Button, Frame);
   end Remove_Battery_Clicked;


   procedure Add_Battery_Row is

      Grid  : Gtk_Grid;
      Remove_Button : Gtk_Button;

      Row_Data : Battery_Row_Data;

   begin

      Battery_Count := Battery_Count + 1;

      Gtk_New
        (Row_Data.Frame,
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
           "Magazyn " & Natural'Image (Battery_Count),
         Field        => Row_Data.Name_Field);

      ---------------------------------------------------------
      -- Enabled
      ---------------------------------------------------------

      Gtk.Check_Button.Gtk_New
        (Row_Data.Enabled,
         "Aktywny");

      Row_Data.Enabled.Set_Active (True);

      Grid.Attach
        (Row_Data.Enabled,
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
         Unit_Text    => "kWh",
         Field        => Row_Data.Capacity_Field);


      ---------------------------------------------------------
      -- Initial SOC
      ---------------------------------------------------------

      Add_Entry
        (Grid,
         Row          => 3,
         Caption      => "SOC początkowy:",
         Default_Text => "0.50",
        Field        => Row_Data.Initial_SOC_Field);


      ---------------------------------------------------------
      -- Minimum SOC
      ---------------------------------------------------------

      Add_Entry
        (Grid,
         Row          => 4,
         Caption      => "SOC minimalny:",
         Default_Text => "0.10",
         Field => Row_Data.Minimum_SOC_Field);


      ---------------------------------------------------------
      -- Maximum power
      ---------------------------------------------------------

      Add_Entry
        (Grid,
         Row          => 5,
         Caption      => "Moc maksymalna:",
         Default_Text => "",
         Unit_Text    => "kW",
         Field => Row_Data.Power_Field);


      ---------------------------------------------------------
      -- Efficiency
      ---------------------------------------------------------

      Add_Entry
        (Grid,
         Row          => 6,
         Caption      => "Sprawność:",
         Default_Text => "0.95",
        Field => Row_Data.Efficiency_Field);


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
           (Remove_Battery_Clicked'Access),
         Gtk.Widget.Gtk_Widget (Row_Data.Frame));


      Row_Data.Frame.Add (Grid);

      Battery_List_Box.Pack_Start
        (Row_Data.Frame,
         Expand  => False,
         Fill    => True,
         Padding => 4);

      Battery_Rows.Append (Row_Data);

      Row_Data.Frame.Show_All;

   end Add_Battery_Row;

   procedure Add_Battery_Row
     (Battery : OZE.Project.Battery)
   is

      Grid  : Gtk_Grid;
      Remove_Button : Gtk_Button;

      Row_Data : Battery_Row_Data;


   begin
      Battery_Count := Battery_Count + 1;

      Gtk_New
        (Row_Data.Frame,
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
           Ada.Strings.Unbounded.To_String (Battery.Name),
         Field => Row_Data.Name_Field);

      ---------------------------------------------------------
      -- Enabled
      ---------------------------------------------------------

      Gtk.Check_Button.Gtk_New
        (Row_Data.Enabled,
         "Aktywny");

      Row_Data.Enabled.Set_Active (Battery.Enabled);

      Grid.Attach
        (Row_Data.Enabled,
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
         Default_Text => Img (Battery.Config.Capacity),
         Unit_Text    => "kWh",
         Field => Row_Data.Capacity_Field);

      ---------------------------------------------------------
      -- Initial SOC
      ---------------------------------------------------------

      Add_Entry
        (Grid,
         Row          => 3,
         Caption      => "Początkowy SOC:",
         Default_Text =>
           Img (OZE.Real (Battery.Config.Initial_SOC)),
         Field => Row_Data.Initial_SOC_Field);

      ---------------------------------------------------------
      -- Minimum SOC
      ---------------------------------------------------------

      Add_Entry
        (Grid,
         Row          => 4,
         Caption      => "Minimalny SOC:",
         Default_Text =>
           Img (OZE.Real (Battery.Config.Minimum_SOC)),
         Field => Row_Data.Minimum_SOC_Field);

      ---------------------------------------------------------
      -- P max
      ---------------------------------------------------------

      Add_Entry
        (Grid,
         Row          => 5,
         Caption      => "Moc maksymalna:",
         Default_Text => Img (Battery.Config.P_Max),
         Unit_Text    => "kW",
         Field => Row_Data.Power_Field);

      ---------------------------------------------------------
      -- Efficiency
      ---------------------------------------------------------

      Add_Entry
        (Grid,
         Row          => 6,
         Caption      => "Sprawność:",
         Default_Text =>
           Img (OZE.Real (Battery.Config.Efficiency)),
         Field => Row_Data.Efficiency_Field);

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
           (Remove_Battery_Clicked'Access),
         Gtk.Widget.Gtk_Widget (Row_Data.Frame));

      Row_Data.Frame.Add (Grid);

      Battery_List_Box.Pack_Start
        (Row_Data.Frame,
         Expand  => False,
         Fill    => True,
         Padding => 4);

      Battery_Rows.Append (Row_Data);

      Row_Data.Frame.Show_All;

   end Add_Battery_Row;


   procedure Create
     (Container : out Gtk.Box.Gtk_Box) is

      Battery_Scrolled : Gtk.Scrolled_Window.Gtk_Scrolled_Window;

      Battery_Frame    : Gtk_Frame;
      Battery_Box : Gtk_Box;
      Add_Battery_Button : Gtk_Button;

   begin

      Battery_Count := 0;
      Battery_Rows.Clear;

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

      if GUI.Project_Loaded then
         declare
            Data : constant OZE.Project.Project_Data :=
              GUI.Current_Project;
         begin
            for Battery of Data.Batteries loop
               Add_Battery_Row (Battery);
            end loop;
         end;
      end if;

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
