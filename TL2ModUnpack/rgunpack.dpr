{$I-}

uses
  classes,
  sysutils,

  rgglobal,
  datunpack,
  layunpack,
  
  TL2DatNode;

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
      curfname:=fname;

      if      ltype=1             then slout:=DoParseDat   (buf)
      else if ltype=2             then slout:=DoParseLayout(buf)
      else if IsProperDat   (buf) then slout:=DoParseDat   (buf)
      else if IsProperLayout(buf) then slout:=DoParseLayout(buf);

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

var
  i:integer;

begin
  //--- Initialization

{$IFDEF DEBUG}
  hashlog:=TStringList.Create;
  hashlog.Sorted:=True;
{$ENDIF}

  //--- Process

  if ParamCount=0 then
  begin
    sl:=TStringList.Create;
    CycleDir('.');
    for i:=0 to sl.Count-1 do
      DoProcessFile(sl[i]);
    sl.Free;
  end
  else
    DoProcessFile(ParamStr(1));

  //--- Finalization

{$IFDEF DEBUG}
  hashlog.Sort;
  hashlog.SaveToFile('hashes.txt');
  hashlog.Free;
{$ENDIF}
end.
