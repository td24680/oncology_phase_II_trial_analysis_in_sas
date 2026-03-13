* Response summary + Kaplan-Meier survival analysis;

* Load project setup;
%include "/home/your_username/oncology_phase_II_trial_analysis/scripts/00_setup.sas";

title;
footnote;

* 1. Import datasets;
proc import datafile="&proj/data/analysis/subject_level_analysis.csv"
    out=adsl
    dbms=csv
    replace;
    guessingrows=max;
run;

proc import datafile="&proj/data/analysis/time_to_event_analysis.csv"
    out=tte
    dbms=csv
    replace;
    guessingrows=max;
run;

* 2. Response summary table;

* Count response by treatment group;
proc freq data=adsl noprint;
    tables treatment_group*best_overall_response / out=response_counts_raw;
run;

* Total n by treatment group; 
proc sql;
    create table total_by_group as
    select treatment_group,
           sum(count) as total_n
    from response_counts_raw
    group by treatment_group;
quit;

* Merge totals and create summary; 
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

* Create empty response table; 
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

* Fill CR;
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
        DrugA   = coalescec("&drugA_cr","0 (0.0%)");
        Placebo = coalescec("&placebo_cr","0 (0.0%)");
    end;
run;

* Fill PR;
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
        DrugA   = coalescec("&drugA_pr","0 (0.0%)");
        Placebo = coalescec("&placebo_pr","0 (0.0%)");
    end;
run;

* Fill SD; 
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
        DrugA   = coalescec("&drugA_sd","0 (0.0%)");
        Placebo = coalescec("&placebo_sd","0 (0.0%)");
    end;
run;

* Fill PD; 
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
        DrugA   = coalescec("&drugA_pd","0 (0.0%)");
        Placebo = coalescec("&placebo_pd","0 (0.0%)");
    end;
run;

* Calculate ORR = CR + PR;
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

* Fill ORR row;
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
        DrugA   = coalescec("&drugA_orr","0 (0.0%)");
        Placebo = coalescec("&placebo_orr","0 (0.0%)");
    end;
run;

* Print response table;
title "Response Summary Table";
proc print data=response_table noobs;
run;

* Save response table;
proc export data=response_table
    outfile="&proj/outputs/tables/response_summary_table.csv"
    dbms=csv
    replace;
run;

* 3. Kaplan-Meier analysis - PFS;
data pfs_data;
    set tte;
    where endpoint = "PFS";
run;

ods graphics on;
ods listing gpath="&proj/outputs/figures";
ods graphics / reset imagename="kaplan_meier_pfs" imagefmt=png;

title "Kaplan-Meier Curve for PFS";
proc lifetest data=pfs_data plots=survival(cb=hw test);
    time time_in_days*censor_flag(1);
    strata treatment_group;
run;

* 4. Kaplan-Meier analysis - OS;
data os_data;
    set tte;
    where endpoint = "OS";
run;

ods graphics / reset imagename="kaplan_meier_os" imagefmt=png;

title "Kaplan-Meier Curve for OS";
proc lifetest data=os_data plots=survival(cb=hw test);
    time time_in_days*censor_flag(1);
    strata treatment_group;
run;

ods graphics off;
title;
footnote;

%put NOTE: Response summary and survival analysis completed.;