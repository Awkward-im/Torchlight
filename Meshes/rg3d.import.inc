{}

function memReadText(var abuf:PByte):string;
var
  lptr:PByte;
  lsize:integer;
begin
  lptr:=abuf;
  while abuf^<>10 do inc(abuf);

  lsize:=abuf-lptr;
  if lsize=0 then
    result:=''
  else
    SetString(result,PAnsiChar(lptr),lsize);
  inc(abuf);
end;

function ReadChunk(var abuf:PByte; var achunk:TOgreChunk):word;
var
  ls:string;
  llen:integer;
  lshow:boolean;
begin
  achunk._type:=memReadWord (abuf);
  achunk._len :=memReadDWord(abuf);
  result:=achunk._type;

//  if RGDebugLevel=dlDetailed then
  begin
    ls:='Chunk type: 0x'+HexStr(achunk._type,4)+' '+GetChunkName(achunk._type)+
           '; length=0x'+HexStr(achunk._len ,4)+' ('+IntToStr(achunk._len)+
            ')';
//            '); offset=0x'  +HexStr(abuf-FBuffer-SizeOf(achunk),8);

    if (achunk._type=M_MESH_BONE_ASSIGNMENT) or
       (achunk._type=M_SUBMESH_BONE_ASSIGNMENT) then
      llen:=18
    else
      llen:=Length(ls);
    lshow:=StrLComp(PAnsiChar(RGLog.Last),PAnsiChar(ls),llen)<>0;

    if lshow then RGLog.Add(ls);
  end
//  else if lshow then RGLog.Reserve('Chunk '+GetChunkName(achunk._type));
end;

function TranslateVersion(const sign:AnsiString):integer;
var
  i:integer;
begin
  for i:=0 to High(FileVersions) do
    if FileVersions[i].sign=sign then exit(FileVersions[i].ver);

  result:=-1;
end;

function GetFileVersion(var abuf:PByte):integer;
var
  ls:AnsiString;
begin
  result:=-1;
  if memReadWord(abuf)=M_HEADER then
  begin
    ls:=memReadText(abuf);
    result:=TranslateVersion(ls);
    if result<40 then
    begin
      Log('version',ls+' not supported');
      exit;
    end
    else
      Log('version',ls);
  end;
end;

{$I rg3d.MDL.inc}
{$I rg3d.Hob.inc}
{$I rg3d.Mesh.inc}

procedure TRGMesh.FixPointers;
var
  lsm:PRGSubMesh;
  i:integer;
begin
  for i:=0 to FSubMeshCount-1 do
  begin
    lsm:=FSubMeshes[i];
    lsm^.FVertex  :=lsm^.GetBuffer(VES_POSITION,0);
    lsm^.FNormal  :=lsm^.GetBuffer(VES_NORMAL  ,0);
    lsm^.FBiNormal:=lsm^.GetBuffer(VES_BINORMAL,0);
// not used, coz pointer getter is fast, and indexed value can be different size
//    lsm^.FTangent :=lsm^.GetBuffer(VES_TANGENT ,0);
  end;
end;

function TRGMesh.ImportFromMemory(aptr:PByte; asize:integer):boolean;
var
  lchunk:TOgreChunk;
begin
  result:=false;

  FBuffer:=aptr;
  FDataSize:=asize;

  FVersion:=GetFileVersion(aptr);
  if FVersion<0 then exit;

  if FVersion=99 then
    result:=ReadMDL(aptr)
  else
  begin
    if (FVersion=90) or (FVersion=91) then
      result:=ReadHob(aptr,FVersion=90);

    if ReadChunk(aptr,lchunk)=M_MESH then
      result:=ReadMesh(aptr);
  end;
  FixPointers();

  Log('offset',HexStr(aptr-FBuffer,8));
end;

function TRGMesh.ImportFromFile(const aFileName:string):boolean;
var
  lfile:File of byte;
  lbuf:PByte;
  lsize:integer;
begin
  Assign(lfile,aFileName);
  Reset(lfile);
  if IOResult=0 then
  begin
    lsize:=FileSize(lfile);
    if lsize>0 then
    begin
      GetMem(lbuf,lsize);
      BlockRead(lfile,lbuf^,lsize);
      Close(lfile);

      result:=ImportFromMemory(lbuf,lsize);
      FreeMem(lbuf);
      exit;
    end;
    Close(lfile);
  end;
  result:=false;
end;
