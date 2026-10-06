package body OZE.Project is

   function Enabled_PV_Sources
     (Project : Project_Data)
      return OZE.Production.PV_Config_Array
   is
      Count : Natural := 0;
   begin
      for Source of Project.PV_Sources loop
         if Source.Enabled then
            Count := Count + 1;
         end if;
      end loop;

      declare
         Result :
         OZE.Production.PV_Config_Array
           (1 .. Count);

         I : Natural := 0;
      begin
         for Source of Project.PV_Sources loop
            if Source.Enabled then
               I := I + 1;
               Result (I) := Source.Config;
            end if;
         end loop;

         return Result;
      end;
   end Enabled_PV_Sources;


   function Enabled_Batteries
     (Project : Project_Data)
      return OZE.EMS.Battery_Config_Array
   is
      Count : Natural := 0;
   begin
      for Battery of Project.Batteries loop
         if Battery.Enabled then
            Count := Count + 1;
         end if;
      end loop;

      declare
         Result :
         OZE.EMS.Battery_Config_Array
           (1 .. Count);

         I : Natural := 0;
      begin
         for Battery of Project.Batteries loop
            if Battery.Enabled then
               I := I + 1;
               Result (I) := Battery.Config;
            end if;
         end loop;

         return Result;
      end;
   end Enabled_Batteries;

end OZE.Project;
