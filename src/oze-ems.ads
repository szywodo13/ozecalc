package OZE.EMS is

   subtype State_Of_Charge is Real range 0.0 .. 1.0;

   type Battery_Config is record
      Capacity            : Energy;
      Initial_SOC         : State_Of_Charge;
      Minimum_SOC         : State_Of_Charge;
      P_Max               : Energy;
      Efficiency          : OZE.Efficiency;
   end record;

   type Battery_Config_Array is
     array (Natural range <>) of Battery_Config;

   Grid_P_Max : Energy;

   type EMS_Result is record
      Auto          : Hourly_Profile;
      Charge        : Hourly_Profile;
      Discharge     : Hourly_Profile;
      SOC_Total     : Hourly_Profile;
      Grid_In       : Hourly_Profile;
      Grid_Out      : Hourly_Profile;
      Unserved_Load : Hourly_Profile;
   end record;

   function Run
     (Production : Hourly_Profile;
      Load       : Hourly_Profile;
      Batteries  : Battery_Config_Array;
      Grid_Limit : Energy)
      return EMS_Result;

end OZE.EMS;
