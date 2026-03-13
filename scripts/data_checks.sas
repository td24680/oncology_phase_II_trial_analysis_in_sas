/*========================================================
  Quick checks for simulated oncology trial datasets
========================================================*/

/*--------------------------------------------------------
  1. Read datasets
--------------------------------------------------------*/
proc import datafile="/Users/hongtuoi/python-learning/oncology_phase_II_trial_analysis/data/raw/demographics.csv"
    out=demographics
    dbms=csv
    replace;
    guessingrows=max;
run;

proc import datafile="/Users/hongtuoi/python-learning/oncology_phase_II_trial_analysis/data/raw/tumor_measurements.csv"
    out=tumor
    dbms=csv
    replace;
    guessingrows=max;
run;

proc import datafile="/Users/hongtuoi/python-learning/oncology_phase_II_trial_analysis/data/raw/adverse_events.csv"
    out=adverse_events
    dbms=csv
    replace;
    guessingrows=max;
run;

proc import datafile="/Users/hongtuoi/python-learning/oncology_phase_II_trial_analysis/data/raw/data_dictionary.csv"
    out=data_dictionary
    dbms=csv
    replace;
    guessingrows=max;
run;

proc import datafile="/Users/hongtuoi/python-learning/oncology_phase_II_trial_analysis/data/analysis/subject_level_analysis.csv"
    out=subject_level_analysis
    dbms=csv
    replace;
    guessingrows=max;
run;

proc import datafile="/Users/hongtuoi/python-learning/oncology_phase_II_trial_analysis/data/analysis/time_to_event_analysis.csv"
    out=time_to_event_analysis
    dbms=csv
    replace;
    guessingrows=max;
run;


/*--------------------------------------------------------
  2. Dataset sizes
--------------------------------------------------------*/
%macro dataset_nobs(dsname);
    %local dsid nobs rc;
    %let dsid = %sysfunc(open(&dsname));
    %let nobs = %sysfunc(attrn(&dsid, nlobs));
    %let rc = %sysfunc(close(&dsid));
    %put &dsname: &nobs rows;
%mend;

%put Dataset sizes;
%put -----------------;
%dataset_nobs(demographics);
%dataset_nobs(tumor);
%dataset_nobs(adverse_events);
%dataset_nobs(data_dictionary);
%dataset_nobs(subject_level_analysis);
%dataset_nobs(time_to_event_analysis);


/*--------------------------------------------------------
  3. Treatment groups
--------------------------------------------------------*/
title "Treatment groups";
proc freq data=demographics;
    tables treatment_group;
run;


/*--------------------------------------------------------
  4. Tumor visit distribution
--------------------------------------------------------*/
title "Tumor visit distribution";
proc freq data=tumor;
    tables visit_name;
run;


/*--------------------------------------------------------
  5. Baseline tumor size summary
--------------------------------------------------------*/
title "Baseline tumor size summary";
proc means data=subject_level_analysis n nmiss mean std min q1 median q3 max;
    var baseline_tumor_size_mm;
run;


/*--------------------------------------------------------
  6. Endpoints in survival dataset
--------------------------------------------------------*/
title "Endpoints in survival dataset";
proc freq data=time_to_event_analysis;
    tables endpoint;
run;


/*--------------------------------------------------------
  7. Censor summary
--------------------------------------------------------*/
title "Censor summary";
proc freq data=time_to_event_analysis;
    tables endpoint*censor_flag;
run;


/*--------------------------------------------------------
  8. Missing values
--------------------------------------------------------*/
proc sql;
    title "Missing values summary";

    select 
        "demographics" as dataset length=30,
        sum(missing(subject_id)) +
        sum(missing(treatment_group)) +
        sum(missing(age)) +
        sum(missing(sex)) as total_missing
    from demographics

    union all

    select 
        "tumor_measurements" as dataset length=30,
        sum(missing(subject_id)) +
        sum(missing(visit_name)) +
        sum(missing(tumor_size_mm)) as total_missing
    from tumor

    union all

    select 
        "adverse_events" as dataset length=30,
        sum(missing(subject_id)) +
        sum(missing(ae_term)) +
        sum(missing(ae_grade)) as total_missing
    from adverse_events

    union all

    select 
        "subject_level_analysis" as dataset length=30,
        sum(missing(subject_id)) +
        sum(missing(treatment_group)) +
        sum(missing(age)) +
        sum(missing(sex)) +
        sum(missing(baseline_tumor_size_mm)) as total_missing
    from subject_level_analysis

    union all

    select 
        "time_to_event_analysis" as dataset length=30,
        sum(missing(subject_id)) +
        sum(missing(endpoint)) +
        sum(missing(time_months)) +
        sum(missing(censor_flag)) as total_missing
    from time_to_event_analysis;
quit;


/*--------------------------------------------------------
  9. Unique subject counts
--------------------------------------------------------*/
proc sql;
    title "Unique subject counts";

    select "demographics" as dataset length=30,
           count(distinct subject_id) as unique_subjects
    from demographics

    union all

    select "subject_level_analysis" as dataset length=30,
           count(distinct subject_id) as unique_subjects
    from subject_level_analysis

    union all

    select "tumor_measurements" as dataset length=30,
           count(distinct subject_id) as unique_subjects
    from tumor

    union all

    select "time_to_event_analysis" as dataset length=30,
           count(distinct subject_id) as unique_subjects
    from time_to_event_analysis;
quit;


%put Data check completed;