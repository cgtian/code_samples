/*
pathways data sharing analysis for april 2015

description
this analysis measures the immediate impact of the newly legislated pathways exam requirements on hs seniors' prospects for graduation
(i.e. how many hs seniors who previously did not meet exam requirements to graduate now meet the new pathways exam requirements?)

code outline
[1] active cohort q (or older) students plus their biographical information

[2] best exam performances plus counts of exams above various thresholds for each student in the above population (who have any)
	[2a] exams for each student
	[2b] best stem exam performance in a subject_detail besides the two associated with the student's highest math and science exams
		[2bi] indexes by studentid_subject and studentid_subject_detail for stem exams
		[2bii] best stem exam performance in a subject_detail besides the two associated with the student's highest math and science exams
	[2c] best exam performances for each student
	[2d] counts of exams above various thresholds for each student
	[2e] exams away from meeting local exam requirements via compensatory score option for each student
	[2f] best exam performances plus counts of exams above various thresholds for each student

[3] students who are one social studies exam away from meeting exam requirements
	[3a] students who are one social studies exam away from meeting exam requirements for an advanced regents diploma
	[3b] students who are one social studies exam away from meeting exam requirements for a regents diploma
	[3c] students who are one social studies exam away from meeting exam requirements for a local diploma (assuming future exams result in scores between 55 and 64 inclusive)
		[3ci] students who meet exam requirements for a local diploma
		[3cii] students who are one social studies exam away from meeting exam requirements for a local diploma (assuming future exams result in scores between 55 and 64 inclusive)
	
[4] best exam performances for students who were one social studies exam away from meeting exam requirements pre-pathways who now meet exam requirements using the stem regents pathway
*/





-----[1] active cohort Q (or older) students plus their biographical information
if object_id('tempdb..#s') is not null drop table #s

select distinct
student_id,
first_nam,
last_nam,
school_dbn,
grd9_entry_cde,
grade_level,
lep_flg,
iep_spec_ed_flg,
s504

into #s

from bio_data

where
status='A'
and grd9_entry_cde<='Q'
and substring(school_dbn,1,2) not in ('84','88')
and substring(school_dbn,4,3)!='444'





-----[2] best exam performances plus counts of exams above various thresholds for each student in the above population (who have any)
---[2a] exams for each student
if object_id('tempdb..#exam_list') is not null drop table #exam_list

select distinct
s.student_id,
sm.schoolyear,
sm.termcd,
sm.coursecd,

substring(sm.coursecd,1,1) as subject,

case 	when substring(sm.coursecd,2,2) in ('XR','XZ','ZR') and substring(sm.coursecd,1,1)+substring(sm.coursecd,4,1) in ('ME','MC','MA') then 'algebra1'
	when substring(sm.coursecd,2,2) in ('XR','XZ','ZR') and substring(sm.coursecd,1,1)+substring(sm.coursecd,4,1) in ('MG','MB') then 'geometry'
	when substring(sm.coursecd,2,2) in ('XR','XZ','ZR') and substring(sm.coursecd,1,1)+substring(sm.coursecd,4,1)='MT' then 'algebra2'
	when substring(sm.coursecd,2,2) in ('XR','XZ','ZR') and substring(sm.coursecd,1,1)+substring(sm.coursecd,4,1) in ('S1','SK','SL') then 'living_environment'
	when substring(sm.coursecd,2,2) in ('XR','XZ','ZR') and substring(sm.coursecd,1,1)+substring(sm.coursecd,4,1) in ('SA','SE','SU') then 'earth_science'
	when substring(sm.coursecd,2,2) in ('XR','XZ','ZR') and substring(sm.coursecd,1,1)+substring(sm.coursecd,4,1) in ('SC','SX') then 'chemistry'
	when substring(sm.coursecd,2,2) in ('XR','XZ','ZR') and substring(sm.coursecd,1,1)+substring(sm.coursecd,4,1) in ('SP','S$') then 'physics'
	end
as subject_detail,

convert	(int,
		case	when sm.mark in ('A','CR','P','PL','PR','WA','WG','WX') and substring(sm.coursecd,2,2) in ('XR','XZ','ZR','XQ','XG','XT','X3') then '65'
			when sm.mark in ('P') and substring(sm.coursecd,2,2) in ('CT','XC') then '65'
			when sm.mark in ('A','S') and substring(sm.coursecd,2,2) in ('CT','XC') then '40'
			else sm.mark end
	)
