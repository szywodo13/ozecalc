with Ada.Text_IO;
with Ada.Directories;
with Ada.Strings;
with Ada.Strings.Unbounded;
with Ada.Strings.Fixed;

with GNATCOLL.JSON;

with OZE.Production;

package body OZE.IO is

   use Ada.Strings.Unbounded;
   use GNATCOLL.JSON;

   package Real_IO is new Ada.Text_IO.Float_IO (Real);

   function Real_Image
     (Value    : Real;
      Decimals : Natural) return String
   is
      Buffer : String (1 .. 64);
   begin
      Real_IO.Put
        (To   => Buffer,
         Item => Value,
         Aft  => Decimals,
         Exp  => 0);

      return
        Ada.Strings.Fixed.Trim
          (Buffer,
           Ada.Strings.Both);
   end Real_Image;

   function JSON_Boolean_Image
     (Value : Boolean) return String
   is
   begin
      if Value then
         return "true";
      else
         return "false";
      end if;
   end JSON_Boolean_Image;

   function JSON_String
     (Value : String) return String
   is
      Result : Unbounded_String;
      Hex    : constant String := "0123456789ABCDEF";
   begin
      Append (Result, '"');

      for C of Value loop
         case C is

         when '"' =>
            Append (Result, '\');
            Append (Result, '"');

         when '\' =>
            Append (Result, '\');
            Append (Result, '\');

         when ASCII.LF =>
            Append (Result, '\');
            Append (Result, 'n');

         when ASCII.CR =>
            Append (Result, '\');
            Append (Result, 'r');

         when ASCII.HT =>
            Append (Result, '\');
            Append (Result, 't');

         when others =>
            if Character'Pos (C) < 32 then
               declare
                  N : constant Natural :=
                    Character'Pos (C);
               begin
                  Append (Result, "\u00");
                  Append (Result, Hex (N / 16 + 1));
                  Append (Result, Hex (N mod 16 + 1));
               end;
            else
               Append (Result, C);
            end if;

         end case;
      end loop;

      Append (Result, '"');

      return To_String (Result);
   end JSON_String;


   function JSON_String
     (Value : Unbounded_String) return String
   is
   begin
      return JSON_String (To_String (Value));
   end JSON_String;


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

         Description =>
           To_Unbounded_String
             (String_Value (Root, "description")),

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

         Tariff_Profile =>
           To_Unbounded_String
             (String_Value
                  (Root, "tariff_profile")),

         PV_Sources =>
           PV_Sources,

         Batteries =>
           Batteries
        );
   end Load_Project;


   procedure Save_Project
     (Project_Directory : String;
      Project           : OZE.Project.Project_Data)
   is
      File : Ada.Text_IO.File_Type;

      PV_Number      : Natural := 0;
      Battery_Number : Natural := 0;

      PV_Count : constant Natural :=
        Natural (Project.PV_Sources.Length);

      Battery_Count : constant Natural :=
        Natural (Project.Batteries.Length);

   begin

      Ada.Text_IO.Create
        (File,
         Ada.Text_IO.Out_File,
         Project_File
           (Project_Directory,
            "project.json"));

      Ada.Text_IO.Put_Line (File, "{");

      Ada.Text_IO.Put_Line
        (File,
         "  ""version"": "
         & Ada.Strings.Fixed.Trim
           (Positive'Image (Project.Version),
            Ada.Strings.Both)
         & ",");

      Ada.Text_IO.Put_Line
        (File,
         "  ""name"": "
         & JSON_String (Project.Name)
         & ",");

      Ada.Text_IO.Put_Line
        (File,
         "  ""description"": "
         & JSON_String (Project.Description)
         & ",");

      ---------------------------------------------------------
      -- Location
      ---------------------------------------------------------

      Ada.Text_IO.Put_Line
        (File,
         "  ""location"": {");

      Ada.Text_IO.Put_Line
        (File,
         "    ""lat"": "
         & Real_Image
           (Project.Location.Site.Latitude, 2)
         & ",");

      Ada.Text_IO.Put_Line
        (File,
         "    ""lon"": "
         & Real_Image
           (Project.Location.Site.Longitude, 2)
         & ",");

      Ada.Text_IO.Put_Line
        (File,
         "    ""timezone"": "
         & JSON_String (Project.Location.Timezone));

      Ada.Text_IO.Put_Line
        (File,
         "  },");

      ---------------------------------------------------------
      -- General project data
      ---------------------------------------------------------

      Ada.Text_IO.Put_Line
        (File,
         "  ""grid_power_kw"": "
         & Real_Image
           (Real (Project.Grid_Limit), 2)
         & ",");

      Ada.Text_IO.Put_Line
        (File,
         "  ""tariff_profile"": "
         & JSON_String (Project.Tariff_Profile)
         & ",");

      ---------------------------------------------------------
      -- PV
      ---------------------------------------------------------

      Ada.Text_IO.Put_Line
        (File,
         "  ""pv_sources"": [");

      for Source of Project.PV_Sources loop

         PV_Number := PV_Number + 1;

         Ada.Text_IO.Put_Line (File, "    {");

         Ada.Text_IO.Put_Line
           (File,
            "      ""name"": "
            & JSON_String (Source.Name)
            & ",");

         Ada.Text_IO.Put_Line
           (File,
            "      ""enabled"": "
            & JSON_Boolean_Image (Source.Enabled)
            & ",");

         Ada.Text_IO.Put_Line
           (File,
            "      ""kwp"": "
            & Real_Image
              (Real (Source.Config.Peak_Power), 2)
            & ",");

         Ada.Text_IO.Put_Line
           (File,
            "      ""technology"": "
            & JSON_String
              (Technology_Image
                   (Source.Config.Technology))
            & ",");

         Ada.Text_IO.Put_Line
           (File,
            "      ""tilt_deg"": "
            & Real_Image
              (Source.Config.Tilt, 2)
            & ",");

         Ada.Text_IO.Put_Line
           (File,
            "      ""azimuth_deg"": "
            & Real_Image
              (Source.Config.Azimuth, 2)
            & ",");

         Ada.Text_IO.Put_Line
           (File,
            "      ""system_loss_frac"": "
            & Real_Image
              (Source.Config.System_Loss, 2)
            & ",");

         Ada.Text_IO.Put_Line
           (File,
            "      ""mounting"": "
            & JSON_String
              (Mounting_Image
                   (Source.Config.Mounting)));

         if PV_Number < PV_Count then
            Ada.Text_IO.Put_Line (File, "    },");
         else
            Ada.Text_IO.Put_Line (File, "    }");
         end if;

      end loop;

      Ada.Text_IO.Put_Line
        (File,
         "  ],");

      ---------------------------------------------------------
      -- Batteries
      ---------------------------------------------------------

      Ada.Text_IO.Put_Line
        (File,
         "  ""batteries"": [");

      for Battery of Project.Batteries loop

         Battery_Number := Battery_Number + 1;

         Ada.Text_IO.Put_Line (File, "    {");

         Ada.Text_IO.Put_Line
           (File,
            "      ""name"": "
            & JSON_String (Battery.Name)
            & ",");

         Ada.Text_IO.Put_Line
           (File,
            "      ""enabled"": "
            & JSON_Boolean_Image (Battery.Enabled)
            & ",");

         Ada.Text_IO.Put_Line
           (File,
            "      ""cap_kwh"": "
            & Real_Image
              (Real (Battery.Config.Capacity), 2)
            & ",");

         Ada.Text_IO.Put_Line
           (File,
            "      ""soc0"": "
            & Real_Image
              (Real (Battery.Config.Initial_SOC), 2)
            & ",");

         Ada.Text_IO.Put_Line
           (File,
            "      ""soc_min"": "
            & Real_Image
              (Real (Battery.Config.Minimum_SOC), 4)
            & ",");

         Ada.Text_IO.Put_Line
           (File,
            "      ""power_kw"": "
            & Real_Image
              (Real (Battery.Config.P_Max), 2)
            & ",");

         Ada.Text_IO.Put_Line
           (File,
            "      ""eta"": "
            & Real_Image
              (Real (Battery.Config.Efficiency), 2));

         if Battery_Number < Battery_Count then
            Ada.Text_IO.Put_Line (File, "    },");
         else
            Ada.Text_IO.Put_Line (File, "    }");
         end if;

      end loop;

      Ada.Text_IO.Put_Line
        (File,
         "  ]");

      Ada.Text_IO.Put_Line
        (File,
         "}");

      Ada.Text_IO.Close (File);

   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;

         raise;

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
      Buy_Price         : out OZE.Costs.Price_Profile;
      Sell_Price        : out OZE.Costs.Price_Profile)
   is
      File : Ada.Text_IO.File_Type;

   begin
      Ada.Text_IO.Open
        (File,
         Ada.Text_IO.In_File,
         Project_File
           (Project_Directory,
            "tariffs.csv"));

      declare
         Header : constant String :=
           Ada.Text_IO.Get_Line (File);
      begin
         if Header /= "t;buy;sell" then
            Ada.Text_IO.Close (File);

            raise Constraint_Error
              with "Invalid tariffs.csv header";
         end if;
      end;


      for H in Hour_Of_Year loop

         if Ada.Text_IO.End_Of_File (File) then
            Ada.Text_IO.Close (File);

            raise Constraint_Error
              with "tariffs.csv contains fewer than 8760 rows";
         end if;

         declare
            Line : constant String :=
              Ada.Text_IO.Get_Line (File);

            Separator_1 : constant Natural :=
              Ada.Strings.Fixed.Index
                (Line,
                 ";");

            Separator_2 : constant Natural :=
              (if Separator_1 = 0
               then 0
               else
                  Ada.Strings.Fixed.Index
                 (Line,
                  ";",
                  From => Separator_1 + 1));
         begin
            if Separator_1 = 0
              or else Separator_2 = 0
            then
               Ada.Text_IO.Close (File);

               raise Constraint_Error
                 with "Invalid row in tariffs.csv";
            end if;

            declare
               Time_Value : constant Natural :=
                 Natural'Value
                   (Line
                      (Line'First ..
                             Separator_1 - 1));

               Buy_Value : constant Real :=
                 Real'Value
                   (Line
                      (Separator_1 + 1 ..
                             Separator_2 - 1));

               Sell_Value : constant Real :=
                 Real'Value
                   (Line
                      (Separator_2 + 1 ..
                             Line'Last));
            begin
               if Time_Value /= H then
                  Ada.Text_IO.Close (File);

                  raise Constraint_Error
                    with "Invalid hour index in tariffs.csv";
               end if;

               Buy_Price (H) := Buy_Value;
               Sell_Price (H) := Sell_Value;
            end;
         end;

      end loop;


      if not Ada.Text_IO.End_Of_File (File) then
         Ada.Text_IO.Close (File);

         raise Constraint_Error
           with "tariffs.csv contains more than 8760 rows";
      end if;

      Ada.Text_IO.Close (File);

   end Load_Tariff_Profiles;


   procedure Import_Tariff_File
     (Source_File       : String;
      Project_Directory : String)
   is
      Check_Directory : constant String :=
        Project_Directory & "/.tariff_check";

      Check_File : constant String :=
        Check_Directory & "/tariffs.csv";

      Target_File : constant String :=
        Project_Directory & "/tariffs.csv";

      Buy_Profile  : OZE.Costs.Price_Profile;
      Sell_Profile : OZE.Costs.Price_Profile;

   begin

      if Ada.Directories.Exists (Check_Directory) then
         Ada.Directories.Delete_Tree (Check_Directory);
      end if;

      Ada.Directories.Create_Directory (Check_Directory);

      Ada.Directories.Copy_File
        (Source_Name => Source_File,
         Target_Name => Check_File,
         Form        => "mode=overwrite");

      --  Tu następuje właściwa walidacja pliku.
      OZE.IO.Load_Tariff_Profiles
        (Project_Directory => Check_Directory,
         Buy_Price         => Buy_Profile,
         Sell_Price        => Sell_Profile);

      --  Dopiero poprawny plik trafia do projektu.
      if Source_File /= Target_File then
         Ada.Directories.Copy_File
           (Source_Name => Source_File,
            Target_Name => Target_File,
            Form        => "mode=overwrite");
      end if;

      Ada.Directories.Delete_Tree (Check_Directory);

   exception
      when others =>

         if Ada.Directories.Exists (Check_Directory) then
            Ada.Directories.Delete_Tree (Check_Directory);
         end if;

         raise;

   end Import_Tariff_File;


   procedure Generate_Flat_Tariff
     (Project_Directory : String;
      Buy_Price         : Real;
      Sell_Price        : Real)
   is
      use Ada.Strings;
      use Ada.Strings.Fixed;

      File : Ada.Text_IO.File_Type;

      File_Name : constant String :=
        Project_Directory & "/tariffs.csv";

   begin

      Ada.Text_IO.Create
        (File => File,
         Mode => Ada.Text_IO.Out_File,
         Name => File_Name);

      Ada.Text_IO.Put_Line
        (File,
         "t;buy;sell");

      for T in Hour_Of_Year loop
         Ada.Text_IO.Put_Line
           (File,
            Trim (Hour_Of_Year'Image (T), Both)
            & ";"
            & Real_Image (Buy_Price, 4)
            & ";"
            & Real_Image (Sell_Price, 4));
      end loop;

      Ada.Text_IO.Close (File);

   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;

   end Generate_Flat_Tariff;


   function Load_Production
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
            "production.csv"));

      ---------------------------------------------------------
      -- Header
      ---------------------------------------------------------

      declare
         Header : constant String :=
           Ada.Text_IO.Get_Line (File);
      begin
         if Header /= "t;production" then
            Ada.Text_IO.Close (File);

            raise Constraint_Error
              with "Invalid production.csv header";
         end if;
      end;

      ---------------------------------------------------------
      -- Data
      ---------------------------------------------------------

      for H in Hour_Of_Year loop

         if Ada.Text_IO.End_Of_File (File) then
            Ada.Text_IO.Close (File);

            raise Constraint_Error
              with "production.csv contains fewer than 8760 rows";
         end if;

         declare
            Line : constant String :=
              Ada.Text_IO.Get_Line (File);

            Separator : constant Natural :=
              Ada.Strings.Fixed.Index
                (Line, ";");

            Second_Separator : constant Natural :=
              (if Separator = 0
               then 0
               else
                  Ada.Strings.Fixed.Index
                 (Line,
                  ";",
                  From => Separator + 1));

         begin
            if Separator = 0
              or else Second_Separator /= 0
              or else Separator = Line'First
              or else Separator = Line'Last
            then
               Ada.Text_IO.Close (File);

               raise Constraint_Error
                 with "Invalid row in production.csv";
            end if;

            declare
               Time_Value : constant Natural :=
                 Natural'Value
                   (Line
                      (Line'First ..
                             Separator - 1));

               Production_Value : constant Real :=
                 Real'Value
                   (Line
                      (Separator + 1 ..
                             Line'Last));

            begin
               if Time_Value /= H then
                  Ada.Text_IO.Close (File);

                  raise Constraint_Error
                    with
                      "Invalid hour index in production.csv";
               end if;

               if Production_Value < 0.0 then
                  Ada.Text_IO.Close (File);

                  raise Constraint_Error
                    with
                      "Negative production value in production.csv";
               end if;

               Result (H) :=
                 Energy (Production_Value);
            end;
         end;

      end loop;

      ---------------------------------------------------------
      -- No extra rows
      ---------------------------------------------------------

      if not Ada.Text_IO.End_Of_File (File) then
         Ada.Text_IO.Close (File);

         raise Constraint_Error
           with "production.csv contains more than 8760 rows";
      end if;

      Ada.Text_IO.Close (File);

      return Result;

   end Load_Production;


   procedure Save_Production
     (Project_Directory : String;
      Production        : Hourly_Profile)
   is
      File : Ada.Text_IO.File_Type;
   begin
      Ada.Text_IO.Create
        (File,
         Ada.Text_IO.Out_File,
         Project_File
           (Project_Directory,
            "production.csv"));

      Ada.Text_IO.Put_Line
        (File,
         "t;production");

      for H in Hour_Of_Year loop
         Ada.Text_IO.Put_Line
           (File,
            Ada.Strings.Fixed.Trim
              (Natural'Image (H),
               Ada.Strings.Both)
            & ";"
            & Real_Image
              (Real (Production (H)),6));
      end loop;

      Ada.Text_IO.Close (File);

   end Save_Production;


   procedure Write_Timeseries
     (Project_Directory : String;
      Production        : Hourly_Profile;
      Load              : Hourly_Profile;
      EMS               : OZE.EMS.EMS_Result;
      Buy_Price         : OZE.Costs.Price_Profile;
      Sell_Price        : OZE.Costs.Price_Profile)
   is
      File : Ada.Text_IO.File_Type;
   begin
      Ada.Text_IO.Create
        (File,
         Ada.Text_IO.Out_File,
         Project_File
           (Project_Directory,
            "timeseries.csv"));

      Ada.Text_IO.Put_Line
        (File,
         "t;production;load;auto;charge;discharge;"
         & "soc_total;grid_in;grid_out;unserved_load;"
         & "buy;sell");

      for H in Hour_Of_Year loop
         Ada.Text_IO.Put_Line
           (File,
            Ada.Strings.Fixed.Trim
              (Natural'Image (H),
               Ada.Strings.Both)
            & ";"
            & Real_Image (Real (Production (H)), 6)
            & ";"
            & Real_Image (Real (Load (H)), 6)
            & ";"
            & Real_Image (Real (EMS.Auto (H)), 6)
            & ";"
            & Real_Image (Real (EMS.Charge (H)), 6)
            & ";"
            & Real_Image (Real (EMS.Discharge (H)), 6)
            & ";"
            & Real_Image (Real (EMS.SOC_Total (H)), 6)
            & ";"
            & Real_Image (Real (EMS.Grid_In (H)), 6)
            & ";"
            & Real_Image (Real (EMS.Grid_Out (H)), 6)
            & ";"
            & Real_Image (Real (EMS.Unserved_Load (H)), 6)
            & ";"
            & Real_Image (Real (EMS.Grid_In (H)) * Buy_Price (H), 6)
            & ";"
            & Real_Image (Real (EMS.Grid_Out (H)) * Sell_Price (H), 6)
           );
      end loop;

      Ada.Text_IO.Close (File);

   end Write_Timeseries;


end OZE.IO;
