{$IFDEF Interface}

function RGDBGetUnitTheme(const aid:TRGID):string;

function RGDBGetQuest(const aid:TRGID; out amods:string; out aname:string):string; overload;
function RGDBGetQuest(const aid:TRGID; out amods:string):string; overload;
function RGDBGetQuest(const aid:TRGID                  ):string; overload;

function RGDBGetMob    (const aid:TRGID; out amods:string):string; overload;
function RGDBGetMob    (const aid:TRGID                  ):string; overload;
function RGDBGetMobMods(const aid:TRGID):string;

type
  TWardrobeData = array of record
    id   :integer;
    _type:string; // integer;
    name :string;
  end;

function RGDBGetWardrobe(var award:TWardrobeData):integer;

{$ELSE}

//----- Unit theme -----

function RGDBGetUnitTheme(const aid:TRGID):string;
begin
  result:=RGDBGetTextValue(aid,'dicuthemes','name');
  if result='' then
    result:='0x'+HexStr(aid,16)
end;

//----- Quests -----

function RGDBGetQuest(const aid:TRGID; out amods:string; out aname:string):string;
begin
  result:=GetById(aid,'quests','',amods,aname);
end;

function RGDBGetQuest(const aid:TRGID; out amods:string):string;
var
  lname:string;
begin
  result:=RGDBGetQuest(aid,amods,lname);
end;

function RGDBGetQuest(const aid:TRGID):string;
var
  lmods:string;
begin
  result:=RGDBGetQuest(aid,lmods);
end;

//----- Mob info -----

function RGDBGetMob(const aid:TRGID; out amods:string):string;
var
  lname:string;
begin
                   result:=GetById(aid,'mobs'      ,'',amods,lname);
  if amods='' then result:=GetById(aid,dbPetTable  ,'',amods,lname);
  if amods='' then result:=GetById(aid,dbClassTable,'',amods,lname);
end;

function RGDBGetMob(const aid:TRGID):string;
var
  lmods:string;
begin
  result:=RGDBGetMob(aid,lmods);
end;

function RGDBGetMobMods(const aid:TRGID):string;
begin
  result:=RGDBGetTextValue(aid,'mobs','modid');
end;

//----- Wardrobe -----

function RGDBGetWardrobe(var award:TWardrobeData):integer;
var
  lSQL:string;
  vm:pointer;
  i:integer;
begin
  if db<>nil then
  begin
    result:=ReturnInt(db,'SELECT count(*) FROM wardrobe');

    SetLength(award,result);

    if result>0 then
    begin
      lSQL:='SELECT id, type, name FROM wardrobe';
      if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
      begin
        i:=0;
        while {(i<result) and} (sqlite3_step(vm)=SQLITE_ROW) do
        begin
          award[i].id   :=sqlite3_column_int (vm,0);
          award[i]._type:=sqlite3_column_text(vm,1);
          award[i].name :=sqlite3_column_text(vm,2);
          inc(i);
        end;
        sqlite3_finalize(vm);
      end;
    end;
  end
  else
    result:=0;
end;

{$ENDIF}