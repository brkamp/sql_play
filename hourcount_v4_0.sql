/*
-- =============================================
-- Author:		Brandon Kamp
-- Create date: 16Apr2020
-- Description:	 Combined Building Occupancy Counts, By Building, By Hour Version_4.0
--		/|\  Optimized and Elegant!  /|\
-- =============================================
*/

SET NOCOUNT ON

USE [DataBaseName] ;

-- SET ALL THE THINGS!
-- Define Date Range for targeted results. (Remember to change the first WHERE below.)
declare @startdate varchar(100) = '2020-03-17'
declare @enddate varchar(100) = '2020-04-10'
--For timezone conversion.
declare @TZ smallint
	select @TZ=DATEPART(TZ, SYSDATETIMEOFFSET())
declare @empty varchar (5)
	set @empty = null


-- CREATE THE DATA
IF OBJECT_ID('tempdb..#hourcount') is not null
	drop table #hourcount

select DATEADD(mi, @TZ, evs.EVENT_TIME_UTC) as 'DateTime', ap.PANELID, r.READERDESC as AccessPoint, evt.EVDESCR as 'Status', em.LASTNAME as LastName, em.FIRSTNAME as FirstName, u.EMPLOYEE as EmployeeNum, b.ID as BadgeNum
	into #hourcount -- Temporary table
from EVENTS evs
	join EVENT evt on evt.EVID = evs.EVENTID
		and evt.EVTYPEID = evs.EVENTTYPE
	join EMP em on em.ID = evs.EMPID
	join BADGE b on b.ID = evs.CARDNUM
	join UDFEMP u on u.ID = em.ID
	join READER r on r.READERID = evs.DEVID
			and r.PANELID = evs.MACHINE
	join ACCESSPANE ap on ap.PANELID = evs.MACHINE
where 
	DATEADD(mi, @TZ, evs.EVENT_TIME_UTC) >= DATEADD(day,-1, convert(date, GETDATE())) and DATEADD(mi, @TZ, evs.EVENT_TIME_UTC) < convert(date, getdate()) -- Use This for Full Previous Date 0-23hrs
--	DATEADD(mi, @TZ, evs.EVENT_TIME_UTC) >= @startdate and DATEADD(mi, @TZ, evs.EVENT_TIME_UTC) <= @enddate -- Use this for Specific Date Range of any size.
		and evs.EVENTTYPE = 0
		and ap.PANELID in (2,3,7,15) -- Micros for Bldgs 1, 3, 5, 7
order by DateTime
;

IF OBJECT_ID('tempdb..#hourcount_out') is not null
	drop table #hourcount_out

select DATEADD(mi, @TZ, evs.EVENT_TIME_UTC) as 'DateTime', ap.PANELID, r.READERDESC as AccessPoint, evt.EVDESCR as 'Status', em.LASTNAME as LastName, em.FIRSTNAME as FirstName, u.EMPLOYEE as EmployeeNum, b.ID as BadgeNum
	into #hourcount_out -- Temporary table
from EVENTS evs
	join EVENT evt on evt.EVID = evs.EVENTID
		and evt.EVTYPEID = evs.EVENTTYPE
	join EMP em on em.ID = evs.EMPID
	join BADGE b on b.ID = evs.CARDNUM
	join UDFEMP u on u.ID = em.ID
	join READER r on r.READERID = evs.DEVID
			and r.PANELID = evs.MACHINE
	join ACCESSPANE ap on ap.PANELID = evs.MACHINE
where 
	DATEADD(mi, @TZ, evs.EVENT_TIME_UTC) >= DATEADD(day,-1, convert(date, GETDATE())) and DATEADD(mi, @TZ, evs.EVENT_TIME_UTC) < convert(date, getdate())
--	DATEADD(mi, @TZ, evs.EVENT_TIME_UTC) >= @startdate and DATEADD(mi, @TZ, evs.EVENT_TIME_UTC) <= @enddate
		and evs.EVENTTYPE = 0
		and ap.PANELID in (2,110,24,88) -- Micros for Bldgs 1, 3, 5, 7
		and r.READERDESC like '%check-out%'
