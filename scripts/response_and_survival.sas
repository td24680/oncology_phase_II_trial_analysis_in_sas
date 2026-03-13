/*========================================================
  Response summary + Kaplan-Meier survival analysis
========================================================*/

/*--------------------------------------------------------
  1. Read datasets
--------------------------------------------------------*/
proc import datafile="/Users/hongtuoi/python-learning/oncology_phase_II_trial_analysis/data/analysis/subject_level_analysis.csv"
    out=adsl
    dbms=csv
    replace;
    guessingrows=max;
run;

proc import datafile="/Users/hongtuoi/python-learning/oncology_phase_II_trial_analysis/data/analysis/time_to_event_analysis.csv"
    out=tte
    dbms=csv
    replace;
    guessingrows=max;
run;


/*--------------------------------------------------------
  2. Response summary table
--------------------------------------------------------*/

/* Count response by treatment group */
proc freq data=adsl noprint;
    tables treatment_group*best_overall_response / out=response_counts_raw;
run;

/* Total n by treatment group */
proc sql;
    create table total_by_group as
    select treatment_group,
           sum(count) as total_n
    from response_counts_raw
    group by treatment_group;
quit;

/* Merge totals and create summary */
proc sort data=response_counts_raw;
    by treatment_group;
run;

proc sort data=total_by_group;
    by treatment_group;
run;

data response_counts;
    merge response_counts_raw total_by_group;
    by treatment_group;
    length summary $20;
    percent = round(100 * count / total_n, 0.1);
    summary = cats(count, " (", put(percent, 5.1), "%)");
    keep treatment_group best_overall_response summary count total_n;
run;


/* Create empty response table */
data response_table;
    length response $20 DrugA $20 Placebo $20;
    input response $char20.;
    datalines;
CR
PR
SD
PD
ORR (CR + PR)
;
run;


/* Fill CR */
proc sql noprint;
    select summary into :drugA_cr trimmed
    from response_counts
    where treatment_group = "DrugA" and best_overall_response = "CR";

    select summary into :placebo_cr trimmed
    from response_counts
    where treatment_group = "Placebo" and best_overall_response = "CR";
quit;

data response_table;
    set response_table;
    if response = "CR" then do;
        DrugA = "&drugA_cr";
        Placebo = "&placebo_cr";
    end;
run;


/* Fill PR */
proc sql noprint;
    select summary into :drugA_pr trimmed
    from response_counts
    where treatment_group = "DrugA" and best_overall_response = "PR";

    select summary into :placebo_pr trimmed
    from response_counts
    where treatment_group = "Placebo" and best_overall_response = "PR";
quit;

data response_table;
    set response_table;
    if response = "PR" then do;
        DrugA = "&drugA_pr";
        Placebo = "&placebo_pr";
    end;
run;


/* Fill SD */
proc sql noprint;
    select summary into :drugA_sd trimmed
    from response_counts
    where treatment_group = "DrugA" and best_overall_response = "SD";

    select summary into :placebo_sd trimmed
    from response_counts
    where treatment_group = "Placebo" and best_overall_response = "SD";
quit;

data response_table;
    set response_table;
    if response = "SD" then do;
        DrugA = "&drugA_sd";
        Placebo = "&placebo_sd";
    end;
run;


/* Fill PD */
proc sql noprint;
    select summary into :drugA_pd trimmed
    from response_counts
    where treatment_group = "DrugA" and best_overall_response = "PD";

    select summary into :placebo_pd trimmed
    from response_counts
    where treatment_group = "Placebo" and best_overall_response = "PD";
quit;

data response_table;
    set response_table;
    if response = "PD" then do;
        DrugA = "&drugA_pd";
        Placebo = "&placebo_pd";
    end;
run;


/* Calculate ORR = CR + PR */
proc sql;
    create table orr_counts as
    select treatment_group,
           sum(count) as n
    from response_counts
    where best_overall_response in ("CR", "PR")
    group by treatment_group;
quit;

proc sort data=orr_counts;
    by treatment_group;
run;

data orr_counts;
    merge orr_counts total_by_group;
    by treatment_group;
    length summary $20;
    percent = round(100 * n / total_n, 0.1);
    summary = cats(n, " (", put(percent, 5.1), "%)");
run;

/* Fill ORR row */
proc sql noprint;
    select summary into :drugA_orr trimmed
    from orr_counts
    where treatment_group = "DrugA";

    select summary into :placebo_orr trimmed
    from orr_counts
    where treatment_group = "Placebo";
quit;

data response_table;
    set response_table;
    if response = "ORR (CR + PR)" then do;
        DrugA = "&drugA_orr";
        Placebo = "&placebo_orr";
    end;
run;


/* Print response table */
title "Response Summary Table";
proc print data=response_table noobs;
run;

/* Save response table */
proc export data=response_table
    outfile="/Users/hongtuoi/python-learning/oncology_phase_II_trial_analysis/outputs/tables/response_summary_table.csv"
    dbms=csv
    replace;
run;


/*--------------------------------------------------------
  3. Kaplan-Meier analysis - PFS
--------------------------------------------------------*/
data pfs_data;
    set tte;
    where endpoint = "PFS";
    event = 1 - censor_flag;
run;

ods graphics on;

title "Kaplan-Meier Curve for PFS";
proc lifetest data=pfs_data plots=survival(cb=hw test);
    time time_in_days* censor_flag(1);
    strata treatment_group;
run;

ods graphics / reset imagename="kaplan_meier_pfs" imagefmt=png;
ods listing gpath="/Users/hongtuoi/python-learning/oncology_phase_II_trial_analysis/outputs/figures";

title "Kaplan-Meier Curve for PFS";
proc lifetest data=pfs_data plots=survival(cb=hw test);
    time time_in_days*censor_flag(1);
    strata treatment_group;
run;


/*--------------------------------------------------------
  4. Kaplan-Meier analysis - OS
--------------------------------------------------------*/
data os_data;
    set tte;
    where endpoint = "OS";
    event = 1 - censor_flag;
run;

ods graphics / reset imagename="kaplan_meier_os" imagefmt=png;
ods listing gpath="/Users/hongtuoi/python-learning/oncology_phase_II_trial_analysis/outputs/figures";

title "Kaplan-Meier Curve for OS";
proc lifetest data=os_data plots=survival(cb=hw test);
    time time_in_days*censor_flag(1);
    strata treatment_group;
run;

ods graphics off;
title;