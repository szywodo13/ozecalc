with OZE.Costs;
with OZE.EMS;
with OZE.Project;

package OZE.IO is

   function Load_Project
     (Project_Directory : String)
      return OZE.Project.Project_Data;

   procedure Save_Project
     (Project_Directory : String;
      Project           : OZE.Project.Project_Data);


   function Load_Load_Profile
     (Project_Directory : String)
   return Hourly_Profile;


   procedure Load_Tariff_Profiles
     (Project_Directory : String;
      Config            : OZE.Project.Tariff_Config;
      Buy_Price         : out OZE.Costs.Price_Profile;
      Sell_Price        : out OZE.Costs.Price_Profile);


   function Load_Production
     (Project_Directory : String)
      return Hourly_Profile;

   procedure Save_Production
     (Project_Directory : String;
      Production        : Hourly_Profile);


   procedure Write_Timeseries
     (Project_Directory : String;
      Production        : Hourly_Profile;
      Load              : Hourly_Profile;
      EMS               : OZE.EMS.EMS_Result;
      Buy_Price         : OZE.Costs.Price_Profile;
      Sell_Price        : OZE.Costs.Price_Profile);

end OZE.IO;
