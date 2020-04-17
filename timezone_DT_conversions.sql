--Get System Timezone Info

--Get system timezone name.
declare @TimeZone varchar(50)
exec master.dbo.xp_regread 'HKEY_LOCAL_MACHINE', 'SYSTEM\CurrentControlSet\Control\TimeZoneInformation', 'TimeZoneKeyName',@TimeZone OUT
select @TimeZone as 'TZName'
;

--Get system timezone offset.
declare @TZ smallint
select @TZ=DATEPART(TZ, SYSDATETIMEOFFSET())
select cast(@TZ/60 as varchar(5))+':'+cast(ABS(@TZ)%60 as varchar(5)) as Hours
select @TZ as Minutes
;


--THIS ONE WORKS!!!!!
USE AccessControl

--This variable get's system time-offset in MINUTES.
declare @TZ smallint
	select @TZ=DATEPART(TZ, SYSDATETIMEOFFSET())

select @TZ

select top 100 EVENT_TIME_UTC
from EVENTS
order by EVENT_TIME_UTC desc

select top 100 DATEADD(mi, @TZ, EVENT_TIME_UTC) as LocalTime --This alters the column-input by the variables value.
from EVENTS
order by EVENT_TIME_UTC desc

