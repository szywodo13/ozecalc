with Ada.Text_IO;
with Ada.Exceptions;

with AWS.Client;
with AWS.Response;
with AWS.Messages;
with AWS.Net.SSL;

procedure Test_AWS is

   use type AWS.Messages.Status_Code;

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

   AWS.Net.SSL.Initialize_Default_Config
     (Security_Mode       => AWS.Net.SSL.TLS_Client,
      Client_Certificate  => "",
      Exchange_Certificate => False,
      Check_Certificate   => True,
      Trusted_CA_Filename =>
        "/etc/ssl/certs/ca-certificates.crt");

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

            if AWS.Response.Status_Code (Response) /= AWS.Messages.S200 then
               Ada.Text_IO.Put_Line (Bodys);
            end if;
         end;

      exception
         when E : others =>
            Ada.Text_IO.Put_Line
              ("BLAD: "
               & Ada.Exceptions.Exception_Information (E));
      end;

   end loop;

end Test_AWS;
