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

type
  tpetinfo = record
    id      :Int64;
    title   :string;
    name    :string;
    atype   :integer;
    scale   :single;
    textures:integer;
  end;

procedure AddToBase(var apet:tpetinfo);
var
  lSQL,sid,lscale:string;
  vm:pointer;
begin
  Str(aPet.id,sid);
  Str(aPet.Scale,lscale);

  lSQL:='INSERT INTO pets (id, name, title, pettype, scale, textures, modid) VALUES ('+
      sid+', '''+apet.name+''',"'+apet.title+'", '+
      IntToStr(apet.atype)+', '+lscale+', '+IntToStr(apet.textures)+', '+smodid+')';
writeln(lSQL);
  if sqlite3_prepare_v2(db,PChar(lSQL),-1,@vm,nil)=SQLITE_OK then
  begin
    sqlite3_step(vm);
    sqlite3_finalize(vm);
  end
  else
    writeln('cant update');
end;

procedure AddPet(fname:PChar);
var
  p:PTL2Node;
  lpet:tpetinfo;
  i:integer;
begin
  p:=ParseDatFile(fname);
  lpet.scale:=1.0;
  lpet.textures:=1;
  for i:=0 to p^.childcount-1 do
  begin
    if CompareWide(p^.children^[i].name,'NAME') then
    begin
      lpet.name:=p^.children^[i].asString;
    end;
    if CompareWide(p^.children^[i].name,'DISPLAYNAME') then
    begin
      lpet.title:=p^.children^[i].asString;
    end;
    if CompareWide(p^.children^[i].name,'UNIT_GUID') then
    begin
      lpet.id:=StrToInt64(p^.children^[i].asString);
    end;
    if CompareWide(p^.children^[i].name,'UNITTYPE') then
    begin
      if CompareWide(p^.children^[i].asString,'STARTING PET') then
        lpet.atype:=0
      else
        lpet.atype:=1;
    end;
    if CompareWide(p^.children^[i].name,'SCALE') then
    begin
      lpet.scale:=p^.children^[i].asFloat;
    end;
    if CompareWide(p^.children^[i].name,'TEXTURE_OVERRIDE_LIST') then
    begin
      lpet.textures:=p^.children^[i].childcount;
    end;
  end;
  AddToBase(lpet);
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
          AddPet(PChar(lname));
        end;
      end;
    until FindNext(sr)<>0;
    FindClose(sr);
  end;
end;

var
  p,pp:PTL2Node;
  modid:int64;
begin
  p:=ParseDatFile('MOD.DAT');
  pp:=FindNode(p,'MOD_ID');
  modid:=pp^.asInteger64;
  DeleteNode(p);

  Str(modid,smodid);
  if sqlite3_open('tl2db.db',@db)<>SQLITE_OK then
    writeln('cant open');
  sqlite3_exec(db,'Begin Transaction',nil,nil,nil);
  CycleDir('MEDIA\UNITS\MONSTERS\PETS');
  CycleDir('MEDIA\UNITS\MONSTERS\WARBOUNDS');
  CycleDir('MEDIA\UNITS\MONSTERS\BROTHER-IN-ARMS');
  sqlite3_exec(db,'End Transaction',nil,nil,nil);
  sqlite3_close(db);
end.
