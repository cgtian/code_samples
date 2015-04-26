/*
pathways data sharing pull for april 2015

code outline
[1] active cohort q (or older) students plus their biographical information

[2] best exam performances for each student in the population
	[2a] exams for students in the population
	[2b] best exam performances for each student in the population
	[2c] best exam performances for each student in the population plus counts of exams above various thresholds

[3] students who are one social studies exam away from meeting exam requirements
	[3a] students who are one social studies exam away from meeting exam requirements for an advanced regents diploma
	[3b] students who are one social studies exam away from meeting exam requirements for a regents diploma
	[3c] students who are one social studies exam away from meeting exam requirements for a local diploma
		[3ci] students who meet exam requirements for a local diploma
		[3cii] students who are one social studies exam away from meeting exam requirements for a local diploma
	
[4] best exam performances for students who were one social studies exam away from meeting exam requirements pre-pathways who now meet exam requirements using the stem regents pathway

contact
chris tian - chris.tian(at)nyu.edu
*/





-----[1] active cohort Q (or older) students plus their biographical information
if object_id('tempdb..#s') is not null drop table #s
select distinct student_id,
first_nam,
last_nam,
school_dbn,
grd9_entry_cde,
grade_level,
lep_flg,
iep_spec_ed_flg,
s504
into #s

from ats_demo.dbo.biogdata

where status='A'
and grd9_entry_cde<='Q'
and substring(school_dbn,1,2) not in ('84','88')
and substring(school_dbn,4,3)<>'444'





-----[2] best exam performances for each student in the population
---	[2a] exams for students in the population
if object_id('tempdb..#exam_list') is not null drop table #exam_list
select distinct
s.student_id,
s.first_nam,
s.last_nam,
s.school_dbn,
s.grd9_entry_cde,
s.grade_level,
s.lep_flg,
s.iep_spec_ed_flg,
s.s504,
sm.schoolyear,
sm.termcd,
sm.coursecd,
convert	(int,
				case
				when sm.mark in ('A','CR','P','PL','PR','WA','WG','WX') and substring(sm.coursecd,2,2) in ('XR','XZ','ZR','XQ','XG','XT','X3') then '65'
				when sm.mark in ('P') and substring(sm.coursecd,2,2) in ('CT','XC') then '65'
				when sm.mark in ('A','S') and substring(sm.coursecd,2,2) in ('CT','XC') then '40'
				else sm.mark end
		) as mark
into #exam_list

from #s as s

inner join sif.dbo.hsst_tbl_studentmarks as sm
on s.student_id=sm.studentid

where sm.isexam=1
and (
		substring(sm.coursecd,2,2) in ('XR','XZ','ZR','XC','XQ','XG','XT','X3') or substring(sm.coursecd,1,3)='RCT'
	)
and sm.mark not in ('ABS','Z','INV','F','MIS')



