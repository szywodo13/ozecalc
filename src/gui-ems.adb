with Gtk.Box;
with Gtk.Frame;
with Gtk.Label;
with Gtk.Enums;

package body GUI.EMS is

   use Gtk.Box;
   use Gtk.Frame;
   use Gtk.Label;
   use Gtk.Enums;

   procedure Create
     (Page : out Gtk.Box.Gtk_Box)
   is
      Results_Frame : Gtk_Frame;
      Report_Frame  : Gtk_Frame;

      Label : Gtk_Label;

   begin

      Gtk_New
        (Page,
         Orientation_Vertical,
         12);

      Page.Set_Border_Width (12);


      Gtk_New (Results_Frame, "Wyniki EMS");

      Gtk_New
        (Label,
         "Zużycie całkowite:" & ASCII.LF &
         "Produkcja całkowita:" & ASCII.LF &
         "Autokonsumpcja:" & ASCII.LF &
         "Import z sieci:" & ASCII.LF &
         "Eksport do sieci:" & ASCII.LF &
         "Samowystarczalność:");

      Results_Frame.Add (Label);

      Page.Pack_Start
        (Results_Frame,
         False,
         False,
         0);


      Gtk_New (Report_Frame, "Raportowanie");

      Gtk_New
        (Label,
         "Wybór danych do raportu" & ASCII.LF &
         "Rozdzielczość: dzienna / tygodniowa / miesięczna" &
         ASCII.LF &
         ASCII.LF &
         "[Oblicz EMS]   [Wczytaj timeseries]   [Generuj raport]");

      Report_Frame.Add (Label);

      Page.Pack_Start
        (Report_Frame,
         True,
         True,
         0);

   end Create;

end GUI.EMS;
