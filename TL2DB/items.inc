{$IFDEF Interface}

function GetTL2Item(const id:TL2ID; out amods:string):string; overload;
function GetTL2Item(const id:TL2ID                  ):string; overload;

function GetTL2Prop(const id:TL2ID; out amods:string):string; overload;
function GetTL2Prop(const id:TL2ID                  ):string; overload;

{$ELSE}

function GetTL2Item(const id:TL2ID; out amods:string):string;
var
  lname:string;
begin
  result:=GetModAndTitle(id,'items','',amods,lname);
end;

function GetTL2Item(const id:TL2ID):string;
var
  lmods:string;
begin
  result:=GetTL2Item(id,lmods);
end;

function GetTL2Prop(const id:TL2ID; out amods:string):string;
var
  lname:string;
begin
  result:=GetModAndTitle(id,'props','',amods,lname);
end;

function GetTL2Prop(const id:TL2ID):string;
var
  lmods:string;
begin
  result:=GetTL2Prop(id,lmods);
end;

{$ENDIF}
