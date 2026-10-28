with Gtk.Dialog;
with Gtk.Widget;

package body GUI.Startup is

   use type Gtk.Dialog.Gtk_Response_Type;

   function Choose_Action return Startup_Action is

      Dialog   : Gtk.Dialog.Gtk_Dialog;
      Response : Gtk.Dialog.Gtk_Response_Type;

      Dummy : Gtk.Widget.Gtk_Widget;

      Response_New  : constant Gtk.Dialog.Gtk_Response_Type := 1;
      Response_Open : constant Gtk.Dialog.Gtk_Response_Type := 2;

   begin

      Gtk.Dialog.Gtk_New
        (Dialog,
         Title  => "OZEcalc",
         Parent => null,
         Flags  => Gtk.Dialog.Modal);

      Dummy :=
        Dialog.Add_Button
          ("Nowy projekt",
           Response_New);

      Dummy :=
        Dialog.Add_Button
          ("Otwórz projekt",
           Response_Open);

      Dummy :=
        Dialog.Add_Button
          ("Anuluj",
           Gtk.Dialog.Gtk_Response_Cancel);

      Response := Dialog.Run;

      Dialog.Destroy;

      if Response = Response_New then
         return New_Project;

      elsif Response = Response_Open then
         return Open_Project;

      else
         return Cancel;
      end if;

   end Choose_Action;


end GUI.Startup;
