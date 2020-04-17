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

procedure AddToBase(const aname:string; aId:int64; const atitle:string);
var
  lSQL,sid,ssaves:string;
  vm:pointer;
begin
  Str(aid,sid);

  lSQL:='INSERT INTO quests (id, name, title, modid) VALUES ('+sid+', '''+aname+''',"'+atitle+
    '", '+smodid+')';

  if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
  begin
    sqlite3_step(vm);
    sqlite3_finalize(vm);
  end
  else
    writeln('cant update');
end;

procedure AddQuest(fname:PChar);
var
  p,pp:PTL2Node;
  s:string;
  name,title:string;
  lid:int64;
  i:integer;
begin
  p:=ParseDatFile(fname);
  title:='';
  lid:=-1;

write(fname);

  for i:=0 to p^.childcount-1 do
  begin
    if p^.children^[i].nodetype<>ntGroup then
    begin
      if CompareWide(p^.children^[i].name,'NAME') then
      begin
        name:=p^.children^[i].asString;
//        write(' name ',name );
      end;
      if CompareWide(p^.children^[i].name,'QUEST_GUID') then
      begin
        lid:=p^.children^[i].asInteger64;
//        write(' id ',lid);
      end;
      if CompareWide(p^.children^[i].name,'DISPLAYNAME') then
      begin
        title:=p^.children^[i].asString;
//        write(' title ',title);
      end;
    end;
  end;
  if lid<>-1 then
  begin
    AddToBase(name,lid,title);
    writeln(' added');
  end
  else
    writeln(' don''t added');
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
          AddQuest(PChar(lname));
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
  p:=ParseDatFile('MOD.DAT');
  pp:=FindNode(p,'MOD_ID');
  modid:=pp^.asInteger64;
  DeleteNode(p);

  Str(modid,smodid);
  if sqlite3_open('tl2db.db',@db)<>SQLITE_OK then
    writeln('cant open');
  sqlite3_exec(db,'Begin Transaction',nil,nil,nil);
  CycleDir('MEDIA\QUESTS');
  sqlite3_exec(db,'End Transaction',nil,nil,nil);
  sqlite3_close(db);
end.
