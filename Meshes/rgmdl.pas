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
    FVersion:integer;
{
    procedure ReadGeometryVertexElement;
    procedure ReadGeometryVertexDeclaration;
    procedure ReadGeometryVertexBuffer;
    procedure ReadGeometry;
    procedure ReadSubMesh;
    procedure ReadMeshLodLevel;
    procedure ReadSubmeshNameTable;
    procedure ReadEdgeGroup;
    procedure readEdgeListLodInfo;
    procedure ReadEdgeListLod;
    procedure ReadEdgeLists;
    procedure ReadPose;
    procedure ReadPoses;
    procedure ReadAnimationPoseKeyFrame;
    procedure ReadAnimationMorphKeyFrame;
    procedure ReadAnimationTrack;
    procedure ReadAnimation;
    procedure ReadAnimations;
    procedure ReadMesh;
}
    procedure ReadTextures;
    procedure ReadBlock5;
    procedure ReadBlock17(acnt:integer);
    procedure ReadBlock1B(acnt:integer);
    procedure ReadBlock1D(acnt:integer);

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
  Log('Textures',lcnt);
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

procedure TRGMDL.ReadBlock5;
var
  i,lcnt:integer;
begin
  lcnt:=FStream.ReadWord();
  if lcnt<>5 then Log('!!!group count<>5',lcnt);

  for i:=0 to lcnt-1 do
  begin
    Log('group #',i);
    Log('  [0]',FStream.ReadWord());
    Log('  [1]',FStream.ReadWord());
    Log('  [2]',FStream.ReadWord());
    Log('  [3] (offset?)',FStream.ReadDWord());
  end;
end;


procedure TRGMDL.ReadBlock1D(acnt:integer);
var
  i,j,lcnt,lcnt1:integer;
begin
  lcnt1:=118;// 13+16+5+10
  Log('size',lcnt1);

  for i:=0 to acnt-1 do
  begin
    Log('name',ReadText(FStream));
    Log('{00} w mesh #' ,FStream.ReadWord());
    Log('{01} w' ,FStream.ReadWord());
    Log('{02} w' ,FStream.ReadWord());
    Log('{03} w' ,FStream.ReadWord());
    Log('{04} w' ,FStream.ReadWord());
    Log('{05} w' ,FStream.ReadWord());
    Log('{06} w' ,FStream.ReadWord());
    Log('{07} w' ,FStream.ReadWord());
    Log('{08} w' ,FStream.ReadWord());
    Log('{09} w' ,FStream.ReadWord());
    Log('{10} w' ,FStream.ReadWord());
    Log('{11} w' ,FStream.ReadWord());
    Log('{12} w' ,FStream.ReadWord());

    Log('{00} w' ,FStream.ReadWord());
    Log('{01} w' ,FStream.ReadWord());
    Log('{02} w' ,FStream.ReadWord());
    Log('{03} w' ,FStream.ReadWord());
    Log('{04} w' ,FStream.ReadWord());
    Log('{05} w' ,FStream.ReadWord());
    Log('{06} w' ,FStream.ReadWord());
    Log('{07} w' ,FStream.ReadWord());
    Log('{08} w' ,FStream.ReadWord());
    Log('{09} w' ,FStream.ReadWord());
    Log('{10} w' ,FStream.ReadWord());
    Log('{11} w' ,FStream.ReadWord());
    Log('{12} w' ,FStream.ReadWord());
    Log('{13} w' ,FStream.ReadWord());
    Log('{14} w' ,FStream.ReadWord());
    Log('{15} w' ,FStream.ReadWord());

    Log('{00} f' ,FStream.ReadFloat());
    Log('{01} f' ,FStream.ReadFloat());
    Log('{02} f' ,FStream.ReadFloat());
    Log('{03} f' ,FStream.ReadFloat());
    Log('{04} f' ,FStream.ReadFloat());

    Log('>textures','');
    LogTexture(0,Integer(FStream.ReadDWord())); // base/diffuse
    LogTexture(1,Integer(FStream.ReadDWord()));
    LogTexture(2,Integer(FStream.ReadDWord())); // dark
    LogTexture(3,Integer(FStream.ReadDWord())); // pref
    LogTexture(4,Integer(FStream.ReadDWord())); // glow
    LogTexture(5,Integer(FStream.ReadDWord())); // normal
    LogTexture(6,Integer(FStream.ReadDWord()));
    LogTexture(7,Integer(FStream.ReadDWord()));
    LogTexture(8,Integer(FStream.ReadDWord())); // spec
    LogTexture(9,Integer(FStream.ReadDWord()));
  end;

  // M_GEOMETRY
  lcnt:=FStream.ReadWord(); // count of geometries?
  if lcnt<>1 then Log('!!!Before vertices is not 1',lcnt);
  // Vertices?
  lcnt:=FStream.ReadDWord(); // x*60 bytes (15 FLoat)
  for i:=0 to lcnt-1 do
  begin
    FStream.ReadFloat(); // X  18f
    FStream.ReadFloat(); // Y  193
    FStream.ReadFloat(); // Z  197

    FStream.ReadFloat(); // 19b
    FStream.ReadFloat(); // 19f
    FStream.ReadFloat(); // 1a3
    FStream.ReadFloat(); // 1a7
    FStream.ReadFloat(); // 1ab
    FStream.ReadFloat(); // 1af
    FStream.ReadFloat(); // 1b3
    FStream.ReadFloat(); // 1b7
    FStream.ReadFloat(); // 1bb
    FStream.ReadFloat(); // 1bf

    FStream.ReadFloat(); // U
    FStream.ReadFloat(); // V
  end;

  // M_SUBMESH?
  lcnt :=FStream.ReadDWord();
  for i:=0 to lcnt-1 do
  begin
    // Faces
    lcnt1:=FStream.ReadDWord();
    FStream.ReadDWord(); // mesh number
    for j:=0 to lcnt1-1 do
    begin
      FStream.ReadWord(); // X
      FStream.ReadWord(); // Y
      FStream.ReadWord(); // Z
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
    FStream.ReadDWord(); //??
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

