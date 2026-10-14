with Gtk.Box;
with Gtk.Frame;
with Gtk.Label;
with Gtk.Enums;

package body GUI.Storage is

   use Gtk.Box;
   use Gtk.Frame;
   use Gtk.Label;
   use Gtk.Enums;

   procedure Create
     (Page : out Gtk.Box.Gtk_Box)
   is
      Parameters_Frame : Gtk_Frame;
      Results_Frame    : Gtk_Frame;

      Label : Gtk_Label;

   begin

      Gtk_New
        (Page,
         Orientation_Vertical,
         12);

      Page.Set_Border_Width (12);


      Gtk_New
        (Parameters_Frame,
         "Analiza magazynu");

      Gtk_New
        (Label,
         "Zakres pojemności magazynu" & ASCII.LF &
         "Moc jako funkcja pojemności" & ASCII.LF &
         "Liczba przebiegów EMS");

      Parameters_Frame.Add (Label);

      Page.Pack_Start
        (Parameters_Frame,
         False,
         False,
         0);


      Gtk_New
        (Results_Frame,
         "Raportowanie");

      Gtk_New
        (Label,
         "Wybór wielkości prezentowanych w analizie" &
         ASCII.LF &
         "Grid in / Grid out / Autokonsumpcja / Koszt / ..." &
         ASCII.LF &
         ASCII.LF &
         "[Oblicz serię]   [Generuj raport]");

      Results_Frame.Add (Label);

      Page.Pack_Start
        (Results_Frame,
         True,
         True,
         0);

   end Create;

end GUI.Storage;
