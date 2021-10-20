

DECLARE @ReportDay smalldatetime
DECLARE @StartDate smalldatetime
DECLARE @EndDate smalldatetime
DECLARE @TimeZone int


------------------------------------------------------------------------------------------------
--Utilization Report Query Instructions.
------------------------------------------------------------------------------------------------

/*
This report query shows you the total lines or channels in use on a minutes-by-minutes bases.
That is, for each minute of a 24 hour day (midnight to midnight).

Run from Microsoft's SQL Management Studio. Follow steps 1-4 below.

*/
------------------------------------------------------------------------------------------------

--Step #1: The datasource is noted below. Refer to the "USE" identifier above.
--NS9: NSPortServerBilling.dbo.BILLING_TABLE
--NSX: NETSatisFAXtionMain.dbo.BILLING_TABLE

--USE NSPortServerBilling --Set for NS9 based fax systems
USE NETSatisFAXtionMain --Set for NSX based fax systems

--Step #2: Set and adjust the correct timezone
SET @TimeZone = -7 --PDT: -7, PST: -8

--Step #3: Set the day for the report. This report only covers a single day or 24 hour period.

-- JDG We commenting this out as we don't need to delcare it here
--SET @ReportDay = '2021-10-18 14:00:00' --Both '9/21/2021' and '2021-09-21' date formats can be used here.
--SET @ReportDateTimeEnd = '2021-10-18 14:59:59' -- JDG added this

--Step #4, Copy and/or graph Minutes vs. Total Utization in Excel.
--You can also change the Order By settings at the bottom of this query. Just comment / uncomment
--the correct Order By that you want to use.


------------------------------------------------------------------------------------------------
--Utilization Report Query, Please DO NOT change below this line.
------------------------------------------------------------------------------------------------

-- JDG we commented this out as we just need the hourly report so we will replace start and enddate with report-time-start and reort-time-end
/*
SET @StartDate = @ReportDay
SET @EndDate =   DATEADD(day,1,@ReportDay)
*/

--Select @StartDate, @EndDate

-- JDG we are going to replace StartDate and Endate Value in this format yyyy-mm-dd HH:mm:ss
SET @StartDate = 'report-time-start'
SET @EndDate =   'report-time-end'


--set @StartDate = FORMAT(GETDATE(),'yyyy') + '-' + FORMAT(GETDATE(),'MM') + '-' + FORMAT(GETDATE(),'dd') + ' 00:00:00.000'
--set @EndDate = FORMAT(DATEADD(day,1,GETDATE()),'yyyy') + '-' + FORMAT(DATEADD(day,1,GETDATE()),'MM') + '-' + FORMAT(DATEADD(day,1,GETDATE()),'dd') + ' 00:00:00.000'

--The following lines remove any minutes from the times set above.

-- JDG We will comment these out as we need the time so we dont need to strip it off
-- SET @StartDate = DATEADD(minute,-DATEPART(minute,@StartDate),@StartDate)
-- SET @EndDate = DATEADD(minute,-DATEPART(minute,@EndDate),@EndDate);


Declare @Timeline AS TABLE (Date smalldatetime);
Declare @Day As Int;
Declare @LastDay As Int;

--Setup the counters and cursors
DECLARE @RowCounter INT = 1;
DECLARE @RowCursor as CURSOR;
Declare @Slot INT = 0;

--Both @CDRs and @Durations must be the same as they are in a UNION
declare @CDRs AS TABLE (MinuteSlot varchar(25), Duration Int, StartTime datetime, TotalSeconds int, IsSend int, PortServer nvarchar(64), FaxErrorCode Int, FaxResult Int);
declare @Durations AS TABLE (MinuteSlot varchar(25), Duration Int, StartTime datetime, TotalSeconds int, IsSend int, PortServer nvarchar(64), FaxErrorCode Int, FaxResult Int);

DECLARE @MinuteSlot varchar(25);
Declare @Duration Int;
Declare @StartTime datetime;
Declare @TotalSeconds Int;
Declare @IsSend Int;
Declare @PortServer nvarchar(64);
Declare @FaxErrorCode Int;
Declare @FaxResult Int;