---[2b] best exam performances for each student in the population
if object_id('tempdb..#best_exams') is not null drop table #best_exams
select distinct
e.student_id,
e.first_nam,
e.last_nam,
e.school_dbn,
e.grd9_entry_cde,
e.grade_level,
e.lep_flg,
e.iep_spec_ed_flg,
e.s504,
max(case when substring(e.coursecd,1,3) in ('EXR','EXZ','EZR') then e.mark end) as max_regents_english,
max(case when substring(e.coursecd,1,3) in ('MXR','MXZ','MZR') then e.mark end) as max_regents_math,
max(case when substring(e.coursecd,1,4) in ('MXRE','MXRC','MXZE','MXZC','MZRE','MXRA') then e.mark end) as max_regents_alg1,
max(case when substring(e.coursecd,1,4) in ('MXRG','MXZG','MZRG','MXRB') then e.mark end) as max_regents_geometry,
max(case when substring(e.coursecd,1,4) in ('MXRT','MXZT') then e.mark end) as max_regents_alg2,
max(case when substring(e.coursecd,1,4) in ('HXRA','HXRU','HXZU','HZRA') then e.mark end) as max_regents_us,
max(case when substring(e.coursecd,1,4) in ('HXR$','HXRG','HXZG','HZR$','HZRE') then e.mark end) as max_regents_global,
max(case when substring(e.coursecd,1,3) in ('SXR','SXZ','SZR') then e.mark end) as max_regents_science,
max(case when substring(e.coursecd,1,4) in ('SXR1','SXRK','SXZK','SZRK','SXRL') then e.mark end) as max_regents_living,
max(case when substring(e.coursecd,1,4) in ('SXRA','SXRE','SXRU','SXZU','SZRE','SZRU') then e.mark end) as max_regents_earth,
max(case when substring(e.coursecd,1,4) in ('SXRC','SXRX','SZRC') then e.mark end) as max_regents_chemistry,
max(case when substring(e.coursecd,1,4) in ('SXR$','SXRP') then e.mark end) as max_regents_physics,
max(case when substring(e.coursecd,2,2) in ('XT','X3') then e.mark end) as max_lote,
max(case when ((c.subjectcd=1 and substring(e.coursecd,1,4)='RCTR') or (substring(e.coursecd,1,4)='EXCR')) then e.mark end) as max_rct_reading,
max(case when ((c.subjectcd=1 and substring(e.coursecd,1,4)='RCTW') or (substring(e.coursecd,1,4)='EXCW')) then e.mark end) as max_rct_writing,
max(case when ((c.subjectcd=3 and substring(e.coursecd,1,4)='RCTM') or (substring(e.coursecd,1,4)='MXCM')) then e.mark end) as max_rct_math,
max(case when ((c.subjectcd=2 and substring(e.coursecd,1,4)='RCTH') or (substring(e.coursecd,1,4)='HXCU')) then e.mark end) as max_rct_us,
max(case when ((c.subjectcd=2 and substring(e.coursecd,1,4)='RCTG') or (substring(e.coursecd,1,4)='HXCG')) then e.mark end) as max_rct_global,
max(case when ((c.subjectcd=4 and substring(e.coursecd,1,4)='RCTS') or (substring(e.coursecd,1,4)='SXCS')) then e.mark end) as max_rct_science,
max(case when substring(e.coursecd,1,3) in ('MXQ','MXG') then e.mark end) as max_pbat_math,
max(case when substring(e.coursecd,1,3) in ('HXQ','HXG') then e.mark end) as max_pbat_ss,
max(case when substring(e.coursecd,1,3) in ('SXQ','SXG') then e.mark end) as max_pbat_science
into #best_exams

from #exam_list as e

inner join sif.dbo.hsst_tbl_courseinfo as c
on c.schooldbn=e.school_dbn
and c.schoolyear=e.schoolyear
and c.termcd=e.termcd
and c.coursecd=e.coursecd

group by e.student_id, e.first_nam, e.last_nam, e.school_dbn, e.grd9_entry_cde, e.grade_level, e.lep_flg, e.iep_spec_ed_flg, e.s504



---[2c] best exam performances for each student in the population plus counts of exams above various thresholds
if object_id('tempdb..#best_exams_plus_counts') is not null drop table #best_exams_plus_counts
select distinct
student_id,
first_nam,
last_nam,
school_dbn,
grd9_entry_cde,
grade_level,
lep_flg,
iep_spec_ed_flg,
s504,

  case	when max_regents_english>=65 then 1 else 0 end
+ case	when max_regents_alg1>=65 then 1 else 0 end
+ case	when max_regents_geometry>=65 then 1 else 0 end
+ case	when max_regents_alg2>=65 then 1 else 0 end
+ case	when max_regents_us>=65 then 1 else 0 end
+ case	when max_regents_global>=65 then 1 else 0 end
+ case	when max_regents_living>=65 and max_regents_earth>=65 then 2
		when max_regents_living>=65 and max_regents_chemistry>=65 then 2
		when max_regents_living>=65 and max_regents_physics>=65 then 2
		when max_regents_earth>=65 and max_regents_chemistry>=65 then 2
		when max_regents_earth>=65 and max_regents_physics>=65 then 2
		when max_regents_chemistry>=65 and max_regents_physics>=65 then 2
		else 0 end
