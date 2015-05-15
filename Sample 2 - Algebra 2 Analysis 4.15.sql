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
	[5a] ethnic breakdown for active cohort r students who have taken or are taking algebra 2 
	[5b] iep status breakdown for active cohort r students who have taken or are taking algebra 2
	[5c] ell status breakdown for active cohort r students who have taken or are taking algebra 2

[6] various demographic breakdowns for active cohort r students
	[6a] ethnic breakdown for active cohort r students
	[6b] iep status breakdown for active cohort r students
	[6c] ell status breakdown for active cohort r students

[7] various measures of algebra 2 availability for cohort r students
	[7a] percentage of schools offering high school level alg2 in 2014
	[7b] percentages of active cohort r students who have taken or are taking alg2 by ethnicity
	[7c] percentages of active cohort r students who have taken or are taking alg2 by iep status
	[7d] percentages of active cohort r students who have taken or are taking alg2 by ell status

deliverables
percentage of schools offering high school level alg2 in 2014: [7a]
percentages of active cohort r students who have taken or are taking alg2 by race: [7b]
percentages of active cohort r students who have taken or are taking alg2 by iep status: [7c]
percentages of active cohort r students who have taken or are taking alg2 by ell status: [7d]
*/





-----[1] number of schools offering high school level alg2 in 2014
if object_id('tempdb..#ct_schools_alg2') is not null drop table #ct_schools_alg2

select
count(distinct sr.numericschooldbn) as ct_schools_alg2

into #ct_schools_alg2

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
and substring(s.schooldbn,4,3)!='444'





-----[2] number of schools scheduling high school course(s) in 2014
if object_id('tempdb..#ct_schools') is not null drop table #ct_schools

select
count(distinct school_dbn) as ct_schools

into #ct_schools

from bio_data

where
grade_level in ('09','10','11','12')
and status='A'
and substring(school_dbn,1,2) not in ('75','79','84','88')
and substring(school_dbn,4,3)!='444'





-----[3] active cohort r students who have taken or are taking algebra 2
---[3a] active cohort r students scheduled for alg2 in 2014
if object_id('tempdb..#students_taking_alg2') is not null drop table #students_taking_alg2

select distinct
sr.studentid,
b.ethnic_cde,
b.iep_spec_ed_flg,
b.lep_flg

into #students_taking_alg2

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
if object_id('tempdb..#students_taken_alg2') is not null drop table #students_taken_alg2

select distinct
s.studentid
b.ethnic_cde,
b.iep_spec_ed_flg,
b.lep_flg

into #students_taken_alg2

from student_marks as s

inner join bio_data as b
on b.student_id=s.studentid

where
s.isexam=0
and substring(s.coursecd,1,2)='MR'
and substring(s.coursecd,4,1) not in ('J','M')
and b.grd9_entry_cde='R'
and b.status='A'



---[3c] active cohort r students who have taken or are taking algebra 2 excluding irrelevant populations
--[3ci] active cohort r students who have taken or are taking algebra 2
if object_id('tempdb..#students_alg2_int') is not null drop table #students_alg2_int

select
studentid,
ethnic_cde,
iep_spec_ed_flg,
lep_flg

into #students_alg2_int

from #students_taking_alg2

union

select
studentid,
ethnic_cde,
iep_spec_ed_flg,
lep_flg

from #students_taken_alg2


--[3cii] active cohort r students who have taken or are taking algebra 2 excluding irrelevant populations
if object_id('tempdb..#students_alg2_final') is not null drop table #students_alg2_final

select
studentid,
ethnic_cde,
iep_spec_ed_flg,
lep_flg

into #students_alg2_final

from #students_alg2_int

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
if object_id('tempdb..#student_list') is not null drop table #student_list

select distinct
student_id,
ethnic_cde,
iep_spec_ed_flg,
lep_flg

into #student_list

from bio_data

where
grd9_entry_cde='R'
and status='A'
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
---[5a] ethnic breakdown for active cohort r students who have taken or are taking algebra 2
if object_id('tempdb..#ct_ethnicity_alg2') is not null drop table #ct_ethnicity_alg2

select
case when ethnic_cde in ('2','C','D') then 'Asian'
when ethnic_cde in ('3','A') then 'Hispanic'
when ethnic_cde in ('4','E') then 'Black'
when ethnic_cde in ('5','F') then 'White'
else 'Other'
end as ethnicity,
count(distinct studentid) as ct_students_alg2

