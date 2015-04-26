/*
algebra 2 analysis for april 2015

description
this analysis measures the availability of algebra 2 courses citywide for cohort r students (on-track hs juniors)

code outline
[1] number of schools offering high school level alg2 in 2014

[2] number of schools scheduling high school course(s) in 2014

[3] active cohort r students who have taken or are taking algebra 2
	[3a] active cohort r students scheduled for alg2 in 2014
	[3b] active cohort r students with algebra 2 on their transcripts
	[3c] active cohort r students who have taken or are taking algebra 2
		[3ci] active cohort r students who have taken or are taking algebra 2
		[3cii] active cohort r students who have taken or are taking algebra 2 excluding irrelevant populations

[4] active cohort r students

[5] various demographic breakdowns for active cohort r students who have taken or are taking algebra 2
	[5a] race breakdown for active cohort r students who have taken or are taking algebra 2 
	[5b] iep breakdown for active cohort r students who have taken or are taking algebra 2
	[5c] ell breakdown for active cohort r students who have taken or are taking algebra 2

[6] various demographic breakdowns for active cohort r students
	[6a] race breakdown for active cohort r students
	[6b] iep breakdown for active cohort r students
	[6c] ell breakdown for active cohort r students

contact
chris tian - chris.tian(at)nyu.edu
*/





-----[1] number of schools offering high school level alg2 in 2014
select count(distinct sr.numericschooldbn) as ct_alg2_hs

from stars_int.dbo.studentrequest as sr

inner join stars_int.dbo.masterschedulereport as msr
on msr.numericschooldbn=sr.numericschooldbn
and msr.schoolyear=sr.schoolyear
and msr.termid=sr.termid
and msr.coursecode=sr.coursecode
and msr.sectionid=sr.assignedsectionid

inner join stars_int.dbo.school as s
on s.numericschooldbn=sr.numericschooldbn

where sr.schoolyear=2014
and substring(sr.coursecode,1,2)='MR'
and substring(sr.coursecode,4,1) not in ('J','M')
and substring(s.schooldbn,1,2) not in ('75','79','84','88')
and substring(s.schooldbn,4,3)<>'444'





-----[2] number of schools scheduling high school course(s) in 2014
select count(distinct school_dbn)

from atslink.ats_demo.dbo.biogdata

where grade_level in ('09','10','11','12')
and status='A'
and substring(school_dbn,1,2) not in ('75','79','84','88')
and substring(school_dbn,4,3)<>'444'





-----[3] active cohort r students who have taken or are taking algebra 2
---[3a] active cohort r students scheduled for alg2 in 2014
if object_id('tempdb..#sa_int1') is not null drop table #sa_int1
select distinct sr.studentid
into #sa_int1

from stars_int.dbo.studentrequest as sr

inner join stars_int.dbo.masterschedulereport as msr
on msr.numericschooldbn=sr.numericschooldbn
and msr.schoolyear=sr.schoolyear
and msr.termid=sr.termid
and msr.coursecode=sr.coursecode
and msr.sectionid=sr.assignedsectionid

inner join atslink.ats_demo.dbo.biogdata as b
on b.student_id=sr.studentid

where sr.schoolyear=2014
and substring(sr.coursecode,1,2)='MR'
and substring(sr.coursecode,4,1) not in ('J','M')
and b.grd9_entry_cde='R'
and b.status='A'



---[3b] active cohort r students with algebra 2 on their transcripts
if object_id('tempdb..#sa_int2') is not null drop table #sa_int2
select distinct s.studentid
into #sa_int2

from siflink.sif.dbo.hsst_tbl_studentmarks as s

inner join atslink.ats_demo.dbo.biogdata as b
on b.student_id=s.studentid

where s.isexam=0
and substring(s.coursecd,1,2)='MR'
and substring(s.coursecd,4,1) not in ('J','M')
and b.grd9_entry_cde='R'
and b.status='A'



---[3c] active cohort r students who have taken or are taking algebra 2
--[3ci] active cohort r students who have taken or are taking algebra 2
if object_id('tempdb..#sa_int3') is not null drop table #sa_int3
select studentid
into #sa_int3

from #sa_int1

union

select studentid

from #sa_int2


--[3cii] active cohort r students who have taken or are taking algebra 2 excluding irrelevant populations
if object_id('tempdb..#sa_final') is not null drop table #sa_final
select studentid
into #sa_final

from #sa_int3

where studentid not in	(
				select distinct b.id 
				from spr_int.prl.raw_biog_prog_union as b
				inner join spr_int.prl.raw_graduation_stu_4yr as g
				on g.id=b.id
				where g.cohort='R'
				and b.admission_date>=convert(datetime,'2012-09-01')
				and	(
						substring(b.dbn,1,2) in ('75','79','84','88') or substring(b.dbn,4,3)='444'
					)
			)





