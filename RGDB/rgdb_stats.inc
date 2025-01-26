{$IFDEF Interface}

function RGDBGetTL2Stat(const aid:TRGID; out amods:string):string; overload;
function RGDBGetTL2Stat(const aid:TRGID                  ):string; overload;

const
  DefStatStat  = 0;
  DefStatSkill = 1;

  DefaultStats: array [0..1] of record
    id:TRGID;
    name:string;
  end = (
    (id:-7998006427425498932; name:'current_player_stat_pts' ),
    (id:8015721566365339376 ; name:'current_player_skill_pts')
  );

function RGDBGetStatIdx(const alist:TL2IdValList; const aid  :TRGID ):integer; overload;
function RGDBGetStatIdx(const alist:TL2IdValList; const aname:string):integer; overload;

{$ELSE}


function RGDBGetTL2Stat(const aid:TRGID; out amods:string):string;
var
  lname:string;
begin
  result:=GetById(aid,'stats','',amods,lname);
end;

function RGDBGetTL2Stat(const aid:TRGID):string;
var
  lmods:string;
begin
  result:=RGDBGetTL2Stat(aid,lmods);
end;

function RGDBGetStatIdx(const alist:TL2IdValList; const aid:TRGID):integer;
var
  i:integer;
begin
  result:=-1;
  if Length(alist)=0 then
    exit;

  if aid<>RGIdEmpty then
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

function RGDBGetStatIdx(const alist:TL2IdValList; const aname:string):integer;
var
  lid:TRGID;
  ls:string;
  i:integer;
begin
  result:=-1;
  if Length(alist)=0 then
    exit;

  Val(aname,lid);
  if lid=0 then
  begin
    lid:=RGIdEmpty;
    ls:=LowerCase(aname);
    for i:=0 to High(DefaultStats) do
    begin
      if ls=DefaultStats[i].name then
      begin
        lid:=DefaultStats[i].id;
        break;
      end;
    end;

    if lid=RGIdEmpty then
      GetByName(ls,'stats',lid);
  end;

  result:=RGDBGetStatIdx(alist, lid);
end;

{$ENDIF}
