/* ------------------------------------------------------------------
   Bundle: logchk2directory (core scan)
   Source: SASLogChecker/06_macros/logchk2directory.sas  (PharmaForest/saslogchecker)
   Author: Yutaka Morioka  (MIT)

   This exercises the substance of %logchk2directory: the keyword
   dictionary, PROC SORT NODUPKEY, the hash-object multidata scan
   (find / find_next) that tests every log line against every term,
   the ERROR/WARNING/NOTE/INFO categorisation, and the KSCAN/KREVERSE
   filename extraction -- all reproduced verbatim from the macro.

   Only the file source is adapted for a portable, self-contained run:
   the macro reads a Windows folder wildcard ("&folder.\*.&extension");
   here a representative SAS log is materialised inline and the fileref
   points at it, so the same scan runs anywhere with no external files.
   The keyword list (including the Shift-JIS hex literals) is copied
   unchanged from the macro.
   ------------------------------------------------------------------ */

/* --- representative log (stands in for a *.log file in the folder) - */
data _null_;
  file "sample.log";
  put "1    data a;";
  put "2      length x 8.;";
  put "3    run;";
  put "NOTE: The data set WORK.A has 1 observations and 1 variables.";
  put "4    data b;";
  put "5      set a;";
  put "6      c = 10 / 0;";
  put "7      keep y;";
  put "8    run;";
  put "NOTE: Division by zero detected at (line 6 column 13).";
  put "NOTE: Missing values were generated as a result of performing an operation on missing values.";
  put "NOTE: Variable y is uninitialized.";
  put "WARNING: The variable y in the DROP, KEEP, or RENAME list has never been referenced.";
  put "9    data c;";
  put "10     set nolib.missing;";
  put "11   run;";
  put "ERROR: Libref NOLIB is not assigned.";
  put "ERROR: File WORK.C.DATA does not exist.";
  put "12   proc print data=c;";
  put "13   run;";
  put "WARNING: The variable name was not found on the input data set.";
  put "INFO: The variable z on data set WORK.C will be overwritten by data set WORK.C.";
run;

/* --- term dictionary: verbatim from %logchk2directory ------------- */
data term;
length term $400.;
key=1;
term="Missing values";output;
term="is uninitialized";output;
term="Division by zero";output;
term="Mathematical operations could not";output;
term="Invalid";output;
term="Character values have been converted to";output;
term="Numeric values have been converted to";output;
term="The meaning of an identifier";output;
term="too small for";output;
term="Unreferenced label";output;
term="WHERE clause has been replaced";output;
term="stopped due to looping";output;
term="will be overwritten by data set";output;
term="repeats of BY values";output;
term="does not exist";output;
term="was not found";output;
term="reached past the end of a line";output;
term="LOSTCARD";output;
term="NOEXEC";output;
term="A CASE expression has no ELSE clause";output;
term="_ERROR_=1";output;
term="have been thinned";output;
term="discarded because neither";output;
term="Processing on disk occurred during summarization.";output;
term="log axis cannot support";output;
term="lines were truncated";output;
term="outside the axis range";output;
term="infinite likelihood i";output;
term="definite";output;
term="8C8791B9926C82F08ADC82F182BE8C768E5A"x;output;
term="8F898AFA89BB82B382EA82C482A282DC82B982F1"x;output;
term="3082C982E682E98F9C8E5A"x;output;
term="89898E5A8EAE82F08C768E5A82C582AB82C882A982C182BD"x;output;
term="88F8909482CD96B38CF8"x;output;
term="96B38CF882C888F89094"x;output;
term="82C995CF8AB782B582DC82B582BD"x;output;
term="88F89770958482C588CD82DC82EA82BD95B68E9A97F182CC"x;output;
term="9094926C82F08376838A8393836782B782E982C982CD8FAC82B382B782AC82E9"x;output;
term="96A28E518FC682CC83898378838B92E88B6082C582B7"x;output;
term="57484552458EAE82F0927582AB8AB782A682DC82B582BD"x;output;
term="838B815B837682AA94AD90B682B582BD82BD82DF"x;output;
term="82C982E682C182C48FE38F9182AB"x;output;
term="4259926C82F08C4A82E895D482B7"x;output;
term="91B68DDD82B582DC82B982F1"x;output;
term="8CA982C282A982E882DC82B982F1"x;output;
term="8CA982C282A982E782C882A2"x;output;
term="96B38CF882C88366815B835E"x;output;
term="8F49925B82C9924282B582BD"x;output;
term="4C4F535443415244"x;output;
term="4E4F4558454383498376835683878393"x;output;
term="434153458EAE82C9454C53458BE5"x;output;
term="5F4552524F525F3D31"x;output;
term="8AD488F8"x;output;
term="96B38E8B"x;output;
term="836683428358834E8F88979D82AA94AD90B682B582DC82B582BD"x;output;
term="838D834F8EB282CD"x;output;
term="90D882E88ECC82C482E782EA82BD8D73"x;output;
term="94CD88CD8A4F"x;output;
term="696E66696E697465"x;output;
term="646566696E697465"x;output;
term="8D7397F182CD90B392E8926C"x;output;
term="95B68E9A82F092B482A682C482A282DC82B7"x;output;
term="95CF909482AA82A082E882DC82B982F1"x;output;
term="8FAC9094935F82AA835683748367"x;output;
term="838D815B836882C582AB82DC82B982F1"x;output;
term="975C96F196BC"x;output;
term="836683748348838B8367"x;output;
run;
data term;
set term;
term=strip(term);
run;
proc sort data=term nodupkey;
by term;
run;

/* --- input source (adapted): the inline log above instead of a
       Windows folder wildcard. The read + scan below are verbatim. */
filename _log_ "sample.log";

data log;
length fname _fname $200. cate $10. record term $400.  hit $500.;
	infile _log_ filename=_fname truncover ;
	input record 1-400 ;
	if 0 then set term;
	if _N_=1 then do;
		declare hash h1(dataset:"term" ,multidata:"Y");
		h1.definekey("key");
		h1.definedata("term");
		h1.definedone();
	end;
	fname=kreverse(kscan(kreverse(_fname),1,"/"));

	_record = strip(record);
	_record = compress(_record,'0A'X || '0D'X|| '0C'X);
	if substr(_record, 1 , 5 ) = 'ERROR'     then cate ='ERROR';
	if substr(_record, 1 , 7 ) = 'WARNING' then cate	='WARNING';
	if substr(_record , 1 , 4 ) = 'NOTE'     then cate ='NOTE';
	if substr(_record, 1 , 5 ) = 'INFO:' 	  then cate ='INFO';
	key=1;
	hit="";
	call missing(hit);
	  rc=h1.find();
	  do while( rc eq 0);
	     if index(strip(_record),strip(term)) then do;
hit=catx(",",hit,term);
end;
	     rc=h1.find_next();
	  end;
	  if cate in ("ERROR","WARNING") then hit=catx(",",cate,hit);
	  if cate in ("ERROR","WARNING") or hit ne "";
label fname="FileName" cate="Category" hit="Hit keyword" _record="Hit recorf";
keep fname cate _record hit  ;
run;

proc sql noprint;
	select count(*) into:logobs
	from log;
quit;
%put NOTE: logchk2directory flagged &logobs suspicious log line(s).;

proc print data=log noobs label;
run;
