﻿{$I-}

{$R ..\TL2Lib\dict.rc}

uses
  classes,
  sysutils,
  inifiles,

  rgglobal,
  rglogging,
  rgnode,
  rgdict,

  rgio.dat,
  rgio.layout,
  rgio.text;

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
        RGLog.Reserve('Processing file '+fname);

        slout:=ParseDatMem(buf);
      end
      else if (ltype=2)           and (ftype<>1) then begin
        RGLog.Reserve('Processing file '+fname);
        slout:=ParseLayoutMem(buf)
{
      end
      else if IsProperDat   (buf) and (ftype< 2) then begin
        RGLog.Reserve('Processing file '+fname);
        slout:=ParseDatMem(buf)
      end
      else if IsProperLayout(buf) and (ftype<>1) then begin
        RGLog.Reserve('Processing file '+fname);
        slout:=ParseLayoutMem(buf);
}      end;

      FreeMem(buf);

      BuildTextFile(slout,PChar(fname+'.1.TXT'));
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
    if RGTags.Import('RGDICT','TEXT')=0 then
      writeln('dictionary.txt ',RGTags.Import('dictionary.txt'));

    writeln('hashed.txt '    ,RGTags.Import('hashed.txt'));
    writeln('tagdict.txt '   ,RGTags.Import('tagdict.txt'));
    writeln('dict-tl1.txt '  ,RGTags.Import('dict-tl1.txt'));
    writeln('dict-tl2.txt '  ,RGTags.Import('dict-tl2.txt'));
    writeln('dict-rg.txt '   ,RGTags.Import('dict-rg.txt'));
    writeln('dict-hob.txt '  ,RGTags.Import('dict-hob.txt'));
    writeln('dict-rgo.txt '  ,RGTags.Import('dict-rgo.txt'));
  end
  else
  begin
    for i:=1 to lcnt do
    begin
      RGTags.Import(lini.ReadString('dicts','dict'+IntToStr(i),''));
    end;
  end;

  LoadLayoutDict('LAYTL1', 'TEXT', verTL1);
  LoadLayoutDict('LAYTL2', 'TEXT', verTL2);
  LoadLayoutDict('LAYRG' , 'TEXT', verRG);
  LoadLayoutDict('LAYRGO', 'TEXT', verRGO);
  LoadLayoutDict('LAYHOB', 'TEXT', verHob);
{
  LoadLayoutDict('compact-tl1.txt', verTL1);
  LoadLayoutDict('compact-tl2.txt', verTL2);
  LoadLayoutDict('compact-rg.txt' , verRG);
  LoadLayoutDict('compact-rgo.txt', verRGO);
  LoadLayoutDict('compact-hob.txt', verHob);
}
  lini.Free;
end;

var
  i:integer;

begin
{$if declared(UseHeapTrace)}
  SetHeapTraceOutput('Trace.log');
  HaltOnError := true;
{$endif}
  //--- Initialization

  //--- Process

  if      ParamStr(1)='-d' then ftype:=1
  else if ParamStr(1)='-l' then ftype:=2
  else if ParamStr(1)='-n' then ftype:=3
  else ftype:=0;

  ProcessINI;

  try
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

  finally
    RGLog.SaveToFile();
  end;

end.
