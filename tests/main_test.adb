with Ada.Text_IO;

with OZE;
with OZE.Costs;
with OZE.EMS;
with OZE.IO;
with OZE.Production;
with OZE.Project;

procedure Main is

   use Ada.Text_IO;

   Project_Directory : constant String := "data";

   Project : constant OZE.Project.Project_Data :=
     OZE.IO.Load_Project (Project_Directory);

   Load_Profile : constant OZE.Hourly_Profile :=
     OZE.IO.Load_Load_Profile (Project_Directory);

   Buy_Price  : OZE.Costs.Price_Profile := [others => 0.0];
   Sell_Price : OZE.Costs.Price_Profile := [others => 0.0];

begin

   Put_Line ("Project loaded.");

   OZE.IO.Load_Tariff_Profiles
     (Project_Directory => Project_Directory,
      Buy_Price         => Buy_Price,
      Sell_Price        => Sell_Price);

   Put_Line ("Load and tariffs loaded.");

   declare
      PV_Sources : constant OZE.Production.PV_Config_Array :=
        OZE.Project.Enabled_PV_Sources (Project);

      -- Production_Profile : constant OZE.Hourly_Profile :=
      --  OZE.Production.Run
      --    (Site       => Project.Location.Site,
      --     PV_Sources => PV_Sources);

   begin
      Put_Line ("Production calculated.");

      -- OZE.IO.Save_Production
      --   (Project_Directory => Project_Directory,
      --    Production        => Production_Profile);

      Put_Line ("production.csv written.");

      declare
         Batteries : constant OZE.EMS.Battery_Config_Array :=
           OZE.Project.Enabled_Batteries (Project);

         EMS_Result : constant OZE.EMS.EMS_Result :=
           OZE.EMS.Run
             (Production => Production_Profile,
              Load       => Load_Profile,
              Batteries  => Batteries,
              Grid_Limit => Project.Grid_Limit);

         Costs_Result : constant OZE.Costs.Costs_Result :=
           OZE.Costs.Run
             (Grid_In    => EMS_Result.Grid_In,
              Grid_Out   => EMS_Result.Grid_Out,
              Buy_Price  => Buy_Price,
              Sell_Price => Sell_Price);

      begin
         Put_Line ("EMS calculated.");
         Put_Line ("Costs calculated.");

         OZE.IO.Write_Timeseries
           (Project_Directory => Project_Directory,
            Production        => Production_Profile,
            Load              => Load_Profile,
            EMS               => EMS_Result,
            Buy_Price         => Buy_Price,
            Sell_Price        => Sell_Price);

         Put_Line ("timeseries.csv written.");

         Put_Line
           ("Buy cost:"
            & OZE.Real'Image (Costs_Result.Buy_Cost));

         Put_Line
           ("Sell revenue:"
            & OZE.Real'Image (Costs_Result.Sell_Revenue));

         Put_Line
           ("Net cost:"
            & OZE.Real'Image (Costs_Result.Net_Cost));

         Put_Line ("Backend run completed.");
      end;
   end;

end Main;
