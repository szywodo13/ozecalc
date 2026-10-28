with Ada.Directories;
with Ada.Exceptions;

with Gtk.Button;
with Gtk.Enums;
with Gtk.Frame;
with Gtk.GEntry;
with Gtk.Grid;
with Gtk.Label;
with Gtk.Widget;
with Gtk.Dialog;
with Gtk.File_Chooser;
with Gtk.File_Chooser_Dialog;
with Gtk.File_Filter;
with Gtk.Handlers;

with OZE.Costs;
with OZE.IO;

package body GUI.Project.Tariffs is

   use type Gtk.Dialog.Gtk_Response_Type;

   Buy_Field       : Gtk.GEntry.Gtk_Entry;
   Sell_Field      : Gtk.GEntry.Gtk_Entry;
   Status_Label    : Gtk.Label.Gtk_Label;
   Load_Button     : Gtk.Button.Gtk_Button;
   Generate_Button : Gtk.Button.Gtk_Button;

   package Button_Callbacks is new Gtk.Handlers.Callback
     (Gtk.Button.Gtk_Button_Record);

   procedure Refresh_Status is

      Buy_Price  : OZE.Costs.Price_Profile;
      Sell_Price : OZE.Costs.Price_Profile;

      File_Name : constant String :=
        GUI.Project_Directory & "/tariffs.csv";

   begin

      if not Ada.Directories.Exists (File_Name) then
         Status_Label.Set_Text ("Taryfy: brak");
         return;
      end if;

      begin

         OZE.IO.Load_Tariff_Profiles
           (Project_Directory => GUI.Project_Directory,
            Buy_Price         => Buy_Price,
            Sell_Price        => Sell_Price);

         Status_Label.Set_Text ("Taryfy: wczytano");

      exception
         when others =>
            Status_Label.Set_Text ("Taryfy: błędny plik");
      end;

   end Refresh_Status;

   procedure Generate_Clicked
     (Button : access Gtk.Button.Gtk_Button_Record'Class)
   is
      pragma Unreferenced (Button);

      Buy_Value : constant OZE.Real :=
        OZE.Real'Value (Buy_Field.Get_Text);

      Sell_Value : constant OZE.Real :=
        OZE.Real'Value (Sell_Field.Get_Text);

   begin

      OZE.IO.Generate_Flat_Tariff
        (Project_Directory => GUI.Project_Directory,
         Buy_Price         => Buy_Value,
         Sell_Price        => Sell_Value);

      Refresh_Status;

   exception
      when E : others =>
         Status_Label.Set_Text
           ("Taryfy: błąd - "
            & Ada.Exceptions.Exception_Message (E));

   end Generate_Clicked;

   procedure Load_Clicked
     (Button : access Gtk.Button.Gtk_Button_Record'Class)
   is
      pragma Unreferenced (Button);

      Dialog     : Gtk.File_Chooser_Dialog.Gtk_File_Chooser_Dialog;
      CSV_Filter : Gtk.File_Filter.Gtk_File_Filter;
      All_Filter : Gtk.File_Filter.Gtk_File_Filter;

      Dummy : Gtk.Widget.Gtk_Widget;

   begin

      Gtk.File_Chooser_Dialog.Gtk_New
        (Dialog => Dialog,
         Title  => "Wczytaj profil taryfowy",
         Parent => null,
         Action => Gtk.File_Chooser.Action_Open);

      Dummy :=
        Dialog.Add_Button
          ("Anuluj",
           Gtk.Dialog.Gtk_Response_Cancel);

      Dummy :=
        Dialog.Add_Button
          ("Wczytaj",
           Gtk.Dialog.Gtk_Response_Accept);

      Gtk.File_Filter.Gtk_New (CSV_Filter);
      CSV_Filter.Set_Name ("Pliki CSV");
      CSV_Filter.Add_Pattern ("*.csv");
      Dialog.Add_Filter (CSV_Filter);

      Gtk.File_Filter.Gtk_New (All_Filter);
      All_Filter.Set_Name ("Wszystkie pliki");
      All_Filter.Add_Pattern ("*");
      Dialog.Add_Filter (All_Filter);

      if Dialog.Run = Gtk.Dialog.Gtk_Response_Accept then

         declare
            Source_File : constant String :=
              Dialog.Get_Filename;
         begin

            Dialog.Destroy;

            OZE.IO.Import_Tariff_File
              (Source_File       => Source_File,
               Project_Directory => GUI.Project_Directory);

            Refresh_Status;

         end;

      else
         Dialog.Destroy;
      end if;

   exception
      when E : others =>
         Status_Label.Set_Text
           ("Taryfy: błędny plik - "
            & Ada.Exceptions.Exception_Message (E));

   end Load_Clicked;

   procedure Create
     (Container : out Gtk.Box.Gtk_Box)
   is
      Tariff_Frame : Gtk.Frame.Gtk_Frame;
      Tariff_Grid  : Gtk.Grid.Gtk_Grid;
      Buttons_Box  : Gtk.Box.Gtk_Box;

      Label : Gtk.Label.Gtk_Label;

   begin

      Gtk.Box.Gtk_New
        (Container,
         Orientation => Gtk.Enums.Orientation_Vertical,
         Spacing     => 0);

      Gtk.Frame.Gtk_New
        (Tariff_Frame,
         "Taryfa");

      Gtk.Grid.Gtk_New (Tariff_Grid);

      Tariff_Grid.Set_Row_Spacing (6);
      Tariff_Grid.Set_Column_Spacing (8);
      Tariff_Grid.Set_Border_Width (8);


      --  Cena zakupu

      Gtk.Label.Gtk_New
        (Label,
         "Cena zakupu:");

      Label.Set_Halign (Gtk.Widget.Align_Start);

      Tariff_Grid.Attach
        (Label,
         0, 0, 1, 1);

      Gtk.GEntry.Gtk_New (Buy_Field);

      Buy_Field.Set_Width_Chars (12);

      Tariff_Grid.Attach
        (Buy_Field,
         1, 0, 1, 1);


      --  Cena sprzedaży

      Gtk.Label.Gtk_New
        (Label,
         "Cena sprzedaży:");

      Label.Set_Halign (Gtk.Widget.Align_Start);

      Tariff_Grid.Attach
        (Label,
         0, 1, 1, 1);

      Gtk.GEntry.Gtk_New (Sell_Field);

      Sell_Field.Set_Width_Chars (12);

      Tariff_Grid.Attach
        (Sell_Field,
         1, 1, 1, 1);


      --  Przyciski

      Gtk.Box.Gtk_New
        (Buttons_Box,
         Orientation => Gtk.Enums.Orientation_Horizontal,
         Spacing     => 8);

      Gtk.Button.Gtk_New
        (Load_Button,
         "Wczytaj");

      Gtk.Button.Gtk_New
        (Generate_Button,
         "Generuj");

      Buttons_Box.Pack_Start
        (Load_Button,
         Expand  => False,
         Fill    => False,
         Padding => 0);

      Buttons_Box.Pack_Start
        (Generate_Button,
         Expand  => False,
         Fill    => False,
         Padding => 0);

      Tariff_Grid.Attach
        (Buttons_Box,
         0, 2, 2, 1);

      Button_Callbacks.Connect
        (Load_Button,
         "clicked",
         Load_Clicked'Access);

      Button_Callbacks.Connect
        (Generate_Button,
         "clicked",
         Generate_Clicked'Access);


      --  Status

      Gtk.Label.Gtk_New
        (Status_Label,
         "Taryfy: brak");

      Status_Label.Set_Halign
        (Gtk.Widget.Align_Start);

      Tariff_Grid.Attach
        (Status_Label,
         0, 3, 2, 1);


      Tariff_Frame.Add (Tariff_Grid);

      Container.Pack_Start
        (Tariff_Frame,
         Expand  => False,
         Fill    => False,
         Padding => 0);


      Refresh_Status;

   end Create;

end GUI.Project.Tariffs;
