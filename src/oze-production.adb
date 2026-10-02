with Ada.Text_IO;
with Ada.Strings;
with Ada.Strings.Fixed;

with AWS.Client;
with AWS.Messages;
with AWS.Response;
with AWS.Net.SSL;

with GNATCOLL.JSON;

package body OZE.Production is

   use type OZE.Energy;

   use GNATCOLL.JSON;

   package Real_IO is new Ada.Text_IO.Float_IO (Real);

   PVGIS_Base       : constant String :=
     "https://re.jrc.ec.europa.eu/api/v5_3";

   PVGIS_TMY        : constant String :=
     PVGIS_Base & "/tmy";

   PVGIS_Seriescalc : constant String :=
     PVGIS_Base & "/seriescalc";


   subtype Month_Number is Positive range 1 .. 12;

   type Month_Year_Array is
     array (Month_Number) of Integer;

   type Month_Hours_Array is
     array (Month_Number) of Natural;

   Hours_Per_Month : constant Month_Hours_Array :=
     [744, 672, 744, 720, 744, 720,
      744, 744, 720, 744, 720, 744];


   function Real_Image
     (Value : Real)
   return String
   is
      Buffer : String (1 .. 40);
   begin
      Real_IO.Put
        (To   => Buffer,
         Item => Value,
         Aft  => 8,
         Exp  => 0);

      return
        Ada.Strings.Fixed.Trim
          (Buffer,
           Ada.Strings.Both);
   end Real_Image;


   function Integer_Image
     (Value : Integer)
      return String
   is
   begin
      return
        Ada.Strings.Fixed.Trim
          (Integer'Image (Value),
           Ada.Strings.Both);
   end Integer_Image;


   function Technology_Name
     (Technology : PV_Technology)
      return String
   is
   begin
      case Technology is
         when Crystalline_Silicon =>
            return "crystSi";

         when Crystalline_Silicon_2025 =>
            return "crystSi2025";

         when CIS =>
            return "CIS";

         when CdTe =>
            return "CdTe";

         when Unknown =>
            return "Unknown";
      end case;
   end Technology_Name;


   function Mounting_Name
     (Mounting : Mounting_Type)
      return String
   is
   begin
      case Mounting is
         when Free =>
            return "free";

         when Building =>
            return "building";
      end case;
   end Mounting_Name;


   function Number
     (Value : JSON_Value)
      return Real
   is
   begin
      case Kind (Value) is
         when JSON_Int_Type =>
            return
              Real
                (Long_Long_Integer'(Get (Value)));

         when JSON_Float_Type =>
            return
              Real (Get_Long_Float (Value));

         when others =>
            raise Constraint_Error
              with "Expected JSON number";
      end case;
   end Number;


   function Integer_Number
     (Value : JSON_Value)
      return Integer
   is
   begin
      case Kind (Value) is
         when JSON_Int_Type =>
            return
              Integer
                (Long_Long_Integer'(Get (Value)));

         when JSON_Float_Type =>
            return
              Integer (Get_Long_Float (Value));

         when others =>
            raise Constraint_Error
              with "Expected JSON integer";
      end case;
   end Integer_Number;


   function HTTP_Get_JSON
     (URL : String)
      return JSON_Value
   is
      Response : constant AWS.Response.Data :=
        AWS.Client.Get (URL => URL);

      Response_Text : constant String :=
        AWS.Response.Message_Body (Response);
   begin
      if AWS.Response.Status_Code (Response)
      not in AWS.Messages.Success
      then
         raise Program_Error
           with
             "PVGIS HTTP error "
             & AWS.Messages.Image
           (AWS.Response.Status_Code (Response))
           & ASCII.LF
           & "URL: "
           & URL
           & ASCII.LF
           & "Response: "
           & Response_Text;
      end if;

      return GNATCOLL.JSON.Read (Response_Text);
   end HTTP_Get_JSON;


   function Get_TMY_Years
     (Site : Location)
      return Month_Year_Array
   is
      URL : constant String :=
        PVGIS_TMY
        & "?lat=" & Real_Image (Site.Latitude)
        & "&lon=" & Real_Image (Site.Longitude)
        & "&outputformat=json"
        & "&browser=0";

      Root    : constant JSON_Value :=
        HTTP_Get_JSON (URL);

      Outputs : constant JSON_Value :=
        Get (Root, "outputs");

      Months  : constant JSON_Array :=
        Get (Outputs, "months_selected");

      Result : Month_Year_Array :=
        [others => 0];

   begin

      if Length (Months) /= 12 then
         raise Program_Error
           with
             "PVGIS TMY response does not contain 12 months";
      end if;

      for I in 1 .. Length (Months) loop
         declare
            Row : constant JSON_Value :=
              Get (Months, I);

            Month : constant Integer :=
              Integer_Number (Get (Row, "month"));

            Year : constant Integer :=
              Integer_Number (Get (Row, "year"));
         begin
            if Month not in Month_Number then
               raise Program_Error
                 with "Invalid month in PVGIS TMY response";
            end if;

            Result (Month_Number (Month)) := Year;
         end;
      end loop;

      for Month in Month_Number loop
         if Result (Month) = 0 then
            raise Program_Error
              with
                "Incomplete PVGIS TMY month selection";
         end if;
      end loop;

      return Result;

   end Get_TMY_Years;


   function Get_Year_Profile
     (Site : Location;
      PV   : PV_Config;
      Year : Integer)
      return Hourly_Profile
   is
      URL : constant String :=
        PVGIS_Seriescalc
        & "?lat=" & Real_Image (Site.Latitude)
        & "&lon=" & Real_Image (Site.Longitude)
        & "&startyear=" & Integer_Image (Year)
        & "&endyear=" & Integer_Image (Year)
        & "&pvcalculation=1"
        & "&peakpower="
        & Real_Image (Real (PV.Peak_Power))
        & "&pvtechchoice="
        & Technology_Name (PV.Technology)
        & "&loss="
        & Real_Image (PV.System_Loss * 100.0)
        & "&trackingtype=0"
        & "&angle="
        & Real_Image (PV.Tilt)
        & "&aspect="
        & Real_Image (PV.Azimuth)
        & "&mountingplace="
        & Mounting_Name (PV.Mounting)
        & "&outputformat=json"
        & "&browser=0";

      Root : constant JSON_Value :=
        HTTP_Get_JSON (URL);

      Outputs : constant JSON_Value :=
        Get (Root, "outputs");

      Hourly : constant JSON_Array :=
        Get (Outputs, "hourly");

      Result : Hourly_Profile :=
        [others => 0.0];

      Output_Index : Natural := 0;

   begin

      for I in 1 .. Length (Hourly) loop
         declare
            Row : constant JSON_Value :=
              Get (Hourly, I);

            Timestamp : constant String :=
              Get (Row, "time");

            P_Watts : constant Real :=
              Number (Get (Row, "P"));
         begin

            --  Remove February 29 so every year has 8760 hours.
            if Timestamp'Length < 8
              or else Timestamp (5 .. 8) /= "0229"
            then
               if Output_Index > Hour_Of_Year'Last then
                  raise Program_Error
                    with
                      "PVGIS year contains more than 8760 usable hours";
               end if;

               Result (Hour_Of_Year (Output_Index)) :=
                 Energy (P_Watts / 1000.0);

               Output_Index := Output_Index + 1;
            end if;

         end;
      end loop;

      if Output_Index /= 8760 then
         raise Program_Error
           with
             "PVGIS year does not contain 8760 usable hours";
      end if;

      return Result;

   end Get_Year_Profile;


   function Build_TMY_Profile
     (Site           : Location;
      PV             : PV_Config;
      Selected_Years : Month_Year_Array)
      return Hourly_Profile
   is

      type Cached_Year is record
         Year    : Integer := 0;
         Profile : Hourly_Profile := [others => 0.0];
      end record;

      type Year_Cache is
        array (Positive range 1 .. 12) of Cached_Year;

      Cache       : Year_Cache;
      Cache_Count : Natural := 0;

      Result : Hourly_Profile :=
        [others => 0.0];

      Source_Hour : Natural := 0;
      Output_Hour : Natural := 0;

   begin

      for Month in Month_Number loop
         declare
            Year        : constant Integer :=
              Selected_Years (Month);

            Cache_Index : Natural := 0;
         begin

            --  Find an already downloaded year.
            for I in 1 .. Cache_Count loop
               if Cache (I).Year = Year then
                  Cache_Index := I;
                  exit;
               end if;
            end loop;

            --  Download each required year only once.
            if Cache_Index = 0 then
               Cache_Count := Cache_Count + 1;
               Cache_Index := Cache_Count;

               Cache (Cache_Index).Year := Year;

               Cache (Cache_Index).Profile :=
                 Get_Year_Profile
                   (Site => Site,
                    PV   => PV,
                    Year => Year);
            end if;

            --  Copy the selected month into the TMY profile.
            for Offset in
              0 .. Hours_Per_Month (Month) - 1
            loop
               Result
                 (Hour_Of_Year (Output_Hour)) :=
                   Cache (Cache_Index).Profile
                 (Hour_Of_Year
                    (Source_Hour + Offset));

               Output_Hour := Output_Hour + 1;
            end loop;

            Source_Hour :=
              Source_Hour + Hours_Per_Month (Month);

         end;
      end loop;

      if Output_Hour /= 8760 then
         raise Program_Error
           with "TMY profile length is not 8760";
      end if;

      return Result;

   end Build_TMY_Profile;


   function Run
     (Site       : Location;
      PV_Sources : PV_Config_Array)
      return Hourly_Profile
   is
      Selected_Years : constant Month_Year_Array :=
        Get_TMY_Years (Site);

      Result : Hourly_Profile :=
        [others => 0.0];

   begin

      for I in PV_Sources'Range loop
         declare
            Profile : constant Hourly_Profile :=
              Build_TMY_Profile
                (Site           => Site,
                 PV             => PV_Sources (I),
                 Selected_Years => Selected_Years);
         begin
            for H in Hour_Of_Year loop
               Result (H) :=
                 Result (H) + Profile (H);
            end loop;
         end;
      end loop;

      return Result;

   end Run;

begin

   AWS.Net.SSL.Initialize_Default_Config
     (Security_Mode        => AWS.Net.SSL.TLS_Client,
      Client_Certificate  => "",
      Check_Certificate   => True,
      Trusted_CA_Filename => "/etc/ssl/certs/ca-certificates.crt");

end OZE.Production;
