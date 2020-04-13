{$I-}
uses
  sqlite3
  ,sysutils
  ,TL2DatNode
  ;

var
  smodid:string;
  db:PSQLite3;

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

procedure AddToBase(const aname:string; aId:int64; const atitle:string; asaves:boolean);
var
  lSQL,sid,ssaves:string;
  vm:pointer;
begin
writeln('stat ',aname);
  if asaves then ssaves:='1' else ssaves:='0';
  Str(aid,sid);

  lSQL:='INSERT INTO stats (id, name, title, saves, modid) VALUES ('+sid+', '''+aname+''',"'+atitle+
    '", '+ssaves+', '+smodid+')';

  if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
  begin
    sqlite3_step(vm);
    sqlite3_finalize(vm);
  end
  else
    writeln('cant update');
end;

procedure AddStat(fname:PChar);
var
  p,pp:PTL2Node;
  s:string;
  name,title:string;
  lid:int64;
  saves:boolean;
  i:integer;
begin
  p:=ParseDatFile(fname,i,s);
  title:='';
  saves:=false;
  for i:=0 to p^.childcount-1 do
  begin
    if CompareWide(p^.children^[i].name,'NAME') then
    begin
      name:=p^.children^[i].asString;
    end;
    if CompareWide(p^.children^[i].name,'UNIQUE_GUID') then
    begin
      lid:=p^.children^[i].asInteger64;
    end;
    if CompareWide(p^.children^[i].name,'SAVES') then
    begin
      saves:=p^.children^[i].asBoolean;
    end;
    if CompareWide(p^.children^[i].name,'DISPLAYNAME') then
    begin
      title:=p^.children^[i].asString;
    end;
  end;
  AddToBase(name,lid,title,saves);
  DeleteNode(p);
end;

procedure CycleDir(const adir:AnsiString);
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
        if UpCase(ExtractFileExt(lname))='.DAT' then
        begin
          AddStat(PChar(lname));
        end;
      end;
    until FindNext(sr)<>0;
    FindClose(sr);
  end;
end;

var
  p,pp:PTL2Node;
  modid:int64;
  s:string;
  i:integer;
begin
  p:=ParseDatFile('MOD.DAT',i,s);
  pp:=FindNode(p,'MOD_ID');
  modid:=pp^.asInteger64;
  DeleteNode(p);

  Str(modid,smodid);
  if sqlite3_open('tl2db.db',@db)<>SQLITE_OK then
    writeln('cant open');
  sqlite3_exec(db,'Begin Transaction',nil,nil,nil);
  CycleDir('MEDIA\STATS');
  sqlite3_exec(db,'End Transaction',nil,nil,nil);
  sqlite3_close(db);
end.
