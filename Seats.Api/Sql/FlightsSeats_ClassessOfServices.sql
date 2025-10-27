--use REZXYDW01
use REZXYDW01
BEGIN TRY Drop Table #TempA END TRY BEGIN CATCH END CATCH
BEGIN TRY Drop Table #TempB END TRY BEGIN CATCH END CATCH


--DECLARE @StartDate datetime
--	   ,@EndDate datetime

--SET @StartDate = '2018-07-02 00:00:00.000'
--SET @EndDate =   '2018-07-02 12:59:59.997'

select IL.DepartureDate  , IL.Flightnumber, IL.Departurestation ,  IL.STD,
ISNULL(CASE WHEN ClassOfservice in ('R','C','J','DJ','GB','RM','RIN','CIN') THEN 'Business' 
            WHEN ClassOfservice in ('JB') THEN 'BusinessUpgrade' 
			 WHEN ClassOfservice in ('UG') THEN 'AirportUpgrade'
			else 'Econonmy' END, 'Econonmy') AS Fare, ClassOfservice ,
PJS.PassengerID Into #TempA
from rez.PassengerJourneySegment  PJS
Inner join rez.PassengerJourneyLeg PJL on PJL.PassengerID=PJS.PassengerID  and PJS.SegmentID=PJL.SegmentID 
right join rez.InventoryLeg IL on IL.InventoryLegID=PJL.InventoryLegID 
where ( IL.DepartureDate >= @StartDate and IL.DepartureDate <= @EndDate ) and IL.Flightnumber <= 3000 
 AND (IL.Status <> 2 )  
 and il.carriercode='XY'
 
group by IL.DepartureDate ,IL.STD, IL.Flightnumber , IL.Departurestation , ClassOfservice , PJS.PassengerID
order by DepartureDate , Flightnumber , Departurestation , ClassOfservice , PassengerID

Select DepartureDate ,STD, Flightnumber , Departurestation ,
 ISNULL(CASE Fare WHEN 'Business' THEN  Count (PassengerID ) END, '0') AS Business, 
ISNULL(CASE Fare WHEN 'BusinessUpgrade' THEN  Count (PassengerID ) END, '0') AS BusinessUpgrade,
ISNULL(CASE Fare WHEN 'AirportUpgrade' THEN  Count (PassengerID ) END, '0') AS AirportUpgrade,
 ISNULL(CASE Fare WHEN 'Econonmy' THEN  Count (PassengerID ) END, '0') AS Econonmy
Into #TempB from  #TempA
group by Flightnumber ,STD, Departurestation , Fare,DepartureDate
Order by Flightnumber , Departurestation , Fare,DepartureDate



Select DepartureDate,STD, Flightnumber , Departurestation ,
 Sum ( Econonmy ) As  Econonmy  ,
 Sum ( Business ) As  Business,

 Sum ( BusinessUpgrade ) As BusinessUpgrade,
 Sum ( AirportUpgrade ) As  AirportUpgrade 
 from #TempB
Group by Flightnumber , Departurestation ,DepartureDate ,STD
order by Flightnumber , Departurestation,DepartureDate





