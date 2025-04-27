{}

function TRGMesh.ReadHob(var aptr:PByte; asMesh:boolean):boolean;
var
  lver:integer;
begin
  result:=true;

//    if FStream.ReadWord()=0002 then
  lver:=memReadWord(aptr);
  Log('format version? w[0] (2) or 1',lver);
  Log('w [1] (9)',memReadWord(aptr));
  Log('w [2] (1)',memReadWord(aptr));
  Log('b (0)'    ,memReadByte(aptr));

  ReadHobMaterial(aptr,lver);

end;
