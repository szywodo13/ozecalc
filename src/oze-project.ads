with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

with OZE.EMS;
with OZE.Production;

package OZE.Project is

   subtype Unbounded_String is
     Ada.Strings.Unbounded.Unbounded_String;


   type Location_Config is record
      Site     : OZE.Production.Location;
      Timezone : Unbounded_String;
   end record;


   type Load_Config is record
      Yearly_Energy : Energy;
      Profile_Name  : Unbounded_String;
   end record;


   type Tariff_Config is record
      Profile_Name : Unbounded_String;
      Buy_Base     : Real;
      Sell_Base    : Real;
   end record;


   type PV_Source is record
      Name    : Unbounded_String;
      Enabled : Boolean;
      Config  : OZE.Production.PV_Config;
   end record;

   package PV_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => PV_Source);


   type Battery is record
      Name    : Unbounded_String;
      Enabled : Boolean;
      Config  : OZE.EMS.Battery_Config;
   end record;

   package Battery_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Battery);


   type Project_Data is record
      Version     : Positive;
      Name        : Unbounded_String;
      Location    : Location_Config;
      Grid_Limit  : Energy;
      Load        : Load_Config;
      PV_Sources  : PV_Vectors.Vector;
      Batteries   : Battery_Vectors.Vector;
      Tariff      : Tariff_Config;
   end record;

   function Enabled_PV_Sources
     (Project : Project_Data)
   return OZE.Production.PV_Config_Array;

   function Enabled_Batteries
     (Project : Project_Data)
   return OZE.EMS.Battery_Config_Array;

end OZE.Project;
