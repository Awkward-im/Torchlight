{}
{$IFDEF Interface}

{$I rg3d.MDL.inc}
{$I rg3d.Hob.inc}
{$I rg3d.Mesh.inc}

    //set direct pointers to Vertex etc after import;
    procedure FixPointers;
{$ELSE}

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
  b:boolean;
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

    result:=ReadMesh(aptr);
  end;
  FixPointers();

  LogLn;
  b:=CalcBounds;
  Log('minx',BoundMin.X);
  Log('miny',BoundMin.Y);
  Log('minz',BoundMin.Z);
  Log('maxx',BoundMax.X);
  Log('maxy',BoundMax.Y);
  Log('maxz',BoundMax.Z);
  if not b then
  begin
    CalcBounds(true);
    Log('minx',BoundMin.X);
    Log('miny',BoundMin.Y);
    Log('minz',BoundMin.Z);
    Log('maxx',BoundMax.X);
    Log('maxy',BoundMax.Y);
    Log('maxz',BoundMax.Z);
  end;

  Log('offset',HexStr(aptr-FBuffer,8));
end;
{$I-}
function TRGMesh.ImportFromFile(const aFileName:string):boolean;
var
  lfile:File of byte;
  lbuf:PByte;
  lsize:integer;
begin
  AssignFile(lfile,aFileName);
  Reset(lfile);
  if IOResult=0 then
  begin
    lsize:=FileSize(lfile);
    if lsize>0 then
    begin
      GetMem(lbuf,lsize);
      BlockRead(lfile,lbuf^,lsize);
      CloseFile(lfile);

      result:=ImportFromMemory(lbuf,lsize);
      FreeMem(lbuf);

      if result then
      begin
        Name:=ExtractNameOnly(aFileName);
        
        if MeshVersion<>99 then
        begin
          AssignFile(lfile,ChangeFileExt(aFileName,'.MATERIAL'));
          Reset(lfile);
          if IOResult=0 then
          begin
            lsize:=FileSize(lfile);
            GetMem(lbuf,lsize+1);
            BlockRead(lfile,lbuf^,lsize);
            lbuf[lsize]:=0;
            CloseFile(lfile);

            ReadMaterialSimple(lbuf,lsize);
            FreeMem(lbuf);
          end;
        end;
      end;

      exit;
    end;
    CloseFile(lfile);
  end;
  result:=false;
end;

{$ENDIF}
