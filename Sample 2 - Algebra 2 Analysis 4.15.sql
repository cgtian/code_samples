/*
algebra 2 analysis for april 2015

description
this analysis measures the availability of algebra 2 courses for cohort r students (on-track hs juniors)

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
	[5b] iep status breakdown for active cohort r students who have taken or are taking algebra 2
	[5c] ell status breakdown for active cohort r students who have taken or are taking algebra 2

[6] various demographic breakdowns for active cohort r students
	[6a] race breakdown for active cohort r students
	[6b] iep status breakdown for active cohort r students
	[6c] ell status breakdown for active cohort r students

deliverables
% of schools offering high school level alg2 in 2014: [1]/[2]
% of active cohort r students who have taken or are taking alg2: [3cii]/[4]
%s of active cohort r students who have taken or are taking alg2 by race: [5a]/[6a]
%s of active cohort r students who have taken or are taking alg2 by iep status: [5b]/[6b]
%s of active cohort r students who have taken or are taking alg2 by ell status: [5c]/[6c]
*/





-----[1] number of schools offering high school level alg2 in 2014
select
count(distinct sr.numericschooldbn) as ct_alg2_hs

from student_request as sr

inner join master_schedule_report as msr
on msr.numericschooldbn=sr.numericschooldbn
and msr.schoolyear=sr.schoolyear
and msr.termid=sr.termid
and msr.coursecode=sr.coursecode
and msr.sectionid=sr.assignedsectionid

inner join school as s
on s.numericschooldbn=sr.numericschooldbn

where
sr.schoolyear=2014
and substring(sr.coursecode,1,2)='MR'
and substring(sr.coursecode,4,1) not in ('J','M')
and substring(s.schooldbn,1,2) not in ('75','79','84','88')
and substring(s.schooldbn,4,3)<>'444'





-----[2] number of schools scheduling high school course(s) in 2014
select
count(distinct school_dbn) as ct_hs

from bio_data

where
grade_level in ('09','10','11','12')
and status='A'
and substring(school_dbn,1,2) not in ('75','79','84','88')
and substring(school_dbn,4,3)<>'444'





-----[3] active cohort r students who have taken or are taking algebra 2
---[3a] active cohort r students scheduled for alg2 in 2014
if object_id('tempdb..#sa_int1') is not null drop table #sa_int1

select distinct
sr.studentid

into #sa_int1

from student_request as sr

inner join master_schedule_report as msr
on msr.numericschooldbn=sr.numericschooldbn
and msr.schoolyear=sr.schoolyear
and msr.termid=sr.termid
and msr.coursecode=sr.coursecode
and msr.sectionid=sr.assignedsectionid

inner join bio_data as b
on b.student_id=sr.studentid

where
sr.schoolyear=2014
and substring(sr.coursecode,1,2)='MR'
and substring(sr.coursecode,4,1) not in ('J','M')
and b.grd9_entry_cde='R'
and b.status='A'



---[3b] active cohort r students with algebra 2 on their transcripts
if object_id('tempdb..#sa_int2') is not null drop table #sa_int2

select distinct
s.studentid

into #sa_int2

from student_marks as s

inner join bio_data as b
on b.student_id=s.studentid

where
s.isexam=0
and substring(s.coursecd,1,2)='MR'
and substring(s.coursecd,4,1) not in ('J','M')
and b.grd9_entry_cde='R'
and b.status='A'



---[3c] active cohort r students who have taken or are taking algebra 2
--[3ci] active cohort r students who have taken or are taking algebra 2
if object_id('tempdb..#sa_int3') is not null drop table #sa_int3

select
studentid

into #sa_int3

from #sa_int1

union

select studentid

from #sa_int2


--[3cii] active cohort r students who have taken or are taking algebra 2 excluding irrelevant populations
if object_id('tempdb..#sa_final') is not null drop table #sa_final

select
studentid

into #sa_final

from #sa_int3

where
studentid not in	(
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

select distinct
student_id

into #s

from bio_data

where
status='A'
and grd9_entry_cde='R'
and student_id not in	(
				select distinct b.id 
				from spr_bio_data as b
				inner join spr_graduation_info as g
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
case when b.ethnic_cde in ('2','C','D') then 'Asian'
when b.ethnic_cde in ('3','A') then 'Hispanic'
when b.ethnic_cde in ('4','E') then 'Black'
when b.ethnic_cde in ('5','F') then 'White'
else 'Other'
end as ethnicity,
count(distinct s.studentid) as ct_students

from #sa_final as s

inner join bio_data as b
on b.student_id=s.studentid

where
b.status='A'

group by 
case when b.ethnic_cde in ('2','C','D') then 'Asian'
when b.ethnic_cde in ('3','A') then 'Hispanic'
when b.ethnic_cde in ('4','E') then 'Black'
when b.ethnic_cde in ('5','F') then 'White'
else 'Other'
end



---[5b] iep status breakdown for active cohort r students who have taken or are taking algebra 2
select
case when b.iep_spec_ed_flg='Y' then 'Student with Disabilities (IEP)'
else NULL
end as iep_status,
count(distinct s.studentid) as ct_students

from #sa_final as s

inner join bio_data as b
on b.student_id=s.studentid

where
b.status='A'

group by 
case when b.iep_spec_ed_flg='Y'
then 'Student with Disabilities (IEP)'
else NULL
end



---[5c] ell status breakdown for active cohort r students who have taken or are taking algebra 2
select
case when b.lep_flg='Y' then 'ELL'
when b.lep_flg='P' then 'Former ELL'
else NULL
end as ell_status,
count(distinct s.studentid) as ct_students

from #sa_final as s

inner join bio_data as b
on b.student_id=s.studentid

where
b.status='A'

group by
case when b.lep_flg='Y' then 'ELL'
when b.lep_flg='P' then 'Former ELL'
else NULL
end





-----[6] various demographic breakdowns for active cohort r students						
---[6a] race breakdown for active cohort r students
select
case when b.ethnic_cde in ('2','C','D') then 'Asian'
when b.ethnic_cde in ('3','A') then 'Hispanic'
when b.ethnic_cde in ('4','E') then 'Black'
when b.ethnic_cde in ('5','F') then 'White'
else 'Other'
end as ethnicity,
count(distinct b.student_id) as ct_students

from #s as s

inner join bio_data as b
on b.student_id=s.student_id

where
b.status='A'

group by
case when b.ethnic_cde in ('2','C','D') then 'Asian'
when b.ethnic_cde in ('3','A') then 'Hispanic'
when b.ethnic_cde in ('4','E') then 'Black'
when b.ethnic_cde in ('5','F') then 'White'
else 'Other'
end



---[6b] iep status breakdown for active cohort r students
select 
case when b.iep_spec_ed_flg='Y' then 'Student with Disabilities (IEP)'
else NULL
end as iep_status,
count(distinct b.student_id) as ct_students

from #s as s

inner join bio_data as b
on b.student_id=s.student_id

where
b.status='A'

group by
case when b1.iep_spec_ed_flg='Y' then 'Student with Disabilities (IEP)'
else NULL
end



---[6c] ell status breakdown for active cohort r students
select 
case when b.lep_flg='Y' then 'ELL'
when b.lep_flg='P' then 'Former ELL'
else NULL
end as ell_status,
count(distinct b.student_id) as ct_students

from #s as s

inner join bio_data as b
on b.student_id=s.student_id

where
b.status='A'

group by
case when b.lep_flg='Y' then 'ELL'
when b.lep_flg='P' then 'Former ELL'
else NULL
end