package OZE.Costs is

   type Price_Profile is array (Hour_Of_Year) of Real;

   type Costs_Result is record
      Buy_Cost     : Real;
      Sell_Revenue : Real;
      Net_Cost     : Real;
   end record;

   function Run
     (Grid_In    : Hourly_Profile;
      Grid_Out   : Hourly_Profile;
      Buy_Price  : Price_Profile;
      Sell_Price : Price_Profile)
      return Costs_Result;

end OZE.Costs;