-----[4] active cohort r students
if object_id('tempdb..#s') is not null drop table #s
select distinct student_id
into #s

from atslink.ats_demo.dbo.biogdata

where status='A'
and grd9_entry_cde='R'
and student_id not in	(
				select distinct b.id 
				from spr_int.prl.raw_biog_prog_union as b
				inner join spr_int.prl.raw_graduation_stu_4yr as g
				on g.id=b.id
				where g.cohort='R'
				and b.admission_date>=convert(datetime,'2012-09-01')
				and	(
						substring(b.dbn,1,2) in ('75','79','84','88') or substring(b.dbn,4,3)='444'
					)
			)





-----[5] various demographic breakdowns for active cohort r students who have taken or are taking algebra 2
---[5a] race breakdown for active cohort r students who have taken or are taking algebra 2 
select 
case when b1.ethnic_cde in ('2','C','D') then 'Asian'
when b1.ethnic_cde in ('3','A') then 'Hispanic'
when b1.ethnic_cde in ('4','E') then 'Black'
when b1.ethnic_cde in ('5','F') then 'White'
else 'Other'
end as ethnicity,
count(distinct s.studentid) as ct_students

from #sa_final as s

inner join atslink.ats_demo.dbo.biogdata as b1
on b1.student_id=s.studentid

where b1.status='A'

group by 
case when b1.ethnic_cde in ('2','C','D') then 'Asian'
when b1.ethnic_cde in ('3','A') then 'Hispanic'
when b1.ethnic_cde in ('4','E') then 'Black'
when b1.ethnic_cde in ('5','F') then 'White'
else 'Other'
end



---[5b] iep breakdown for active cohort r students who have taken or are taking algebra 2
select
case when b1.iep_spec_ed_flg='Y' then 'Student with Disabilities (IEP)'
else NULL
end as iep_status,
count(distinct s.studentid) as ct_students

from #sa_final as s

inner join atslink.ats_demo.dbo.biogdata as b1
on b1.student_id=s.studentid

where b1.status='A'

group by 
case when b1.iep_spec_ed_flg='Y'
then 'Student with Disabilities (IEP)'
else NULL
end



---[5c] ell breakdown for active cohort r students who have taken or are taking algebra 2
select
case when b1.lep_flg='Y' then 'ELL'
when b1.lep_flg='P' then 'Former ELL'
else NULL
end as ell_status,
count(distinct s.studentid) as ct_students

from #sa_final as s

inner join atslink.ats_demo.dbo.biogdata as b1
on b1.student_id=s.studentid

where b1.status='A'

group by
case when b1.lep_flg='Y' then 'ELL'
when b1.lep_flg='P' then 'Former ELL'
else NULL
end





-----[6] various demographic breakdowns for active cohort r students						
---[6a] race breakdown for active cohort r students
select 
case when b1.ethnic_cde in ('2','C','D') then 'Asian'
when b1.ethnic_cde in ('3','A') then 'Hispanic'
when b1.ethnic_cde in ('4','E') then 'Black'
when b1.ethnic_cde in ('5','F') then 'White'
else 'Other'
end as ethnicity,
count(distinct b1.student_id)

from atslink.ats_demo.dbo.biogdata as b1

inner join #s as s
on s.student_id=b1.student_id

where b1.status='A'

group by
case when b1.ethnic_cde in ('2','C','D') then 'Asian'
when b1.ethnic_cde in ('3','A') then 'Hispanic'
when b1.ethnic_cde in ('4','E') then 'Black'
when b1.ethnic_cde in ('5','F') then 'White'
else 'Other'
end



---[6b] iep breakdown for active cohort r students
select 
case when b1.iep_spec_ed_flg='Y' then 'Student with Disabilities (IEP)'
else NULL
end as iep_status,
count(distinct b1.student_id) as ct_students

from atslink.ats_demo.dbo.biogdata as b1

inner join #s as s
on s.student_id=b1.student_id

where b1.status='A'

group by
case when b1.iep_spec_ed_flg='Y' then 'Student with Disabilities (IEP)'
else NULL
end



---[6c] ell breakdown for active cohort r students
select 
case when b1.lep_flg='Y' then 'ELL'
when b1.lep_flg='P' then 'Former ELL'
else NULL
end as ell_status,
count(distinct b1.student_id) as ct_students

from atslink.ats_demo.dbo.biogdata as b1

inner join #s as s
on s.student_id=b1.student_id

where b1.status='A'

group by
case when b1.lep_flg='Y' then 'ELL'
when b1.lep_flg='P' then 'Former ELL'
else NULL
end