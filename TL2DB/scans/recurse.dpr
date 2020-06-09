uses
  sysutils,
  TL2DatNode,
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

procedure DoAddFileBase(const fname:string);
var
  p:PTL2Node;
  lSQL,lfile,lbase,lid:string;
  vm:pointer;
  i:integer;
begin
  lbase:='';
  lid  :='';

  p:=ParseDatFile(PChar(fname));
  for i:=0 to p^.childcount-1 do
  begin
    if CompareWide(p^.children^[i].name,'BASEFILE') then
    begin
      lbase:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'UNIT_GUID') then
    begin
      lid:=p^.children^[i].asString;
    end
  end;
  DeleteNode(p);

  if lid<>'' then
  begin
    lfile:=LowerCase(fname);
    for i:=1 to Length(lfile) do if lfile[i]='\' then lfile[i]:='/';
    lbase:=LowerCase(lbase);
    for i:=1 to Length(lbase) do if lbase[i]='\' then lbase[i]:='/';

    lSQL:='UPDATE items SET file='+FixedText(lfile)+', base='+FixedText(lbase)+
        ' WHERE id='+lid;

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
        if UpCase(ExtractFileExt(lname))='.DAT' then
        begin
DoAddFileBase(lname);
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

  CycleDir('MEDIA\UNITS\ITEMS');

  CopyToFile(db,'tl2db2.db');
  sqlite3_close(db);
end.
