with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Ada.Containers;
with OZE.Project;
with OZE.IO;
with OZE.EMS;
-- with OZE.Costs;
-- with OZE.Production;
use type OZE.Energy;
use type OZE.Real;

procedure Main is

   use Ada.Text_IO;
   use type Ada.Strings.Unbounded.Unbounded_String;
   use type Ada.Containers.Count_Type;

   pragma Assertion_Policy (Check);

begin

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

   declare
      Project : constant OZE.Project.Project_Data :=
        OZE.IO.Load_Project ("data");
   begin
      Put_Line
        ("Project loaded: "
         & Ada.Strings.Unbounded.To_String
           (Project.Name));

      pragma Assert (Project.Version = 1);

      pragma Assert
        (not OZE.Project.PV_Vectors.Is_Empty
           (Project.PV_Sources));

      Put_Line ("Project IO test passed.");
   end;


   declare
      Project_1 : constant OZE.Project.Project_Data :=
        OZE.IO.Load_Project ("data_test");
   begin
      OZE.IO.Save_Project
        ("data_test",
         Project_1);

      declare
         Project_2 : constant OZE.Project.Project_Data :=
           OZE.IO.Load_Project ("data_test");
      begin
         pragma Assert
           (Project_2.Version = Project_1.Version);

         pragma Assert
           (Project_2.Name = Project_1.Name);

         pragma Assert
           (Project_2.PV_Sources.Length =
              Project_1.PV_Sources.Length);

         pragma Assert
           (Project_2.Batteries.Length =
              Project_1.Batteries.Length);

         Put_Line ("Project save/load test passed.");
      end;
   end;


   declare
      Load : constant OZE.Hourly_Profile :=
        OZE.IO.Load_Load_Profile ("data");

      Annual_Load : OZE.Energy := 0.0;
   begin
      for H in OZE.Hour_Of_Year loop
         pragma Assert (Load (H) >= 0.0);

         Annual_Load :=
           Annual_Load + Load (H);
      end loop;

      pragma Assert (Annual_Load > 0.0);

      Put_Line
        ("Load profile test passed.");
      Put_Line
        ("Annual load:"
         & OZE.Energy'Image (Annual_Load)
         & " kWh");
   end;

end Main;
