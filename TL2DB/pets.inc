{$IFDEF Interface}

function GetTL2Pet(const id:TL2ID; out amod:string  ):string; overload;
function GetTL2Pet(const id:TL2ID                   ):string; overload;

{$ELSE}

function GetTL2Pet(const id:TL2ID; out amod:string):string;
var
  lname:string;
begin
  result:=GetModAndTitle(id,'pets','',amod,lname);
end;

function GetTL2Pet(const id:TL2ID):string;
var
  lmod:string;
begin
  result:=GetTL2Pet(id,lmod);
end;

{$ENDIF}
