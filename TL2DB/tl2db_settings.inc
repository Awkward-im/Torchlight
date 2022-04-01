{$IFDEF Interface}

const
  DefStatPerLvl     = 5;
  DefSkillPerLvl    = 1;
  DefSkillPerFame   = 1;
  DefaultMPperFocus = 5;
  DefaultHPperVit   = 36;
  DefaultHPperLevel = 400;
  DefaultMPperLevel = 10;
  DefaultHPbase     = 2000;
  DefaultMPbase     = 475;

  DefaultExpGate: array of integer = (
    3000    ,8000    ,16000   ,26000   ,39000   ,54000   ,73000   ,94000   ,117000  ,144000,
    173000  ,205000  ,240000  ,278000  ,319000  ,363000  ,410000  ,460000  ,513000  ,569000,
    628000  ,690000  ,755000  ,824000  ,896000  ,971000  ,1049000 ,1131000 ,1216000 ,1305000,
    1397000 ,1492000 ,1591000 ,1693000 ,1799000 ,1909000 ,2022000 ,2138000 ,2259000 ,2383000,
    2510000 ,2642000 ,2777000 ,2916000 ,3059000 ,3206000 ,3356000 ,3511000 ,3669000 ,3832000,
    4038000 ,4252000 ,4474000 ,4703000 ,4940000 ,5186000 ,5439000 ,5701000 ,5972000 ,6251000,
    6539000 ,6836000 ,7142000 ,7458000 ,7783000 ,8118000 ,8463000 ,8818000 ,9183000 ,9558000,
    9944000 ,10340000,10748000,11167000,11597000,12038000,12491000,12956000,13432000,13921000,
    14423000,14936000,15463000,16002000,16555000,17121000,17700000,18293000,18900000,19522000,
    20157000,20807000,21471000,22151000,22845000,23555000,24280000,25021000,25778000,26551000
  );
  DefaultFameGate: array of integer = (
    2000  ,5000  ,9000  ,14000 ,21000 ,30000 ,48000 ,62000 ,78000 ,96000 ,115000,
    137000,160000,186000,213000,242000,273000,307000,342000,379000,419000,460000,
    504000,550000,598000,648000,700000,755000,811000,870000,932000,995000,10000000
  );

{$IF NOT DEFINED(TIntegerDynArray)}
type
  TIntegerDynArray = array of Integer;
{$ENDIF}

function GetGraph     (const aname:string):string;
function GetGraphArray(const aname:string):TIntegerDynArray;

//----- Tiers -----

type
  tTierArray = array of record
    name  :string;
    levels:array of integer;
  end;

procedure LoadTiers(out atier:tTierArray);

{$ELSE}

function GetGraph(const aname:string):string;
var
  lSQL:string;
  vm:pointer;
begin
  result:='';
  if (db<>nil) and (aname<>'') then
  begin
    lSQL:='SELECT value FROM graph WHERE name='''+aname+'''';
    if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        result:=sqlite3_column_text(vm,0);
      end;
      sqlite3_finalize(vm);
    end;
  end;
end;

function GetGraphArray(const aname:string):TIntegerDynArray;
var
  ls:string;
begin
  ls:=GetGraph(aname);
  if ls<>'' then result:=SplitInt(ls,',') else SetLength(result,0);
end;

//----- Tiers -----

//!!!! default game values now only
procedure LoadTiers(out atier:tTierArray);
var
  lSQL,ls:string;
  vm:pointer;
  lcnt:integer;
begin
  if db<>nil then
  begin
    SetLength(atier,14); // default for TL2
    lcnt:=0;
//    lSQL:='SELECT name, value FROM tiers WHERE modid='' 0 ''';
    lSQL:='SELECT name, value FROM graph WHERE (modid='' 0 '') AND (name GLOB ''SKILLTIER*'')';
    if sqlite3_prepare_v2(db, PAnsiChar(lSQL),-1, @vm, nil)=SQLITE_OK then
    begin
      while sqlite3_step(vm)=SQLITE_ROW do
      begin
        if lcnt=High(atier) then SetLength(atier,Length(atier)+1);

        atier[lcnt].name:=sqlite3_column_text(vm,0);

        ls:=sqlite3_column_text(vm,1);
        if ls<>'' then atier[lcnt].levels:=SplitInt(ls,',') else SetLength(atier[lcnt].levels,0);

        inc(lcnt);
      end;
      sqlite3_finalize(vm);
    end;
  end
  else
    SetLength(atier,0);
end;

{$ENDIF}
