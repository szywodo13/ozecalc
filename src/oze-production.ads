package OZE.Production is

   type Location is record
      Latitude  : Real;
      Longitude : Real;
   end record;

   type Mounting_Type is
     (Free,
      Building);

   type PV_Technology is
     (Crystalline_Silicon,
      Crystalline_Silicon_2025,
      CIS,
      CdTe,
      Unknown);

   type PV_Config is record
      Peak_Power  : Energy;
      Technology  : PV_Technology;
      Tilt        : Real;
      Azimuth     : Real;
      System_Loss : Real;
      Mounting    : Mounting_Type;
   end record;

   type PV_Config_Array is
     array (Positive range <>) of PV_Config;

   function Run
     (Site       : Location;
      PV_Sources : PV_Config_Array)
      return Hourly_Profile;

end OZE.Production;