// Differs from 1D just in mesh info size
procedure TRGMDL.ReadBlock1B(acnt:integer);
var
  i,j,lcnt,lcnt1:integer;
begin
  lcnt1:=104;// 10+14+5+9
  Log('size',lcnt1);

  for i:=0 to acnt-1 do
  begin
    Log('name',ReadText(FStream));
    Log('{00} w mesh #' ,FStream.ReadWord());
    Log('{01} w' ,FStream.ReadWord());
    Log('{02} w' ,FStream.ReadWord());
    Log('{03} w' ,FStream.ReadWord());
    Log('{04} w' ,FStream.ReadWord());
    Log('{05} w' ,FStream.ReadWord());
    Log('{06} w' ,FStream.ReadWord());
    Log('{07} w' ,FStream.ReadWord());
    Log('{08} w' ,FStream.ReadWord());
    Log('{09} w' ,FStream.ReadWord());

    Log('{00} w' ,FStream.ReadWord());
    Log('{01} w' ,FStream.ReadWord());
    Log('{02} w' ,FStream.ReadWord());
    Log('{03} w' ,FStream.ReadWord());
    Log('{04} w' ,FStream.ReadWord());
    Log('{05} w' ,FStream.ReadWord());
    Log('{06} w' ,FStream.ReadWord());
    Log('{07} w' ,FStream.ReadWord());
    Log('{08} w' ,FStream.ReadWord());
    Log('{09} w' ,FStream.ReadWord());
    Log('{10} w' ,FStream.ReadWord());
    Log('{11} w' ,FStream.ReadWord());
    Log('{12} w' ,FStream.ReadWord());
    Log('{13} w' ,FStream.ReadWord());

    Log('{00} f' ,FStream.ReadFloat());
    Log('{01} f' ,FStream.ReadFloat());
    Log('{02} f' ,FStream.ReadFloat());
    Log('{03} f' ,FStream.ReadFloat());
    Log('{04} f' ,FStream.ReadFloat());

    Log('>textures','');
    LogTexture(0,Integer(FStream.ReadDWord())); // base/diffuse
    LogTexture(1,Integer(FStream.ReadDWord()));
    LogTexture(2,Integer(FStream.ReadDWord()));
    LogTexture(3,Integer(FStream.ReadDWord()));
    LogTexture(4,Integer(FStream.ReadDWord())); // normal
    LogTexture(5,Integer(FStream.ReadDWord()));
    LogTexture(6,Integer(FStream.ReadDWord()));
    LogTexture(7,Integer(FStream.ReadDWord()));
    LogTexture(8,Integer(FStream.ReadDWord()));
  end;

  // M_GEOMETRY
  lcnt:=FStream.ReadWord(); // count of geometries?
  if lcnt<>1 then Log('!!!Before vertices is not 1',lcnt);
  // Vertices?
  lcnt:=FStream.ReadDWord(); // x*60 bytes (15 FLoat)
  for i:=0 to lcnt-1 do
  begin
    FStream.ReadFloat(); // X  18f
    FStream.ReadFloat(); // Y  193
    FStream.ReadFloat(); // Z  197

    FStream.ReadFloat(); // 19b
    FStream.ReadFloat(); // 19f
    FStream.ReadFloat(); // 1a3
    FStream.ReadFloat(); // 1a7
    FStream.ReadFloat(); // 1ab
    FStream.ReadFloat(); // 1af
    FStream.ReadFloat(); // 1b3
    FStream.ReadFloat(); // 1b7
    FStream.ReadFloat(); // 1bb
    FStream.ReadFloat(); // 1bf

    FStream.ReadFloat(); // U
    FStream.ReadFloat(); // V
  end;

  // M_SUBMESH?
  lcnt :=FStream.ReadDWord();
  for i:=0 to lcnt-1 do
  begin
    // Faces
    lcnt1:=FStream.ReadDWord();
    FStream.ReadDWord(); // mesh number
    for j:=0 to lcnt1-1 do
    begin
      FStream.ReadWord(); // X
      FStream.ReadWord(); // Y
      FStream.ReadWord(); // Z
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
    FStream.ReadDWord(); //??
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