as mark,

row_number() over	(	
				partition by student_id
				order by student_id asc
			)
as index_all

into #exam_list

from #s as s

inner join student_marks as sm
on s.student_id=sm.studentid

where
sm.isexam=1
and	(
		substring(sm.coursecd,2,2) in ('XR','XZ','ZR','XC','XQ','XG','XT','X3') or substring(sm.coursecd,1,3)='RCT'
	)
and sm.mark not in ('ABS','Z','INV','F','MIS')



---[2b] best stem exam performance in a subject_detail besides the two associated with the student's highest math and science exams
--[2bi] indexes by studentid_subject and studentid_subject_detail for stem exams
if object_id('tempdb..#second_stem_setup') is not null drop table #second_stem_setup

select distinct
student_id,
schoolyear,
termcd,
coursecd,
subject,
subject_detail,
mark,

row_number() over	(	
				partition by student_id, subject
				order by student_id, subject, mark desc, index_all
			)
as index_studentid_subject,

row_number() over	(
				partition by student_id, subject_detail
				order by student_id, subject_detail, mark desc, index_all
			)
as index_studentid_subject_detail

into #second_stem_int

from #exam_list

where
subject_detail is not null


--[2bii] best stem exam performance in a subject_detail besides the two associated with the student's highest math and science exams
if object_id('tempdb..#max_regents_second_stem') is not null drop table #max_regents_second_stem

select
student_id,
max(mark) as max_regents_second_stem

into #max_regents_second_stem

from #second_stem_int

where
index_studentid_subject!=1
and index_studentid_subject_detail=1

group by
student_id



---[2c] best exam performances
if object_id('tempdb..#best_exams') is not null drop table #best_exams

select distinct
e.student_id,
max(case when substring(e.coursecd,1,3) in ('EXR','EXZ','EZR') then mark end) as max_regents_english,
max(case when substring(e.coursecd,1,3) in ('MXR','MXZ','MZR') then mark end) as max_regents_math,
max(case when substring(e.coursecd,1,4) in ('MXRE','MXRC','MXZE','MXZC','MZRE','MXRA') then mark end) as max_regents_alg1,
max(case when substring(e.coursecd,1,4) in ('MXRG','MXZG','MZRG','MXRB') then mark end) as max_regents_geometry,
max(case when substring(e.coursecd,1,4) in ('MXRT','MXZT') then mark end) as max_regents_alg2,
max(case when substring(e.coursecd,1,3) in ('HXR','HXZ','HZR') then mark end) as max_regents_ss,
max(case when substring(e.coursecd,1,4) in ('HXRA','HXRU','HXZU','HZRA') then mark end) as max_regents_us,
max(case when substring(e.coursecd,1,4) in ('HXR$','HXRG','HXZG','HZR$','HZRE') then mark end) as max_regents_global,
max(case when substring(e.coursecd,1,3) in ('SXR','SXZ','SZR') then mark end) as max_regents_science,
max(case when substring(e.coursecd,1,4) in ('SXR1','SXRK','SXZK','SZRK','SXRL') then mark end) as max_regents_living,
max(case when substring(e.coursecd,1,4) in ('SXRA','SXRE','SXRU','SXZU','SZRE','SZRU') then mark end) as max_regents_earth,
max(case when substring(e.coursecd,1,4) in ('SXRC','SXRX','SZRC') then mark end) as max_regents_chemistry,
max(case when substring(e.coursecd,1,4) in ('SXR$','SXRP') then mark end) as max_regents_physics,
ss.max_regents_second_stem,
max(case when substring(e.coursecd,1,3) in ('FXT','FX3') then mark end) as max_lote,
max(case when (substring(e.coursecd,1,4)='RCTR' or substring(coursecd,1,4)='EXCR') then mark end) as max_rct_reading,
max(case when (substring(e.coursecd,1,4)='RCTW' or substring(coursecd,1,4)='EXCW') then mark end) as max_rct_writing,
max(case when (substring(e.coursecd,1,4)='RCTM' or substring(coursecd,1,4)='MXCM') then mark end) as max_rct_math,
max(case when (substring(e.coursecd,1,4)='RCTH' or substring(coursecd,1,4)='HXCU') then mark end) as max_rct_us,
max(case when (substring(e.coursecd,1,4)='RCTG' or substring(coursecd,1,4)='HXCG') then mark end) as max_rct_global,
max(case when (substring(e.coursecd,1,4)='RCTS' or substring(coursecd,1,4)='SXCS') then mark end) as max_rct_science,
max(case when substring(e.coursecd,1,3) in ('MXQ','MXG') then mark end) as max_pbat_math,
max(case when substring(e.coursecd,1,3) in ('HXQ','HXG') then mark end) as max_pbat_ss,
max(case when substring(e.coursecd,1,3) in ('SXQ','SXG') then mark end) as max_pbat_science

