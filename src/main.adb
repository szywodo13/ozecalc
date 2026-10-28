with Gtk.Main;
with Gtkada.Dialogs;
with Gtkada.File_Selection;

with GUI;
with GUI.Startup;
with GUI.Main_Window;

procedure Main is

   Action : GUI.Startup.Startup_Action;

begin

   Gtk.Main.Init;

   Action := GUI.Startup.Choose_Action;

   case Action is

      when GUI.Startup.Cancel =>
         return;

      when GUI.Startup.Open_Project =>

         loop

            declare
               Directory : constant String :=
                 Gtkada.File_Selection.File_Selection_Dialog
                   (Title      => "Otwórz projekt",
                    Dir_Only   => True,
                    Must_Exist => True);
            begin

               if Directory = "" then
                  return;
               end if;

               if GUI.Is_Project_Directory (Directory) then
                  GUI.Open_Project (Directory);
                  exit;

               else
                  declare
                     Dummy : Gtkada.Dialogs.Message_Dialog_Buttons;
                  begin
                     Dummy :=
                       Gtkada.Dialogs.Message_Dialog
                         (Msg         =>
                            "Wybrany katalog nie zawiera pliku project.json.",
                          Dialog_Type => Gtkada.Dialogs.Error,
                          Buttons     => Gtkada.Dialogs.Button_OK,
                          Title       => "Nieprawidłowy katalog projektu");
                  end;
               end if;

            end;

         end loop;

      when GUI.Startup.New_Project =>

         loop

            declare
               Directory : constant String :=
                 Gtkada.File_Selection.File_Selection_Dialog
                   (Title      => "Wybierz pusty katalog dla nowego projektu",
                    Dir_Only   => True,
                    Must_Exist => True);
            begin

               if Directory = "" then
                  return;
               end if;

               if GUI.Is_Empty_Directory (Directory) then
                  GUI.Open_Project (Directory);
                  exit;

               else
                  declare
                     Dummy :
                     Gtkada.Dialogs.Message_Dialog_Buttons;
                  begin
                     Dummy :=
                       Gtkada.Dialogs.Message_Dialog
                         (Msg =>
                            "Wybrany katalog nie jest pusty.",
                          Dialog_Type => Gtkada.Dialogs.Error,
                          Buttons     => Gtkada.Dialogs.Button_OK,
                          Title       => "Nie można utworzyć projektu");
                  end;
               end if;

            end;

         end loop;
   end case;

   GUI.Main_Window.Create;
   Gtk.Main.Main;

end Main;
