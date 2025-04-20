{TODO: check when 2nd UV block in type0}
unit RGMDL;

interface

uses
  Classes,
  SysUtils,
  rgglobal,
  rgstream,
  RGMesh;

type
  TFacePoint = record
    X:integer;
    Y:integer;
    Z:integer;
  end;
type
  TSubMeshInfo = record
    ofsface :integer;
    numface :integer;
    material:integer;
  end;
  TMaterial = record
    name   :string;
  end;
  TBone = record
    vertex:integer;
    bone  :integer;
    weight:single;
  end;
type
  TRGMDL = object
  public
    FStream:TStream;
    FName:string;

    FVertexCount:integer;
    FVersion:integer;

    FTextures : array of string;
    FVertices : array of TVector3;
    FNormals  : array of TVector3;
    FFaces    : array of TFacePoint;
    FUVs      : array of TVector2;
    FSubMeshes: array of TSubMeshInfo;
    FMaterials: array of TMaterial;
    FBones    : array of TBone;

    FAddBlock:integer;

    procedure ReadTextures;
    function ReadBlockX5:integer;

    function  ReadMaterialInfo(aver:integer):boolean;
    procedure ReadModelDataType0();
    procedure ReadModelDataType1();

  public
    function  ReadMDLFile:boolean;

    procedure Init;
    procedure Free;
    procedure Clear;
    function  LoadFromFile(aname:PAnsiChar):boolean;
    procedure SaveToXML(const aStream:TStream);
    procedure SaveToXML(const aFileName:String);
    procedure SaveToOBJ(const aStream:TStream);
    procedure SaveToOBJ(const aFileName:String);
    procedure SaveMaterial(const aFileName:String);
  end;


implementation


procedure TRGMDL.SaveMaterial(const aFileName:String);
var
  sl:TStringList;
  i:integer;
begin
  sl:=TStringList.Create;
  try

    for i:=0 to High(FMaterials) do
    begin
      sl.Add('material '+FMaterials[i].name);
      sl.Add('{');
      sl.Add('  technique');
      sl.Add('  {');
      sl.Add('    pass');
      sl.Add('    {');
//      sl.Add('      ambient 0.588235 0.588235 0.588235');
//      sl.Add('      diffuse 0.588235 0.588235 0.588235');
//      sl.Add('      specular 0 0 0 0');
//      sl.Add('      emissive 0 0 0');
      sl.Add('      texture_unit');
      sl.Add('      {');
//      sl.Add('        texture '+FTextures[]);
      sl.Add('      }');
      sl.Add('    }');
      sl.Add('  }');
      sl.Add('}');
    end;

    sl.SaveToFile(aFileName);
  finally
    FreeAndNil(sl);
  end;
end;

