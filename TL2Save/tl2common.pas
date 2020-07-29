unit TL2Common;

interface

procedure DbgLn(const atxt:string);
function Check(aval:qword; const albl:string; aright:qword):qword;
function Check(aval:single; const albl:string; aright:single):single;
function SecToTime ( sec:cardinal):string;
function MSecToTime(msec:cardinal):string;


implementation

procedure DbgLn(const atxt:string);
begin
  if IsConsole then
    writeln(atxt);
end;

function Check(aval:qword; const albl:string; aright:qword):qword;
begin
  result:=aval;

  if aval<>aright then
    if IsConsole then
      writeln('  Unknown value ',aval,' at label ',albl,' must be [',aright,']');
end;

function Check(aval:single; const albl:string; aright:single):single;
begin
  result:=aval;

  if aval<>aright then
    if IsConsole then
      writeln(' Unknown value ',aval:0:4,' at label ',albl,' must be [',aright:0:4,']');
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
  Str(hours:2,shour); if shour[1]=' ' then shour[1]:='0';
  Str(mins :2,smin ); if smin [1]=' ' then smin [1]:='0';
  Str(secs :2,ssec ); if ssec [1]=' ' then ssec [1]:='0';
  result:=sday+' '+shour+':'+smin+':'+ssec;
end;

function MSecToTime(msec:cardinal):string;
begin
  result:=SecToTime(msec div 1000);
end;

end.
