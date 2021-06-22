{$I-}

uses
  classes,
  sysutils,
  inifiles,

  rgglobal,
  rglog,
  rgnode,
  rgdict,

  rgdatunpack,
  rglayunpack;

const
  GoodExtArray : array of string = (
    '.DAT',
    '.ANIMATION',
    '.TEMPLATE',
    '.HIE',
    '.WDAT',
    '.LAYOUT'
  );

var
  ftype: integer;

procedure DoProcessFile(const fname:string);
var
  f:file of byte;
  buf:pByte;
  slout:pointer;
  lext:string;
  ltype,l:integer;
begin
  ltype:=0;
  lext:=UpCase(ExtractFileExt(fname));

  if (lext='.LAYOUT') then ltype:=2
  else
  begin
    for l:=0 to High(GoodExtArray) do
      if lext=GoodExtArray[l] then
      begin
        ltype:=1;
        break;
      end;
    if ltype=0 then
    begin
      lext:=UpCase(fname);
      for l:=0 to High(GoodExtArray) do
        if Pos(GoodExtArray[l]+'.',lext)>0 then
        begin
          ltype:=-1;
          break;
        end;
    end;
  end;

  if ltype<>0 then
  begin
    AssignFile(f,fname);
    Reset(f);
    if IOResult=0 then
    begin
      l:=FileSize(f);
      GetMem(buf,l);
      BlockRead(f,buf^,l);
      CloseFile(f);

      slout:=nil;
//      curfname:=fname;
      if      (ltype=1)           and (ftype< 2) then begin
        RGLog.Add('Processing file '+fname);
        slout:=DoParseDat   (buf)
      end
      else if (ltype=2)           and (ftype<>1) then begin
        RGLog.Add('Processing file '+fname);
        slout:=DoParseLayout(buf)
      end
      else if IsProperDat   (buf) and (ftype< 2) then begin
        RGLog.Add('Processing file '+fname);
        slout:=DoParseDat   (buf)
      end
      else if IsProperLayout(buf) and (ftype<>1) then begin
        RGLog.Add('Processing file '+fname);
        slout:=DoParseLayout(buf);
      end;

      FreeMem(buf);

      WriteDatTree(slout,PChar(fname+'.TXT'));
      DeleteNode(slout);
    end;
  end;
end;

var
  sl:TStringList;

procedure CycleDir(const adir:String);
var
  sr:TSearchRec;
begin
  if FindFirst(adir+'\*.*',faAnyFile and faDirectory,sr)=0 then
  begin
    repeat
      if (sr.Attr and faDirectory)=faDirectory then
      begin
        if (sr.Name<>'.') and (sr.Name<>'..') then
          CycleDir(adir+'\'+sr.Name);
      end
      else
      begin
        sl.Add(adir+'\'+sr.Name);
//        DoProcessFile(adir+'\'+sr.Name);
      end;
    until FindNext(sr)<>0;
    FindClose(sr);
  end;
end;


procedure ProcessINI;
var
  lini:TINIFile;
  i,lcnt:integer;
begin
  lini:=TINIFile.Create(ChangeFileExt(ParamStr(0),'.INI'));
  lcnt:=lini.ReadInteger('dicts','count',0);
  if lcnt=0 then
  begin
    writeln('dictionary.txt ',RGTags.Import('dictionary.txt'));
    writeln('hashed.txt '    ,RGTags.Import('hashed.txt'));
    writeln('tagdict.txt '   ,RGTags.Import('tagdict.txt'));
  end
  else
  begin
    for i:=1 to lcnt do
    begin
      RGTags.Import(lini.ReadString('dicts','dict'+IntToStr(i),''));
    end;
  end;

  ReadLayINI(lini);
  lini.Free;
end;

var
  i:integer;

begin
  //--- Initialization

  //--- Process

  if      ParamStr(1)='-d' then ftype:=1
  else if ParamStr(1)='-l' then ftype:=2
  else if ParamStr(1)='-n' then ftype:=3
  else ftype:=0;

  ProcessINI;

  if (ParamCount=0) or (ftype<>0) then
  begin
    sl:=TStringList.Create;
    // Make file list at start to skip freshly created decoded files
    CycleDir('.');
    for i:=0 to sl.Count-1 do
      DoProcessFile(sl[i]);
    sl.Free;
  end
  else
    DoProcessFile(ParamStr(1));

  //--- Finalization

  RGLog.Save();

end.