+ case	when max_lote>=65 then 1 else 0 end
as ct_advanced_regents65,

  case	when max_regents_english>=65 then 1 else 0 end
+ case	when max_regents_math>=65 then 1 else 0 end
+ case	when max_regents_us>=65 then 1 else 0 end
+ case	when max_regents_global>=65 then 1 else 0 end
+ case	when max_regents_science>=65 then 1 else 0 end
as ct_regents65,

  case	when max_regents_english>=55 then 1 else 0 end
+ case	when max_regents_math>=55 then 1 else 0 end
+ case	when max_regents_us>=55 then 1 else 0 end
+ case	when max_regents_global>=55 then 1 else 0 end
+ case	when max_regents_science>=55 then 1 else 0 end
as ct_regents55,

  case	when max_regents_english>=45 then 1 else 0 end
+ case	when max_regents_math>=45 then 1 else 0 end
+ case	when max_regents_us>=45 then 1 else 0 end
+ case	when max_regents_global>=45 then 1 else 0 end
+ case	when max_regents_science>=45 then 1 else 0 end
as ct_regents45,

  case	when max_regents_english>=65 then 1 else 0 end
+ case	when max_regents_math>=65 or max_pbat_math>=65 then 1 else 0 end
+ case	when max_regents_us>=65 or max_pbat_ss>=65 then 1 else 0 end
+ case	when max_regents_global>=65 or max_pbat_ss>=65 then 1 else 0 end
+ case	when max_regents_science>=65 or max_pbat_science>=65 then 1 else 0 end
as ct_mixr,

  case	when max_regents_english>=55 or (max_rct_reading=65 and max_rct_writing=65) then 1 else 0 end
+ case	when max_regents_math>=55 or max_rct_math=65 or max_pbat_math>=65 then 1 else 0 end
+ case	when max_regents_us>=55 or max_rct_us=65 or max_pbat_ss>=65 then 1 else 0 end
+ case	when max_regents_global>=55 or max_rct_global=65 or max_pbat_ss>=65 then 1 else 0 end
+ case	when max_regents_science>=55 or max_rct_science=65 or max_pbat_science>=65 then 1 else 0 end
as ct_mixl,

max_regents_english,
max_regents_math,
max_regents_alg1,
max_regents_geometry,
max_regents_alg2,
max_regents_us,
max_regents_global,
max_regents_science,
max_regents_living,
max_regents_earth,
max_regents_chemistry,
max_regents_physics,
max_rct_reading,
max_rct_writing,
max_rct_math,
max_rct_us,
max_rct_global,
max_rct_science,
max_pbat_math,
max_pbat_ss,
max_pbat_science
into #best_exams_plus_counts

from #best_exams





-----[3] students who are one social studies exam away from meeting exam requirements
---	[3a] students who are one social studies exam away from meeting exam requirements for an advanced regents diploma
if object_id('tempdb..#one_away_advanced') is not null drop table #one_away_advanced
select distinct student_id
into #one_away_advanced

from #best_exams_plus_counts

where ct_advanced_regents65=8
and (max_regents_us<65 or max_regents_global<65)



---[3b] students who are one social studies exam away from meeting exam requirements for a regents diploma
if object_id('tempdb..#one_away_regents') is not null drop table #one_away_regents
select distinct student_id
into #one_away_regents

from #best_exams_plus_counts

where ct_mixr=4
and (max_pbat_ss<65 or max_pbat_ss is null)
and	(
		(max_regents_global<65 or max_regents_global is null)
		or 
		(max_regents_us<65 or max_regents_us is null)
	)
