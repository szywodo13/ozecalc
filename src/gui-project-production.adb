with Ada.Exceptions;
with Ada.Strings.Unbounded;

with Glib.Main;

with Gtk.Frame;
with Gtk.Label;
with Gtk.Button;
with Gtk.Enums;
with Gtk.Handlers;

with OZE.IO;
with OZE.Project;
with OZE.Production;

package body GUI.Project.Production is

   use Gtk.Box;
   use Gtk.Frame;
   use Gtk.Label;
   use Gtk.Button;
   use Gtk.Enums;

   type Generation_Status is
     (Idle, Running, Ready, Failed);

   protected Generation_Result is

      procedure Set_Running;

      procedure Set_Ready
        (Value : OZE.Hourly_Profile);

      procedure Set_Failed
        (Message : String);

      function Status return Generation_Status;

      procedure Get_Profile
        (Value : out OZE.Hourly_Profile);

      function Error_Message
        return Ada.Strings.Unbounded.Unbounded_String;

   private

      Current_Status : Generation_Status := Idle;

      Profile : OZE.Hourly_Profile :=
        [others => 0.0];

      Error : Ada.Strings.Unbounded.Unbounded_String;

   end Generation_Result;

   protected body Generation_Result is

      procedure Set_Running is
      begin
         Current_Status := Running;
         Error := Ada.Strings.Unbounded.Null_Unbounded_String;
      end Set_Running;


      procedure Set_Ready
        (Value : OZE.Hourly_Profile)
      is
      begin
         Profile := Value;
         Current_Status := Ready;
      end Set_Ready;


      procedure Set_Failed
        (Message : String)
      is
      begin
         Error :=
           Ada.Strings.Unbounded.To_Unbounded_String
             (Message);

         Current_Status := Failed;
      end Set_Failed;


      function Status return Generation_Status is
      begin
         return Current_Status;
      end Status;


      procedure Get_Profile
        (Value : out OZE.Hourly_Profile)
      is
      begin
         Value := Profile;
      end Get_Profile;


      function Error_Message
        return Ada.Strings.Unbounded.Unbounded_String
      is
      begin
         return Error;
      end Error_Message;

   end Generation_Result;

   task Generation_Worker is
      entry Start
        (Data      : OZE.Project.Project_Data;
         Directory : String);
   end Generation_Worker;


   task body Generation_Worker is

      Data_Copy      : OZE.Project.Project_Data;
      Directory_Copy : Ada.Strings.Unbounded.Unbounded_String;
      Production     : OZE.Hourly_Profile;

   begin
      loop
         select

            accept Start
              (Data      : OZE.Project.Project_Data;
               Directory : String)
            do
               Data_Copy := Data;

               Directory_Copy :=
                 Ada.Strings.Unbounded.To_Unbounded_String
                   (Directory);
            end Start;

            begin

               Production :=
                 OZE.Production.Run
                   (Site       => Data_Copy.Location.Site,
                    PV_Sources =>
                      OZE.Project.Enabled_PV_Sources
                        (Data_Copy));

               -- Dopiero po udanym PVGIS zapisujemy pliki

               OZE.IO.Save_Project
                 (Project_Directory =>
                    Ada.Strings.Unbounded.To_String
                      (Directory_Copy),
                  Project => Data_Copy);

               OZE.IO.Save_Production
                 (Project_Directory =>
                    Ada.Strings.Unbounded.To_String
                      (Directory_Copy),
                  Production => Production);

               Generation_Result.Set_Ready
                 (Production);

            exception
               when E : others =>
                  Generation_Result.Set_Failed
                    (Ada.Exceptions.Exception_Information (E));
            end;

         or
            terminate;
         end select;
      end loop;
   end Generation_Worker;

   package Button_Callbacks is new Gtk.Handlers.Callback
     (Gtk.Button.Gtk_Button_Record);

   Status_Label : Gtk_Label;
   Generate     : Gtk_Button;

   function Check_Generation return Boolean is
   begin

      case Generation_Result.Status is

      when Running =>
         return True;

      when Ready =>

         GUI.Open_Project
           (GUI.Project_Directory);

         Status_Label.Set_Text
           ("Produkcja: dostępna");

         Generate.Set_Sensitive (True);

         return False;

      when Failed =>

         Status_Label.Set_Selectable (True);
         Status_Label.Set_Line_Wrap (True);

         Status_Label.Set_Text
           ("Produkcja: błąd - " &
              Ada.Strings.Unbounded.To_String
              (Generation_Result.Error_Message));

         Generate.Set_Sensitive (True);

         return False;

      when Idle =>
         Generate.Set_Sensitive (True);
         return False;

      end case;

   exception
      when E : others =>

         Status_Label.Set_Text
           ("Błąd GUI: " &
              Ada.Exceptions.Exception_Name (E) &
              " - " &
              Ada.Exceptions.Exception_Message (E));

         Generate.Set_Sensitive (True);

         return False;

   end Check_Generation;

   procedure Generate_Clicked
     (Button : access Gtk.Button.Gtk_Button_Record'Class)
   is
      pragma Unreferenced (Button);

   begin

      declare
         Data : constant OZE.Project.Project_Data :=
           GUI.Project.Current_Data;

         Timeout_Id : Glib.Main.G_Source_Id;

      begin

         Generation_Result.Set_Running;

         Status_Label.Set_Text
           ("Produkcja: pobieranie danych z PVGIS...");

         Generate.Set_Sensitive (False);

         Generation_Worker.Start
           (Data      => Data,
            Directory => GUI.Project_Directory);

         Timeout_Id :=
           Glib.Main.Timeout_Add
             (Interval => 200,
              Func     => Check_Generation'Access);

      end;

   exception
      when E : others =>

         Generate.Set_Sensitive (True);

         Status_Label.Set_Text
           ("Błąd: " &
              Ada.Exceptions.Exception_Name (E) &
              " - " &
              Ada.Exceptions.Exception_Message (E));

   end Generate_Clicked;

   procedure Create
     (Container : out Gtk.Box.Gtk_Box)
   is
      Frame        : Gtk_Frame;
      Box          : Gtk_Box;
   begin

      Gtk_New
        (Frame,
         "Produkcja");

      Gtk_New
        (Box,
         Orientation_Horizontal,
         12);

      if GUI.Production_Available then
         Gtk_New
           (Status_Label,
            "Produkcja: dostępna");
      else
         Gtk_New
           (Status_Label,
            "Produkcja: brak    ");
      end if;

      Gtk_New
        (Generate,
         "Symuluj produkcję");

      Button_Callbacks.Connect
        (Generate,
         "clicked",
         Button_Callbacks.To_Marshaller
           (Generate_Clicked'Access));

      Box.Pack_Start
        (Status_Label,
         Expand  => False,
         Fill    => False,
         Padding => 4);

      Box.Pack_Start
        (Generate,
         Expand  => False,
         Fill    => False,
         Padding => 4);

      Frame.Add (Box);

      Gtk_New
        (Container,
         Orientation_Vertical,
         0);

      Container.Pack_Start
        (Frame,
         Expand  => False,
         Fill    => True,
         Padding => 0);

   end Create;

end GUI.Project.Production;
