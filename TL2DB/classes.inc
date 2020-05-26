{$IFDEF Interface}

function GetTL2Class(const id:TL2ID; out amod:string;
                     out aname:string               ):string; overload;
function GetTL2Class(const id:TL2ID; out amod:string):string; overload;
function GetTL2Class(const id:TL2ID                 ):string; overload;

{$ELSE}

function GetTL2Class(const id:TL2ID; out amod:string; out aname:string):string;
begin
  result:=GetModAndTitle(id,'classes','',amod,aname);
end;

function GetTL2Class(const id:TL2ID; out amod:string):string;
var
  lname:string;
begin
  result:=GetTL2Class(id,amod,lname);
end;

function GetTL2Class(const id:TL2ID):string;
var
  lmod:string;
begin
  result:=GetTL2Class(id,lmod);
end;

{$ENDIF}