into #ct_ethnicity_alg2

from #students_alg2_final

group by 
case when ethnic_cde in ('2','C','D') then 'Asian'
when ethnic_cde in ('3','A') then 'Hispanic'
when ethnic_cde in ('4','E') then 'Black'
when ethnic_cde in ('5','F') then 'White'
else 'Other'
end



---[5b] iep status breakdown for active cohort r students who have taken or are taking algebra 2
if object_id('tempdb..#ct_iep_alg2') is not null drop table #ct_iep_alg2

select
case when iep_spec_ed_flg='Y' then 'Student with Disabilities (IEP)'
else NULL
end as iep_status,
count(distinct studentid) as ct_students_alg2

into #ct_iep_alg2

from #students_alg2_final

group by 
case when iep_spec_ed_flg='Y'
then 'Student with Disabilities (IEP)'
else NULL
end



---[5c] ell status breakdown for active cohort r students who have taken or are taking algebra 2
if object_id('tempdb..#ct_ell_alg2') is not null drop table #ct_ell_alg2

select
case when lep_flg='Y' then 'ELL'
when lep_flg='P' then 'Former ELL'
else NULL
end as ell_status,
count(distinct studentid) as ct_students_alg2

into #ct_ell_alg2

from #students_alg2_final

group by
case when lep_flg='Y' then 'ELL'
when lep_flg='P' then 'Former ELL'
else NULL
end





-----[6] various demographic breakdowns for active cohort r students						
---[6a] ethnic breakdown for active cohort r students
if object_id('tempdb..#ct_ethnicity') is not null drop table #ct_ethnicity

select
case when ethnic_cde in ('2','C','D') then 'Asian'
when ethnic_cde in ('3','A') then 'Hispanic'
when ethnic_cde in ('4','E') then 'Black'
when ethnic_cde in ('5','F') then 'White'
else 'Other'
end as ethnicity,
count(distinct b.student_id) as ct_students

into #ct_ethnicity

from #student_list

case when ethnic_cde in ('2','C','D') then 'Asian'
when ethnic_cde in ('3','A') then 'Hispanic'
when ethnic_cde in ('4','E') then 'Black'
when ethnic_cde in ('5','F') then 'White'
else 'Other'
end



---[6b] iep status breakdown for active cohort r students
if object_id('tempdb..#ct_iep') is not null drop table #ct_iep

select 
case when iep_spec_ed_flg='Y' then 'Student with Disabilities (IEP)'
else NULL
end as iep_status,
count(distinct student_id) as ct_students

into #ct_iep

from #student_list

group by
case when b1.iep_spec_ed_flg='Y' then 'Student with Disabilities (IEP)'
else NULL
end



---[6c] ell status breakdown for active cohort r students
if object_id('tempdb..#ct_ell') is not null drop table #ct_ell

select 
case when lep_flg='Y' then 'ELL'
when lep_flg='P' then 'Former ELL'
else NULL
end as ell_status,
count(distinct student_id) as ct_students

into #ct_ell

from #student_list

group by
case when lep_flg='Y' then 'ELL'
when lep_flg='P' then 'Former ELL'
else NULL
end





-----[7] various measures of algebra 2 availability for cohort r students
---[7a] percentage of schools offering high school level alg2 in 2014
select
sa.ct_schools_alg2,
s.ct_schools,
sa.ct_schools_alg2/s.ct_schools as perc_schools_alg2

from #schools_alg2 as sa

cross join #schools as s



---[7b] percentages of active cohort r students who have taken or are taking alg2 by race
select
ea.ct_students_alg2,
e.ct_students,
ea.ct_students_alg2/e.ct_students as perc_students_alg2

from #ct_ethnicity_alg2 as ea

right join #ct_ethnicity as e
on e.ethnicity=ea.ethnicity



---[7c] percentages of active cohort r students who have taken or are taking alg2 by iep status
select
ia.ct_students_alg2,
i.ct_students,
ia.ct_students_alg2/i.ct_students as perc_alg2_students

from #ct_iep_alg2 as ia

right join #ct_iep as i
on i.iep_status=ia.iep_status



---[7d] percentages of active cohort r students who have taken or are taking alg2 by ell status
select
ea.ct_students_alg2,
e.ct_students,
ea.ct_students_alg2/e.ct_students as perc_alg2_students

from #ct_ell_alg2 as ea

right join #ct_ell as e
on e.ell_status=ea.ell_status