--Get the list of CDR's
--DECLARE @StartDate smalldatetime
--DECLARE @EndDate smalldatetime
--DECLARE @TimeZone int
--DECLARE @LocalTime datetime
DECLARE @PortStillBusy datetime


Declare @NotOurProblemErrors table(NotOurProblemErrorsTable int);


--For the Busy, Voice, No Answer errors use ... [NOT] IN (Select * From @NotOurProblemErrors)
--From FaxSIPit
--NO ANSWER
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (27977) --No answer
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (28026) --No answer
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (29202) --No answer (cause=18)
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (29203) --No answer from user (user alerted) (cause=19)
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (29215) --Normal unspecified (cause=31) (able to replicate)
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (30237) --No answer

insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (28025) --Voice answered (able to replicate)
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (30209) --Voice called   (able to replicate)
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (27979) --Voice answered (unverified)
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (27985) --Voice answered (unverified)
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (30239) --Voice answered (unverified)
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (30246) --Voice answered (unverified)
 
--SIT TONES
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (28023) --Number not in service
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (28027) --Reorder tone
 
--BUSY
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (28024) --Busy
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (29201) --Busy (cause=17)
 
--From IAFax
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (28502) --Busy (486)
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (29201) --Busy (cause 17)
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (30245) --Busy
 
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (30209) --Voice answered: didn't receive handshake after 35 seconds
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (30237) --No answer
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (30247) --No answer
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (30248) --Number not in service: reorder (fast busy) tone detected
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (30244) --Number not in service: Special Information Tone detected
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (29185) --Number not in service (cause 1)

insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (29200) --Voice answered: Call was hung up (cause 16)
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (30243) --Voice answered: Call was hung up (received BYE)

insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (28420) --404 Not found
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (29218) --Busy: no circuit available (cause 34)
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (29225) --Busy: temporary failure in phone network (cause 41)

--Inbound Errors
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (30002) --Account logged out 11
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (30004) --Receive is disabled for this account 779
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (30007) --No sessions available 377
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (30011) --DID not found 44
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (30016) --Client refused or unable to accept receive fax 8
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (30224) --Call hung up (received DCN) 113
insert into @NotOurProblemErrors (NotOurProblemErrorsTable) values (30271) --Call was canceled (received CANCEL) 18


Insert Into @CDRs

Select

--MinuteSlot
CONCAT
(
	RIGHT('0'+ CONVERT(VARCHAR,DatePart(yyyy,DATEADD(hour,@TimeZone,StartTime))), 4), '-',
	RIGHT('0'+ CONVERT(VARCHAR,DatePart(mm,DATEADD(hour,@TimeZone,StartTime))), 2), '-',
	RIGHT('0'+ CONVERT(VARCHAR,DatePart(dd,DATEADD(hour,@TimeZone,StartTime))), 2), ' ',
	RIGHT('0'+ CONVERT(VARCHAR,DatePart(hh,DATEADD(hour,@TimeZone,StartTime))), 2), ':',
	RIGHT('0'+ CONVERT(VARCHAR,DatePart(mi,DATEADD(hour,@TimeZone,StartTime))), 2)
),

--Duration
CASE
  WHEN CEILING(Cast(TotalSeconds As decimal)/60)-1 < 0 THEN 0
  ELSE CEILING(Cast(TotalSeconds As decimal)/60)-1
END,

CONVERT(datetime,DATEADD(hour,@TimeZone, StartTime),104),
TotalSeconds,
IsSend,
PortServer,
FaxErrorCode,

CASE
  WHEN FaxErrorCode = 0 THEN 0 --Successful
  WHEN FaxErrorCode <> 0 AND FaxErrorCode IN (Select * From @NotOurProblemErrors) THEN 1 --Not our issue, e.g. busy, not answer or voice answered
  WHEN FaxErrorCode <> 0 AND FaxErrorCode NOT IN (Select * From @NotOurProblemErrors) THEN 2 --Fax error
  ELSE 2
END As FaxResult

From BILLING_TABLE

Where

CDRType = 0 AND

