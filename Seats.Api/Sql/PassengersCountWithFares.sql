--use TSTXYDW01
use REZXYDW01

BEGIN TRY Drop Table #Temp1 END TRY BEGIN CATCH END CATCH
BEGIN TRY Drop Table #Temp2 END TRY BEGIN CATCH END CATCH
BEGIN TRY Drop Table #Temp3 END TRY BEGIN CATCH END CATCH   
BEGIN TRY Drop Table #Temp4 END TRY BEGIN CATCH END CATCH 
BEGIN TRY Drop Table #Temp5 END TRY BEGIN CATCH END CATCH   
BEGIN TRY Drop Table #Temp6 END TRY BEGIN CATCH END CATCH   


 --DECLARE @StartDate Char(23),
 --       @EndDate Char(23) , @EndDate2 Char(23) 
 --       SET @StartDate  = '2025-04-19 00:00:00.000' 
 --       SET @ENDDate    = '2025-04-19 23:59:59.997'
	--	SET @ENDDate2    = '2025-04-20 23:59:59.997'

Select BookingID= (Select bp.bookingid from rez.bookingpassenger bp where bp.passengerid = pj.passengerid),
PassengerID= PJ.PassengerID,DepatureDate= IL.STD,FlightNumber= IL.FlightNumber,DepartureStation= IL.DepartureStation,ArrivalStation= IL.ArrivalStation ,IL.InventoryLegID
into #Temp1
From rez.InventoryLeg IL 
inner join rez.PassengerJourneyLeg PJL on IL.InventoryLegID=PJL.InventoryLegID 
left outer join rez.PassengerJourneySegment pj on PJL.PassengerID=PJ.PassengerID  and PJL.SegmentID=PJ.SegmentID
AND  IL.DepartureStation= pj.DepartureStation and IL.DepartureDate= pj.DepartureDate
Where ( IL.STD  between cast(@StartDate as datetime) AND cast(@EndDate as datetime)) AND IL.Status <> 2  and (IL.FlightNumber not between 900 and 999  ) --AND LTRIM (IL.FlightNumber) ='205'  
 and il.carriercode='XY'
 --and il.flightnumber='  46'
Select *,BK_Status	= (Select b.Status from rez.booking b where b.BookingID = BT.BookingID)into #Temp2 From #Temp1 BT 

Update #Temp2 Set PassengerID = null,BookingID= null Where (BK_Status  = '1' OR  BK_Status  = '4')  

select T.BookingID ,  T.PassengerID  , PFC.FeeNumber , T.FlightNumber, PF.DepartureStation , PF.ArrivalStation ,PFC.ChargeCode ,DepatureDate,
 ISNULL(CASE PFC.ChargeType WHEN  1  then (PFC.ChargeAmount* -1) END,(PFC.ChargeAmount)) AS ChargeAmount ,T.InventoryLegID into #Temp3 from #Temp2 T 
left outer join rez.PassengerFee PF on T.passengerid = PF.passengerid  and T.DepartureStation = PF.DepartureStation  and T.ArrivalStation  = PF.ArrivalStation
left outer join rez.PassengerFeeCharge PFC on PF.passengerid = PFC.passengerid and PF.FeeNumber = PFC.FeeNumber
where T.BookingID is not null  and PFC.FeeNumber is  not null  
group by T.BookingID , T.PassengerID , PFC.FeeNumber ,T.FlightNumber, PF.DepartureStation , PF.ArrivalStation  , PFC.ChargeCode  , PFC.ChargeType , ChargeAmount ,T.InventoryLegID,DepatureDate
order by T.BookingID , T.PassengerID 

