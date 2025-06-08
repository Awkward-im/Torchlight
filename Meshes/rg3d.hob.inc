{}

{$IFDEF Interface}

    function  ReadHob(var aptr:PByte; asMesh:boolean):boolean;
    procedure WriteHob(astream:TStream);

{$ELSE}

function TRGMesh.ReadHob(var aptr:PByte; asMesh:boolean):boolean;
var
  lDumpAddr:PByte;
  lver:integer;
begin
  lver:=memReadWord(aptr); // v.1 mean use custom hash
  Log('format version? w[0] (2) or 1',lver);

  Log('w [1] (9)'     ,memReadWord(aptr)); // must be >8 (not used in material)
  Log('Skinned? (1)'  ,memReadByte(aptr)); // check hash? skinned?
  Log('w strings? (0)',memReadWord(aptr)); // string table count

  lDumpAddr:=aptr;
  result:=ReadHobMaterials(aptr,lver);
  if result then
  begin
    FDumpSize:=aptr-lDumpAddr;
    GetMem(FMaterialDump,FDumpSize);
    move(lDumpAddr^,FMaterialDump^,FDumpSize);
  end;
end;

procedure TRGMesh.WriteHob(astream:TStream);
begin
  astream.WriteWord(2);
  astream.WriteWord(9);
  astream.WriteByte(0);
  astream.WriteWord(0);

  if (FMaterialDump<>nil) and (FDumpSize>0) then
    astream.Write(FMaterialDump^,FDumpSize)
  else
    WriteHobMaterial(astream);
end;

{$ENDIF}
