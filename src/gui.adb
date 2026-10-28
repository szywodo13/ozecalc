with Ada.Strings.Unbounded;
with Ada.Directories;

with OZE.IO;

package body GUI is

   use Ada.Strings.Unbounded;
   use type Ada.Directories.File_Kind;

   Directory_Name : Unbounded_String;

   Current_Data : OZE.Project.Project_Data;
   Data_Loaded  : Boolean := False;

   Production_Data : OZE.Hourly_Profile :=
     [others => 0.0];
   Production_Loaded : Boolean := False;

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
      Directory_Name :=
        To_Unbounded_String (Directory);

      if Has_Project then
         Current_Data :=
           OZE.IO.Load_Project (Directory);

         Data_Loaded := True;
      else
         Data_Loaded := False;
      end if;

      Production_Loaded := False;

      if Has_Production then
         begin
            Production_Data :=
              OZE.IO.Load_Production (Directory);

            Production_Loaded := True;

         exception
            when others =>
               Production_Loaded := False;
         end;
      end if;

   end Open_Project;


   function Project_Directory return String is
   begin
      return To_String (Directory_Name);
   end Project_Directory;

   function Is_Project_Directory
     (Directory : String) return Boolean
   is
   begin
      return Ada.Directories.Exists
        (Ada.Directories.Compose
           (Containing_Directory => Directory,
            Name                 => "project.json"));
   end Is_Project_Directory;

   function Is_Empty_Directory
     (Directory : String) return Boolean
   is
      Search : Ada.Directories.Search_Type;
      Item   : Ada.Directories.Directory_Entry_Type;
   begin

      if not Ada.Directories.Exists (Directory) then
         return False;
      end if;

      if Ada.Directories.Kind (Directory) /=
        Ada.Directories.Directory
      then
         return False;
      end if;

      Ada.Directories.Start_Search
        (Search    => Search,
         Directory => Directory,
         Pattern   => "*",
         Filter    => [others => True]);

      while Ada.Directories.More_Entries (Search) loop

         Ada.Directories.Get_Next_Entry
           (Search,
            Item);

         declare
            Name : constant String :=
              Ada.Directories.Simple_Name (Item);
         begin

            if Name /= "." and then Name /= ".." then
               Ada.Directories.End_Search (Search);
               return False;
            end if;

         end;

      end loop;

      Ada.Directories.End_Search (Search);

      return True;

   end Is_Empty_Directory;

   function Current_Project
     return OZE.Project.Project_Data
   is
   begin
      return Current_Data;
   end Current_Project;


   function Project_Loaded return Boolean is
   begin
      return Data_Loaded;
   end Project_Loaded;

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

   function Production_Available return Boolean is
     (Production_Loaded);

   function Current_Production return OZE.Hourly_Profile is
   begin
      return Production_Data;
   end Current_Production;

end GUI;
