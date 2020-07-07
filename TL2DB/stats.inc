{$IFDEF Interface}

function GetTL2Stat(const aid:TL2ID; out amods:string):string; overload;
function GetTL2Stat(const aid:TL2ID                  ):string; overload;

const
  DefStatStat  = 0;
  DefStatSkill = 1;

  DefaultStats: array [0..1] of record
    id:TL2ID;
    name:string;
  end = (
    (id:-7998006427425498932; name:'current_player_stat_pts' ),
    (id:8015721566365339376 ; name:'current_player_skill_pts')
  );

function GetStatIdx(const alist:TL2IdValList; const aid  :TL2ID ):integer; overload;
function GetStatIdx(const alist:TL2IdValList; const aname:string):integer; overload;

{$ELSE}


function GetTL2Stat(const aid:TL2ID; out amods:string):string;
var
  lname:string;
begin
  result:=GetById(aid,'stats','',amods,lname);
end;

function GetTL2Stat(const aid:TL2ID):string;
var
  lmods:string;
begin
  result:=GetTL2Stat(aid,lmods);
end;

function GetStatIdx(const alist:TL2IdValList; const aid:TL2ID):integer;
var
  i:integer;
begin
  result:=-1;
  if Length(alist)=0 then
    exit;

  if aid<>TL2IdEmpty then
  begin
    for i:=0 to High(alist) do
    begin
      if alist[i].id=aid then
      begin
        result:=i;
        exit;
      end;
    end;
  end;
end;

function GetStatIdx(const alist:TL2IdValList; const aname:string):integer;
var
  lid:TL2ID;
  ls:string;
  i:integer;
begin
  result:=-1;
  if Length(alist)=0 then
    exit;

  Val(aname,lid);
  if lid=0 then
  begin
    lid:=TL2IdEmpty;
    ls:=LowerCase(aname);
    for i:=0 to High(DefaultStats) do
    begin
      if ls=DefaultStats[i].name then
      begin
        lid:=DefaultStats[i].id;
        break;
      end;
    end;

    if lid=TL2IdEmpty then
      GetByName(ls,'stats',lid);
  end;

  result:=GetStatIdx(alist, lid);
end;

{$ENDIF}
