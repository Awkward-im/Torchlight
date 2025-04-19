unit RGMDL;

interface

uses
  Classes,
  SysUtils,
  rgglobal,
  rgstream,
  RGMesh;

procedure Trace(const fname:AnsiString);


implementation

type
  TRGMDL = object
  public
    FStream:TStream;
    FVertexCount:integer;
    FSubMeshes:integer;   // sure, if Meshes=1 only
    FVersion:integer;
    FMeshVersion:integer;

    procedure ReadTextures;
    procedure ReadBlockX5;

    function  ReadMeshInfo(aver:integer):boolean;
    procedure ReadModelDataType0();
    procedure ReadModelDataType1();

    function  ReadMDLFile:boolean;

    procedure Init;
    procedure Free;
    procedure Clear;
    procedure LoadFromFile(fname:PAnsiChar);
  end;

var
  FTextures:array of string;

procedure LogTexture(num,idx:integer);
var
  ls:string;
begin
  if idx>=0 then ls:=FTextures[idx] else ls:='';
  Log('{'+IntToStr(num)+'} I '+IntToStr(idx),ls);
end;

procedure TRGMDL.ReadTextures;
var
  ls:string;
  i,j,lcnt:integer;
begin
  lcnt:=FStream.ReadDWord();
  Log(#13#10'Textures',lcnt);
  SetLength(FTextures,lcnt);
  for i:=0 to lcnt-1 do
  begin
    ls:=ReadText(FStream);
    j:=FStream.ReadDWord();
    FTextures[i]:=ls;

    Log('['+IntToStr(i)+'] '+ls,j);

    if i<>j then Log('!!!Texture code is not ordered','');
  end;
end;

procedure TRGMDL.ReadBlockX5;
var
  i,lcnt:integer;
begin
  lcnt:=FStream.ReadWord();
  Log('>groups (always same values, 5 [default] or 6 times)',lcnt);
  for i:=0 to lcnt-1 do
  begin
    Log('group #',i);
    Log('  w[0]',FStream.ReadWord());
    Log('  w[1]',FStream.ReadWord());
    Log('  w[2]',FStream.ReadWord());
    Log('  w[3]',FStream.ReadWord());
    Log('  w[4]',FStream.ReadWord());
  end;
end;

{
  Check: index arrays are "expanded" arrays of structures,
    next data is just unique combo which can be repeated in normal case?
  So, index must be ALWAYS same or GREATER than ANY sizes of them
}
procedure TRGMDL.ReadModelDataType0();
var
  FIndexCount:integer;
  i,lcnt,lcnt1:integer;
begin

  //=======

  FStream.ReadWord();            // 0001

  Log('float x',FStream.ReadFloat());
  Log('float y',FStream.ReadFloat());
  Log('float z',FStream.ReadFloat());

  FIndexCount:=FStream.ReadDword();
  Log(#13#10'indexCount',FIndexCount);
  Log(HexStr(FStream.Position,8),'first index');
  for i:=0 to FIndexCount-1 do
    FStream.ReadDWord();

  // Vertices
  FVertexCount:=FStream.ReadDword();
  Log(HexStr(FStream.Position,8),IntToStr(FVertexCount)+' vertices');
  for i:=0 to FVertexCount-1 do
  begin
    FStream.ReadFloat();
    FStream.ReadFloat();
    FStream.ReadFloat();
  end;

  if FMeshVersion=$0E then
  begin
    lcnt:=FStream.ReadDword(); // save as FVertextCount
    Log(HexStr(FStream.Position,8),IntToStr(lcnt)+' 6x floats');
    for i:=0 to lcnt-1 do
    begin
      FStream.ReadFloat();
      FStream.ReadFloat();
      FStream.ReadFloat();
      FStream.ReadFloat();
      FStream.ReadFloat();
      FStream.ReadFloat();
    end;
  end;

  //=======

  FStream.ReadWord();            // 0001

  Log(#13#10+HexStr(FStream.Position,8),'UV index');
  // UV indices integer TStrip
  for i:=0 to FIndexCount-1 do
    FStream.ReadDWord();

  // UV?
  lcnt:=FStream.ReadDword();
  Log(HexStr(FStream.Position,8),IntToStr(lcnt)+' UVs');
  for i:=0 to lcnt-1 do
  begin
    FStream.ReadFloat();
    FStream.ReadFloat();
  end;

  //!!!!! CHEAT Maybe BlockX5 with 6 groups?
  if (FMeshVersion=$0E) and (FSubMeshes>1) then
  begin
    Log(#13#10+HexStr(FStream.Position,8),'UV-2 index');
    for i:=0 to FIndexCount-1 do
      FStream.ReadDWord();

    // UV?
    lcnt:=FStream.ReadDword();
    Log(HexStr(FStream.Position,8),IntToStr(lcnt)+' 2nd UVs');
    for i:=0 to lcnt-1 do
    begin
      FStream.ReadFloat();
      FStream.ReadFloat();
    end;
  end;

  //=======

  FStream.ReadWord();            // 0001
  
  Log(#13#10+HexStr(FStream.Position,8),'3x float index');
  for i:=0 to FIndexCount-1 do
    FStream.ReadDWord();

  // normals?

  lcnt:=FStream.ReadDWord();
  Log(HexStr(FStream.Position,8),IntToStr(lcnt)+' 3x floats');
  for i:=0 to lcnt-1 do
  begin
    FStream.ReadFloat();
    FStream.ReadFloat();
    FStream.ReadFloat();
  end;

  Log('dword (0)',FStream.ReadDWord());
  Log('dword (0)',FStream.ReadDWord());

  // Last group (faces)

  i:=FStream.ReadDWord();        // total items
  lcnt:=FStream.ReadDWord();     // total submeshes
  Log(#13#10'last group, '+IntToStr(i)+' items in '+IntToStr(lcnt)+' mesh[es]','');

  for i:=0 to lcnt-1 do
  begin
    FStream.ReadWord();          // submesh #
    lcnt1:=FStream.ReadDWord();  // submesh items count
    Log('  last['+IntToStr(i)+']='+IntToStr(lcnt1),HexStr(FStream.Position,8));
    FStream.Seek(lcnt1*3*SizeOf(DWord),soFromCurrent);
  end;
end;

procedure TRGMDL.ReadModelDataType1();
var
  i,j,lcnt,lcnt1:integer;
begin
  // M_GEOMETRY
  lcnt:=FStream.ReadWord(); // count of geometries?
  if lcnt<>1 then Log('!!!Before vertices is not 1',lcnt);

  FVertexCount:=FStream.ReadDWord(); // Vertices, x*60 bytes (15 FLoat)
  Log('Vertices '+IntToStr(FVertexCount)+'x60 offset',HexStr(FStream.Position,8));
  for i:=0 to FVertexCount-1 do
  begin
    FStream.ReadFloat();         // X
    FStream.ReadFloat();         // Y
    FStream.ReadFloat();         // Z

    FStream.ReadFloat();
    FStream.ReadFloat();
    FStream.ReadFloat();
    FStream.ReadFloat();
    FStream.ReadFloat();
    FStream.ReadFloat();
    FStream.ReadFloat();
    FStream.ReadFloat();
    FStream.ReadFloat();
    FStream.ReadFloat();

    FStream.ReadFloat();         // U
    FStream.ReadFloat();         // V
  end;

  // M_SUBMESH
  lcnt :=FStream.ReadDWord();    // submeshes
  for i:=0 to lcnt-1 do
  begin
    lcnt1:=FStream.ReadDWord();  // Faces
    FStream.ReadDWord();         // submesh number
    Log('Submesh '+IntToStr(i)+' faces '+IntToStr(lcnt1)+' offset',HexStr(FStream.Position,8));
    for j:=0 to lcnt1-1 do
    begin
      FStream.ReadWord();        // X
      FStream.ReadWord();        // Y
      FStream.ReadWord();        // Z
    end;
  end;

  // M_MESH_BOUNDS?
  Log('minx',FStream.ReadFloat());
  Log('miny',FStream.ReadFloat());
  Log('minz',FStream.ReadFloat());
  Log('maxx',FStream.ReadFloat());
  Log('maxy',FStream.ReadFloat());
  Log('maxz',FStream.ReadFloat());

  // M_MESH_SKELETON_LINK
  Log('skeletonName',ReadText(FStream));

//?? M_MESH_BONE_ASSIGNMENT
  lcnt:=FStream.ReadDWord();
  if lcnt>0 then
  begin
    Log(IntToStr(lcnt)+' (Bones vertices ?) offset',HexStr(FStream.Position,8));
    Log('(bones ?) count',FStream.ReadDWord()); //?? Bones? (limit for boneIndex)
    for i:=0 to lcnt-1 do
    begin
      FStream.ReadDword();
      FStream.ReadDWord();
      FStream.ReadFloat();
{
      Log('vertextIndex',FStream.ReadDword());
      Log('boneIndex'   ,FStream.ReadDWord());
      Log('weight'      ,FStream.ReadFloat());
}
    end;
  end;
end;


function TRGMDL.ReadMeshInfo(aver:integer):boolean;
var
  i:integer;
begin
  if not (aver in [$01,$02,$03, $07,$08,$09, $0E]) then exit(false);
  for i:=0 to FSubMeshes-1 do
  begin
    Log(#13#10'name',ReadText(FStream));

    Log('{00} w mesh #'      ,FStream.ReadWord());
    Log('{01} w (part of #?)',FStream.ReadWord());
    Log('{02} w can be >1'   ,FStream.ReadWord());
    Log('{03} w' ,FStream.ReadWord());
    Log('{04} w' ,FStream.ReadWord());
    Log('{05} w' ,FStream.ReadWord());
    Log('{06} w' ,FStream.ReadWord());
    if aver>=3 then
      Log('{07} w' ,FStream.ReadWord());
    if aver>=7 then
    begin
      Log('{08} w' ,FStream.ReadWord());
      Log('{09} w' ,FStream.ReadWord());
    end;
    if aver>=9 then
    begin
      Log('{10} w' ,FStream.ReadWord());
      Log('{11} w' ,FStream.ReadWord());
    end;
    if aver>=14 then
    begin
      Log('{12} w' ,FStream.ReadWord());
      Log('{13} w' ,FStream.ReadWord());
      Log('{14} w' ,FStream.ReadWord());
    end;
    //--------------------------------
    Log('>number groups','');
    Log('{00} w' ,Int16(FStream.ReadWord()));

    if aver>=7 then
      Log('{7+ 1} w' ,Int16(FStream.ReadWord()));

    if aver>=14 then
    begin
      Log('{14+ 1} w' ,Int16(FStream.ReadWord()));
      Log('{14+ 2} w' ,Int16(FStream.ReadWord()));
    end;

    Log('{02} w' ,Int16(FStream.ReadWord()));
    Log('{03} w' ,Int16(FStream.ReadWord()));
    Log('{04} w' ,Int16(FStream.ReadWord()));

    Log('{05} w' ,Int16(FStream.ReadWord()));
    Log('{06} w' ,Int16(FStream.ReadWord()));
    Log('{07} w' ,Int16(FStream.ReadWord()));

    Log('{08} w' ,Int16(FStream.ReadWord()));
    Log('{09} w' ,Int16(FStream.ReadWord()));
    Log('{10} w' ,Int16(FStream.ReadWord()));

    Log('{11} w' ,Int16(FStream.ReadWord()));
    Log('{12} w' ,Int16(FStream.ReadWord()));
    Log('{13} w' ,Int16(FStream.ReadWord()));

    if aver>=8 then
    begin
      Log('{8+ 14} w' ,FStream.ReadWord());
      Log('{8+ 15} w' ,FStream.ReadWord());
      Log('{8+ 16} w' ,FStream.ReadWord());
    end;
    //--------------------------------
    Log('{00} f' ,FStream.ReadFloat());
    Log('{01} f' ,FStream.ReadFloat());
    if aver>=2 then
    begin
      Log('{02} f' ,FStream.ReadFloat());
      Log('{03} f' ,FStream.ReadFloat());
      Log('{04} f' ,FStream.ReadFloat());
    end;
    if aver>=14 then
      Log('{05} f' ,FStream.ReadFloat());
    //--------------------------------
    Log('>textures','');
    if aver>=14 then
    begin
      LogTexture(1400,Int32(FStream.ReadDWord())); // 10 14+ normals
      LogTexture(1401,Int32(FStream.ReadDWord())); // 11 14+
      LogTexture(1402,Int32(FStream.ReadDWord())); // 12 14+
      LogTexture(1403,Int32(FStream.ReadDWord())); // 13 14+
      LogTexture(1404,Int32(FStream.ReadDWord())); // 14 14+
    end;
    LogTexture(0,Int32(FStream.ReadDWord()));      // 00 base/diffuse
    LogTexture(1,Int32(FStream.ReadDWord()));      // 01 ??
    if aver>=8 then
      LogTexture(802,Int32(FStream.ReadDWord()));  // 09 8+ environment dark (ambient)
    LogTexture(2,Int32(FStream.ReadDWord()));      // 02 environment "ref"
    LogTexture(3,Int32(FStream.ReadDWord()));      // 03 glow
    LogTexture(4,Int32(FStream.ReadDWord()));      // 04 normal
    LogTexture(5,Int32(FStream.ReadDWord()));      // 05
    LogTexture(6,Int32(FStream.ReadDWord()));      // 06
    LogTexture(7,Int32(FStream.ReadDWord()));      // 07 specular / surface?
    if aver>=7 then
      LogTexture(708,Int32(FStream.ReadDWord()));  // 08 7+
    if aver>=14 then
    begin
      LogTexture(14015,Int32(FStream.ReadDWord())); // 15 14+ paint
      LogTexture(14016,Int32(FStream.ReadDWord())); // 16 14+ paint surface
    end;
  end;

  result:=true;
end;

function TRGMDL.ReadMDLFile:boolean;
var
  lchunk:TOgreChunk;
  ls:AnsiString;
begin
  result:=false;

  // Header. No chunk size field
  lchunk._type:=FStream.ReadWord();
  if lchunk._type=M_HEADER then
  begin
    ls:=ReadText(FStream);
    FVersion:=TranslateVersion(ls);
    if (FVersion<40) then
    begin
      Log('version',ls+' not supported');
      exit;
    end
    else
      Log('version',ls);
  end
  else
    exit;

  //===== RG/RGO =====

  if FVersion=99 then
  begin
    FMeshVersion:=FStream.ReadWord();
    Log('type ',FMeshVersion);

    Log('first' ,FStream.ReadWord());
    Log('second',FStream.ReadWord());
    if FMeshVersion=14 then // type=$0E - RGO
      Log('v.0E add' ,FStream.ReadWord());

    ReadBlockX5();
  
    Log('float (scale?)',FStream.ReadFloat());
    Log('dd (1)',FStream.ReadDWord());
    Log('dd (0)',FStream.ReadDWord());
    Log('dd (0)',FStream.ReadDWord());
    Log('dd (0)',FStream.ReadDWord());

    FSubMeshes:=FStream.ReadDWord();

    ReadTextures();

    Log(#13#10'SubMeshes',FSubMeshes);

    // can make one function with IFs when will understand fields
    if not ReadMeshInfo(FMeshVersion mod 20) then
    begin
      Log('!!!unknown type',FMeshVersion);
      exit;
    end;

    if FMeshVersion>20 then
      ReadModelDataType1()
    else
      ReadModelDataType0();

  end;

  Log('offset',HexStr(FStream.Position,8));
end;


procedure TRGMDL.LoadFromFile(fname:PAnsiChar);
begin
  if FStream<>nil then
  begin
    Clear;
    FStream.Free;
  end;

  FStream:=TMemoryStream.Create;
  TMemoryStream(FStream).LoadFromFile(fname);

  ReadMDLFile();

  FStream.Free;
  FStream:=nil;
end;


procedure TRGMDL.Init;
begin
  FStream:=nil;
  FTextures:=nil;
end;

procedure TRGMDL.Free;
begin
  FStream.Free;
  FStream:=nil;

  SetLength(FTextures,0);

  Clear;
end;

procedure TRGMDL.Clear;
begin
end;


procedure Trace(const fname:AnsiString);
var
  lmesh:TRGMDL;
begin
  lmesh.Init;
  lmesh.LoadFromFile(PAnsiChar(fname));
  lmesh.Free;

  RGLog.SaveToFile(ParamStr(1)+'.log');
end;

end.