into #best_exams

from #exam_list as e

left join #max_regents_second_stem as ss
on ss.student_id=e.student_id

group by
e.student_id,
ss.max_regents_second_stem



---[2d] counts of exams above various thresholds
if object_id('tempdb..#exam_counts') is not null drop table #exam_counts

select distinct
s.student_id,

  case	when be.max_regents_english>=65 then 1 else 0 end
+ case	when be.max_regents_alg1>=65 then 1 else 0 end
+ case	when be.max_regents_geometry>=65 then 1 else 0 end
+ case	when be.max_regents_alg2>=65 then 1 else 0 end
+ case	when be.max_regents_us>=65 then 1 else 0 end
+ case	when be.max_regents_global>=65 then 1 else 0 end
+ case	when	(
			  case	when be.max_regents_living>=65 then 1 else 0 end
			+ case	when be.max_regents_earth>=65 then 1 else 0 end
			+ case	when be.max_regents_chemistry>=65 then 1 else 0 end
			+ case	when be.max_regents_physics>=65 then 1 else 0 end
		)
		>2
	then	2
	else	(
			  case	when be.max_regents_living>=65 then 1 else 0 end
			+ case	when be.max_regents_earth>=65 then 1 else 0 end
			+ case	when be.max_regents_chemistry>=65 then 1 else 0 end
			+ case	when be.max_regents_physics>=65 then 1 else 0 end
		)
	end
+ case	when be.max_lote>=65 then 1 else 0 end
as ct_advanced_regents65,

  case	when be.max_regents_english>=65 then 1 else 0 end
+ case	when be.max_regents_math>=65 then 1 else 0 end
+ case	when be.max_regents_us>=65 then 1 else 0 end
+ case	when be.max_regents_global>=65 then 1 else 0 end
+ case	when be.max_regents_science>=65 then 1 else 0 end
as ct_regents65,

  case	when be.max_regents_english>=65 then 1 else 0 end
+ case	when be.max_regents_math>=65 then 1 else 0 end
+ case	when be.max_regents_ss>=65 then 1 else 0 end
+ case	when be.max_regents_science>=65 then 1 else 0 end
+ case	when be.max_regents_second_stem>=65 then 1 else 0 end
as ct_regents65_star,

  case	when be.max_regents_living>=65 then 1 else 0 end
+ case	when be.max_regents_earth>=65 then 1 else 0 end
+ case	when be.max_regents_chemistry>=65 then 1 else 0 end
+ case	when be.max_regents_physics>=65 then 1 else 0 end
as ct_regents_science65,

  case	when be.max_regents_english>=45 and be.max_regents_english<55 then 1 else 0 end
+ case	when be.max_regents_math>=45 and be.max_regents_math<55 then 1 else 0 end
+ case	when be.max_regents_us>=45 and be.max_regents_us<55 then 1 else 0 end
+ case	when be.max_regents_global>=45 and be.max_regents_global<55 then 1 else 0 end
+ case  when be.max_regents_science>=45 and be.max_regents_science<55 then 1 else 0 end
as ct_regents45to55,

  case	when be.max_regents_english>=45 and be.max_regents_english<55 then 1 else 0 end
