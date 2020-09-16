{$I-}

uses
  classes,
  sysutils,

  rgglobal,
  datunpack,
  layunpack,
  
  TL2DatNode,
  TL2Memory;


procedure DoProcessFile(const fname:string);
var
  f:file of byte;
  buf:pByte;
  slout:PTL2Node;
  lext:string;
  ltype,l:integer;
begin
  ltype:=0;
  lext:=UpCase(ExtractFileExt(fname));
  if (lext='.DAT') or (lext='.ANIMATION') then ltype:=1
  else if (lext='.LAYOUT') then ltype:=2;

  if ltype>0 then
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

      if ltype=1 then
        slout:=DoParseDat(buf)
      else if ltype=2 then
        slout:=DoParseLayout(buf);

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