and student_id not in (select student_id from #one_away_advanced)



---	[3c] students who are one social studies exam away from meeting exam requirements for a local diploma
-- [3ci] students who meet exam requirements for a local diploma
if object_id('tempdb..#meets_reqs_local') is not null drop table #meets_reqs_local
select distinct student_id
into #meets_reqs_local

from #best_exams_plus_counts

where iep_spec_ed_flg='Y'
and	(
		ct_mixl=5				---this condition is not necessary for the purposes of our analysis but is included to be consistent with other analyses in april 2015's data sharing series
		or
		(ct_regents45=5 and max_regents_english>=55 and max_regents_math>=55 and ct_regents45-ct_regents55<=ct_regents65)
	)


--[3cii] students who are one social studies exam away from meeting exam requirements for a local diploma
if object_id('tempdb..#one_away_local') is not null drop table #one_away_local
select distinct student_id
into #one_away_local

from #best_exams_plus_counts

where iep_spec_ed_flg='Y'
and ct_mixl=4
and (max_pbat_ss<65 or max_pbat_ss is null)
and (
		(
			(max_regents_us<55 or max_regents_us is null)
			and (max_rct_us<65 or max_rct_us is null)
		)
	or	
		(	
			(max_regents_global<55 or max_regents_global is null)
			and (max_rct_global<65 or max_rct_global is null)
		)
	)
and student_id not in (select student_id from #meets_reqs_local)
and student_id not in (select student_id from #one_away_advanced)
and student_id not in (select student_id from #one_away_regents)
---note: only partially takes into account compensatory score option (via #meets_reqs_local exclusion)





-----[4] best exam performances for students who were one social studies exam away from meeting exam requirements pre-pathways who now meet exam requirements using the stem regents pathway
select *,
0 as dummy_local_requirements,
0 as dummy_regents_requirements,
1 as dummy_advanced_requirements

from #best_exams

where student_id in (select student_id from #one_away_advanced)
and	(
		(max_regents_living>=65 and max_regents_earth>=65 and max_regents_chemistry>=65)
		or (max_regents_living>=65 and max_regents_earth>=65 and max_regents_physics>=65)
		or (max_regents_earth>=65 and max_regents_chemistry>=65 and max_regents_physics>=65)
	)

union

select *,
0 as dummy_local_requirements,
1 as dummy_regents_requirements,
0 as dummy_advanced_requirements

from #best_exams

where student_id in (select student_id from #one_away_regents)
and	(
		(max_regents_alg1>=65 and max_regents_geometry>=65)
		or (max_regents_alg1>=65 and max_regents_alg2>=65)
		or (max_regents_geometry>=65 and max_regents_alg2>=65)
		or (max_regents_living>=65 and max_regents_earth>=65)
		or (max_regents_living>=65 and max_regents_chemistry>=65)
		or (max_regents_living>=65 and max_regents_physics>=65)
		or (max_regents_earth>=65 and max_regents_chemistry>=65)
		or (max_regents_earth>=65 and max_regents_physics>=65)
		or (max_regents_chemistry>=65 and max_regents_physics>=65)
	)

union

select *,
1 as dummy_local_requirements,
0 as dummy_regents_requirements,
0 as dummy_advanced_requirements

from #best_exams

where student_id in (select student_id from #one_away_local)
and	(
		(max_regents_alg1>=55 and max_regents_geometry>=55)
		or (max_regents_alg1>=55 and max_regents_alg2>=55)
		or (max_regents_geometry>=55 and max_regents_alg2>=55)
		or (max_regents_living>=55 and max_regents_earth>=55)
		or (max_regents_living>=55 and max_regents_chemistry>=55)
		or (max_regents_living>=55 and max_regents_physics>=55)
		or (max_regents_earth>=55 and max_regents_chemistry>=55)
		or (max_regents_earth>=55 and max_regents_physics>=55)
		or (max_regents_chemistry>=55 and max_regents_physics>=55)
	)

order by
dummy_advanced_requirements,
dummy_regents_requirements,
dummy_local_requirements,
student_id asc
---note: does not take into account compensatory score option