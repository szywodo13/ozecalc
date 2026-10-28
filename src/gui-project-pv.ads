with Gtk.Box;
with OZE.Project;

package GUI.Project.PV is

   function Current_Sources return OZE.Project.PV_Vectors.Vector;

   procedure Create (Container : out Gtk.Box.Gtk_Box);

end GUI.Project.PV;
