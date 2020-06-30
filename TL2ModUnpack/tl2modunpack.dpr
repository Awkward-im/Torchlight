program TL2ModUnpack;

uses
  classes,
  sysutils,
  paszlib,
  TL2ModInfo;

const
  pftDat       = $00;
  pftLayout    = $01;
  pftMesh      = $02;
  pftSkeleton  = $03;
  pftDds       = $04;
  pftPng       = $05;
  pftOgg       = $06;
  pftDirectory = $07;
  pftMaterial  = $08;
  pftRaw       = $09;
  pftImageSet  = $0B;
  pftTtf       = $0C;
  pftFont      = $0D;
  pftAnimation = $10;
  pftHie       = $11;
  pftScheme    = $12;
  pftLookNFeel = $13;
  pftMpd       = $14;

procedure Unpack(f:TStream; const aname:WideString; ofs:dword; asize:dword);
var
  lf:file of byte;
  strm:TZStream;
  buf,dst:PByte;
  usize,csize:dword;
  ret:integer;
begin
  f.Position:=ofs;
  usize:=f.ReadDWord;
  csize:=f.ReadDWord;
writeln(aname,'; a=',asize,', u=',usize,', c=',csize);
  if usize<>asize then
  begin
    writeln('wrong usize for ',aname);
    exit;
  end;
  if csize>0 then
  begin
    GetMem(buf ,csize);
    f.Read(buf^,csize);
    GetMem(dst ,usize);

  	strm.avail_in := 0;
  	strm.next_in  := Z_NULL;
  	ret := inflateInit(strm);
  	strm.avail_in := csize;
  	strm.next_in  := buf;

  	strm.avail_out := usize;
  	strm.next_out  := dst;

  	ret := inflate(strm, Z_FINISH);

  	inflateEnd(strm);
  end
  else
  begin
    buf:=nil;
    GetMem(dst ,usize);
    f.Read(dst^,usize);
  end;

	AssignFile(lf,aname);
	Rewrite(lf);
	BlockWrite(lf,dst^,usize);
	CloseFile(lf);
  
  FreeMem(buf);
  FreeMem(dst);
end;

procedure ReadDirectory(fin,f:TStream; const mi:TTL2ModInfo);
var
  sl:TStringList;
  wpath,ws:WideString;
  ft:QWord;//FILETIME;
  i,j:integer;
  lcnt,lcnt1:dword;
  lpos,loffs,lusize:dword;
  llen:word;
  ltype:byte;
begin
  f.ReadWord (); // version/signature
  f.ReadDWord(); // checksum?
  llen:=f.ReadWord();
  SetLength(ws,llen);
  f.Read(ws[1],llen*SizeOf(WideChar));
  lcnt:=f.ReadDWord; // entries? directories?
  lcnt:=f.ReadDWord; // files?

  sl:=TStringList.Create;

  lpos:=f.Position;
  for i:=0 to lcnt-1 do
  begin
    llen:=f.ReadWord();
    if llen>0 then
    begin
      SetLength(wpath,llen);
      f.Read(wpath[1],llen*SizeOf(WideChar));
    end;
    lcnt1:=f.ReadDWord();

    for j:=0 to lcnt1-1 do
    begin
      f.ReadDWord;
      ltype:=f.ReadByte;
      llen:=f.ReadWord;
      SetLength(ws,llen);
      f.Read(ws[1],llen*SizeOf(WideChar));
      loffs :=f.ReadDWord;
      lusize:=f.ReadDWord;
      ft    :=f.ReadQWord;
      if ltype=pftDirectory then sl.Add(wpath+ws);
    end;
  end;

  sl.Sort;
  for i:=0 to sl.Count-1 do
    CreateDir(sl[i]);
  sl.Free;

  f.Position:=lpos;
  for i:=0 to lcnt-1 do
  begin
    llen:=f.ReadWord();
    if llen>0 then
    begin
      SetLength(wpath,llen);
      f.Read(wpath[1],llen*SizeOf(WideChar));
    end;
    lcnt1:=f.ReadDWord();

    for j:=0 to lcnt1-1 do
    begin
      f.ReadDWord;
      ltype:=f.ReadByte;
      llen:=f.ReadWord;
      SetLength(ws,llen);
      f.Read(ws[1],llen*SizeOf(WideChar));
      loffs :=f.ReadDWord;
      lusize:=f.ReadDWord;
      ft    :=f.ReadQWord;
      if ltype<>pftDirectory then
      begin
        Unpack(fin,wpath+ws,mi.offData+loffs,lusize);
      end;
    end;
  end;

end;

var
  f,m:TStream;
  mi:TTL2ModInfo;
begin
  ReadModInfo(pointer(ParamStr(1)),mi);
  f:=TFileStream.Create(ParamStr(1),fmOpenRead);
  m:=TMemoryStream.Create;
  f.Position:=mi.offDir;
  m.CopyFrom(f,f.Size-f.Position);
  m.Position:=0;
  ReadDirectory(f,m,mi);
  f.Free;
  m.Free;
end.