procedure TRGMDL.SaveToXML(const aStream:TStream);

  procedure WriteLine(const aString:UTF8String);
  const
    NewLine:array[0..1] of AnsiChar=(#13,#10);
  begin
    if length(aString)>0 then
      aStream.WriteBuffer(aString[1],length(aString));

    aStream.WriteBuffer(NewLine[0],SizeOf(NewLine));
  end;

  function FloatToStr(const aValue:single):UTF8String;
  begin
    Str(aValue:0:12,result);
  end;

var
  i,j,lofs:integer;
begin
  WriteLine('<mesh>');

  WriteLine('<sharedgeometry vertexcount="'+IntToStr(FVertexCount)+'">');

  WriteLine('<vertexbuffer positions="true" normals="true" texture_coord_dimensions_0="2" texture_coords="1">');
  for i:=0 to FVertexCount-1 do
  begin
    WriteLine('<vertex>');

    WriteLine(
      '<position x="'+FloatToStr(FVertices[i].x)+
              '" y="'+FloatToStr(FVertices[i].y)+
              '" z="'+FloatToStr(FVertices[i].z)+'" />');

    WriteLine(
      '<normal x="'+FloatToStr(FNormals[i].x)+
            '" y="'+FloatToStr(FNormals[i].y)+
            '" z="'+FloatToStr(FNormals[i].z)+'" />');

    WriteLine(
      '<texcoord u="'+FloatToStr(FNormals[i].x)+
              '" v="'+FloatToStr(FNormals[i].y)+'" />');

    WriteLine('</vertex>');
  end;
  WriteLine('</vertexbuffer>');

  WriteLine('</sharedgeometry>');

  WriteLine('<submeshes>');
  for i:=0 to High(FSubMeshes) do
  begin
    if FSubMeshes[i].numface=0 then continue;


    WriteLine('<submesh material="'+FMaterials[FSubMeshes[i].material].name+
        '" usesharedvertices="true" use32bitindexes="true" operationtype="triangle_list">');

    WriteLine('<faces count="'+IntToStr(FSubMeshes[i].numface)+'">');

    lofs:=FSubMeshes[i].ofsface;
    for j:=0 to FSubMeshes[i].numface-1 do
    begin
      WriteLine(
        '<face v1="'+(IntToStr(FFaces[lofs+j].X))+
            '" v2="'+(IntToStr(FFaces[lofs+j].Y))+
            '" v3="'+(IntToStr(FFaces[lofs+j].Z))+'" />');
    end;
    
    WriteLine('</faces>');
    WriteLine('</submesh>');
  end;
  WriteLine('</submeshes>');

  if Length(FBones)>0 then
  begin
    WriteLine('<boneassignments>');
    for i:=0 to High(FBones) do
      WriteLine('<vertexboneassignment vertexindex="'+IntToStr(FBones[i].vertex)+
        '" boneindex="'+IntToStr(FBones[i].bone)+'" weight="'+FloatToStr(FBones[i].weight)+'" />');
    WriteLine('</boneassignments>');
  end;

  WriteLine('</mesh>');
end;

procedure TRGMDL.SaveToXML(const aFileName:String);
var
  lStream:TFileStream;
begin
  lStream:=TFileStream.Create(aFileName,fmCreate);
  try
    SaveToXML(lStream);
  finally
    FreeAndNil(lStream);
  end;
end;

procedure TRGMDL.SaveToOBJ(const aStream:TStream);

  procedure WriteLine(const aString:UTF8String);
  const
    NewLine:array[0..1] of AnsiChar=(#13,#10);
  begin
    if length(aString)>0 then
      aStream.WriteBuffer(aString[1],length(aString));

    aStream.WriteBuffer(NewLine[0],SizeOf(NewLine));
  end;

  function FloatToStr(const aValue:single):UTF8String;
  begin
    Str(aValue:0:12,result);
  end;

var
  i,j,lofs:integer;
begin
  if Length(FTextures)>0 then
  begin
    WriteLine('mtllib '+FName+'.mtl');
    for i:=0 to High(FTextures) do
    begin
    end;
  end;

  WriteLine('o Mesh');
  for i:=0 to FVertexCount-1 do
  begin
    WriteLine('v '+
      FloatToStr(FVertices[i].x)+' '+
      FloatToStr(FVertices[i].y)+' '+
      FloatToStr(FVertices[i].z));
  end;

  WriteLine('');

  for i:=0 to FVertexCount-1 do
  begin
    WriteLine('vn '+
      FloatToStr(FNormals[i].x)+' '+
      FloatToStr(FNormals[i].y)+' '+
      FloatToStr(FNormals[i].z));
  end;

  WriteLine('');

  for i:=0 to FVertexCount-1 do
  begin
    WriteLine('vt '+
      FloatToStr(FUVs[i].x)+' '+
      FloatToStr(FUVs[i].y));
  end;

  for i:=0 to High(FSubMeshes) do
  begin
    WriteLine('');
    WriteLine('g '+FMaterials[FSubMeshes[i].material].name);

    if FSubMeshes[i].numface>0 then
    begin
      WriteLine('usemtl '+FMaterials[FSubMeshes[i].material].name{FTextures[0]});

      lofs:=FSubMeshes[i].ofsface;
      for j:=0 to FSubMeshes[i].numface-1 do
      begin
      WriteLine('f '+
        (IntToStr(FFaces[lofs+j].X+1))+' '+
        (IntToStr(FFaces[lofs+j].Y+1))+' '+
        (IntToStr(FFaces[lofs+j].Z+1)));
      end;
    end;
  end;
  
end;

procedure TRGMDL.SaveToOBJ(const aFileName:String);
var
  lStream:TFileStream;
begin
  lStream:=TFileStream.Create(aFileName,fmCreate);
  try
    SaveToOBJ(lStream);
  finally
    FreeAndNil(lStream);
  end;
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

function TRGMDL.ReadBlockX5:integer;
var
  i:integer;
begin
  result:=FStream.ReadWord();
  Log('>groups (always same values, 5 [default] or 6 times)',result);
  for i:=0 to result-1 do
  begin
    Log('group #',i);
    Log('  w[0]',FStream.ReadWord());
    Log('  w[1]',FStream.ReadWord());
    Log('  w[2]',FStream.ReadWord());
    Log('  w[3]',FStream.ReadWord());
    Log('  w[4]',FStream.ReadWord());
  end;
end;

procedure TRGMDL.ReadModelDataType0();
var
  i,j,lface,lcnt,lcnt1:integer;
  lbuf:array of TVector3;
  ltex:array of TVector2;
  lidx:array of integer;
begin
  lbuf:=nil;

  lcnt:=FStream.ReadWord();  // 0001
  if lcnt<>1 then Log('!!!Before vertices is not 1',lcnt);

  Log(#13#10'float x',FStream.ReadFloat());
  Log('float y',FStream.ReadFloat());
  Log('float z',FStream.ReadFloat());

  //===== Vertices =====

  FVertexCount:=FStream.ReadDword();
  Log(#13#10'vertexCount',FVertexCount);
  SetLength(lidx,FVertexCount); // index array, one for all other blocks

  SetLength(FVertices,FVertexCount);

  Log(HexStr(FStream.Position,8),'Vertex index');
  FStream.Read(lidx[0],FVertexCount*4);

  lcnt:=FStream.ReadDword();
  Log(HexStr(FStream.Position,8),IntToStr(lcnt)+' unique vertices');

  SetLength(lbuf,lcnt);
  FStream.Read(lbuf[0],lcnt*SizeOf(TVector3));

  for i:=0 to FVertexCount-1 do
  begin
    FVertices[i].X:=lbuf[lidx[i]].X;
    FVertices[i].Y:=lbuf[lidx[i]].Y;
    FVertices[i].Z:=lbuf[lidx[i]].Z;
  end;

  if FVersion=$0E then
  begin
    lcnt:=FStream.ReadDword(); // usually, same as for vertices
    Log(HexStr(FStream.Position,8),IntToStr(lcnt)+' (unique) 6x floats');

    FStream.Seek(lcnt*6*SizeOf(single),soFromCurrent);
  end;

  //===== Texture =====

  lcnt:=FStream.ReadWord();  // 0001
  if lcnt<>1 then Log('!!!Before UVs is not 1',lcnt);

  SetLength(FUVs,FVertexCount);

  Log(#13#10+HexStr(FStream.Position,8),'UV index');
  FStream.Read(lidx[0],FVertexCount*4);

  lcnt:=FStream.ReadDword();
  Log(HexStr(FStream.Position,8),IntToStr(lcnt)+' unique UVs');

  SetLength(ltex,lcnt);
  FStream.Read(ltex[0],lcnt*SizeOf(TVector2));

  for i:=0 to FVertexCount-1 do
  begin
    FUVs[i].X:=ltex[lidx[i]].X;
    FUVs[i].Y:=ltex[lidx[i]].Y;
  end;

  //===== 2nd Texture =====

  //!!!!! CHEAT
  if (FVersion=$0E) and (FAddBlock>5) then
  begin
    Log(#13#10+HexStr(FStream.Position,8),'UV-2 index');
    FStream.Read(lidx[0],FVertexCount*4);

    lcnt:=FStream.ReadDword();
    Log(HexStr(FStream.Position,8),IntToStr(lcnt)+' unique 2nd UVs');

    if lcnt<>Length(ltex) then
    begin
      SetLength(ltex,0);
      SetLength(ltex,lcnt);
    end;
    FStream.Read(ltex[0],lcnt*SizeOf(TVector2));
{
    for i:=0 to FVertexCount-1 do
    begin
      FUVs[i].X:=ltex[lidx[i]].X;
      FUVs[i].Y:=ltex[lidx[i]].Y;
    end;
}
  end;

  SetLength(ltex,0);

  //===== Normals =====

  lcnt:=FStream.ReadWord();  // 0001
  if lcnt<>1 then Log('!!!Before normals is not 1',lcnt);
  
  // normals?

  SetLength(FNormals,FVertexCount);

  Log(#13#10+HexStr(FStream.Position,8),'3x float (normals) index');
  FStream.Read(lidx[0],FVertexCount*4);

  lcnt:=FStream.ReadDword();
  Log(HexStr(FStream.Position,8),IntToStr(lcnt)+' unique 3x floats (normals)');

  if lcnt<>Length(lbuf) then
  begin
    SetLength(lbuf,0);
    SetLength(lbuf,lcnt);
  end;
  FStream.Read(lbuf[0],lcnt*SizeOf(TVector3));
  for i:=0 to FVertexCount-1 do
  begin
    FNormals[i].X:=lbuf[lidx[i]].X;
    FNormals[i].Y:=lbuf[lidx[i]].Y;
    FNormals[i].Z:=lbuf[lidx[i]].Z;
  end;

  //=====  Unknown =====

  Log(#13#10'dword (0)',FStream.ReadDWord());
  Log(      'dword (0)',FStream.ReadDWord());

  // ===== Faces =====

  i:=FStream.ReadDWord();        // total items
  SetLength(FFaces,i);

  lcnt:=FStream.ReadDWord();     // total submeshes
  SetLength(FSubMeshes,lcnt);
  
  Log(#13#10'Faces, '+IntToStr(i)+' items in '+IntToStr(lcnt)+' submesh[es]','');

  lface:=0;
  for i:=0 to lcnt-1 do
  begin
    j    :=FStream.ReadWord();   // material #
    lcnt1:=FStream.ReadDWord();  // submesh items count
    FSubMeshes[i].ofsface :=lface;
    FSubMeshes[i].numface :=lcnt1;
    FSubMeshes[i].material:=j;
    Log('Submesh '+IntToStr(i)+', material '+FMaterials[j].name+
        ', faces '+IntToStr(lcnt1)+' offset',HexStr(FStream.Position,8));

    for j:=0 to lcnt1-1 do
    begin
      FFaces[lface+j].X:=FStream.ReadDWord();
      FFaces[lface+j].Y:=FStream.ReadDWord();
      FFaces[lface+j].Z:=FStream.ReadDWord();
    end;

    inc(lface,lcnt1);
  end;

  SetLength(lidx,0);
  SetLength(lbuf,0);
end;

procedure TRGMDL.ReadModelDataType1();
var
  ls:string;
  i,j,lcnt,lcnt1:integer;
  lface,lpos:integer;
begin
  // M_GEOMETRY
  lcnt:=FStream.ReadWord(); // count of geometries?
  if lcnt<>1 then Log('!!!Before vertices is not 1',lcnt);

  FVertexCount:=FStream.ReadDWord(); // Vertices, x*60 bytes (15 FLoat)
  SetLength(FVertices,FVertexCount);
  SetLength(FNormals ,FVertexCount);
  SetLength(FUVs     ,FVertexCount);
  Log(#13#10'Vertices '+IntToStr(FVertexCount)+' x60 offset',HexStr(FStream.Position,8));
  for i:=0 to FVertexCount-1 do
  begin
    FVertices[i].X:=FStream.ReadFloat();    // X
    FVertices[i].Y:=FStream.ReadFloat();    // Y
    FVertices[i].Z:=FStream.ReadFloat();    // Z

    FStream.ReadFloat();
    FStream.ReadFloat();
    FStream.ReadFloat();
    FStream.ReadFloat();
    FStream.ReadFloat();
    FStream.ReadFloat();
    FStream.ReadFloat();

    FNormals[i].X:=FStream.ReadFloat();     // NX
    FNormals[i].Y:=FStream.ReadFloat();     // NY
    FNormals[i].Z:=FStream.ReadFloat();     // NZ

    FUVs[i].X:=FStream.ReadFloat();         // U
    FUVs[i].Y:=FStream.ReadFloat();         // V
  end;

  // M_SUBMESH
  lcnt :=FStream.ReadDWord();    // submeshes
  SetLength(FSubMeshes,lcnt);
  Log(#13#10'SubMeshes',lcnt);

  // calc total faces
  lface:=0;
  lpos:=FStream.Position;
  for i:=0 to lcnt-1 do
  begin
    lcnt1:=FStream.ReadDWord();
    inc(lface,lcnt1);
    if i<>(lcnt-1) then FStream.Seek((lcnt1*3*2)+4,soFromCurrent);
  end;
  FStream.Position:=lpos;
  SetLength(FFaces,lface);

  lface:=0;
  for i:=0 to lcnt-1 do
  begin
    lcnt1:=FStream.ReadDWord();  // Faces
    j:=FStream.ReadDWord();      // material number
    FSubMeshes[i].ofsface :=lface;
    FSubMeshes[i].numface :=lcnt1;
    FSubMeshes[i].material:=j;

    Log('Submesh '+IntToStr(i)+', material '+FMaterials[j].name+
        ', faces '+IntToStr(lcnt1)+' offset',HexStr(FStream.Position,8));
    for j:=0 to lcnt1-1 do
    begin
      FFaces[lface+j].X:=FStream.ReadWord();
      FFaces[lface+j].Y:=FStream.ReadWord();
      FFaces[lface+j].Z:=FStream.ReadWord();
    end;
    inc(lface,lcnt1);
  end;

  // M_MESH_BOUNDS?
  Log(#13#10'minx',FStream.ReadFloat());
  Log('miny',FStream.ReadFloat());
  Log('minz',FStream.ReadFloat());
  Log('maxx',FStream.ReadFloat());
  Log('maxy',FStream.ReadFloat());
  Log('maxz',FStream.ReadFloat());

  // M_MESH_SKELETON_LINK
  ls:=ReadText(FStream);
  if ls<>'' then Log(#13#10'skeletonName',ls);

//?? M_MESH_BONE_ASSIGNMENT
  lcnt:=FStream.ReadDWord();
  if lcnt>0 then
  begin
    SetLength(FBones,lcnt);
    Log(IntToStr(lcnt)+' (Bones vertices ?) offset',HexStr(FStream.Position,8));
    Log('(bones ?) count',FStream.ReadDWord()); //?? Bones? (limit for boneIndex)
    for i:=0 to lcnt-1 do
    begin
      FBones[i].vertex:=FStream.ReadDword(); // vertextIndex
      FBones[i].bone  :=FStream.ReadDWord(); // boneIndex
      FBones[i].weight:=FStream.ReadFloat(); // weight
    end;
  end;
end;

//----- ReadMeshInfo -----

function TRGMDL.ReadMaterialInfo(aver:integer):boolean;

  procedure LogTexture(const descr:AnsiString; idx:integer);
  var
    ls:AnsiString;
  begin
    if idx>=0 then ls:=FTextures[idx] else ls:='';
    Log('{'+descr+'} = '+IntToStr(idx),ls);
  end;

var
  i,ltmp:integer;
begin
  if not (aver in [$01,$02,$03, $07,$08,$09, $0E]) then exit(false);

  SetLength(FMaterials,FStream.ReadDWord());
  Log(#13#10'Materials',Length(FMaterials));

  ReadTextures();

  for i:=0 to High(FMaterials) do
  begin
    FMaterials[i].name:=ReadText(FStream);
    Log(#13#10'name',FMaterials[i].name); // material name

    ltmp:=FStream.ReadWord();
    Log('{00} w material #?'      ,ltmp);
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
    Log('>colors?','');
    Log('{00} w' ,Int16(FStream.ReadWord()));

    if aver>=7 then
      Log('{7+ 1} w' ,Int16(FStream.ReadWord()));

    if aver>=14 then
    begin
      Log('{14+ 1} w' ,Int16(FStream.ReadWord()));
      Log('{14+ 2} w' ,Int16(FStream.ReadWord()));
    end;

    Log(#13#10'{02} w' ,Int16(FStream.ReadWord()));
    Log('{03} w' ,Int16(FStream.ReadWord()));
    Log('{04} w' ,Int16(FStream.ReadWord()));

    Log(#13#10'{05} w' ,Int16(FStream.ReadWord()));
    Log('{06} w' ,Int16(FStream.ReadWord()));
    Log('{07} w' ,Int16(FStream.ReadWord()));

    Log(#13#10'{08} w' ,Int16(FStream.ReadWord()));
    Log('{09} w' ,Int16(FStream.ReadWord()));
    Log('{10} w' ,Int16(FStream.ReadWord()));

    Log(#13#10'{11} w' ,Int16(FStream.ReadWord()));
    Log('{12} w' ,Int16(FStream.ReadWord()));
    Log('{13} w' ,Int16(FStream.ReadWord()));

    if aver>=8 then
    begin
      Log(#13#10'{8+ 14} w' ,FStream.ReadWord());
      Log('{8+ 15} w' ,FStream.ReadWord());
      Log('{8+ 16} w' ,FStream.ReadWord());
    end;
    //--------------------------------
    Log('>values','');
    Log('{00} f' ,FStream.ReadFloat());
    Log('{01} f' ,FStream.ReadFloat());
    if aver>=2 then
    begin
      Log('{02} f' ,FStream.ReadFloat());
      Log('{03} f' ,FStream.ReadFloat());
      Log('{04} f' ,FStream.ReadFloat());
    end;
    if aver>=14 then
      Log('{05} f' ,FStream.ReadFloat()); // brightness?
    //--------------------------------
    Log('>textures','');
    if aver>=14 then
    begin
      LogTexture('14 00',Int32(FStream.ReadDWord()));      // 10 14+ normals
      LogTexture('14 01',Int32(FStream.ReadDWord()));      // 11 14+
      LogTexture('14 02',Int32(FStream.ReadDWord()));      // 12 14+
      LogTexture('14 03',Int32(FStream.ReadDWord()));      // 13 14+
      LogTexture('14 04',Int32(FStream.ReadDWord()));      // 14 14+
    end;
    LogTexture('base',Int32(FStream.ReadDWord()));         // 00 base/diffuse
    LogTexture('??  ',Int32(FStream.ReadDWord()));           // 01 ??
    if aver>=8 then
      LogTexture('8 env dark',Int32(FStream.ReadDWord())); // 09 8+ environment dark (ambient)
    LogTexture('env ',Int32(FStream.ReadDWord()));       // 02 environment "ref"
    LogTexture('glow',Int32(FStream.ReadDWord()));       // 03 glow
    LogTexture('norm',Int32(FStream.ReadDWord()));       // 04 normal
    LogTexture('   5',Int32(FStream.ReadDWord()));       // 05
    LogTexture('   6',Int32(FStream.ReadDWord()));       // 06
    LogTexture('spec',Int32(FStream.ReadDWord()));       // 07 specular / surface?
    if aver>=7 then
      LogTexture('??7+',Int32(FStream.ReadDWord()));         // 08 7+
    if aver>=14 then
    begin
      LogTexture('14 paint  ',Int32(FStream.ReadDWord())); // 15 14+ paint
      LogTexture('14 surface',Int32(FStream.ReadDWord())); // 16 14+ paint surface
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
    FVersion:=FStream.ReadWord();
    Log('type ',FVersion);

    Log('first (1)' ,FStream.ReadWord());
    Log('second (0)',FStream.ReadWord());
    if FVersion=14 then // type=$0E - RGO
      Log('v.0E add (1)' ,FStream.ReadWord());

    FAddBlock:=ReadBlockX5();
  
    Log('float (scale?)',FStream.ReadFloat());
    Log('dd (1)',FStream.ReadDWord());
    Log('dd (0)',FStream.ReadDWord());
    Log('dd (0)',FStream.ReadDWord()); // 4 for VIRAX 
    Log('dd (0)',FStream.ReadDWord());

    if not ReadMaterialInfo(FVersion mod 20) then
    begin
      Log('!!!unknown type',FVersion);
      exit;
    end;

    if FVersion>20 then
      ReadModelDataType1()
    else
      ReadModelDataType0();

    result:=true;
  end;

  Log('offset',HexStr(FStream.Position,8));
end;


function TRGMDL.LoadFromFile(aname:PAnsiChar):boolean;
begin
  if FStream<>nil then
  begin
    Clear;
    FStream.Free;
  end;
  FName:=ExtractNameOnly(aname);

  FStream:=TMemoryStream.Create;
  TMemoryStream(FStream).LoadFromFile(aname);

  result:=ReadMDLFile();

  FStream.Free;
  FStream:=nil;
end;


procedure TRGMDL.Init;
begin
  FStream:=nil;

  FMaterials:=nil;
  FTextures :=nil;
  FVertices :=nil;
  FNormals  :=nil;
  FFaces    :=nil;
  FUVs      :=nil;
  FSubMeshes:=nil;
  FBones    :=nil;

end;

procedure TRGMDL.Free;
begin
  FStream.Free;
  FStream:=nil;

  Clear;
end;

procedure TRGMDL.Clear;
begin
  SetLength(FTextures ,0);
  SetLength(FMaterials,0);
  SetLength(FSubMeshes,0);
  SetLength(FVertices ,0);
  SetLength(FNormals  ,0);
  SetLength(FFaces    ,0);
  SetLength(FUVs      ,0);
  SetLength(FBones    ,0);
end;

{
procedure Trace(const fname:AnsiString);
var
  lmesh:TRGMDL;
begin
  lmesh.Init;
  lmesh.LoadFromFile(PAnsiChar(fname));
  lmesh.SaveToObj(fname+'.obj');
  lmesh.Free;

  RGLog.SaveToFile(ParamStr(1)+'.log');
end;
}
end.
