package OZE is

   type Real is digits 15;

   type Energy is new Real;

   subtype Efficiency is Real range 0.0 .. 1.0;

   subtype Hour_Of_Year is Natural range 0 .. 8759;

   type Hourly_Profile is array (Hour_Of_Year) of Energy;

end OZE;
