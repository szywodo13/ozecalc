package body OZE.Costs is

   function Run
     (Grid_In    : Hourly_Profile;
      Grid_Out   : Hourly_Profile;
      Buy_Price  : Price_Profile;
      Sell_Price : Price_Profile)
      return Costs_Result
   is
      Result : Costs_Result :=
        (Buy_Cost     => 0.0,
         Sell_Revenue => 0.0,
         Net_Cost     => 0.0);
   begin

      for H in Hour_Of_Year loop
         Result.Buy_Cost :=
           Result.Buy_Cost
           + Real (Grid_In (H)) * Buy_Price (H);

         Result.Sell_Revenue :=
           Result.Sell_Revenue
           + Real (Grid_Out (H)) * Sell_Price (H);
      end loop;

      Result.Net_Cost :=
        Result.Buy_Cost - Result.Sell_Revenue;

      return Result;

   end Run;

end OZE.Costs;
