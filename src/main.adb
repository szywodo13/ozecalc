with Gtk.Main;
with Gtkada.File_Selection;

with GUI;
with GUI.Main_Window;

procedure Main is

begin

   Gtk.Main.Init;

   declare

      Directory : constant String :=
        Gtkada.File_Selection.File_Selection_Dialog
          (Title      => "Wskaż katalog projektu",
           Dir_Only   => True,
           Must_Exist => True);

   begin

      --  Anulowano wybór katalogu

      if Directory = "" then
         return;
      end if;


      GUI.Open_Project
        (Directory);


      GUI.Main_Window.Create;

      Gtk.Main.Main;

   end;

end Main;
