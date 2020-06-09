uses
  sysutils,
  TL2ModInfo,
  awksqlite3,
  sqlite3;

var
  db:PSQLite3;

function FixedText(const astr:string):string;
begin
  result:=#39+StringReplace(astr,#39,#39#39,[rfReplaceAll])+#39;
end;

function CompareWide(s1,s2:PWideChar):boolean;
begin
  if s1=s2 then exit(true);
  if ((s1=nil) and (s2^=#0)) or
     ((s2=nil) and (s1^=#0)) then exit(true);
  repeat
    if s1^<>s2^ then exit(false);
    if s1^=#0 then exit(true);
    inc(s1);
    inc(s2);
  until false;
end;

//===================================

procedure AddTheMod(const fname:string);
var
  lSQL:string;
  vm:pointer;
  lmod:TTL2ModInfo;
begin
  if ReadModInfo(PChar(fname),lmod) then
  begin
    lSQL:='INSERT INTO Mods (id,title,version,gamever,author,descr,website,download) '+
          ' VALUES ('+IntToStr(lmod.modid)+', '+FixedText(lmod.title)+', '+IntToStr(lmod.modver)+
          ', '+IntToStr(lmod.gamever)+', '+FixedText(lmod.author)+', '+FixedText(lmod.descr)+
          ', '+FixedText(lmod.website)+', '+FixedText(lmod.download)+')';

    if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
    begin
      sqlite3_step(vm);
      sqlite3_finalize(vm);
    end;
  end;
end;

procedure CycleDir(const adir:String);
var
  sr:TSearchRec;
  lname:AnsiString;
begin
  if FindFirst(adir+'\*.*',faAnyFile and faDirectory,sr)=0 then
  begin
    repeat
      lname:=adir+'\'+sr.Name;
      if (sr.Attr and faDirectory)=faDirectory then
      begin
        if (sr.Name<>'.') and (sr.Name<>'..') then
          CycleDir(lname);
      end
      else
      begin
        if UpCase(ExtractFileExt(lname))='.MOD' then
        begin
AddTheMod(lname);
        end;
      end;
    until FindNext(sr)<>0;
    FindClose(sr);
  end;
end;

begin
  sqlite3_open(':memory:',@db);
  if CopyFromFile(db,'tl2db2.db')<>SQLITE_OK then
  begin
    writeln('can''t open');
    exit;
  end;

  CycleDir('.');

  CopyToFile(db,'tl2db2.db');
  sqlite3_close(db);
end.