select #Temp3.DepatureDate, #Temp3.InventoryLegID, PNR = (Select RecordLocator from rez.Booking B where B.BookingID = #Temp3.BookingID), #Temp3.BookingID , #Temp3.PassengerID , 
FlightNumber = CASE(FlightNumber) WHEN '' THEN (select top 1 FlightNumber from rez.BookingPassenger BP inner join rez.PassengerJourneySegment PJS on PJS.PassengerID = BP.PassengerID where BP.BookingID = #Temp3.BookingID order by PJS.DepartureDate) ELSE FlightNumber END ,  
DepStation = CASE(DepartureStation) WHEN '' THEN (select top 1 DepartureStation from rez.BookingPassenger BP inner join rez.PassengerJourneySegment PJS on PJS.PassengerID = BP.PassengerID where BP.BookingID = #Temp3.BookingID order by PJS.DepartureDate) ELSE DepartureStation END , 
ArrStation = CASE(ArrivalStation) WHEN '' THEN (select top 1 ArrivalStation from rez.BookingPassenger BP inner join rez.PassengerJourneySegment PJS on PJS.PassengerID = BP.PassengerID where BP.BookingID = #Temp3.BookingID order by PJS.DepartureDate) ELSE ArrivalStation END ,#Temp3.ChargeCode, #Temp3.ChargeAmount,#Temp3.FeeNumber   into #Temp4 from #Temp3

group by #Temp3.DepatureDate, #Temp3.BookingID ,#Temp3.PassengerID,#Temp3.FlightNumber, #Temp3.DepartureStation , #Temp3.ArrivalStation , #Temp3.ChargeCode, #Temp3.ChargeAmount,#Temp3.FeeNumber ,#Temp3.InventoryLegID

--select PNR ,DepartureDate = (select top 1 IL2.STD from rez.BookingPassenger BP inner join rez.PassengerJourneySegment PJS on PJS.PassengerID = BP.PassengerID  inner join rez.PassengerJourneyLeg PJL2  on PJL2.PassengerID=PJS.PassengerID  and PJL2.SegmentID=PJS.SegmentID    inner join rez.InventoryLeg IL2  on IL2.InventoryLegID=PJL2.InventoryLegID 
--left outer join rez.PassengerFee PF on BP.passengerid = PF.passengerid 
--left outer join rez.PassengerFeeCharge PFC on PF.passengerid = PFC.passengerid and PF.FeeNumber = PFC.FeeNumber
--where BP.BookingID = #Temp4.BookingID and PJS.DepartureStation = #Temp4.DepStation and PJS.arrivalstation = #Temp4.ArrStation
--order by PJS.DepartureDate ),FlightNumber,DepStation , ArrStation , ChargeCode,chargeamount  into #Temp5 from #Temp4 order by PNR

select InventoryLegID, PNR ,
 DepartureDate=#Temp4.DepatureDate,FlightNumber,DepStation , ArrStation , ChargeCode,chargeamount 
into #Temp5 
from #Temp4 order by PNR

--select distinct  PNR,DepartureDate ,FlightNumber, DepStation , ArrStation , ChargeCode,chargeamount=1,count (ChargeCode) as Chargecount  from #Temp5
--where (departureDate is null or departureDate between @StartDate and @EndDate2)
--and ChargeCode in ('STND','BNPB','BNME','BNMC','BNMF','BNFG','BNFH','BNVA','BNVD','ANCB','ANCD','ANEA','ANEC','ANME','ANMF','CNPA','CNEB','CNTC','CNVD','BCHA','BCHB')
--group by PNR,DepartureDate,FlightNumber,DepStation , ArrStation ,ChargeCode,chargeamount
--order by DepartureDate,FlightNumber

--SELECT *
--FROM (
    SELECT 
       --PNR,
        DepartureDate,
		FlightNumber,
        DepStation,
        ArrStation,

		Economy=(select count(distinct BP.PassengerID) from rez.BookingPassenger BP inner join rez.booking b on b.bookingid=bp.BookingID INNER JOIN rez.PassengerJourneySegment pjs ON BP.PassengerID = PJS.PassengerID 
  INNER JOIN rez.PassengerJourneyLeg PJL ON PJS.PassengerID = PJL.PassengerID and Pjs.SegmentID = PJL.SegmentID
  INNER JOIN rez.InventoryLeg IL1 ON IL1.inventoryLegID  = PJL.inventoryLegID 
  where #Temp5.[InventoryLegID]=IL1.[InventoryLegID] and PJS.ClassOfService not in ('R','C','J','DJ','GB','RM','RIN','CIN')),

  		OnlineUpgrade=(select count(distinct BP.PassengerID) from rez.BookingPassenger BP inner join rez.booking b on b.bookingid=bp.BookingID INNER JOIN rez.PassengerJourneySegment pjs ON BP.PassengerID = PJS.PassengerID 
  INNER JOIN rez.PassengerJourneyLeg PJL ON PJS.PassengerID = PJL.PassengerID and Pjs.SegmentID = PJL.SegmentID
  INNER JOIN rez.InventoryLeg IL1 ON IL1.inventoryLegID  = PJL.inventoryLegID 
  where #Temp5.[InventoryLegID]=IL1.[InventoryLegID] and PJS.ClassOfService in ('JB')),

   		AirportUpgrade=(select count(distinct BP.PassengerID) from rez.BookingPassenger BP inner join rez.booking b on b.bookingid=bp.BookingID INNER JOIN rez.PassengerJourneySegment pjs ON BP.PassengerID = PJS.PassengerID 
  INNER JOIN rez.PassengerJourneyLeg PJL ON PJS.PassengerID = PJL.PassengerID and Pjs.SegmentID = PJL.SegmentID
  INNER JOIN rez.InventoryLeg IL1 ON IL1.inventoryLegID  = PJL.inventoryLegID 
  where #Temp5.[InventoryLegID]=IL1.[InventoryLegID] and PJS.ClassOfService in ('UG')),


  
    premium=(select count(distinct BP.PassengerID) from rez.BookingPassenger BP inner join rez.booking b on b.bookingid=bp.BookingID INNER JOIN rez.PassengerJourneySegment pjs ON BP.PassengerID = PJS.PassengerID 
  INNER JOIN rez.PassengerJourneyLeg PJL ON PJS.PassengerID = PJL.PassengerID and Pjs.SegmentID = PJL.SegmentID
  INNER JOIN rez.InventoryLeg IL1 ON IL1.inventoryLegID  = PJL.inventoryLegID 
  where (#Temp5.[InventoryLegID]=IL1.[InventoryLegID] and PJS.ClassOfService in ('R','C','J','DJ','GB','RM','RIN','CIN') )),
  
  BNPB=(select count(distinct BP.PassengerID) from rez.BookingPassenger BP inner join rez.booking b on b.bookingid=bp.BookingID INNER JOIN rez.PassengerJourneySegment pjs ON BP.PassengerID = PJS.PassengerID 
  INNER JOIN rez.PassengerJourneyLeg PJL ON PJS.PassengerID = PJL.PassengerID and Pjs.SegmentID = PJL.SegmentID
  INNER JOIN rez.InventoryLeg IL1 ON IL1.inventoryLegID  = PJL.inventoryLegID 
  INNER  join rez.PassengerFee PF on BP.passengerid = PF.passengerid and PF.InventoryLegID=IL1.InventoryLegID
  INNER  join rez.PassengerFeeCharge PFC on PF.passengerid = PFC.passengerid and PF.FeeNumber = PFC.FeeNumber
  where (#Temp5.[InventoryLegID]=IL1.[InventoryLegID] and PJS.ClassOfService in ('R','C','J','DJ','GB','RM','RIN','CIN') and PFC.ChargeCode   in ('BNPB'))),

  BNME=(select count(distinct BP.PassengerID) from rez.BookingPassenger BP inner join rez.booking b on b.bookingid=bp.BookingID INNER JOIN rez.PassengerJourneySegment pjs ON BP.PassengerID = PJS.PassengerID 
  INNER JOIN rez.PassengerJourneyLeg PJL ON PJS.PassengerID = PJL.PassengerID and Pjs.SegmentID = PJL.SegmentID
  INNER JOIN rez.InventoryLeg IL1 ON IL1.inventoryLegID  = PJL.inventoryLegID 
  INNER  join rez.PassengerFee PF on BP.passengerid = PF.passengerid  and PF.InventoryLegID=IL1.InventoryLegID
  INNER  join rez.PassengerFeeCharge PFC on PF.passengerid = PFC.passengerid and PF.FeeNumber = PFC.FeeNumber
  where (#Temp5.[InventoryLegID]=IL1.[InventoryLegID] and PJS.ClassOfService in ('R','C','J','DJ','GB','RM','RIN','CIN') and PFC.ChargeCode   in ('BNME'))),

   BNMC=(select count(distinct BP.PassengerID) from rez.BookingPassenger BP inner join rez.booking b on b.bookingid=bp.BookingID INNER JOIN rez.PassengerJourneySegment pjs ON BP.PassengerID = PJS.PassengerID 
  INNER JOIN rez.PassengerJourneyLeg PJL ON PJS.PassengerID = PJL.PassengerID and Pjs.SegmentID = PJL.SegmentID
  INNER JOIN rez.InventoryLeg IL1 ON IL1.inventoryLegID  = PJL.inventoryLegID 
  INNER  join rez.PassengerFee PF on BP.passengerid = PF.passengerid and PF.InventoryLegID=IL1.InventoryLegID
  INNER  join rez.PassengerFeeCharge PFC on PF.passengerid = PFC.passengerid and PF.FeeNumber = PFC.FeeNumber
  where (#Temp5.[InventoryLegID]=IL1.[InventoryLegID] and PJS.ClassOfService in ('R','C','J','DJ','GB','RM','RIN','CIN') and PFC.ChargeCode   in ('BNMC'))),

   BNMF=(select count(distinct BP.PassengerID) from rez.BookingPassenger BP inner join rez.booking b on b.bookingid=bp.BookingID INNER JOIN rez.PassengerJourneySegment pjs ON BP.PassengerID = PJS.PassengerID 
  INNER JOIN rez.PassengerJourneyLeg PJL ON PJS.PassengerID = PJL.PassengerID and Pjs.SegmentID = PJL.SegmentID
  INNER JOIN rez.InventoryLeg IL1 ON IL1.inventoryLegID  = PJL.inventoryLegID 
  INNER  join rez.PassengerFee PF on BP.passengerid = PF.passengerid and PF.InventoryLegID=IL1.InventoryLegID
  INNER  join rez.PassengerFeeCharge PFC on PF.passengerid = PFC.passengerid and PF.FeeNumber = PFC.FeeNumber
  where (#Temp5.[InventoryLegID]=IL1.[InventoryLegID] and PJS.ClassOfService in ('R','C','J','DJ','GB','RM','RIN','CIN') and PFC.ChargeCode   in ('BNMF'))) ,

        
		-- 1. BNFG
BNFG = (
  SELECT COUNT(DISTINCT BP.PassengerID)
  FROM rez.BookingPassenger BP
  INNER JOIN rez.Booking B
    ON B.BookingID = BP.BookingID
  INNER JOIN rez.PassengerJourneySegment PJS
    ON BP.PassengerID = PJS.PassengerID
  INNER JOIN rez.PassengerJourneyLeg PJL
    ON PJS.PassengerID = PJL.PassengerID
   AND PJS.SegmentID   = PJL.SegmentID
  INNER JOIN rez.InventoryLeg IL1
    ON IL1.InventoryLegID = PJL.InventoryLegID
  INNER JOIN rez.PassengerFee PF
    ON BP.PassengerID = PF.PassengerID and PF.InventoryLegID=IL1.InventoryLegID
  INNER JOIN rez.PassengerFeeCharge PFC
    ON PF.PassengerID = PFC.PassengerID
   AND PF.FeeNumber    = PFC.FeeNumber
  WHERE #Temp5.InventoryLegID = IL1.InventoryLegID
    AND PJS.ClassOfService IN ('R','C','J','DJ','GB','RM','RIN','CIN')
    AND PFC.ChargeCode = 'BNFG'
),

-- 2. BNFH
BNFH = (
  SELECT COUNT(DISTINCT BP.PassengerID)
  FROM rez.BookingPassenger BP
  INNER JOIN rez.Booking B
    ON B.BookingID = BP.BookingID
  INNER JOIN rez.PassengerJourneySegment PJS
    ON BP.PassengerID = PJS.PassengerID
  INNER JOIN rez.PassengerJourneyLeg PJL
    ON PJS.PassengerID = PJL.PassengerID
   AND PJS.SegmentID   = PJL.SegmentID
  INNER JOIN rez.InventoryLeg IL1
    ON IL1.InventoryLegID = PJL.InventoryLegID
  INNER JOIN rez.PassengerFee PF
    ON BP.PassengerID = PF.PassengerID and PF.InventoryLegID=IL1.InventoryLegID
  INNER JOIN rez.PassengerFeeCharge PFC
    ON PF.PassengerID = PFC.PassengerID 
   AND PF.FeeNumber    = PFC.FeeNumber
  WHERE #Temp5.InventoryLegID = IL1.InventoryLegID
    AND PJS.ClassOfService IN ('R','C','J','DJ','GB','RM','RIN','CIN')
    AND PFC.ChargeCode = 'BNFH'
),

-- 3. BNVA
BNVA = (
  SELECT COUNT(DISTINCT BP.PassengerID)
  FROM rez.BookingPassenger BP
  INNER JOIN rez.Booking B
    ON B.BookingID = BP.BookingID
  INNER JOIN rez.PassengerJourneySegment PJS
    ON BP.PassengerID = PJS.PassengerID
  INNER JOIN rez.PassengerJourneyLeg PJL
    ON PJS.PassengerID = PJL.PassengerID
   AND PJS.SegmentID   = PJL.SegmentID
  INNER JOIN rez.InventoryLeg IL1
    ON IL1.InventoryLegID = PJL.InventoryLegID
  INNER JOIN rez.PassengerFee PF
    ON BP.PassengerID = PF.PassengerID  and PF.InventoryLegID=IL1.InventoryLegID
  INNER JOIN rez.PassengerFeeCharge PFC
    ON PF.PassengerID = PFC.PassengerID
   AND PF.FeeNumber    = PFC.FeeNumber
  WHERE #Temp5.InventoryLegID = IL1.InventoryLegID
    AND PJS.ClassOfService IN ('R','C','J','DJ','GB','RM','RIN','CIN')
    AND PFC.ChargeCode = 'BNVA'
),

-- 4. BNVD
BNVD = (
  SELECT COUNT(DISTINCT BP.PassengerID)
  FROM rez.BookingPassenger BP
  INNER JOIN rez.Booking B
    ON B.BookingID = BP.BookingID
  INNER JOIN rez.PassengerJourneySegment PJS
    ON BP.PassengerID = PJS.PassengerID
  INNER JOIN rez.PassengerJourneyLeg PJL
    ON PJS.PassengerID = PJL.PassengerID
   AND PJS.SegmentID   = PJL.SegmentID
  INNER JOIN rez.InventoryLeg IL1
    ON IL1.InventoryLegID = PJL.InventoryLegID
  INNER JOIN rez.PassengerFee PF
    ON BP.PassengerID = PF.PassengerID  and PF.InventoryLegID=IL1.InventoryLegID
  INNER JOIN rez.PassengerFeeCharge PFC
    ON PF.PassengerID = PFC.PassengerID
   AND PF.FeeNumber    = PFC.FeeNumber
  WHERE #Temp5.InventoryLegID = IL1.InventoryLegID
    AND PJS.ClassOfService IN ('R','C','J','DJ','GB','RM','RIN','CIN')
    AND PFC.ChargeCode = 'BNVD'
),

-- 5. ANCB
ANCB = (
  SELECT COUNT(DISTINCT BP.PassengerID)
  FROM rez.BookingPassenger BP
  INNER JOIN rez.Booking B
    ON B.BookingID = BP.BookingID
  INNER JOIN rez.PassengerJourneySegment PJS
    ON BP.PassengerID = PJS.PassengerID
  INNER JOIN rez.PassengerJourneyLeg PJL
    ON PJS.PassengerID = PJL.PassengerID
   AND PJS.SegmentID   = PJL.SegmentID
  INNER JOIN rez.InventoryLeg IL1
    ON IL1.InventoryLegID = PJL.InventoryLegID
  INNER JOIN rez.PassengerFee PF
    ON BP.PassengerID = PF.PassengerID and PF.InventoryLegID=IL1.InventoryLegID
  INNER JOIN rez.PassengerFeeCharge PFC
    ON PF.PassengerID = PFC.PassengerID
   AND PF.FeeNumber    = PFC.FeeNumber
  WHERE #Temp5.InventoryLegID = IL1.InventoryLegID
    AND PJS.ClassOfService IN ('R','C','J','DJ','GB','RM','RIN','CIN')
    AND PFC.ChargeCode = 'ANCB'
),

-- 6. ANCD
ANCD = (
  SELECT COUNT(DISTINCT BP.PassengerID)
  FROM rez.BookingPassenger BP
  INNER JOIN rez.Booking B
    ON B.BookingID = BP.BookingID
  INNER JOIN rez.PassengerJourneySegment PJS
    ON BP.PassengerID = PJS.PassengerID
  INNER JOIN rez.PassengerJourneyLeg PJL
    ON PJS.PassengerID = PJL.PassengerID
   AND PJS.SegmentID   = PJL.SegmentID
  INNER JOIN rez.InventoryLeg IL1
    ON IL1.InventoryLegID = PJL.InventoryLegID
  INNER JOIN rez.PassengerFee PF
    ON BP.PassengerID = PF.PassengerID and PF.InventoryLegID=IL1.InventoryLegID
  INNER JOIN rez.PassengerFeeCharge PFC
    ON PF.PassengerID = PFC.PassengerID
   AND PF.FeeNumber    = PFC.FeeNumber
  WHERE #Temp5.InventoryLegID = IL1.InventoryLegID
    AND PJS.ClassOfService IN ('R','C','J','DJ','GB','RM','RIN','CIN')
    AND PFC.ChargeCode = 'ANCD'
),

-- 7. ANEA
ANEA = (
  SELECT COUNT(DISTINCT BP.PassengerID)
  FROM rez.BookingPassenger BP
  INNER JOIN rez.Booking B
    ON B.BookingID = BP.BookingID
  INNER JOIN rez.PassengerJourneySegment PJS
    ON BP.PassengerID = PJS.PassengerID
  INNER JOIN rez.PassengerJourneyLeg PJL
    ON PJS.PassengerID = PJL.PassengerID
   AND PJS.SegmentID   = PJL.SegmentID
  INNER JOIN rez.InventoryLeg IL1
    ON IL1.InventoryLegID = PJL.InventoryLegID
  INNER JOIN rez.PassengerFee PF
    ON BP.PassengerID = PF.PassengerID and PF.InventoryLegID=IL1.InventoryLegID
  INNER JOIN rez.PassengerFeeCharge PFC
    ON PF.PassengerID = PFC.PassengerID
   AND PF.FeeNumber    = PFC.FeeNumber
  WHERE #Temp5.InventoryLegID = IL1.InventoryLegID
    AND PJS.ClassOfService IN ('R','C','J','DJ','GB','RM','RIN','CIN')
    AND PFC.ChargeCode = 'ANEA'
),

-- 8. ANEC
ANEC = (
  SELECT COUNT(DISTINCT BP.PassengerID)
  FROM rez.BookingPassenger BP
  INNER JOIN rez.Booking B
    ON B.BookingID = BP.BookingID
  INNER JOIN rez.PassengerJourneySegment PJS
    ON BP.PassengerID = PJS.PassengerID
  INNER JOIN rez.PassengerJourneyLeg PJL
    ON PJS.PassengerID = PJL.PassengerID
   AND PJS.SegmentID   = PJL.SegmentID
  INNER JOIN rez.InventoryLeg IL1
    ON IL1.InventoryLegID = PJL.InventoryLegID
  INNER JOIN rez.PassengerFee PF
    ON BP.PassengerID = PF.PassengerID and PF.InventoryLegID=IL1.InventoryLegID
  INNER JOIN rez.PassengerFeeCharge PFC
    ON PF.PassengerID = PFC.PassengerID
   AND PF.FeeNumber    = PFC.FeeNumber
  WHERE #Temp5.InventoryLegID = IL1.InventoryLegID
    AND PJS.ClassOfService IN ('R','C','J','DJ','GB','RM','RIN','CIN')
    AND PFC.ChargeCode = 'ANEC'
),

-- 9. ANME
ANME = (
  SELECT COUNT(DISTINCT BP.PassengerID)
  FROM rez.BookingPassenger BP
  INNER JOIN rez.Booking B
    ON B.BookingID = BP.BookingID
  INNER JOIN rez.PassengerJourneySegment PJS
    ON BP.PassengerID = PJS.PassengerID
  INNER JOIN rez.PassengerJourneyLeg PJL
    ON PJS.PassengerID = PJL.PassengerID
   AND PJS.SegmentID   = PJL.SegmentID
  INNER JOIN rez.InventoryLeg IL1
    ON IL1.InventoryLegID = PJL.InventoryLegID
  INNER JOIN rez.PassengerFee PF
    ON BP.PassengerID = PF.PassengerID and PF.InventoryLegID=IL1.InventoryLegID
  INNER JOIN rez.PassengerFeeCharge PFC
    ON PF.PassengerID = PFC.PassengerID
   AND PF.FeeNumber    = PFC.FeeNumber
  WHERE #Temp5.InventoryLegID = IL1.InventoryLegID
    AND PJS.ClassOfService IN ('R','C','J','DJ','GB','RM','RIN','CIN')
    AND PFC.ChargeCode = 'ANME'
),

-- 10. ANMF
ANMF = (
  SELECT COUNT(DISTINCT BP.PassengerID)
  FROM rez.BookingPassenger BP
  INNER JOIN rez.Booking B
    ON B.BookingID = BP.BookingID
  INNER JOIN rez.PassengerJourneySegment PJS
    ON BP.PassengerID = PJS.PassengerID
  INNER JOIN rez.PassengerJourneyLeg PJL
    ON PJS.PassengerID = PJL.PassengerID
   AND PJS.SegmentID   = PJL.SegmentID
  INNER JOIN rez.InventoryLeg IL1
    ON IL1.InventoryLegID = PJL.InventoryLegID
  INNER JOIN rez.PassengerFee PF
    ON BP.PassengerID = PF.PassengerID and PF.InventoryLegID=IL1.InventoryLegID
  INNER JOIN rez.PassengerFeeCharge PFC
    ON PF.PassengerID = PFC.PassengerID
   AND PF.FeeNumber    = PFC.FeeNumber
  WHERE #Temp5.InventoryLegID = IL1.InventoryLegID
    AND PJS.ClassOfService IN ('R','C','J','DJ','GB','RM','RIN','CIN')
    AND PFC.ChargeCode = 'ANMF'
),

-- 11. CNPA
CNPA = (
  SELECT COUNT(DISTINCT BP.PassengerID)
  FROM rez.BookingPassenger BP
  INNER JOIN rez.Booking B
    ON B.BookingID = BP.BookingID
  INNER JOIN rez.PassengerJourneySegment PJS
    ON BP.PassengerID = PJS.PassengerID
  INNER JOIN rez.PassengerJourneyLeg PJL
    ON PJS.PassengerID = PJL.PassengerID
   AND PJS.SegmentID   = PJL.SegmentID
  INNER JOIN rez.InventoryLeg IL1
    ON IL1.InventoryLegID = PJL.InventoryLegID
  INNER JOIN rez.PassengerFee PF
    ON BP.PassengerID = PF.PassengerID and PF.InventoryLegID=IL1.InventoryLegID
  INNER JOIN rez.PassengerFeeCharge PFC
    ON PF.PassengerID = PFC.PassengerID
   AND PF.FeeNumber    = PFC.FeeNumber
  WHERE #Temp5.InventoryLegID = IL1.InventoryLegID
    AND PJS.ClassOfService IN ('R','C','J','DJ','GB','RM','RIN','CIN')
    AND PFC.ChargeCode = 'CNPA'
),

-- 12. CNEB
CNEB = (
  SELECT COUNT(DISTINCT BP.PassengerID)
  FROM rez.BookingPassenger BP
  INNER JOIN rez.Booking B
    ON B.BookingID = BP.BookingID
  INNER JOIN rez.PassengerJourneySegment PJS
    ON BP.PassengerID = PJS.PassengerID
  INNER JOIN rez.PassengerJourneyLeg PJL
    ON PJS.PassengerID = PJL.PassengerID
   AND PJS.SegmentID   = PJL.SegmentID
  INNER JOIN rez.InventoryLeg IL1
    ON IL1.InventoryLegID = PJL.InventoryLegID
  INNER JOIN rez.PassengerFee PF
    ON BP.PassengerID = PF.PassengerID and PF.InventoryLegID=IL1.InventoryLegID
  INNER JOIN rez.PassengerFeeCharge PFC
    ON PF.PassengerID = PFC.PassengerID
   AND PF.FeeNumber    = PFC.FeeNumber
  WHERE #Temp5.InventoryLegID = IL1.InventoryLegID
    AND PJS.ClassOfService IN ('R','C','J','DJ','GB','RM','RIN','CIN')
    AND PFC.ChargeCode = 'CNEB'
),

-- 13. CNTC
CNTC = (
  SELECT COUNT(DISTINCT BP.PassengerID)
  FROM rez.BookingPassenger BP
  INNER JOIN rez.Booking B
    ON B.BookingID = BP.BookingID
  INNER JOIN rez.PassengerJourneySegment PJS
    ON BP.PassengerID = PJS.PassengerID
  INNER JOIN rez.PassengerJourneyLeg PJL
    ON PJS.PassengerID = PJL.PassengerID
   AND PJS.SegmentID   = PJL.SegmentID
  INNER JOIN rez.InventoryLeg IL1
    ON IL1.InventoryLegID = PJL.InventoryLegID
  INNER JOIN rez.PassengerFee PF
    ON BP.PassengerID = PF.PassengerID and PF.InventoryLegID=IL1.InventoryLegID
  INNER JOIN rez.PassengerFeeCharge PFC
    ON PF.PassengerID = PFC.PassengerID
   AND PF.FeeNumber    = PFC.FeeNumber
  WHERE #Temp5.InventoryLegID = IL1.InventoryLegID
    AND PJS.ClassOfService IN ('R','C','J','DJ','GB','RM','RIN','CIN')
    AND PFC.ChargeCode = 'CNTC'
),

-- 14. CNVD
CNVD = (
  SELECT COUNT(DISTINCT BP.PassengerID)
  FROM rez.BookingPassenger BP
  INNER JOIN rez.Booking B
    ON B.BookingID = BP.BookingID
  INNER JOIN rez.PassengerJourneySegment PJS
    ON BP.PassengerID = PJS.PassengerID
  INNER JOIN rez.PassengerJourneyLeg PJL
    ON PJS.PassengerID = PJL.PassengerID
   AND PJS.SegmentID   = PJL.SegmentID
  INNER JOIN rez.InventoryLeg IL1
    ON IL1.InventoryLegID = PJL.InventoryLegID
  INNER JOIN rez.PassengerFee PF
    ON BP.PassengerID = PF.PassengerID and PF.InventoryLegID=IL1.InventoryLegID
  INNER JOIN rez.PassengerFeeCharge PFC
    ON PF.PassengerID = PFC.PassengerID
   AND PF.FeeNumber    = PFC.FeeNumber
  WHERE #Temp5.InventoryLegID = IL1.InventoryLegID
    AND PJS.ClassOfService IN ('R','C','J','DJ','GB','RM','RIN','CIN')
    AND PFC.ChargeCode = 'CNVD'
),

-- 15. BCHA
BCHA = (
  SELECT COUNT(DISTINCT BP.PassengerID)
  FROM rez.BookingPassenger BP
  INNER JOIN rez.Booking B
    ON B.BookingID = BP.BookingID
  INNER JOIN rez.PassengerJourneySegment PJS
    ON BP.PassengerID = PJS.PassengerID
  INNER JOIN rez.PassengerJourneyLeg PJL
    ON PJS.PassengerID = PJL.PassengerID
   AND PJS.SegmentID   = PJL.SegmentID
  INNER JOIN rez.InventoryLeg IL1
    ON IL1.InventoryLegID = PJL.InventoryLegID
  INNER JOIN rez.PassengerFee PF
    ON BP.PassengerID = PF.PassengerID and PF.InventoryLegID=IL1.InventoryLegID
  INNER JOIN rez.PassengerFeeCharge PFC
    ON PF.PassengerID = PFC.PassengerID
   AND PF.FeeNumber    = PFC.FeeNumber
  WHERE #Temp5.InventoryLegID = IL1.InventoryLegID
    AND PJS.ClassOfService IN ('R','C','J','DJ','GB','RM','RIN','CIN')
    AND PFC.ChargeCode = 'BCHA'
),

-- 16. BCHB
BCHB = (
  SELECT COUNT(DISTINCT BP.PassengerID)
  FROM rez.BookingPassenger BP
  INNER JOIN rez.Booking B
    ON B.BookingID = BP.BookingID
  INNER JOIN rez.PassengerJourneySegment PJS
    ON BP.PassengerID = PJS.PassengerID
  INNER JOIN rez.PassengerJourneyLeg PJL
    ON PJS.PassengerID = PJL.PassengerID
   AND PJS.SegmentID   = PJL.SegmentID
  INNER JOIN rez.InventoryLeg IL1
    ON IL1.InventoryLegID = PJL.InventoryLegID
  INNER JOIN rez.PassengerFee PF
    ON BP.PassengerID = PF.PassengerID and PF.InventoryLegID=IL1.InventoryLegID
  INNER JOIN rez.PassengerFeeCharge PFC
    ON PF.PassengerID = PFC.PassengerID
   AND PF.FeeNumber    = PFC.FeeNumber
  WHERE #Temp5.InventoryLegID = IL1.InventoryLegID
    AND PJS.ClassOfService IN ('R','C','J','DJ','GB','RM','RIN','CIN')
    AND PFC.ChargeCode = 'BCHB'
)

        --ChargeCode,
       -- COUNT(ChargeCode) AS ChargeCount
 into #Temp6  
 FROM #Temp5
    WHERE (DepartureDate BETWEEN @StartDate AND @EndDate)
    --AND ChargeCode IN ('STND','BNPB','BNME','BNMC','BNMF','BNFG','BNFH','BNVA','BNVD',
    --                   'ANCB','ANCD','ANEA','ANEC','ANME','ANMF','CNPA','CNEB','CNTC',
    --                   'CNVD','BCHA','BCHB')
    GROUP BY  DepartureDate, FlightNumber, DepStation, ArrStation, InventoryLegID
	--,pnr
--) AS SourceTable

ORDER BY FlightNumber,DepartureDate

select DepartureDate,FlightNumber,DepStation,ArrStation,Economy,premium,STND=premium -(BNPB+BNME+BNMC+BNMF+BNFG+BNFH+BNVA+BNVD+ ANCB+ANCD+ANEA+ANEC+ANME+ANMF+CNPA+CNEB+CNTC+CNVD+BCHA+BCHB),OnlineUpgrade,AirportUpgrade,BNPB,BNME,BNMC,BNMF,BNFG,BNFH,BNVA,BNVD, ANCB,ANCD,ANEA,ANEC,ANME,ANMF,CNPA,CNEB,CNTC, CNVD,BCHA,BCHB from #Temp6
ORDER BY FlightNumber,DepartureDate