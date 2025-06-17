{}
{$IFDEF Interface}

{$I rg3d.MDL.inc}
{$I rg3d.Hob.inc}
{$I rg3d.Mesh.inc}

    // setup some empty fields and blocks for proper values
    procedure PostProcess;

{$ELSE}

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

procedure TRGMesh.PostProcess;
var
  i,j:integer;
begin

  //--- Set FBoneCount if not set ---

  if FBoneCount=0 then
  begin
    for i:=0 to FSubMeshCount-1 do
    begin
      with FSubMeshes[i]^ do
        for j:=0 to FBoneAssignCount-1 do
          if FBoneCount<FBones[j].boneIndex then
            FBoneCount:=FBones[j].boneIndex;
    end;
  end;

  //--- Set Skeleton name if need ---

  if (Skeleton='') and (FBoneCount>0) and (Name<>'') then Skeleton:=Name+'.skeleton';

  // better to convert local vertices to shared
  // and remove VE blocks
  // shared geometry - no submesh blocks

  //--- Set proper VEList fields ---
  //--- Set fast access pointers ---

  for i:=0 to FSubMeshCount-1 do
  begin
    with FSubMeshes[i]^ do
    begin
      for j:=0 to FVEList.Count-1 do
      begin
        with FVElist[j]^ do
        begin
          source:=j;
          offset:=0;
          index :=0;
          case semantic of
            VES_POSITION: FVertex  :=Buffer[j];
            VES_NORMAL  : FNormal  :=Buffer[j];
            VES_BINORMAL: FBiNormal:=Buffer[j];
          end;
        end;
      end;
    end;
  end;

// not used, coz pointer getter is fast, and indexed value can be different size
//    lsm^.FTangent :=lsm^.GetBuffer(VES_TANGENT ,0);

  //--- Remove empty (no faces) submeshes ---

  for i:=FSubMeshCount-1 downto 1 do
    if FSubMeshes[i]^.FFaceCount=0 then DeleteSubMesh(i);
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
  PostProcess();

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

      Name:=ExtractNameOnly(aFileName);
      result:=ImportFromMemory(lbuf,lsize);
      FreeMem(lbuf);

      if result then
      begin
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
