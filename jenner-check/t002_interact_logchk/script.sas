/* ------------------------------------------------------------------
   Bundle: interact_logchk (log-scan core)
   Source: SASLogChecker/06_macros/interact_logchk.sas  (PharmaForest/saslogchecker)
   Author: Yutaka Morioka  (MIT)

   %interact_logchk reads the interactive log window and flags ERROR,
   WARNING, and a curated set of noteworthy NOTE/INFO messages, matching
   both plain-text and Shift-JIS (hex) forms so it works in mixed-encoding
   sessions. This bundle exercises that classification core verbatim: the
   ERROR/WARNING/NOTE/INFO categorisation via SUBSTR, the PUT(_record,$hex.)
   rendering, and the INDEX() keyword matching on the author's curated list.

   The macro's interactive plumbing (the `dm` window/print/viewtable
   commands, which only run inside the SAS 9.4 GUI) is not part of this
   headless run; a representative log is materialised inline and read in
   its place. The classification logic below is copied unchanged.
   ------------------------------------------------------------------ */

/* --- representative log (stands in for the interactive log window) - */
data _null_;
  file "log.txt";
  put "ERROR: File WORK.X.DATA does not exist.";
  put "ERROR: Libref NOLIB is not assigned.";
  put "WARNING: Apparent symbolic reference NAME not resolved.";
  put "NOTE: Missing values were generated as a result of performing an operation on missing values.";
  put "NOTE: Variable c is uninitialized.";
  put "NOTE: Division by zero detected at (line 6 column 13).";
  put "NOTE: Character values have been converted to numeric values at (line 3 column 5).";
  put "NOTE: The data set WORK.A has 1 observations and 1 variables.";
  put "NOTE: MERGE statement has more than one data set with repeats of BY values.";
  put "INFO: The variable y on data set WORK.X will be overwritten by data set WORK.Y.";
run;

filename tempf "log.txt";

/* --- classification core: verbatim from %interact_logchk ---------- */
data __log;
length cate $10. record $400. hex_record  $2000. target $400.  FL $1. ;
	infile tempf truncover end=eof;
	input record 1-400 ;
  call missing(FL);
	_record = strip(record);
  _record = compress(_record,'0A'X || '0D'X|| '0C'X);
	if substr(_record , 1 , 5 ) = 'ERROR'   then cate ='ERROR';
	if substr(_record , 1 , 7 ) = 'WARNING' then cate ='WARNING';
	if substr(_record , 1 , 4 ) = 'NOTE'   then cate ='NOTE';
	if substr(_record , 1 , 5 ) = 'INFO:' 	then cate ='INFO';
  hex_record=put(_record,$hex.);
  if CATE in ('ERROR','WARNING') then FL="Y";

  if index(record,"_ERROR_=1") then do;FL="Y"; target="_ERROR_=1";end;
  if CATE in ("NOTE","INFO") then do;
      /*Missing values were generated as a result of performing an operation on missing values.*/
      if index(record,"Missing values") then do;FL="Y"; target="Missing values";end;
      /*Variable x is uninitialized.*/
      if index(record,"is uninitialized") then do;FL="Y"; target="is uninitialized";end;
      /*Division by zero detected ...*/
      if index(record,"Division by zero") then do;FL="Y"; target="Division by zero";end;
      /*Mathematical operations could not be performed ...*/
      if index(record,"Mathematical operations could not") then do;FL="Y"; target="Mathematical operations could not";end;
      /*Invalid ... to function ...*/
      if index(record,"Invalid") then do;FL="Y"; target="Invalid";end;
      /*Character values have been converted to numeric values ...*/
      if index(record,"Character values have been converted to") then do;FL="Y"; target="Character values have been converted to";end;
      /*Numeric values have been converted to character values ...*/
      if index(record,"Numeric values have been converted to") then do;FL="Y"; target="Numeric values have been converted to";end;
      /*Unreferenced label defined: y.*/
      if index(record,"Unreferenced label") then do;FL="Y"; target="Unreferenced label";end;
      /*WHERE clause has been replaced.*/
      if index(record,"WHERE clause has been replaced") then do;FL="Y"; target="WHERE clause has been replaced";end;
      /*DATA STEP stopped due to looping.*/
      if index(record,"stopped due to looping") then do;FL="Y"; target="stopped due to looping";end;
      /*INFO: ... will be overwritten by data set ...*/
      if index(record,"will be overwritten by data set") then do;FL="Y"; target="will be overwritten by data set";end;
      /*MERGE statement has more than one data set with repeats of BY values.*/
      if index(record,"repeats of BY values") then do;FL="Y"; target="repeats of BY values";end;
      /* Library X does not exist.*/
      if index(record,"does not exist") then do;FL="Y"; target="does not exist";end;
      /*... was not found ...*/
      if index(record,"was not found") then do;FL="Y"; target="was not found";end;
  end;
  line=_N_;
  if FL="Y";
  label cate='Category' record='Text' line='Line' Target="Target Keyword";
  drop _record hex_record FL;
run;

proc sql noprint;
	select count(*) into: __obs   trimmed from __log ;
	select count(*) into: __obs_e trimmed from __log where cate="ERROR";
	select count(*) into: __obs_w trimmed from __log where cate="WARNING";
	select count(*) into: __obs_n trimmed from __log where cate="NOTE";
	select count(*) into: __obs_i trimmed from __log where cate="INFO";
quit;

filename tempf clear;

%put NOTE: interact_logchk summary -- ERROR:&__obs_e  WARNING:&__obs_w  NOTE:&__obs_n  INFO:&__obs_i (total &__obs).;

proc print data=__log noobs label;
run;
