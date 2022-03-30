{%REGION Props}
{
  Check if mod attached for data id already
  return ModMask if no data id yet
  return existing mod   line if     found and DoUpdate
  return new      mod   line if not found and DoUpdate
  return          empty line if           no  DoUpdate
}
function CheckForMod(ams:pointer; const atable,anid,amodid:string):string;
var
  lSQL,lmodid:string;
  vm:pointer;
  lmodfound:boolean;
begin
  // let mean: ID not found
  result:=PModScanner(ams)^.FModMask;

  lSQL:='SELECT modid FROM '+atable+' WHERE id='+anid;
  if sqlite3_prepare_v2(PModScanner(ams)^.db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
  begin
    if sqlite3_step(vm)=SQLITE_ROW then
    begin
      lmodid:=sqlite3_column_text(vm,0);
      // have attached mods (must be always if 'anid' is presents)
      if lmodid<>'' then
      begin
        lmodfound:=(lmodid=' 0 ') or (Pos(result,lmodid)>0);
        if PModScanner(ams)^.FDoUpdate then
        begin
          // ID found, mod found, update all - return existing mod line
          if lmodfound then result:=lmodid
          // ID found, mod not found, update all - return new mod line
          else result:=lmodid+amodid+' ';
        end
        else
        begin
          // ID found, mod not found, not update all - modify mod
          if not lmodfound then
          begin
            sqlite3_finalize(vm);
            lmodid:=lmodid+amodid+' ';
            lSQL:='UPDATE '+atable+' SET modid='''+lmodid+''' WHERE id='+anid;
            sqlite3_prepare_v2(PModScanner(ams)^.db,PChar(lSQL),-1,@vm,nil);
            sqlite3_step(vm);
          end;
          // ID found, mod found, not update all - skip all
          result:='';
        end;
      end;
    end;
    sqlite3_finalize(vm);
  end;
  if result<>'' then result:=''''+result+'''';
end;


function AddTheMod(adb:PSQLite3; const amodinfo:TTL2ModInfo):boolean;
var
  lmodid,lSQL:string;
  vm:pointer;
  lver:integer;
begin
  Str(amodinfo.modid,lmodid);
  lSQL:='SELECT version FROM Mods WHERE id='+lmodid;
  lver:=0;
  if sqlite3_prepare_v2(adb,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
  begin
    if sqlite3_step(vm)=SQLITE_ROW then
      lver:=sqlite3_column_int(vm,0);
    sqlite3_finalize(vm);
  end;

  if lver<>0 then
  begin
    if amodinfo.modver<=lver then exit(true);
    lSQL:='UPDATE Mods SET version='+IntToStr(amodinfo.modver)+' WHERE id='+lmodid;
  end
  else
  begin
    lSQL:='INSERT INTO mods (id,title,version,gamever,author,descr,website,download) '+
          ' VALUES ('+lmodid              +', '+FixedText(amodinfo.title  )+
          ', '+IntToStr (amodinfo.modver )+', '+IntToStr (amodinfo.gamever)+
          ', '+FixedText(amodinfo.author )+', '+FixedText(amodinfo.descr)+
          ', '+FixedText(amodinfo.website)+', '+FixedText(amodinfo.download)+')';
  end;
  result:=ExecuteDirect(adb,lSQL);
end;

function CreateModTable(adb:PSQLite3):boolean;
begin
  if not IsTableExists(adb,'mods') then
  begin
    result:=ExecuteDirect(adb,
      'CREATE TABLE mods ('+
      '    id       INTEGER     PRIMARY KEY,'+
      '    title    TEXT,'+
      '    version  INTEGER (2),'+
      '    gamever  INTEGER (8),'+
      '    author   TEXT,'+
      '    descr    TEXT,'+
      '    website  TEXT,'+
      '    download TEXT,'+
      '    tags     TEXT );');

    result:=ExecuteDirect(adb,
      'INSERT INTO mods (id,title,version,gamever,author,descr,website,download) '+
            ' VALUES (0, ''Torchlight 2'', 0, 281582351482885, ''Runic Games'''+
            ', ''Torchlight 2 game (without mods)'', NULL, NULL);');
{!!!!!!!!!!!!!!
    PModScanner(ams)^.FModId  :='0';
    PModScanner(ams)^.FModMask:=' 0 ';
}
  end;
end;

{%ENDREGION}