(
  (CONVERT(datetime,DATEADD(hour,@TimeZone, StartTime),104) BETWEEN @StartDate AND @EndDate)

  OR

  ((CONVERT(datetime,DATEADD(hour,@TimeZone, CreatedOn),104) BETWEEN @StartDate AND @EndDate) AND CONVERT(datetime,DATEADD(hour,@TimeZone, StartTime),104) < @StartDate)
)

--AND IsSend = 1



--Select * From @CDRs Order By MinuteSlot Asc



SET @RowCursor = CURSOR FOR
Select * From @CDRs;
 
OPEN @RowCursor;
FETCH NEXT FROM @RowCursor INTO @MinuteSlot, @Duration, @StartTime, @TotalSeconds, @IsSend, @PortServer, @FaxErrorCode, @FaxResult;
 
WHILE @@FETCH_STATUS = 0
BEGIN

  IF @Duration > 0
  BEGIN

    SET @Slot = 1;
  
	WHILE @Slot <= @Duration
    BEGIN

      SET @PortStillBusy = DATEADD(minute,@Slot,@StartTime);

      SET @MinuteSlot = CONCAT
      (
	    RIGHT('0'+ CONVERT(VARCHAR,DatePart(yyyy,@PortStillBusy)), 4), '-',
	    RIGHT('0'+ CONVERT(VARCHAR,DatePart(mm,@PortStillBusy)), 2), '-',
	    RIGHT('0'+ CONVERT(VARCHAR,DatePart(dd,@PortStillBusy)), 2), ' ',
	    RIGHT('0'+ CONVERT(VARCHAR,DatePart(hh,@PortStillBusy)), 2), ':',
	    RIGHT('0'+ CONVERT(VARCHAR,DatePart(mi,@PortStillBusy)), 2)
      )

      Insert Into @Durations Select @MinuteSlot, @Duration, @StartTime, @TotalSeconds, @IsSend, @PortServer, @FaxErrorCode, @FaxResult
      SET @Slot = @Slot + 1;
    END;
  END;


  FETCH NEXT FROM @RowCursor INTO @MinuteSlot, @Duration, @StartTime, @TotalSeconds, @IsSend, @PortServer, @FaxErrorCode, @FaxResult;
END

CLOSE @RowCursor;
DEALLOCATE @RowCursor;



--Get all the minute slots for a full day: 24x60=1440
/*
WITH DateIntervalsCTE AS
(
	SELECT 0 i, @startdate AS Date
	UNION ALL
	SELECT i + 1, DATEADD(minute, i, @startdate )
	FROM DateIntervalsCTE
	WHERE DATEADD(minute, i, @startdate ) <= @enddate
)
*/

-- JDG 
/*
We are only interested in the minutes usage for the current hour.
So we can comment out the while loop
*/
SET @Day = 0;
SET @LastDay = 1;

-- JDG Commented this out
/*
WHILE @Day < @LastDay
BEGIN

  WITH DateIntervalsCTE AS
  (
	  SELECT 1 i, DATEADD(dd,@Day,@startdate) AS Date
	  UNION ALL
	  SELECT i + 1, DATEADD(minute,i,DATEADD(dd,@Day,@startdate))
	  FROM DateIntervalsCTE
	  WHERE DATEADD(minute, i, DATEADD(dd,@Day,@startdate) ) < DATEADD(dd,@Day+1,@startdate)
  )
  Insert Into @Timeline Select Date From DateIntervalsCTE
  OPTION (MAXRECURSION 32767);

  SET @Day = @Day + 1;
END;
*/
-- JDG Added this line to remove the while loop
WITH DateIntervalsCTE AS
(
  SELECT 1 i, DATEADD(dd,@Day,@startdate) AS Date
  UNION ALL
  SELECT i + 1, DATEADD(minute,i,DATEADD(dd,@Day,@startdate))
  FROM DateIntervalsCTE
  WHERE DATEADD(minute, i, DATEADD(dd,@Day,@startdate) ) < DATEADD(dd,@Day+1,@startdate)
)
Insert Into @Timeline Select Date From DateIntervalsCTE
OPTION (MAXRECURSION 32767);


Select 

