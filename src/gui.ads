package GUI is

   procedure Open_Project (Directory : String);

   function Project_Directory return String;

   function Has_Project    return Boolean;
   function Has_Load       return Boolean;
   function Has_Tariffs    return Boolean;
   function Has_Production return Boolean;
   function Has_Timeseries return Boolean;

end GUI;
