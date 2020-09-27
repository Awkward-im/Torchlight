uses
  sysutils,
  TL2DatNode,
  RGGlobal,
  awksqlite3,
  sqlite3;

const
  GameRoot = 'G:\Games\Torchlight 2\';
var
  db:PSQLite3;
  cnt:integer;

function FixedText(const astr:string):string;
begin
  result:=#39+StringReplace(astr,#39,#39#39,[rfReplaceAll])+#39;
end;

//===================================

function GetBaseStack(const fname:string):string;
var
  p:PTL2Node;
  lbase:string;
  i:integer;
begin
  result:='';
  lbase :='';
  p:=ParseDatFile(PChar(fname));
  if p=nil then
  begin
    p:=ParseDatFile(PChar(GameRoot+fname));
    if p=nil then
    begin
      writeln('can''t load: ',fname);
      exit;
    end;
  end;

  for i:=0 to p^.childcount-1 do
  begin
    if CompareWide(p^.children^[i].name,'MAXSTACKSIZE') then
    begin
      Str(p^.children^[i].asInteger,result);
      break;
    end;
    if CompareWide(p^.children^[i].name,'BASEFILE') then
    begin
      lbase:=p^.children^[i].asString;
    end;
  end;

  if (result='') and (lbase<>'') then
    result:=GetBaseStack(lbase);

  DeleteNode(p);
end;

procedure UpdateItem(const fname:string);
var
  p:PTL2Node;
  lSQL,lbase,lid,lstack:string;
  vm:pointer;
  i:integer;
begin
  lbase :='';
  lid   :='';
  lstack:='';

  p:=ParseDatFile(PChar(fname));
  for i:=0 to p^.childcount-1 do
  begin
    if CompareWide(p^.children^[i].name,'BASEFILE') then
    begin
      lbase:=p^.children^[i].asString;
    end
    else if CompareWide(p^.children^[i].name,'MAXSTACKSIZE') then
    begin
      Str(p^.children^[i].asInteger,lstack);
    end
    else if CompareWide(p^.children^[i].name,'UNIT_GUID') then
    begin
      lid:=p^.children^[i].asString;
    end
  end;
  DeleteNode(p);

  if lid<>'' then
  begin
    i:=1;
    lSQL:='SELECT stack FROM items WHERE id='+lid;
    if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
    begin
      if sqlite3_step(vm)=SQLITE_ROW then
      begin
        i:=sqlite3_column_int(vm,0);
      end;
      sqlite3_finalize(vm);
    end;

    if i<=1 then
    begin
      if (lstack='') and (lbase<>'') then
        lstack:=GetBaseStack(lbase);

      if (lstack<>'') and (lstack<>'1') then
      begin
        lSQL:='UPDATE items SET stack='+lstack+' WHERE id='+lid;

        if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
        begin
          sqlite3_step(vm);
          sqlite3_finalize(vm);
    inc(cnt);
        end;
      end;
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
UpdateItem(lname);
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

  cnt:=0;
  CycleDir('MEDIA\UNITS\ITEMS');
writeln(cnt,' items affected');

  CopyToFile(db,'tl2db2.db');
  sqlite3_close(db);
end.
