unit TL2Replace;

interface

function TranslateToEnglish(const amodid: Int64; const adir:AnsiString):integer;


implementation

uses
  rgglobal,
  sqlite3dyn,
  rgtrans,
  rgio.dat,
  rgnode,
  rgdb.text;


var
  DictEn:pointer;

function ProcessDatFile(anode:pointer):integer;
var
  p:pointer;
  lsrc,ldst:AnsiString;
  w:PWideChar;
  i,ltype:integer;
begin
  result:=0;
  for i:=0 to GetChildCount(anode)-1 do
  begin
    p:=GetChild(anode,i);
    ltype:=GetNodeType(p);
    case ltype of
      rgGroup: inc(result,ProcessDatFile(p));
      rgString,
      rgTranslate: begin
        lsrc:=WideToStr(AsString(p));
        ldst:=rgtrans.GetTranslation(DictEn,lsrc);
        if ldst<>lsrc then
        begin
          w:=StrToWide(ldst);
          AsString(p,w); // String, Translate, Note - no matter, set just value
          FreeMem(w);
          inc(result);
        end;
      end;
    end;
  end;
end;

function TranslateToEnglish(const amodid: Int64; const adir:AnsiString):integer;
var
  vm,p:pointer;
  ldir,ls,lfname,lmod:AnsiString;
begin
  if not (adir[Length(adir)] in ['/','\']) then ldir:=adir+'\' else ldir:=adir;
  Str(amodid,lmod);

  // dictionary
  DictEn:=NewTranslation();
  ls:='SELECT distinct s.src, t.dst FROM strings s'+
      ' RIGHT JOIN trans_en t ON t.srcid=s.id'+
      ' INNER JOIN refs     r ON r.srcid=s.id'+
      ' WHERE s.deleted=0 AND r.modid='+lmod+
      ' AND s.src GLOB concat(''*['',char(128),''-'',char(65535),'']*'')';
  if sqlite3_prepare_v2(tldb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
  begin
    while sqlite3_step(vm)=SQLITE_ROW do
    begin
      AddTranslation(DictEn, sqlite3_column_text(vm,0), sqlite3_column_text(vm,1));
    end;
    sqlite3_finalize(vm);
  end;

  // file list
  ls:='SELECT distinct concat(d.value,f.value) FROM strings s'+
      ' RIGHT JOIN trans_en t ON t.srcid=s.id'+
      ' INNER JOIN refs     r ON r.srcid=s.id'+
      ' INNER JOIN dicdirs  d ON d.id   =r.dir'+
      ' INNER JOIN dicfiles f ON f.id   =r.file'+
      ' WHERE s.deleted=0 AND r.modid='+lmod+
      ' AND s.src GLOB concat(''*['',char(128),''-'',char(65535),'']*'')';
   
  result:=0;
  if sqlite3_prepare_v2(tldb, PAnsiChar(ls),-1, @vm, nil)=SQLITE_OK then
  begin
    while sqlite3_step(vm)=SQLITE_ROW do
    begin
      lfname:=ldir+sqlite3_column_text(vm,0);
      p:=ParseDatFile(lfname);
      if p<>nil then
      begin
        if ProcessDatFile(p)>0 then
        begin
          inc(result);
          BuildDatFile(p,lfname,verTL2);
          RGLog.Add(lfname+' moved to English');
        end;
        DeleteNode(p);
      end;
    end;
    sqlite3_finalize(vm);
  end;

  FreeTranslation(DictEn);
end;

end.
