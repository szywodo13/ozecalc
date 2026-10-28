package GUI.Startup is

   type Startup_Action is
     (Cancel,
      New_Project,
      Open_Project);

   function Choose_Action return Startup_Action;

end GUI.Startup;
