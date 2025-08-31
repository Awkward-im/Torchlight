{%REGION Props}
{
  Check if mod attached for data id already
  return ModMask if no data id yet
  return existing mod   line if     found and DoUpdate
  return new      mod   line if not found and DoUpdate
  return          empty line if           no  DoUpdate
}

function CheckForMod(ams:pointer; const atable,awhere:string):string;
var
  lSQL,lmodid:string;
  vm:pointer;
  lmodfound:boolean;
begin
  // let mean: ID not found
  result:=PModScanner(ams)^.FModMask;

  lSQL:='SELECT modid FROM '+atable+' WHERE '+awhere;
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
          else result:=lmodid+PModScanner(ams)^.FModId+' ';
        end
        else
        begin
          // ID found, mod not found, not update all - modify mod
          if not lmodfound then
          begin
            sqlite3_finalize(vm);
            lmodid:=lmodid+PModScanner(ams)^.FModId+' ';
            lSQL:='UPDATE '+atable+' SET modid='''+lmodid+''' WHERE '+awhere;
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

function CheckNameForMod(ams:pointer; const atable,aname:string):string;
begin
  result:=CheckForMod(ams,atable,'name='''+aname+'''');
end;

function CheckNamePlusForMod(ams:pointer; const atable,aname,aplus:string):string;
begin
  result:=CheckForMod(ams,atable,'(name='''+aname+''') AND ('+aplus+')');
end;

function CheckIdForMod(ams:pointer; const atable,anid:string):string;
begin
  result:=CheckForMod(ams,atable,'id='+anid);
end;


function AddTheMod(adb:PSQLite3; const amodinfo:TTL2ModInfo):boolean;
var
  lwhere,lmodid,lSQL,ltitle:string;
  lver:integer;
begin
  ltitle:=amodinfo.title;
  if (amodinfo.modid=0) or (amodinfo.modid=-1) then
  begin
    lmodid:='-1';
    lwhere:='title='+FixedText(ltitle);
//    lver:=ReturnInt(adb,'SELECT version FROM Mods WHERE title=?1',amodinfo.title);
  end
  else
  begin
    Str(amodinfo.modid,lmodid);
    lwhere:='id='+lmodid;
//    lver:=ReturnInt(adb,'SELECT version FROM Mods WHERE id='+lmodid);
  end;
  lSQL:='SELECT version FROM Mods WHERE '+lwhere;
  lver:=ReturnInt(adb,lSQL);

  if lver>0 then
  begin
    if amodinfo.modver<=lver then exit(true);
    ExecuteDirect(adb,
      'UPDATE Mods SET version='+IntToStr(amodinfo.modver)+' WHERE '+lwhere);
  end
  else
  begin
    ExecuteDirect(adb,
      'INSERT INTO mods (id,title,version,gamever,author,descr,website,download) '+
          ' VALUES ('+lmodid +', ?1, '+IntToStr(amodinfo.modver)+', '+
          IntToStr(amodinfo.gamever)+', ?2, ?3, ?4, ?5)',
          [amodinfo.title,amodinfo.author,amodinfo.descr,amodinfo.website,amodinfo.download]);
  end;
end;

function CreateModTable(adb:PSQLite3; aver:integer):boolean;
begin
  if not IsTableExists(adb,'mods') then
  begin
    result:=ExecuteDirect(adb,
      'CREATE TABLE mods ('+
      '    id       INTEGER,'+
      '    title    TEXT,'+
      '    version  INTEGER (2),'+
      '    gamever  INTEGER (8),'+
      '    author   TEXT,'+
      '    descr    TEXT,'+
      '    website  TEXT,'+
      '    download TEXT,'+
      '    tags     TEXT );');

    if ABS(aver)=verTL1 then
      result:=ExecuteDirect(adb,
        'INSERT INTO mods (id,title,version,gamever,author,descr,website,download) '+
              ' VALUES (0, ''Torchlight'', 1, 0x0001000F00000000, ''Runic Games'''+
              ', ''Torchlight game (without mods)'', NULL, NULL);');

    if ABS(aver)=verTL2 then
      result:=ExecuteDirect(adb,
        'INSERT INTO mods (id,title,version,gamever,author,descr,website,download) '+
              ' VALUES (0, ''Torchlight 2'', 2, 0x0001001900090005, ''Runic Games'''+
              ', ''Torchlight 2 game (without mods)'', NULL, NULL);');

{!!!!!!!!!!!!!!
    PModScanner(ams)^.FModId  :='0';
    PModScanner(ams)^.FModMask:=' 0 ';
}
  end
  else
    result:=true;
end;

{%ENDREGION}
