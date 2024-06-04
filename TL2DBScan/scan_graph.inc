{%REGION Graph}
function AddGraphToBase(ams:pointer; const aname,agraph:string):boolean;
var
  vm:pointer;
  lmodid,lSQL:string;
  lid:integer;
begin
  result:=false;

  lid:=-1;
  lSQL:='SELECT id, modid FROM graph WHERE (name='''+aname+''') AND (value='''+agraph+''')';
  if sqlite3_prepare_v2(PModScanner(ams)^.db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
  begin
    if sqlite3_step(vm)=SQLITE_ROW then
    begin
      lid   :=sqlite3_column_int (vm,0);
      lmodid:=sqlite3_column_text(vm,1);
    end;
    sqlite3_finalize(vm);
  end;
  // graph found
  if lid>=0 then
  begin
    if Pos(PModScanner(ams)^.FModMask,lmodid)<0 then
    begin
      lSQL:='UPDATE graph SET modid='''+
          lmodid+PModScanner(ams)^.FModId+' '' WHERE id='+IntToStr(lid);

      result:=ExecuteDirect(PModScanner(ams)^.db,lSQL);
    end
    else
      result:=true;
    exit;
  end
  else
  begin
    lSQL:='REPLACE INTO graph (name, value, modid) VALUES ('''+
        aname+''', '''+agraph+''', '' '+PModScanner(ams)^.FModId+' '')';

    result:=ExecuteDirect(PModScanner(ams)^.db,lSQL);
  end;
end;

function AddGraphNode(ams:pointer; anode:pointer; const aname:string; amul:integer):integer;
var
  lnode:pointer;
  ls,lls:string;
  i:integer;
begin
  result:=0;

  ls:='';
  for i:=0 to GetChildCount(anode)-1 do
  begin
    lnode:=GetChild(anode,i);
    if GetNodeType(lnode)=rgGroup then
    begin
      Str(Trunc(AsFloat(GetChild(lnode,1))*amul), lls);
//      Str(AsFloat(GetChild(lnode,1)):0:4,lls);
      ls:=ls+lls+',';
    end;
  end;
  if Length(ls)>0 then
  begin
    SetLength(ls,Length(ls)-1);
    if AddGraphToBase(ams,aname,ls) then
      result:=1;
  end;
end;

function ScanGraph(ams:pointer; const aname:string; amul:integer):integer;
var
  p:pointer;
begin
  result:=0;

  RGLog.Reserve('Scan graph '+aname);

  LoadFile(ams,'MEDIA/GRAPHS/STATS/'+aname+'.DAT',p);
  if p<>nil then
  begin
    if AddGraphNode(ams,p,aname,amul)>0 then
      result:=1
    else
    begin
      if PModScanner(ams)^.FLogLevel>1 then RGLog.Add('can''t update '+aname);
      result:=0;
    end;
    DeleteNode(p);
  end;
  RGLog.Reserve('');
end;

procedure LoadDefaultGraphs(ams:pointer);
begin
  ScanGraph(ams,'EXPERIENCEGATE'             ,1);
  ScanGraph(ams,'FAMEGATE'                   ,1);
  ScanGraph(ams,'MANA_PLAYER_BONUS_FOCUS'    ,1);
  ScanGraph(ams,'HP_PLAYER_BONUS_VITALITY'   ,1);
  ScanGraph(ams,'SKILL_POINTS_PER_FAME_LEVEL',1);
  ScanGraph(ams,'SKILL_POINTS_PER_LEVEL'     ,1);
  ScanGraph(ams,'STAT_POINTS_PER_LEVEL'      ,1);
  ScanGraph(ams,'HEALTH_PLAYER_GENERIC'      ,10);
  ScanGraph(ams,'MANA_PLAYER_GENERIC'        ,10);
  ScanGraph(ams,'HEALTH_MINION_BYLEVEL'      ,1);
  ScanGraph(ams,'DAMAGE_MINION_BYLEVEL'      ,1);
  ScanGraph(ams,'ARMOR_MINION_BYLEVEL'       ,1);

  ScanGraph(ams,'SKILLTIER1'        ,1);
  ScanGraph(ams,'SKILLTIER1_PASSIVE',1);
  ScanGraph(ams,'SKILLTIER2'        ,1);
  ScanGraph(ams,'SKILLTIER2_PASSIVE',1);
  ScanGraph(ams,'SKILLTIER3'        ,1);
  ScanGraph(ams,'SKILLTIER3_PASSIVE',1);
  ScanGraph(ams,'SKILLTIER4'        ,1);
  ScanGraph(ams,'SKILLTIER4_PASSIVE',1);
  ScanGraph(ams,'SKILLTIER5'        ,1);
  ScanGraph(ams,'SKILLTIER5_PASSIVE',1);
  ScanGraph(ams,'SKILLTIER6'        ,1);
  ScanGraph(ams,'SKILLTIER6_PASSIVE',1);
  ScanGraph(ams,'SKILLTIER7'        ,1);
  ScanGraph(ams,'SKILLTIER7_PASSIVE',1);
end;

function CreateGraphTable(adb:PSQLite3):boolean;
begin
  if not IsTableExists(adb,'graph') then
  begin
    result:=ExecuteDirect(adb,
      'CREATE TABLE graph ('+
      '  id    INTEGER PRIMARY KEY AUTOINCREMENT,'+
      '  name  TEXT,'+
      '  value TEXT,'+
      '  modid TEXT);');

//!!!!!!!!!!!!!    LoadDefaultGraphs(ams);
  end
  else
    result:=true;
end;
{
*SKILL_POINTS_PER_FAME_LEVEL
*SKILL_POINTS_PER_LEVEL
*STAT_POINTS_PER_LEVEL
DISABLE_DAMAGE_BYLEVEL
DISABLE_ARMOR_BYLEVEL
CITIZEN_SKILL_POINTS_PER_FAME_LEVEL
CITIZEN_SKILL_POINTS_PER_LEVEL

+*EXPERIENCEGATE
+*FAMEGATE
*HEALTH_PLAYER_GENERIC
*MANA_PLAYER_GENERIC
+*MANA_PLAYER_BONUS_FOCUS
+*HP_PLAYER_BONUS_VITALITY
*HEALTH_MINION_BYLEVEL
*DAMAGE_MINION_BYLEVEL
*ARMOR_MINION_BYLEVEL
ARMOR_PET_BYLEVEL
DAMAGE_PET_BYLEVEL
HEALTH_PET_BYLEVEL
}

{%ENDREGION Graph}
