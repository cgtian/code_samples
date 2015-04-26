/*
code outline
[1] number of schools offering high school level alg2 in 2014

[2A] active cohort r students scheduled for alg2 in 2014
[2B] active cohort r students with algebra 2 on their transcripts
[2C] active cohort r students who have taken or are taking algebra 2

[3A] race breakdown for active cohort r students who have taken or are taking algebra 2 
[3B] iep breakdown for active cohort r students who have taken or are taking algebra 2
[3C] ell breakdown for active cohort r students who have taken or are taking algebra 2

[4] number of schools scheduling high school course(s) in 2014

[5] number of active cohort r students

[6A] race breakdown for active cohort r students
[6B] iep breakdown for active cohort r students
[6C] ell breakdown for active cohort r students

contact
chris tian - ctian2@schools.nyc.gov
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





---[2A] cohort r students scheduled for alg2 in 2014
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



---[2B] cohort r students with algebra 2 on their transcripts
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



---[2C] cohort r students who have taken or are taking algebra 2
if object_id('tempdb..#sa_int3') is not null drop table #sa_int3
select studentid
into #sa_int3
from #sa_int1
union
select studentid
from #sa_int2

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





---[3A] race breakdown for cohort r students who have taken or are taking algebra 2 
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



---[3B] iep breakdown for cohort r students who have taken or are taking algebra 2
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



---[3C] ell breakdown for cohort r students who have taken or are taking algebra 2
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





---[4] number of schools scheduling high school course(s) in 2014
select count(distinct school_dbn)
from atslink.ats_demo.dbo.biogdata
where grade_level in ('09','10','11','12')
and status='A'
and substring(school_dbn,1,2) not in ('75','79','84','88')
and substring(school_dbn,4,3)<>'444'





---[5] number of active cohort r students
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




						
---[6A] race breakdown for active cohort r students
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




---[6B] iep breakdown for active cohort r students
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




---[6C] ell breakdown for active cohort r students
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





---[7] number of cohort p students who have attempted the algebra 2 exam by the end of their first four years in hs
select count(distinct s.studentid) as ct_students

from sif.dbo.hsst_tbl_studentmarks as s

inner join ats_demo.dbo.biogdata as b
on b.student_id=s.studentid and b.school_dbn=s.schooldbn

where s.isexam=1
and substring(s.coursecd,1,4)='MXRT'
and s.schoolyear<=2013
and b.grd9_entry_cde='P'
and b.student_id not in	(
							select distinct student_id
							from ats_demo.dbo.biogdata
							where admission_dte>=20100901
							and (
									substring(school_dbn,1,2) in ('75','79','84','88') or substring(school_dbn,4,3)='444'
								)
						)



select count(distinct student_id) as ct_students
from ats_demo.dbo.biogdata
where grd9_entry_cde='P'
and student_id not in	(
							select distinct student_id
							from ats_demo.dbo.biogdata
							where admission_dte>=20100901
							and (
									substring(school_dbn,1,2) in ('75','79','84','88') or substring(school_dbn,4,3)='444'
								)
						)