+ case	when be.max_regents_math>=45 and be.max_regents_math<55 then 1 else 0 end
+ case	when be.max_regents_ss>=45 and be.max_regents_ss<55 then 1 else 0 end
+ case  when be.max_regents_science>=45 and be.max_regents_science<55 then 1 else 0 end
+ case	when be.max_regents_second_stem>=45 and be.max_regents_second_stem<55 then 1 else 0 end
as ct_regents45to55_star,

  case	when be.max_regents_english>=65 then 1 else 0 end
+ case	when be.max_regents_math>=65 or max_pbat_math>=65 then 1 else 0 end
+ case	when be.max_regents_us>=65 or max_pbat_ss>=65 then 1 else 0 end
+ case	when be.max_regents_global>=65 or max_pbat_ss>=65 then 1 else 0 end
+ case	when be.max_regents_science>=65 or max_pbat_science>=65 then 1 else 0 end
as ct_mixr,

  case	when s.iep_spec_ed_flg='Y'
	then	(
			  case	when be.max_regents_english>=55 or (be.max_rct_reading=65 and be.max_rct_writing=65) then 1 else 0 end
			+ case	when be.max_regents_math>=55 or be.max_rct_math=65 or be.max_pbat_math>=65 then 1 else 0 end
			+ case	when be.max_regents_us>=55 or be.max_rct_us=65 or be.max_pbat_ss>=65 then 1 else 0 end
			+ case	when be.max_regents_global>=55 or be.max_rct_global=65 or be.max_pbat_ss>=65 then 1 else 0 end
			+ case	when be.max_regents_science>=55 or be.max_rct_science=65 or be.max_pbat_science>=65 then 1 else 0 end
		)
	else NULL
	end
as ct_mixl

into #exam_counts

from #s as s

inner join #best_exams as be
on be.student_id=s.student_id



---[2e] exams away from meeting local exam requirements via compensatory score option (SWDs only)
if object_id('tempdb..#exams_away_local_cs') is not null drop table #exams_away_local_cs

select distinct
be.student_id,

  case	when be.max_regents_english<55 or be.max_regents_english is null then 1 else 0 end
+ case	when be.max_regents_math<55 or be.max_regents_math is null then 1 else 0 end
+ case	when be.max_regents_science<45 or be.max_regents_science is null then 1 else 0 end
+ case	when be.max_regents_us<45 or be.max_regents_us is null then 1 else 0 end
+ case	when be.max_regents_global<45 or be.max_regents_global is null then 1 else 0 end
+ case	when ec.ct_regents45to55-ec.ct_regents65
	     -(case when max_regents_english>=45 and max_regents_english<55 then 1 else 0 end)
	     -(case when max_regents_math>=45 and max_regents_math<55 then 1 else 0 end)
	     >=0
	then ec.ct_regents45to55-ec.ct_regents65
	     -(case when max_regents_english>=45 and max_regents_english<55 then 1 else 0 end)
	     -(case when max_regents_math>=45 and max_regents_math<55 then 1 else 0 end)
	else 0 
	end
as ct_exams_away_local_cs

into #exams_away_local_cs

from #s as s

inner join #best_exams as be
on be.student_id=s.student_id

inner join #exam_counts as ec
on ec.student_id=be.student_id

where
s.iep_spec_ed_flg='Y'



---[2f] best exam performances plus counts of exams above various thresholds
if object_id('tempdb..#best_exams_plus_counts') is not null drop table #best_exams_plus_counts

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
be.max_regents_english,
be.max_regents_math,
be.max_regents_alg1,
be.max_regents_geometry,
be.max_regents_alg2,
be.max_regents_ss,
be.max_regents_us,
be.max_regents_global,
be.max_regents_science,
be.max_regents_living,
be.max_regents_earth,
be.max_regents_chemistry,
be.max_regents_physics,
be.max_regents_second_stem,
be.max_lote,
be.max_rct_reading,
be.max_rct_writing,
be.max_rct_math,
be.max_rct_us,
be.max_rct_global,
be.max_rct_science,
be.max_pbat_math,
be.max_pbat_ss,
be.max_pbat_science,
ec.ct_advanced_regents65,
ec.ct_regents65,
ec.ct_regents65_star,
ec.ct_regents_science65,
ec.ct_regents45to55,
ec.ct_regents45to55_star,
ec.ct_mixr,
ec.ct_mixl,
ealc.ct_exams_away_local_cs

