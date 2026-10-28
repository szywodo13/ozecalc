with OZE.Project;

package GUI is

   procedure Open_Project (Directory : String);

   function Project_Directory return String;

   function Is_Project_Directory
     (Directory : String) return Boolean;

   function Is_Empty_Directory
     (Directory : String) return Boolean;

   function Current_Project
     return OZE.Project.Project_Data;

   function Project_Loaded return Boolean;

   function Has_Project    return Boolean;
   function Has_Load       return Boolean;
   function Has_Tariffs    return Boolean;
   function Has_Production return Boolean;
   function Has_Timeseries return Boolean;

   function Production_Available return Boolean;
   function Current_Production return OZE.Hourly_Profile;

end GUI;
