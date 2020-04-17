-- Subtraction example

/*

select *
from EVENTS
where
	EVENTTYPE = 0
		and DEVID = 4
		and MACHINE = 99 -- 99 and 15

select *
from EVENTS
where
	EVENTTYPE = 0
		and DEVID = 4
		and MACHINE = 15 -- 99 and 15

*/



select
	(
	select count(*)
	from EVENTS
	where
		EVENTTYPE = 0
			and DEVID = 4
			and MACHINE = 99 -- 99 and 15
	)
	-
	(
	select count(*)
	from EVENTS
	where
		EVENTTYPE = 0
			and DEVID = 4
			and MACHINE = 15 -- 99 and 15
	)
as Difference
