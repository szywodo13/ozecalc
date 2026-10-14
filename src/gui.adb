with Ada.Strings.Unbounded;
with Ada.Directories;

package body GUI is

   use Ada.Strings.Unbounded;

   Directory_Name : Unbounded_String;

   function File_Exists (Name : String) return Boolean is
   begin
      if Directory_Name = Null_Unbounded_String then
         return False;
      end if;

      return Ada.Directories.Exists
        (Ada.Directories.Compose
           (Containing_Directory => To_String (Directory_Name),
            Name                 => Name));
   end File_Exists;


   procedure Open_Project (Directory : String) is
   begin
      Directory_Name := To_Unbounded_String (Directory);
   end Open_Project;


   function Project_Directory return String is
   begin
      return To_String (Directory_Name);
   end Project_Directory;


   function Has_Project return Boolean is
   begin
      return File_Exists ("project.json");
   end Has_Project;


   function Has_Load return Boolean is
   begin
      return File_Exists ("load.csv");
   end Has_Load;


   function Has_Tariffs return Boolean is
   begin
      return File_Exists ("tariffs.csv");
   end Has_Tariffs;


   function Has_Production return Boolean is
   begin
      return File_Exists ("production.csv");
   end Has_Production;


   function Has_Timeseries return Boolean is
   begin
      return File_Exists ("timeseries.csv");
   end Has_Timeseries;

end GUI;
