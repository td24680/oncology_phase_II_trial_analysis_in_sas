%let proj=/home/u64449610/oncology_phase_II_trial_analysis;

libname raw "&proj/data/raw";
libname ana "&proj/data/analysis";

%let out_tables=&proj/outputs/tables;
%let out_figures=&proj/outputs/figures;