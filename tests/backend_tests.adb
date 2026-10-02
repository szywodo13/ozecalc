with Ada.Text_IO;
with Ada.Strings.Unbounded;
with OZE.Project;
with OZE.IO;
with OZE.EMS;
with OZE.Costs;
with OZE.Production;
use type OZE.Energy;
use type OZE.Real;

procedure backend_tests is

   pragma Assertion_Policy (Check);

   Production : OZE.Hourly_Profile := [others => 0.0];
   Load       : OZE.Hourly_Profile := [others => 0.0];

   Batteries : OZE.EMS.Battery_Config_Array (1 .. 1) :=
     [1 =>
        (Capacity    => 10.0,
         Initial_SOC => 0.5,
         Minimum_SOC => 0.1,
         P_Max       => 4.0,
         Efficiency  => 1.0)];

begin

   --  Hour 0:
   --  Production = 6, Load = 2
   --  Self-consumption = 2
   --  Surplus = 4
   --  Battery: 5 -> 9 kWh
   Production (0) := 6.0;
   Load (0)       := 2.0;

   --  Hour 1:
   --  Production = 0, Load = 5
   --  Battery can deliver 4 kWh because P_Max = 4
   --  Battery: 9 -> 5 kWh
   --  Grid supplies remaining 1 kWh
   Production (1) := 0.0;
   Load (1)       := 5.0;

   declare
      Result : constant OZE.EMS.EMS_Result :=
        OZE.EMS.Run
          (Production => Production,
           Load       => Load,
           Batteries  => Batteries,
           Grid_Limit => 100.0);
   begin

      --  Hour 0
      pragma Assert (Result.Auto (0) = 2.0);
      pragma Assert (Result.Charge (0) = 4.0);
      pragma Assert (Result.Discharge (0) = 0.0);
      pragma Assert (Result.Grid_In (0) = 0.0);
      pragma Assert (Result.Grid_Out (0) = 0.0);
      pragma Assert (Result.SOC_Total (0) = 9.0);

      --  Hour 1
      pragma Assert (Result.Auto (1) = 0.0);
      pragma Assert (Result.Charge (1) = 0.0);
      pragma Assert (Result.Discharge (1) = 4.0);
      pragma Assert (Result.Grid_In (1) = 1.0);
      pragma Assert (Result.Grid_Out (1) = 0.0);
      pragma Assert (Result.SOC_Total (1) = 5.0);
      pragma Assert (Result.Unserved_Load (1) = 0.0);

      Ada.Text_IO.Put_Line ("EMS test passed.");

   end;

   declare
      Production_2 : OZE.Hourly_Profile := [others => 0.0];
      Load_2       : OZE.Hourly_Profile := [others => 0.0];

      Batteries_2 : OZE.EMS.Battery_Config_Array (1 .. 2) :=
        [1 =>
           (Capacity     => 4.0,
            Initial_SOC  => 0.75,
            Minimum_SOC  => 0.0,
            P_Max        => 4.0,
            Efficiency   => 1.0),

         2 =>
           (Capacity     => 10.0,
            Initial_SOC  => 0.5,
            Minimum_SOC  => 0.0,
            P_Max        => 4.0,
            Efficiency   => 1.0)];

   begin

      --  10 kWh production and 2 kWh load leave 8 kWh surplus.
      Production_2 (0) := 10.0;
      Load_2 (0)       := 2.0;

      declare
         Result : constant OZE.EMS.EMS_Result :=
           OZE.EMS.Run
             (Production => Production_2,
              Load       => Load_2,
              Batteries  => Batteries_2,
              Grid_Limit => 100.0);
      begin

         pragma Assert (Result.Auto (0) = 2.0);

         --  Battery 1 becomes full after 0.25 h.
         --  Battery 2 receives redistributed power afterwards.
         pragma Assert (Result.Charge (0) = 5.0);

         pragma Assert (Result.Grid_Out (0) = 3.0);

         --  Battery 1: 4 kWh
         --  Battery 2: 9 kWh
         pragma Assert (Result.SOC_Total (0) = 13.0);

         pragma Assert (Result.Grid_In (0) = 0.0);
         pragma Assert (Result.Discharge (0) = 0.0);
         pragma Assert (Result.Unserved_Load (0) = 0.0);

         Ada.Text_IO.Put_Line
           ("EMS redistribution test passed.");

      end;

   end;

   declare
      Grid_In    : OZE.Hourly_Profile := [others => 0.0];
      Grid_Out   : OZE.Hourly_Profile := [others => 0.0];

      Buy_Price  : OZE.Costs.Price_Profile := [others => 0.0];
      Sell_Price : OZE.Costs.Price_Profile := [others => 0.0];
   begin

      Grid_In (0)    := 2.0;
      Grid_Out (0)   := 1.0;

      Buy_Price (0)  := 0.80;
      Sell_Price (0) := 0.30;

      declare
         Result : constant OZE.Costs.Costs_Result :=
           OZE.Costs.Run
             (Grid_In    => Grid_In,
              Grid_Out   => Grid_Out,
              Buy_Price  => Buy_Price,
              Sell_Price => Sell_Price);
      begin
         pragma Assert (Result.Buy_Cost = 1.60);
         pragma Assert (Result.Sell_Revenue = 0.30);
         pragma Assert (Result.Net_Cost = 1.30);

         Ada.Text_IO.Put_Line ("Costs test passed.");
      end;

   end;

   declare
      Site : constant OZE.Production.Location :=
        (Latitude  => 53.43,
         Longitude => 14.55);

      PV_Sources : constant OZE.Production.PV_Config_Array :=
        [1 =>
           (Peak_Power  => 1.0,
            Technology  => OZE.Production.Crystalline_Silicon_2025,
            Tilt        => 35.0,
            Azimuth     => 0.0,
            System_Loss => 0.14,
            Mounting    => OZE.Production.Building)];

      Production : constant OZE.Hourly_Profile :=
        OZE.Production.Run
          (Site       => Site,
           PV_Sources => PV_Sources);

      Annual_Production : OZE.Energy := 0.0;

   begin

      for H in OZE.Hour_Of_Year loop
         pragma Assert (Production (H) >= 0.0);
         Annual_Production :=
           Annual_Production + Production (H);
      end loop;

      --  Broad sanity check for a 1 kWp installation.
      pragma Assert (Annual_Production > 500.0);
      pragma Assert (Annual_Production < 2_000.0);

      Ada.Text_IO.Put_Line
        ("Production test passed.");

      Ada.Text_IO.Put_Line
        ("Annual production: "
         & OZE.Energy'Image (Annual_Production)
         & " kWh");

   end;

   declare
      Project : constant OZE.Project.Project_Data :=
        OZE.IO.Load_Project ("data");
   begin
      Ada.Text_IO.Put_Line
        ("Project loaded: "
         & Ada.Strings.Unbounded.To_String
           (Project.Name));

      pragma Assert (Project.Version = 1);
      pragma Assert
        (not OZE.Project.PV_Vectors.Is_Empty
           (Project.PV_Sources));

      Ada.Text_IO.Put_Line ("Project IO test passed.");
   end;

end backend_tests;
