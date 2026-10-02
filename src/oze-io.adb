with Ada.Text_IO;
with Ada.Directories;
with Ada.Strings.Unbounded;
with Ada.Strings.Fixed;

with GNATCOLL.JSON;

with OZE.Production;

package body OZE.IO is

   use Ada.Strings.Unbounded;
   use GNATCOLL.JSON;


   function Project_File
     (Project_Directory : String;
      File_Name         : String) return String
   is
     (Ada.Directories.Compose
        (Containing_Directory => Project_Directory,
         Name                 => File_Name));


   function Read_JSON_File
     (File_Name : String) return JSON_Value
   is
      Result : constant Read_Result := Read_File (File_Name);
   begin
      if not Result.Success then
         raise Constraint_Error
           with "Invalid JSON file "
           & File_Name
           & ": "
           & Format_Parsing_Error (Result.Error);
      end if;

      return Result.Value;
   end Read_JSON_File;


   function Number
     (Value : JSON_Value) return Real
   is
   begin
      case Kind (Value) is
         when JSON_Int_Type =>
            return Real
              (Long_Long_Integer'(Get (Value)));

         when JSON_Float_Type =>
            return Real
              (Get_Long_Float (Value));

         when others =>
            raise Constraint_Error
              with "JSON value is not a number";
      end case;
   end Number;


   function Number
     (Object     : JSON_Value;
      Field_Name : String) return Real
   is
     (Number (Get (Object, Field_Name)));


   function String_Value
     (Object     : JSON_Value;
      Field_Name : String) return String
   is
     (String'(Get (Object, Field_Name)));


   function Technology
     (Value : String)
      return OZE.Production.PV_Technology
   is
   begin
      if Value = "crystSi" then
         return OZE.Production.Crystalline_Silicon;

      elsif Value = "crystSi2025" then
         return OZE.Production.Crystalline_Silicon_2025;

      elsif Value = "CIS" then
         return OZE.Production.CIS;

      elsif Value = "CdTe" then
         return OZE.Production.CdTe;

      elsif Value = "Unknown" then
         return OZE.Production.Unknown;

      else
         raise Constraint_Error
           with "Unknown PV technology: " & Value;
      end if;
   end Technology;


   function Mounting
     (Value : String)
      return OZE.Production.Mounting_Type
   is
   begin
      if Value = "free" then
         return OZE.Production.Free;

      elsif Value = "building" then
         return OZE.Production.Building;

      else
         raise Constraint_Error
           with "Unknown PV mounting type: " & Value;
      end if;
   end Mounting;


   function Technology_Image
     (Value : OZE.Production.PV_Technology)
   return String
   is
   begin
      case Value is
      when OZE.Production.Crystalline_Silicon =>
         return "crystSi";

      when OZE.Production.Crystalline_Silicon_2025 =>
         return "crystSi2025";

      when OZE.Production.CIS =>
         return "CIS";

      when OZE.Production.CdTe =>
         return "CdTe";

      when OZE.Production.Unknown =>
         return "Unknown";
      end case;
   end Technology_Image;


   function Mounting_Image
     (Value : OZE.Production.Mounting_Type)
   return String
   is
   begin
      case Value is
      when OZE.Production.Free =>
         return "free";

      when OZE.Production.Building =>
         return "building";
      end case;
   end Mounting_Image;


   procedure Set_Real_Field
     (Object     : JSON_Value;
      Field_Name : String;
      Value      : Real)
   is
   begin
      Set_Field_Long_Float
        (Object,
         Field_Name,
         Long_Float (Value));
   end Set_Real_Field;


   function Load_Project
     (Project_Directory : String)
      return OZE.Project.Project_Data
   is
      Root : constant JSON_Value :=
        Read_JSON_File
          (Project_File
             (Project_Directory,
              "project.json"));

      Location_JSON : constant JSON_Value :=
        Get (Root, "location");

      Load_JSON : constant JSON_Value :=
        Get (Root, "load");

      Tariff_JSON : constant JSON_Value :=
        Get (Root, "tariff");

      PV_JSON : constant JSON_Array :=
        Get (Root, "pv_sources");

      Batteries_JSON : constant JSON_Array :=
        Get (Root, "batteries");

      PV_Sources :
      OZE.Project.PV_Vectors.Vector;

      Batteries :
      OZE.Project.Battery_Vectors.Vector;

   begin

      for I in 1 .. Length (PV_JSON) loop
         declare
            Item : constant JSON_Value :=
              Get (PV_JSON, I);
         begin
            OZE.Project.PV_Vectors.Append
              (PV_Sources,
               OZE.Project.PV_Source'
               (Name =>
                    To_Unbounded_String
                  (String_Value (Item, "name")),

                Enabled =>
                  Boolean'(Get (Item, "enabled")),

                Config =>
                  (Peak_Power =>
                     Energy
                       (Number (Item, "kwp")),

                   Technology =>
                     Technology
                       (String_Value
                            (Item, "technology")),

                   Tilt =>
                     Number (Item, "tilt_deg"),

                   Azimuth =>
                     Number
                       (Item, "azimuth_deg"),

                   System_Loss =>
                     Number
                       (Item, "system_loss_frac"),

                   Mounting =>
                     Mounting
                       (String_Value
                            (Item, "mounting")))));
         end;
      end loop;


      for I in 1 .. Length (Batteries_JSON) loop
         declare
            Item : constant JSON_Value :=
              Get (Batteries_JSON, I);
         begin
            OZE.Project.Battery_Vectors.Append
              (Batteries,
               OZE.Project.Battery'
               (Name =>
                    To_Unbounded_String
                  (String_Value (Item, "name")),

                Enabled =>
                  Boolean'(Get (Item, "enabled")),

                Config =>
                  (Capacity =>
                     Energy
                       (Number (Item, "cap_kwh")),

                   Initial_SOC =>
                     OZE.EMS.State_Of_Charge
                       (Number (Item, "soc0")),

                   Minimum_SOC =>
                     OZE.EMS.State_Of_Charge
                       (Number (Item, "soc_min")),

                   P_Max =>
                     Energy
                       (Number (Item, "power_kw")),

                   Efficiency =>
                     OZE.Efficiency
                       (Number (Item, "eta")))));
         end;
      end loop;


      return
        (Version =>
           Positive
             (Integer'(Get (Root, "version"))),

         Name =>
           To_Unbounded_String
             (String_Value (Root, "name")),

         Location =>
           (Site =>
                (Latitude =>
                     Number (Location_JSON, "lat"),

                 Longitude =>
                   Number (Location_JSON, "lon")),

            Timezone =>
              To_Unbounded_String
                (String_Value
                     (Location_JSON, "timezone"))),

         Grid_Limit =>
           Energy
             (Number (Root, "grid_power_kw")),

         Load =>
           (Yearly_Energy =>
                Energy
              (Number
                   (Load_JSON, "yearly_kwh")),

            Profile_Name =>
              To_Unbounded_String
                (String_Value
                     (Load_JSON, "profile"))),

         PV_Sources =>
           PV_Sources,

         Batteries =>
           Batteries,

         Tariff =>
           (Profile_Name =>
                To_Unbounded_String
              (String_Value
                   (Tariff_JSON, "profile")),

            Buy_Base =>
              Number
                (Tariff_JSON, "buy_base"),

            Sell_Base =>
              Number
                (Tariff_JSON, "sell_base")));
   end Load_Project;


   procedure Save_Project
     (Project_Directory : String;
      Project           : OZE.Project.Project_Data)
   is
      Root          : JSON_Value := Create_Object;
      Location_JSON : JSON_Value := Create_Object;
      Load_JSON     : JSON_Value := Create_Object;
      Tariff_JSON   : JSON_Value := Create_Object;

      PV_JSON        : JSON_Array := Empty_Array;
      Batteries_JSON : JSON_Array := Empty_Array;

      File : Ada.Text_IO.File_Type;

   begin
      Set_Field
        (Root,
         "version",
         Integer (Project.Version));

      Set_Field
        (Root,
         "name",
         Project.Name);


      Set_Real_Field
        (Location_JSON,
         "lat",
         Project.Location.Site.Latitude);

      Set_Real_Field
        (Location_JSON,
         "lon",
         Project.Location.Site.Longitude);

      Set_Field
        (Location_JSON,
         "timezone",
         Project.Location.Timezone);

      Set_Field
        (Root,
         "location",
         Location_JSON);


      Set_Real_Field
        (Root,
         "grid_power_kw",
         Real (Project.Grid_Limit));


      Set_Real_Field
        (Load_JSON,
         "yearly_kwh",
         Real (Project.Load.Yearly_Energy));

      Set_Field
        (Load_JSON,
         "profile",
         Project.Load.Profile_Name);

      Set_Field
        (Root,
         "load",
         Load_JSON);


      for Source of Project.PV_Sources loop
         declare
            Item : JSON_Value := Create_Object;
         begin
            Set_Field
              (Item,
               "enabled",
               Source.Enabled);

            Set_Field
              (Item,
               "name",
               Source.Name);

            Set_Real_Field
              (Item,
               "kwp",
               Real (Source.Config.Peak_Power));

            Set_Field
              (Item,
               "technology",
               Technology_Image
                 (Source.Config.Technology));

            Set_Real_Field
              (Item,
               "tilt_deg",
               Source.Config.Tilt);

            Set_Real_Field
              (Item,
               "azimuth_deg",
               Source.Config.Azimuth);

            Set_Real_Field
              (Item,
               "system_loss_frac",
               Source.Config.System_Loss);

            Set_Field
              (Item,
               "mounting",
               Mounting_Image
                 (Source.Config.Mounting));

            Append
              (PV_JSON,
               Item);
         end;
      end loop;

      Set_Field
        (Root,
         "pv_sources",
         PV_JSON);


      for Battery of Project.Batteries loop
         declare
            Item : JSON_Value := Create_Object;
         begin
            Set_Field
              (Item,
               "enabled",
               Battery.Enabled);

            Set_Field
              (Item,
               "name",
               Battery.Name);

            Set_Real_Field
              (Item,
               "cap_kwh",
               Real (Battery.Config.Capacity));

            Set_Real_Field
              (Item,
               "soc0",
               Real (Battery.Config.Initial_SOC));

            Set_Real_Field
              (Item,
               "soc_min",
               Real (Battery.Config.Minimum_SOC));

            Set_Real_Field
              (Item,
               "power_kw",
               Real (Battery.Config.P_Max));

            Set_Real_Field
              (Item,
               "eta",
               Real (Battery.Config.Efficiency));

            Append
              (Batteries_JSON,
               Item);
         end;
      end loop;

      Set_Field
        (Root,
         "batteries",
         Batteries_JSON);


      Set_Field
        (Tariff_JSON,
         "profile",
         Project.Tariff.Profile_Name);

      Set_Real_Field
        (Tariff_JSON,
         "buy_base",
         Project.Tariff.Buy_Base);

      Set_Real_Field
        (Tariff_JSON,
         "sell_base",
         Project.Tariff.Sell_Base);

      Set_Field
        (Root,
         "tariff",
         Tariff_JSON);


      Ada.Text_IO.Create
        (File,
         Ada.Text_IO.Out_File,
         Project_File
           (Project_Directory,
            "project.json"));

      Ada.Text_IO.Put_Line
        (File,
         Write
           (Root,
            Compact => False));

      Ada.Text_IO.Close (File);

   end Save_Project;


   function Load_Load_Profile
     (Project_Directory : String)
   return Hourly_Profile
   is
      File : Ada.Text_IO.File_Type;

      Result : Hourly_Profile :=
        [others => 0.0];

   begin
      Ada.Text_IO.Open
        (File,
         Ada.Text_IO.In_File,
         Project_File
           (Project_Directory,
            "load.csv"));

      -- Skip header
      declare
         Header : constant String :=
           Ada.Text_IO.Get_Line (File);
      begin
         if Header /= "t;load" then
            Ada.Text_IO.Close (File);

            raise Constraint_Error
              with "Invalid load.csv header";
         end if;
      end;


      for H in Hour_Of_Year loop

         if Ada.Text_IO.End_Of_File (File) then
            Ada.Text_IO.Close (File);

            raise Constraint_Error
              with "load.csv contains fewer than 8760 rows";
         end if;

         declare
            Line : constant String :=
              Ada.Text_IO.Get_Line (File);

            Separator : constant Natural :=
              Ada.Strings.Fixed.Index
                (Line,
                 ";");
         begin
            if Separator = 0 then
               Ada.Text_IO.Close (File);

               raise Constraint_Error
                 with "Invalid row in load.csv";
            end if;

            declare
               Time_Value : constant Natural :=
                 Natural'Value
                   (Line
                      (Line'First ..
                             Separator - 1));

               Load_Value : constant Real :=
                 Real'Value
                   (Line
                      (Separator + 1 ..
                             Line'Last));
            begin

               if Time_Value /= H then
                  Ada.Text_IO.Close (File);

                  raise Constraint_Error
                    with "Invalid hour index in load.csv";
               end if;

               if Load_Value < 0.0 then
                  Ada.Text_IO.Close (File);

                  raise Constraint_Error
                    with "Negative load value in load.csv";
               end if;

               Result (H) :=
                 Energy (Load_Value);
            end;
         end;

      end loop;


      if not Ada.Text_IO.End_Of_File (File) then
         Ada.Text_IO.Close (File);

         raise Constraint_Error
           with "load.csv contains more than 8760 rows";
      end if;

      Ada.Text_IO.Close (File);

      return Result;

   end Load_Load_Profile;


   procedure Load_Tariff_Profiles
     (Project_Directory : String;
      Config            : OZE.Project.Tariff_Config;
      Buy_Price         : out OZE.Costs.Price_Profile;
      Sell_Price        : out OZE.Costs.Price_Profile)
   is
      pragma Unreferenced
        (Project_Directory, Config,
         Buy_Price, Sell_Price);
   begin
      raise Program_Error
        with "Load_Tariff_Profiles not implemented";
   end Load_Tariff_Profiles;


   function Load_Production
     (Project_Directory : String)
      return Hourly_Profile
   is
      pragma Unreferenced (Project_Directory);
   begin
      return
        (raise Program_Error
           with "Load_Production not implemented");
   end Load_Production;


   procedure Save_Production
     (Project_Directory : String;
      Production        : Hourly_Profile)
   is
      pragma Unreferenced
        (Project_Directory, Production);
   begin
      raise Program_Error
        with "Save_Production not implemented";
   end Save_Production;


   procedure Write_Timeseries
     (Project_Directory : String;
      Production        : Hourly_Profile;
      Load              : Hourly_Profile;
      EMS               : OZE.EMS.EMS_Result;
      Buy_Price         : OZE.Costs.Price_Profile;
      Sell_Price        : OZE.Costs.Price_Profile)
   is
      pragma Unreferenced
        (Project_Directory,
         Production,
         Load,
         EMS,
         Buy_Price,
         Sell_Price);
   begin
      raise Program_Error
        with "Write_Timeseries not implemented";
   end Write_Timeseries;

end OZE.IO;
