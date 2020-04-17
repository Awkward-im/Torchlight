unit TL2Common;

interface

uses
   classes
  ,tl2types
  ;

type
  TTL2ParseType = (ptLite, ptStandard, ptDeep, ptDeepest);

type
  gc_BaseClass = (Berserker, Embermage, Engineer, Outlander);

procedure SaveDump(const aname:string; aptr:pByte; asize:cardinal);
function Check(aval:qword; const albl:string; aright:qword):qword;
function SecToTime ( sec:cardinal):string;
function MSecToTime(msec:cardinal):string;

function GetDifficulty(acode:integer):string;

implementation

uses
   tl2strings;

procedure SaveDump(const aname:string; aptr:pByte; asize:cardinal);
var
  f:file of byte;
begin
  AssignFile(f,aname);
  Rewrite(f);
  BlockWrite(f,aptr^,asize);
  CloseFile(f);
end;

function Check(aval:qword; const albl:string; aright:qword):qword;
begin
  result:=aval;

  if aval<>aright then
    if IsConsole then
      writeln('!!Unknown value ',aval,' at label ',albl,' must be [',aright,']');
end;

function SecToTime(sec:cardinal):string;
var
  days,hours,mins,secs:integer;
  sday,shour,smin,ssec:shortstring;
begin
  days :=sec div 86400;
  sec  :=sec-days*86400;
  hours:=sec div 3600;
  sec  :=sec-hours*3600;
  mins :=sec div 60;
  sec  :=sec-mins*60;
  secs :=sec;

  result:='';

  if days>0 then Str(days,sday) else sday:='';
  Str(hours,shour);
  Str(mins,smin);
  Str(secs,ssec);
  result:=sday+' '+shour+':'+smin+':'+ssec;
end;

function MSecToTime(msec:cardinal):string;
begin
  result:=SecToTime(msec div 1000);
end;

function GetDifficulty(acode:integer):string;
begin
  case acode of
    0: result:=rsCasual;
    1: result:=rsNormal;
    2: result:=rsVeteran;
    3: result:=rsExpert;
  else
    result:='';
  end;
end;

end.