CASE
  WHEN MinuteSlot = '0' THEN Minute
  ELSE MinuteSlot
END as 'Minute',

--#Start '# Started',
--#NoDuration '# No Duration',
--#Duration '# Minute Rollover',

#Start + #NoDuration + #Duration 'Total'

--#Sends,
--#Receives,

--#Sends_Raw,
--#Receives_Raw,

--#Success,
--#NotOurIssue,
--#FaxError,

--#Offline,
--#HDFull,
--#NoChannels

--[#SEA_VZN (snd)],
--[#SEA_VZN (rcv)],
--[#PDX_VZN (snd)],
--[#PDX_VZN (rcv)],
--[#PDX_LV3 (snd)],
--[#SEA_M3K (snd)],
--[#SEA_M3K (rcv)]

From
(

SELECT DISTINCT

CONCAT
(
	RIGHT('0'+ CONVERT(VARCHAR,DatePart(yyyy,Date)),4), '-',
	RIGHT('0'+ CONVERT(VARCHAR,DatePart(mm,Date)),2), '-',
	RIGHT('0'+ CONVERT(VARCHAR,DatePart(dd,Date)),2), ' ',
	RIGHT('0'+ CONVERT(VARCHAR,DatePart(hh,Date)),2), ':',
	RIGHT('0'+ CONVERT(VARCHAR,DatePart(mi,Date)),2)
) as [Minute],

ISNULL(PortUtilization.[Minute],0) as MinuteSlot,


ISNULL(PortUtilization.#Start,0) as #Start,
ISNULL(PortUtilization.#NoDuration,0) as #NoDuration,
ISNULL(PortUtilization.#Duration,0) as #Duration,

ISNULL(PortUtilization.#Sends,0) as #Sends,
ISNULL(PortUtilization.#Receives,0) as #Receives,

ISNULL(PortUtilization.#Sends_Raw,0) as #Sends_Raw,
ISNULL(PortUtilization.#Receives_Raw,0) as #Receives_Raw,

ISNULL(PortUtilization.#Success,0) as #Success,
ISNULL(PortUtilization.#NotOurIssue,0) as #NotOurIssue,
ISNULL(PortUtilization.#FaxError,0) as #FaxError

--ISNULL(PortUtilization.#Offline,0) as #Offline,
--ISNULL(PortUtilization.#HDFull,0) as #HDFull,
--ISNULL(PortUtilization.#NoChannels,0) as #NoChannels

--ISNULL(PortUtilization.[#SEA_VZN (snd)],0) as [#SEA_VZN (snd)],
--ISNULL(PortUtilization.[#SEA_VZN (rcv)],0) as [#SEA_VZN (rcv)],
--ISNULL(PortUtilization.[#PDX_VZN (snd)],0) as [#PDX_VZN (snd)],
--ISNULL(PortUtilization.[#PDX_VZN (rcv)],0) as [#PDX_VZN (rcv)],
--ISNULL(PortUtilization.[#PDX_LV3 (snd)],0) as [#PDX_LV3 (snd)],
--ISNULL(PortUtilization.[#SEA_M3K (snd)],0) as [#SEA_M3K (snd)],
--ISNULL(PortUtilization.[#SEA_M3K (rcv)],0) as [#SEA_M3K (rcv)]


--FROM DateIntervalsCTE FULL OUTER JOIN
FROM @Timeline FULL OUTER JOIN
(

	SELECT
	  MinuteSlot as [Minute],
	  SUM(CASE WHEN SlotType = 'Start' AND TotalSeconds > 0 AND FaxErrorCode NOT IN (30002,30102,30007,30016) THEN 1 ELSE 0 END) AS #Start,
	  SUM(CASE WHEN SlotType = 'Start' AND TotalSeconds = 0 AND FaxErrorCode NOT IN (30002,30102,30007,30016) THEN 1 ELSE 0 END) AS #NoDuration,
	  SUM(CASE WHEN SlotType = 'Duration' AND FaxErrorCode NOT IN (30002,30102,30007,30016) THEN 1 ELSE 0 END) AS #Duration,

	  SUM(CASE WHEN IsSend = 1 THEN 1 ELSE 0 END) AS #Sends,
	  SUM(CASE WHEN IsSend = 0 THEN 1 ELSE 0 END) AS #Receives,

	  SUM(CASE WHEN IsSend = 1 AND SlotType = 'Start' THEN 1 ELSE 0 END) AS #Sends_Raw,
	  SUM(CASE WHEN IsSend = 0 AND SlotType = 'Start' THEN 1 ELSE 0 END) AS #Receives_Raw,

	  SUM(CASE WHEN FaxResult = 0 AND SlotType = 'Start' THEN 1 ELSE 0 END) AS #Success,
	  SUM(CASE WHEN FaxResult = 1 AND SlotType = 'Start' THEN 1 ELSE 0 END) AS #NotOurIssue,
	  SUM(CASE WHEN FaxResult = 2 AND SlotType = 'Start' THEN 1 ELSE 0 END) AS #FaxError

	  --SUM(CASE WHEN (FaxErrorCode = 30002 OR FaxErrorCode = 30102) THEN 1 ELSE 0 END)/3 AS #Offline, --Adjustment by 1/3 for TF retries by M5
	  --SUM(CASE WHEN FaxErrorCode = 30007 THEN 1 ELSE 0 END)/3 AS #HDFull, --Adjustment by 1/3 for TF retries by M5
	  --SUM(CASE WHEN FaxErrorCode = 30016 THEN 1 ELSE 0 END) AS #NoChannels


	  --SUM(CASE WHEN PortServer = 'Port Server (Verizon SIP) on SEA-PS-X5-01' AND IsSend = 1 THEN 1 ELSE 0 END) '#SEA_VZN (snd)',
	  --SUM(CASE WHEN PortServer = 'Port Server (Verizon SIP) on SEA-PS-X5-01' AND IsSend = 0 THEN 1 ELSE 0 END) '#SEA_VZN (rcv)',

	  --SUM(CASE WHEN PortServer = 'Port Server (Verizon SIP) on PDX-PS-X5-01' AND IsSend = 1 THEN 1 ELSE 0 END) AS '#PDX_VZN (snd)',
	  --SUM(CASE WHEN PortServer = 'Port Server (Verizon SIP) on PDX-PS-X5-01' AND IsSend = 0 THEN 1 ELSE 0 END) AS '#PDX_VZN (rcv)',

	  --SUM(CASE WHEN PortServer = 'Port Server (LV3) on PDX-PS-X5-03' THEN 1 ELSE 0 END) AS '#PDX_LV3 (snd)',

	  --SUM(CASE WHEN PortServer = 'Port Server (M3K) on SEA-PS-X5-02' AND IsSend = 1 THEN 1 ELSE 0 END) AS '#SEA_M3K (snd)',
	  --SUM(CASE WHEN PortServer = 'Port Server (M3K) on SEA-PS-X5-02' AND IsSend = 0 THEN 1 ELSE 0 END) AS '#SEA_M3K (rcv)'

	FROM
	(
	  Select *, 'Start' 'SlotType' From @CDRs
	  Union All --Add "All" to not automatically remove duplicates
	  Select *, 'Duration' 'SlotType' From @Durations
	) As Utilization


	Group By MinuteSlot

) As PortUtilization


On CONCAT
(
	RIGHT('0'+ CONVERT(VARCHAR,DatePart(yyyy,Date)),4), '-',
	RIGHT('0'+ CONVERT(VARCHAR,DatePart(mm,Date)),2), '-',
	RIGHT('0'+ CONVERT(VARCHAR,DatePart(dd,Date)),2), ' ',
	RIGHT('0'+ CONVERT(VARCHAR,DatePart(hh,Date)),2), ':',
	RIGHT('0'+ CONVERT(VARCHAR,DatePart(mi,Date)),2)
) = PortUtilization.[Minute]

) As Results

Where Minute <> '-- :'

--Condense
--AND (#Start <> 0 OR #NoDuration <> 0 OR #Duration <> 0)

--Change the Order By below as needed to easily see top utilization
--Order By MinuteSlot
Order By 2 Desc --Order By 'Total'

OPTION (MAXRECURSION 32767);