// Differs from 1D just in mesh info size
procedure TRGMDL.ReadBlock17(acnt:integer);
var
  i,j,lcnt,lcnt1:integer;
begin
  lcnt1:=94;// 8+13+5+8
  Log('size',lcnt1);

  for i:=0 to acnt-1 do
  begin
    Log('name',ReadText(FStream));
    Log('{00} w mesh #' ,FStream.ReadWord());
    Log('{01} w' ,FStream.ReadWord());
    Log('{02} w' ,FStream.ReadWord());
    Log('{03} w' ,FStream.ReadWord());
    Log('{04} w' ,FStream.ReadWord());
    Log('{05} w' ,FStream.ReadWord());
    Log('{06} w' ,FStream.ReadWord());
    Log('{07} w' ,FStream.ReadWord());

    Log('{00} w' ,FStream.ReadWord());
    Log('{01} w' ,FStream.ReadWord());
    Log('{02} w' ,FStream.ReadWord());
    Log('{03} w' ,FStream.ReadWord());
    Log('{04} w' ,FStream.ReadWord());
    Log('{05} w' ,FStream.ReadWord());
    Log('{06} w' ,FStream.ReadWord());
    Log('{07} w' ,FStream.ReadWord());
    Log('{08} w' ,FStream.ReadWord());
    Log('{09} w' ,FStream.ReadWord());
    Log('{10} w' ,FStream.ReadWord());
    Log('{11} w' ,FStream.ReadWord());
    Log('{12} w' ,FStream.ReadWord());

    Log('{00} f' ,FStream.ReadFloat());
    Log('{01} f' ,FStream.ReadFloat());
    Log('{02} f' ,FStream.ReadFloat());
    Log('{03} f' ,FStream.ReadFloat());
    Log('{04} f' ,FStream.ReadFloat());

    Log('>textures','');
    LogTexture(0,Integer(FStream.ReadDWord())); // base/diffuse
    LogTexture(1,Integer(FStream.ReadDWord()));
    LogTexture(2,Integer(FStream.ReadDWord()));
    LogTexture(3,Integer(FStream.ReadDWord()));
    LogTexture(4,Integer(FStream.ReadDWord())); // normal
    LogTexture(5,Integer(FStream.ReadDWord()));
    LogTexture(6,Integer(FStream.ReadDWord()));
    LogTexture(7,Integer(FStream.ReadDWord()));
  end;

  // M_GEOMETRY
  lcnt:=FStream.ReadWord(); // count of geometries?
  if lcnt<>1 then Log('!!!Before vertices is not 1',lcnt);
  // Vertices?
  lcnt:=FStream.ReadDWord(); // x*60 bytes (15 FLoat)
  for i:=0 to lcnt-1 do
  begin
    FStream.ReadFloat(); // X  18f
    FStream.ReadFloat(); // Y  193
    FStream.ReadFloat(); // Z  197

    FStream.ReadFloat(); // 19b
    FStream.ReadFloat(); // 19f
    FStream.ReadFloat(); // 1a3
    FStream.ReadFloat(); // 1a7
    FStream.ReadFloat(); // 1ab
    FStream.ReadFloat(); // 1af
    FStream.ReadFloat(); // 1b3
    FStream.ReadFloat(); // 1b7
    FStream.ReadFloat(); // 1bb
    FStream.ReadFloat(); // 1bf

    FStream.ReadFloat(); // U
    FStream.ReadFloat(); // V
  end;

  // M_SUBMESH?
  lcnt :=FStream.ReadDWord();
  for i:=0 to lcnt-1 do
  begin
    // Faces
    lcnt1:=FStream.ReadDWord();
    FStream.ReadDWord(); // mesh number
    for j:=0 to lcnt1-1 do
    begin
      FStream.ReadWord(); // X
      FStream.ReadWord(); // Y
      FStream.ReadWord(); // Z
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
    FStream.ReadDWord(); //??
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


