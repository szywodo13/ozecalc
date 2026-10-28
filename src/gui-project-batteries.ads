with Gtk.Box;
with OZE.Project;

package GUI.Project.Batteries is

   function Current_Batteries return OZE.Project.Battery_Vectors.Vector;

   procedure Create (Container : out Gtk.Box.Gtk_Box);

end GUI.Project.Batteries;
