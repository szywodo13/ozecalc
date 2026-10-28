with Ada.Text_IO;
with Ada.Exceptions;

with AWS.Client;
with AWS.Response;
with AWS.Messages;

procedure Test_AWS is

   URL : constant String :=
     "https://re.jrc.ec.europa.eu/api/v5_3/seriescalc?"
     & "lat=53.46000000&lon=14.78000000"
     & "&startyear=2017&endyear=2017"
     & "&pvcalculation=1"
     & "&peakpower=14.00000000"
     & "&pvtechchoice=crystSi"
     & "&loss=14.00000000"
     & "&trackingtype=0"
     & "&angle=35.00000000"
     & "&aspect=34.00000000"
     & "&mountingplace=free"
     & "&outputformat=json"
     & "&browser=0";

begin

   for I in 1 .. 10 loop

      Ada.Text_IO.Put
        (Integer'Image (I) & ": ");

      begin

         declare
            Response : constant AWS.Response.Data :=
              AWS.Client.Get
                (URL => URL);

            Bodys : constant String :=
              AWS.Response.Message_Body (Response);
         begin
            Ada.Text_IO.Put_Line
              (AWS.Messages.Image
                 (AWS.Response.Status_Code (Response))
               & ", "
               & Natural'Image (Bodys'Length)
               & " bytes");
         end;

      exception
         when E : others =>
            Ada.Text_IO.Put_Line
              ("BLAD: "
               & Ada.Exceptions.Exception_Information (E));
      end;

   end loop;

end Test_AWS;