function TRGMDL.ReadMDLFile:boolean;
var
  lchunk:TOgreChunk;
  ls:AnsiString;
  i,lcnt,lcnt1,ltype:integer;
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
    ltype:=FStream.ReadWord();
    Log('type (models=29)',ltype);

    Log('first' ,FStream.ReadWord());
    Log('second',FStream.ReadWord());
    if ltype=14 then
      Log('add' ,FStream.ReadWord());

    ReadBlock5();
  
    Log('float (scale?)',FStream.ReadFloat());
    Log('dd (1)',FStream.ReadDWord());
    Log('dd (0)',FStream.ReadDWord());
    Log('dd (0)',FStream.ReadDWord());
    Log('dd (0)',FStream.ReadDWord());

    lcnt :=FStream.ReadDWord();
    ReadTextures();

    Log('Meshes',lcnt);
    case ltype of
      $01: lcnt1:=80 ;//  7+13+2+8
      $02: lcnt1:=92 ;//  7+13+5+8
      $03: lcnt1:=94 ;//  8+13+5+8
      $08: lcnt1:=114;// 10+17+5+10
      $09: lcnt1:=118;// 12+17+5+10
      $0E: lcnt1:=160;// 15+19+6+17
      $17:  begin
        ReadBlock17(lcnt);

        Log('offset',HexStr(FStream.Position,8));
        result:=true;
        exit;
      end;

      $1B:  begin
        ReadBlock1D(lcnt);

        Log('offset',HexStr(FStream.Position,8));
        result:=true;
        exit;
      end;

      $1D: begin
        ReadBlock1D(lcnt);

        Log('offset',HexStr(FStream.Position,8));
        result:=true;
        exit;
      end;

    else
      lcnt1:=0;
    end;

    Log('size',lcnt1);
    for i:=0 to lcnt-1 do
    begin
      Log('name',ReadText(FStream));
      Log('{00} w mesh #' ,FStream.ReadWord());
      Log('{01} w' ,FStream.ReadWord());
      Log('{02} w' ,FStream.ReadWord());
      Log('{03} w' ,FStream.ReadWord());
      Log('{04} w' ,FStream.ReadWord());
      Log('{05} w' ,FStream.ReadWord());
      Log('{06} w' ,FStream.ReadWord());
