unit rgglobal;

interface

uses
  Classes,
  TL2DatNode;

//--- Constants

const
  verTL1 = 1;
  verTL2 = 2;
  verHob = 3;
  verRG  = 4;

//--- Variables

var
  hashlog:TStringList;

var
  curfname:string;

//--- Functions

function CompareWide(s1,s2:PWideChar):boolean;

//----- Implementation

implementation


function CompareWide(s1,s2:PWideChar):boolean;
begin
  if s1=s2 then exit(true);
  if ((s1=nil) and (s2^=#0)) or
     ((s2=nil) and (s1^=#0)) then exit(true);
  repeat
    if s1^<>s2^ then exit(false);
    if s1^=#0 then exit(true);
    inc(s1);
    inc(s2);
  until false;
end;


initialization

finalization

end.