order by DateTime
/*
select * from #hourcount
order by DateTime
select * from #hourcount_out
order by DateTime
*/
;



-- Get First and Last Records
--select * from #hourcount
IF OBJECT_ID('tempdb..#precount_in') is not null
	drop table #precount_in
;
with firstread_CTE as (
	select min(DateTime)as DateTime, LastName, FirstName, EmployeeNum
	from #hourcount
	group by LastName, FirstName, EmployeeNum
	)
	select hc.DateTime, hc.PANELID, hc.LastName, hc.FirstName, hc.EmployeeNum
		into #precount_in
	from #hourcount hc
		join firstread_CTE fr on fr.DateTime = hc.DateTime
			and fr.LastName = hc.LastName
			and fr.FirstName = hc.FirstName
			and fr.EmployeeNum = hc.EmployeeNum
	order by hc.LastName
;
IF OBJECT_ID('tempdb..#precount_out') is not null
	drop table #precount_out
;
with lastread_CTE as (
	select max(DateTime)as DateTime, LastName, FirstName, EmployeeNum
	from #hourcount_out
	group by LastName, FirstName, EmployeeNum
	)
	select hco.DateTime, hco.PANELID, hco.LastName, hco.FirstName, hco.EmployeeNum
		into #precount_out
	from #hourcount_out hco
		join lastread_CTE lr on lr.DateTime = hco.DateTime
			and lr.LastName = hco.LastName
			and lr.FirstName = hco.FirstName
			and lr.EmployeeNum = hco.EmployeeNum
	order by hco.lastname
;
/*
select * from #precount_in
select * from #precount_out
*/





-- Get away from those silly PANELIDs
select
	case
		when PANELID = '2'
			then '1'
		when PANELID = '3'
			then '3'
		when PANELID = '7'
			then '5'
		when PANELID = '15'
			then '7'
		else 0
	end as Building_In, DateTime, LastName, FirstName, EmployeeNum
from #precount_in
order by DateTime
print '' -- blank line for shitty output/reporting purposes

select
	case
		when PANELID = '2'
			then '1'
		when PANELID = '110'
			then '3'
		when PANELID = '24'
			then '5'
		when PANELID = '88'
			then '7'
		else 0
	end as Building_Out, DateTime, LastName, FirstName, EmployeeNum
from #precount_out
order by DateTime
print '' -- blank line for shitty output/reporting purposes

;




-- NOW Sort AND Count the Things...
-- BLDG 1 Sort AND Count
with b1_in_CTE as (
	select hl.hour as 'B1_Hours', count(format(datepart(hour, pc.DateTime),'00')) as 'Total In'
	from #precount_in pc
		right join HOURLIST hl on hl.hour = format(datepart(hour, pc.DateTime),'00')
			and pc.PANELID = 2
	group by hl.hour, format(datepart(hour, pc.DateTime),'00')
	)
	,
	b1_out_CTE as (
	select hl.hour as 'B1_Hours', count(format(datepart(hour, pco.DateTime),'00')) as 'Total Out'
	from #precount_out pco
		right join HOURLIST hl on hl.hour = format(datepart(hour, pco.DateTime),'00')
			and pco.PANELID = 2
	group by hl.hour, format(datepart(hour, pco.DateTime),'00')
	)
		select boi.B1_Hours, boi.[Total In], boo.[Total Out], (boi.[Total In]) - (boo.[Total Out]) as 'Occupancy'
		from b1_in_CTE boi
			join b1_out_CTE boo on boi.B1_Hours = boo.B1_Hours
		order by boi.B1_Hours
print '' -- blank line for shitty output/reporting purposes
;

