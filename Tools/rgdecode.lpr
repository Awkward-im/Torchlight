{$I-}

{$R ..\TL2Lib\dict.rc}

uses
  classes,
  sysutils,

  rgglobal,
  rgnode,
  rgfile,
  rgdict,
  rgdictlayout,

  rgio.dat,
  rgio.layout,
  rgio.raw,
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


procedure DoProcessFile(const fname:string);
var
  f:file of byte;
  buf:pByte;
  slout:PWideChar;
  l:integer;
begin
  AssignFile(f,fname);
  Reset(f);
  if IOResult=0 then
  begin
    RGLog.Reserve('Processing file '+fname);

    l:=FileSize(f);
    GetMem(buf,l);
    BlockRead(f,buf^,l);
    CloseFile(f);

    slout:=nil;
    if DecompileFile(buf, l, fname, slout) then
    begin
      AssignFile(f,fname+'.1.TXT');
      Rewrite(f);
      if IOResult=0 then
      begin
        BlockWrite(f,slout^,Length(slout)*SizeOf(WideChar));
        CloseFile(f);
      end;
      FreeMem(slout);
    end;

    FreeMem(buf);
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

var
  i:integer;

begin
{$if declared(UseHeapTrace)}
  SetHeapTraceOutput('Trace.log');
  HaltOnError := true;
{$endif}
  //--- Initialization

  RGTags.Import ('RGDICT', 'TEXT');
  LoadLayoutDict('LAYTL1', 'TEXT', verTL1);
  LoadLayoutDict('LAYTL2', 'TEXT', verTL2);
  LoadLayoutDict('LAYRG' , 'TEXT', verRG);
  LoadLayoutDict('LAYRGO', 'TEXT', verRGO);
  LoadLayoutDict('LAYHOB', 'TEXT', verHob);

  //--- Process

  try
    if (ParamCount=0) then
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