into #best_exams_plus_counts

from #s as s

left join #best_exams as be
on be.student_id=s.student_id

left join #exam_counts as ec
on ec.student_id=s.student_id

left join #exams_away_local_cs as ealc
on ealc.student_id=s.student_id





-----[3] students who are one social studies exam away from meeting exam requirements
---[3a] students who are one social studies exam away from meeting exam requirements for an advanced regents diploma
if object_id('tempdb..#one_away_advanced') is not null drop table #one_away_advanced

select distinct
student_id

into #one_away_advanced

from #best_exams_plus_counts

where
ct_advanced_regents65=8
and (max_regents_us<65 or max_regents_us is null or max_regents_global<65 or max_regents_global is null)



---[3b] students who are one social studies exam away from meeting exam requirements for a regents diploma
if object_id('tempdb..#one_away_regents') is not null drop table #one_away_regents

select distinct
student_id

into #one_away_regents

from #best_exams_plus_counts

where
ct_mixr=4
and (max_pbat_ss<65 or max_pbat_ss is null)
and	(
		(max_regents_global<65 or max_regents_global is null)
		or 
		(max_regents_us<65 or max_regents_us is null)
	)
and student_id not in (select student_id from #one_away_advanced)



---[3c] students who are one social studies exam away from meeting exam requirements for a local diploma
--[3ci] students who meet exam requirements for a local diploma
if object_id('tempdb..#meets_reqs_local') is not null drop table #meets_reqs_local

select distinct
student_id

into #meets_reqs_local

from #best_exams_plus_counts

where
iep_spec_ed_flg='Y'
and	(
		ct_mixl=5
		or
		(
			max_regents_english>=55
			and max_regents_math>=55
			and max_regents_us>=45
			and max_regents_global>=45
			and max_regents_science>=45
			and ct_regents45to55<=ct_regents65
		)
	)


--[3cii] students who are one social studies exam away from meeting exam requirements for a local diploma
if object_id('tempdb..#one_away_local') is not null drop table #one_away_local

select distinct
student_id

into #one_away_local

from #best_exams_plus_counts

where
iep_spec_ed_flg='Y'
and	(
		(
			ct_mixl=4
			and (max_pbat_ss<65 or max_pbat_ss is null)
			and	(
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
		)
		or
		(
			ct_exams_away_local_cs=1
			and	(
					(
						(max_regents_us<55 or max_regents_us is null)
						and max_regents_english>=55
						and max_regents_math>=55
						and max_regents_global>=45
						and max_regents_science>=45
					)
					or
					(
						(max_regents_global<55 or max_regents_global is null)
						and max_regents_english>=55
						and max_regents_math>=55
						and max_regents_us>=45
						and max_regents_science>=45
					)
				)
		)
	)
and student_id not in (select student_id from #meets_reqs_local)
and student_id not in (select student_id from #one_away_advanced)
and student_id not in (select student_id from #one_away_regents)





-----[4] best exam performances for students who were one social studies exam away from meeting exam requirements pre-pathways who now meet exam requirements using the stem regents pathway
select *,
0 as dummy_local_requirements,
0 as dummy_regents_requirements,
1 as dummy_advanced_requirements

from #best_exams_plus_counts

where
student_id in (select student_id from #one_away_advanced)
and ct_regents_science65>=3

union

select *,
0 as dummy_local_requirements,
1 as dummy_regents_requirements,
0 as dummy_advanced_requirements

from #best_exams_plus_counts

where
student_id in (select student_id from #one_away_regents)
and max_regents_second_stem>=65

union

select *,
1 as dummy_local_requirements,
0 as dummy_regents_requirements,
0 as dummy_advanced_requirements

from #best_exams_plus_counts

where
student_id in (select student_id from #one_away_local)
and	(
		(
			ct_mixl=4
			and max_regents_second_stem>=55
		)
		or
		(
			ct_exams_away_local_cs=1
			and max_regents_english>=55
			and max_regents_math>=55
			and max_regents_ss>=45
			and max_regents_science>=45
			and max_regents_second_stem>=45
			and ct_regents45to55_star<=ct_regents65_star
		)
	)

order by
dummy_advanced_requirements,
dummy_regents_requirements,
dummy_local_requirements,
student_id