if not (ltype in [1,2]) then
      Log('{07} w' ,FStream.ReadWord());
if ltype in [8,9,14] then
begin
      Log('{08} w' ,FStream.ReadWord());
      Log('{09} w' ,FStream.ReadWord());
if not (ltype in [8]) then
begin
      Log('{10} w' ,FStream.ReadWord());
      Log('{11} w' ,FStream.ReadWord());
if ltype<>9 then
      Log('{12} w' ,FStream.ReadWord());
end;
if ltype=14 then
begin
      Log('{13} w' ,FStream.ReadWord());
      Log('{14} w' ,FStream.ReadWord());
end;
end;
      Log('{00} w' ,FStream.ReadWord());
      Log('{01} w' ,FStream.ReadWord());
      Log('{02} w' ,FStream.ReadWord());
      Log('{03} w' ,FStream.ReadWord());
      Log('{04} w' ,FStream.ReadWord());
      Log('{05} w' ,FStream.ReadWord());
      Log('{06} w' ,FStream.ReadWord());
      Log('{07} w' ,FStream.ReadWord());
      Log('{08} w' ,FStream.ReadWord());
      Log('{09} w' ,FStream.ReadWord());
      Log('{10} w' ,FStream.ReadWord());
      Log('{11} w' ,FStream.ReadWord());
      Log('{12} w' ,FStream.ReadWord());
if ltype in [8,9,14] then
begin
      Log('{13} w' ,FStream.ReadWord());
      Log('{14} w' ,FStream.ReadWord());
      Log('{15} w' ,FStream.ReadWord());
if (ltype in [8,9]) then
      Log('{16} w' ,FStream.ReadWord());
if ltype=14 then
begin
      Log('{16} w' ,FStream.ReadWord());
      Log('{17} w' ,FStream.ReadWord());
      Log('{18} w' ,FStream.ReadWord());
end;
end;
      Log('{00} f' ,FStream.ReadFloat());
      Log('{01} f' ,FStream.ReadFloat());
if ltype<>1 then
begin
      Log('{02} f' ,FStream.ReadFloat());
      Log('{03} f' ,FStream.ReadFloat());
      Log('{04} f' ,FStream.ReadFloat());
end;
if ltype=14 then
begin
      Log('{05} f' ,FStream.ReadFloat());
end;
      Log('>textures','');
      LogTexture(0,Integer(FStream.ReadDWord())); // base/diffuse
      LogTexture(1,Integer(FStream.ReadDWord()));
      LogTexture(2,Integer(FStream.ReadDWord())); // 1D - dark
      LogTexture(3,Integer(FStream.ReadDWord())); // 1D - pref, 1,2 - glow?
      LogTexture(4,Integer(FStream.ReadDWord())); // 17,1B - normal, 1D - glow
      LogTexture(5,Integer(FStream.ReadDWord())); // 1D - normal
      LogTexture(6,Integer(FStream.ReadDWord()));
      LogTexture(7,Integer(FStream.ReadDWord()));
if ltype in [8,9,14] then
begin
      LogTexture(8,Integer(FStream.ReadDWord())); // 1D - spec
      LogTexture(9,Integer(FStream.ReadDWord()));
if ltype=14 then
begin
      LogTexture(10,Integer(FStream.ReadDWord()));
      LogTexture(11,Integer(FStream.ReadDWord()));
      LogTexture(12,Integer(FStream.ReadDWord()));
      LogTexture(13,Integer(FStream.ReadDWord()));
      LogTexture(14,Integer(FStream.ReadDWord()));
      LogTexture(15,Integer(FStream.ReadDWord()));
      LogTexture(16,Integer(FStream.ReadDWord()));
end;
end;
    end;
  end;

  Log('offset',HexStr(FStream.Position,8));
  result:=true;
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
