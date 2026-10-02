package body OZE.EMS is

   type Battery_State is record
      SOC                 : Energy;
      Minimum_SOC         : Energy;
      Maximum_SOC         : Energy;
      P_Max               : Energy;
      Efficiency          : OZE.Efficiency;
   end record;

   type Battery_State_Array is
     array (Natural range <>) of Battery_State;


   function Scale
     (Value  : Energy;
      Factor : Real)
      return Energy
   is
     (Energy (Real (Value) * Factor));


   function Divide
     (Value  : Energy;
      Factor : Real)
      return Energy
   is
     (Energy (Real (Value) / Factor));


   function Initial_State
     (Config : Battery_Config)
      return Battery_State
   is
   begin
      return
        (SOC                 =>
           Scale (Config.Capacity, Config.Initial_SOC),

         Minimum_SOC         =>
           Scale (Config.Capacity, Config.Minimum_SOC),

         Maximum_SOC         =>
           Config.Capacity,

         P_Max =>
           Config.P_Max,

         Efficiency          =>
           Config.Efficiency);
   end Initial_State;

   ------------- C H A R G E --------------------

   procedure Charge_Batteries
     (States          : in out Battery_State_Array;
      Surplus_Energy  : in     Energy;
      Absorbed_Energy :    out Energy)
   is
      Remaining_Time : Real := 1.0;

      Total_P_Max : Energy;
      ESS_Power   : Energy;
      Delta_Time  : Real;

      Power_Share : array (States'Range) of Energy :=
        (others => 0.0);

      Time_To_Full : array (States'Range) of Real :=
        (others => 0.0);

   begin
      Absorbed_Energy := 0.0;

      if Surplus_Energy = 0.0 then
         return;
      end if;

      while Remaining_Time > 0.0 loop

         --  Calculate total power of batteries still available for charging.
         Total_P_Max := 0.0;

         for I in States'Range loop
            if States (I).SOC < States (I).Maximum_SOC then
               Total_P_Max := Total_P_Max + States (I).P_Max;
            end if;
         end loop;

         --  No battery can accept more energy.
         exit when Total_P_Max = 0.0;

         --  Limit ESS charging power by the total power of available batteries.
         if Surplus_Energy < Total_P_Max then
            ESS_Power := Surplus_Energy;
         else
            ESS_Power := Total_P_Max;
         end if;

         --  Distribute ESS power proportionally to P_Max.
         for I in States'Range loop
            if States (I).SOC < States (I).Maximum_SOC then
               Power_Share (I) :=
                 ESS_Power * States (I).P_Max / Total_P_Max;
            else
               Power_Share (I) := 0.0;
            end if;
         end loop;

         --  Find the first battery that reaches Maximum_SOC.
         Delta_Time := Remaining_Time;

         for I in States'Range loop
            if Power_Share (I) > 0.0 then
               Time_To_Full (I) :=
                 Real (States (I).Maximum_SOC - States (I).SOC)
                   / (Real (Power_Share (I))
                      * States (I).Efficiency);

               if Time_To_Full (I) < Delta_Time then
                  Delta_Time := Time_To_Full (I);
               end if;
            else
               Time_To_Full (I) := 0.0;
            end if;
         end loop;

         --  Perform the event substep.
         for I in States'Range loop
            if Power_Share (I) > 0.0 then
               declare
                  Input_Energy : constant Energy :=
                    Scale (Power_Share (I), Delta_Time);

                  Stored_Energy : constant Energy :=
                    Scale (Input_Energy,
                           States (I).Efficiency);
               begin
                  --  If this battery caused the event, set the boundary
                  --  explicitly instead of relying on floating-point equality
                  --  after arithmetic.
                  if Time_To_Full (I) = Delta_Time then
                     States (I).SOC := States (I).Maximum_SOC;
                  else
                     States (I).SOC :=
                       States (I).SOC + Stored_Energy;
                  end if;

                  Absorbed_Energy :=
                    Absorbed_Energy + Input_Energy;
               end;
            end if;
         end loop;

         Remaining_Time := Remaining_Time - Delta_Time;

      end loop;

   end Charge_Batteries;

   ------------- D I S C H A R G E --------------------

   procedure Discharge_Batteries
     (States           : in out Battery_State_Array;
      Deficit_Energy   : in     Energy;
      Delivered_Energy :    out Energy)
   is
      Remaining_Time : Real := 1.0;

      Total_P_Max : Energy;
      ESS_Power   : Energy;
      Delta_Time  : Real;

      Power_Share : array (States'Range) of Energy :=
        (others => 0.0);

      Time_To_Empty : array (States'Range) of Real :=
        (others => 0.0);

   begin
      Delivered_Energy := 0.0;

      if Deficit_Energy = 0.0 then
         return;
      end if;

      while Remaining_Time > 0.0 loop

         --  Calculate total power of batteries still available
         --  for discharging.
         Total_P_Max := 0.0;

         for I in States'Range loop
            if States (I).SOC > States (I).Minimum_SOC then
               Total_P_Max := Total_P_Max + States (I).P_Max;
            end if;
         end loop;

         --  No battery can deliver more energy.
         exit when Total_P_Max = 0.0;

         --  Limit ESS discharging power by the total power
         --  of available batteries.
         if Deficit_Energy < Total_P_Max then
            ESS_Power := Deficit_Energy;
         else
            ESS_Power := Total_P_Max;
         end if;

         --  Distribute ESS power proportionally to P_Max.
         for I in States'Range loop
            if States (I).SOC > States (I).Minimum_SOC then
               Power_Share (I) :=
                 ESS_Power * States (I).P_Max / Total_P_Max;
            else
               Power_Share (I) := 0.0;
            end if;
         end loop;

         --  Find the earliest battery reaching Minimum_SOC.
         Delta_Time := Remaining_Time;

         for I in States'Range loop
            if Power_Share (I) > 0.0 then
               Time_To_Empty (I) :=
                 Real
                   (States (I).SOC - States (I).Minimum_SOC)
                     * States (I).Efficiency
                 / Real (Power_Share (I));

               if Time_To_Empty (I) < Delta_Time then
                  Delta_Time := Time_To_Empty (I);
               end if;
            else
               Time_To_Empty (I) := 0.0;
            end if;
         end loop;

         --  Perform the event substep.
         for I in States'Range loop
            if Power_Share (I) > 0.0 then
               declare
                  Output_Energy : constant Energy :=
                    Scale (Power_Share (I), Delta_Time);

                  Removed_Energy : constant Energy :=
                    Divide
                      (Output_Energy,
                       States (I).Efficiency);
               begin
                  --  Set the boundary explicitly for batteries
                  --  that reach Minimum_SOC in this substep.
                  if Time_To_Empty (I) = Delta_Time then
                     States (I).SOC := States (I).Minimum_SOC;
                  else
                     States (I).SOC :=
                       States (I).SOC - Removed_Energy;
                  end if;

                  Delivered_Energy :=
                    Delivered_Energy + Output_Energy;
               end;
            end if;
         end loop;

         Remaining_Time := Remaining_Time - Delta_Time;

      end loop;

   end Discharge_Batteries;

   -------------- R U N ----------------

   function Run
     (Production : Hourly_Profile;
      Load       : Hourly_Profile;
      Batteries  : Battery_Config_Array;
      Grid_Limit : Energy)
      return EMS_Result
   is

      States : Battery_State_Array (Batteries'Range);

      Result : EMS_Result :=
        (Auto          => [others => 0.0],
         Charge        => [others => 0.0],
         Discharge     => [others => 0.0],
         SOC_Total     => [others => 0.0],
         Grid_In       => [others => 0.0],
         Grid_Out      => [others => 0.0],
         Unserved_Load => [others => 0.0]);

   begin

      --  Initialize battery states.
      for I in Batteries'Range loop
         States (I) := Initial_State (Batteries (I));
      end loop;

      for H in Hour_Of_Year loop
         declare
            Remaining_Production : Energy := Production (H);
            Remaining_Load       : Energy := Load (H);

            Absorbed  : Energy := 0.0;
            Delivered : Energy := 0.0;
         begin

            --  Direct self-consumption.
            if Remaining_Production < Remaining_Load then
               Result.Auto (H) := Remaining_Production;
            else
               Result.Auto (H) := Remaining_Load;
            end if;

            Remaining_Production :=
              Remaining_Production - Result.Auto (H);

            Remaining_Load :=
              Remaining_Load - Result.Auto (H);

            --  Deficit: batteries first, then grid.
            if Remaining_Load > 0.0 then

               Discharge_Batteries
                 (States           => States,
                  Deficit_Energy   => Remaining_Load,
                  Delivered_Energy => Delivered);

               Result.Discharge (H) := Delivered;
               Remaining_Load := Remaining_Load - Delivered;

               if Remaining_Load > 0.0 then
                  if Remaining_Load < Grid_Limit then
                     Result.Grid_In (H) := Remaining_Load;
                  else
                     Result.Grid_In (H) := Grid_Limit;
                  end if;

                  Remaining_Load :=
                    Remaining_Load - Result.Grid_In (H);

                  Result.Unserved_Load (H) := Remaining_Load;
               end if;

               --  Surplus: batteries first, then grid.
            elsif Remaining_Production > 0.0 then

               Charge_Batteries
                 (States          => States,
                  Surplus_Energy  => Remaining_Production,
                  Absorbed_Energy => Absorbed);

               Result.Charge (H) := Absorbed;

               Remaining_Production :=
                 Remaining_Production - Absorbed;

               if Remaining_Production > 0.0 then
                  if Remaining_Production < Grid_Limit then
                     Result.Grid_Out (H) := Remaining_Production;
                  else
                     Result.Grid_Out (H) := Grid_Limit;
                  end if;

                  --  Any remaining production is curtailed.
               end if;

            end if;

            --  Store total ESS energy at the end of the hour.
            Result.SOC_Total (H) := 0.0;

            for I in States'Range loop
               Result.SOC_Total (H) :=
                 Result.SOC_Total (H) + States (I).SOC;
            end loop;

         end;
      end loop;

      return Result;

   end Run;

end OZE.EMS;
