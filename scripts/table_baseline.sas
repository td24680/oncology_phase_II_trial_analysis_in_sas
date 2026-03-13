* Create Table 1: Baseline Characteristics;

* Load project setup;
%include "/home/u64449610/oncology_phase_II_trial_analysis/scripts/00_setup.sas";

title;
footnote;

* 1. Import analysis dataset;
proc import datafile="&proj/data/analysis/subject_level_analysis.csv"
    out=adsl
    dbms=csv
    replace;
    guessingrows=max;
run;

* 2. Patient counts; 
proc freq data=adsl noprint;
    tables treatment_group / out=patient_counts(drop=percent);
run;

* 3. Age summary: mean (SD); 
proc means data=adsl noprint mean std;
    class treatment_group;
    var age;
    output out=age_stats mean=mean_age std=sd_age;
run;

data age_summary;
    set age_stats;
    where _TYPE_ = 1;
    length age_mean_sd $30;
    age_mean_sd = cats(
        put(round(mean_age, 0.1), 5.1),
        " (",
        put(round(sd_age, 0.1), 5.1),
        ")"
    );
    keep treatment_group age_mean_sd;
run;

* 4. Sex summary: n (%);
proc freq data=adsl noprint;
    tables treatment_group*sex / out=sex_counts;
run;

proc sql;
    create table total_by_group as
    select treatment_group,
           sum(count) as total_n
    from sex_counts
    group by treatment_group;
quit;

proc sort data=sex_counts;
    by treatment_group;
run;

proc sort data=total_by_group;
    by treatment_group;
run;

data sex_summary;
    merge sex_counts total_by_group;
    by treatment_group;
    length summary $20;
    percent = round(100 * count / total_n, 0.1);
    summary = cats(count, " (", put(percent, 5.1), "%)");
    keep treatment_group sex summary;
run;

* 5. Baseline tumor size summary: mean (SD);
proc means data=adsl noprint mean std;
    class treatment_group;
    var baseline_tumor_size_mm;
    output out=tumor_stats mean=mean_tumor std=sd_tumor;
run;

data tumor_summary;
    set tumor_stats;
    where _TYPE_ = 1;
    length baseline_tumor_mean_sd $30;
    baseline_tumor_mean_sd = cats(
        put(round(mean_tumor, 0.1), 6.1),
        " (",
        put(round(sd_tumor, 0.1), 6.1),
        ")"
    );
    keep treatment_group baseline_tumor_mean_sd;
run;

* 6. Create empty Table 1 structure;
data table1;
    length variable $50 DrugA $30 Placebo $30;
    input variable $char50.;
    datalines;
Number of patients
Age, mean (SD)
Baseline tumor size (mm), mean (SD)
Male, n (%)
Female, n (%)
;
run;

* 7. Fill in patient counts;
proc sql noprint;
    select count into :drugA_n trimmed
    from patient_counts
    where treatment_group = "DrugA";

    select count into :placebo_n trimmed
    from patient_counts
    where treatment_group = "Placebo";
quit;

data table1;
    set table1;
    if variable = "Number of patients" then do;
        DrugA   = coalescec("&drugA_n","0");
        Placebo = coalescec("&placebo_n","0");
    end;
run;

* 8. Fill in age summary;
proc sql noprint;
    select age_mean_sd into :drugA_age trimmed
    from age_summary
    where treatment_group = "DrugA";

    select age_mean_sd into :placebo_age trimmed
    from age_summary
    where treatment_group = "Placebo";
quit;

data table1;
    set table1;
    if variable = "Age, mean (SD)" then do;
        DrugA   = coalescec("&drugA_age","");
        Placebo = coalescec("&placebo_age","");
    end;
run;

* 9. Fill in baseline tumor summary;
proc sql noprint;
    select baseline_tumor_mean_sd into :drugA_tumor trimmed
    from tumor_summary
    where treatment_group = "DrugA";

    select baseline_tumor_mean_sd into :placebo_tumor trimmed
    from tumor_summary
    where treatment_group = "Placebo";
quit;

data table1;
    set table1;
    if variable = "Baseline tumor size (mm), mean (SD)" then do;
        DrugA   = coalescec("&drugA_tumor","");
        Placebo = coalescec("&placebo_tumor","");
    end;
run;

* 10. Fill in male summary;
proc sql noprint;
    select summary into :drugA_male trimmed
    from sex_summary
    where treatment_group = "DrugA" and sex = "Male";

    select summary into :placebo_male trimmed
    from sex_summary
    where treatment_group = "Placebo" and sex = "Male";
quit;

data table1;
    set table1;
    if variable = "Male, n (%)" then do;
        DrugA   = coalescec("&drugA_male","0 (0.0%)");
        Placebo = coalescec("&placebo_male","0 (0.0%)");
    end;
run;

* 11. Fill in female summary;
proc sql noprint;
    select summary into :drugA_female trimmed
    from sex_summary
    where treatment_group = "DrugA" and sex = "Female";

    select summary into :placebo_female trimmed
    from sex_summary
    where treatment_group = "Placebo" and sex = "Female";
quit;

data table1;
    set table1;
    if variable = "Female, n (%)" then do;
        DrugA   = coalescec("&drugA_female","0 (0.0%)");
        Placebo = coalescec("&placebo_female","0 (0.0%)");
    end;
run;

* 12. Print Table 1;
title "Table 1. Baseline Characteristics";
proc print data=table1 noobs label;
run;

* 13. Export Table 1;
proc export data=table1
    outfile="&proj/outputs/tables/table1_baseline_characteristics.csv"
    dbms=csv
    replace;
run;

%put NOTE: Table 1 generation completed.;