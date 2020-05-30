{$IFDEF Interface}

function GetTL2Item(const aid:TL2ID; out amods:string):string; overload;
function GetTL2Item(const aid:TL2ID                  ):string; overload;

function GetTL2Prop(const aid:TL2ID; out amods:string):string; overload;
function GetTL2Prop(const aid:TL2ID                  ):string; overload;

{$ELSE}

function GetTL2Item(const aid:TL2ID; out amods:string):string;
var
  lname:string;
begin
  result:=GetById(aid,'items','',amods,lname);
end;

function GetTL2Item(const aid:TL2ID):string;
var
  lmods:string;
begin
  result:=GetTL2Item(aid,lmods);
end;

function GetTL2Prop(const aid:TL2ID; out amods:string):string;
var
  lname:string;
begin
  result:=GetById(aid,'props','',amods,lname);
end;

function GetTL2Prop(const aid:TL2ID):string;
var
  lmods:string;
begin
  result:=GetTL2Prop(aid,lmods);
end;

{$ENDIF}