-- BLDG 3 Sort AND Count
with b3_in_CTE as (
	select hl.hour as 'B3_Hours', count(format(datepart(hour, pc.DateTime),'00')) as 'Total In'
	from #precount_in pc
		right join HOURLIST hl on hl.hour = format(datepart(hour, pc.DateTime),'00')
			and pc.PANELID = 3
	group by hl.hour, format(datepart(hour, pc.DateTime),'00')
	)
	,
	b3_out_CTE as (
	select hl.hour as 'B3_Hours', count(format(datepart(hour, pco.DateTime),'00')) as 'Total Out'
	from #precount_out pco
		right join HOURLIST hl on hl.hour = format(datepart(hour, pco.DateTime),'00')
			and pco.PANELID = 110
	group by hl.hour, format(datepart(hour, pco.DateTime),'00')
	)
		select bti.B3_Hours, bti.[Total In], bto.[Total Out], (bti.[Total In]) - (bto.[Total Out]) as 'Occupancy'
		from b3_in_CTE bti
			join b3_out_CTE bto on bti.B3_Hours = bto.B3_Hours
		order by bti.B3_Hours
print '' -- blank line for shitty output/reporting purposes
;

-- BLDG 5 Sort AND Count
with b5_in_CTE as (
	select hl.hour as 'B5_Hours', count(format(datepart(hour, pc.DateTime),'00')) as 'Total In'
	from #precount_in pc
		right join HOURLIST hl on hl.hour = format(datepart(hour, pc.DateTime),'00')
			and pc.PANELID = 7
	group by hl.hour, format(datepart(hour, pc.DateTime),'00')
	)
	,
	b5_out_CTE as (
	select hl.hour as 'B5_Hours', count(format(datepart(hour, pco.DateTime),'00')) as 'Total Out'
	from #precount_out pco
		right join HOURLIST hl on hl.hour = format(datepart(hour, pco.DateTime),'00')
			and pco.PANELID = 24
	group by hl.hour, format(datepart(hour, pco.DateTime),'00')
	)
		select bfi.B5_Hours, bfi.[Total In], bfo.[Total Out], (bfi.[Total In]) - (bfo.[Total Out]) as 'Occupancy'
		from b5_in_CTE bfi
			join b5_out_CTE bfo on bfi.B5_Hours = bfo.B5_Hours
		order by bfi.B5_Hours
print '' -- blank line for shitty output/reporting purposes
;

-- BLDG 7 Sort AND Count
with b7_in_CTE as (
	select hl.hour as 'B7_Hours', count(format(datepart(hour, pc.DateTime),'00')) as 'Total In'
	from #precount_in pc
		right join HOURLIST hl on hl.hour = format(datepart(hour, pc.DateTime),'00')
			and pc.PANELID = 15
	group by hl.hour, format(datepart(hour, pc.DateTime),'00')
	)
	,
	b7_out_CTE as (
	select hl.hour as 'B7_Hours', count(format(datepart(hour, pco.DateTime),'00')) as 'Total Out'
	from #precount_out pco
		right join HOURLIST hl on hl.hour = format(datepart(hour, pco.DateTime),'00')
			and pco.PANELID = 88
	group by hl.hour, format(datepart(hour, pco.DateTime),'00')
	)
		select bsi.B7_Hours, bsi.[Total In], bso.[Total Out], (bsi.[Total In]) - (bso.[Total Out]) as 'Occupancy'
		from b7_in_CTE bsi
			join b7_out_CTE bso on bsi.B7_Hours = bso.B7_Hours
		order by bsi.B7_Hours
print '' -- blank line for shitty output/reporting purposes
;




/*
-- TEST ALL THE THINGS!

select * from #hourcount
order by DateTime


select * from #hourcount
--where LastName = 'kamp'
order by DateTime

select * from #precount_in
--where LastName = 'kamp'
--order by DateTime
order by LastName



select * from #hourcount_out
where LastName = 'kamp'
order by DateTime

select * from #precount_out
where LastName = 'kamp'
order by DateTime



select * from #hourcount
order by LastName
select * from #precount_in
order by LastName
--order by DateTime

select * from #hourcount_out
order by LastName

--order by DateTime



*/
