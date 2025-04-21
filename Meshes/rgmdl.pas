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
  TRGB = record // byte used, word is in file
    R:word;
    G:word;
    B:word;
  end;
type
  TSubMeshInfo = record
    ofsface :integer;
    numface :integer;
    material:integer;
  end;
  PMaterial = ^TMaterial;
  TMaterial = record
    name   :string;
    ambient :TRGB;
    diffuse :TRGB;
    specular:TRGB;
    emissive:TRGB;
    add     :TRGB;
    textures:array [0..16] of integer;
  end;
  TBone = record
    vertex:integer;
    bone  :integer;
    weight:single;
  end;
  TDataCatalog = record
    _map   :int16; // 0 always
    _size  :int16; // 1 - 8 bytes; 2 - 12 bytes; 3 - 16 bytes
    _type  :int16; // 1 - vertex; 9 - ?; 8 - ?; 4 - normals; 7 - UVs
    _offset:int16; // see Block1 (20+ format data)
    _number:int16; // for UV v.0E atm. like #
  end;
type
  TRGMDL = object
  public
    FStream:TStream;
    FName:string;

    FVersion:integer;

    FVertexCount:integer;
    FVertices : array of TVector3;
    FNormals  : array of TVector3;
    FUVs      : array of TVector2;

    FFaces    : array of TFacePoint;
    FSubMeshes: array of TSubMeshInfo;

    FTextures : array of string;
    FMaterials: array of TMaterial;

    FSkeleton : string;
    FBones    : array of TBone;
    FBounds   : record
      minx:single;
      miny:single;
      minz:single;
      maxx:single;
      maxy:single;
      maxz:single;
    end;

    FAddBlock:integer;

    procedure ReadTextures;
    function ReadDataCatalog:integer;

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

    function GetMaterial():string;
  end;


implementation

const
  // texture indexes
  txtBase         = 5;
  //
  txtEnvDiffuse   = 7;
  txtEndSpecualar = 8;
  txtGlow         = 9;
  txtNormal       = 10;
  //
  //
  txtSpecular     = 13;
  //
  txtPaint        = 15;
  txtPaintSurface = 16;


function RGBToFloat(const aval:TRGB):string;
var
  lr,lg,lb:string;
begin
  if aval.R=0 then lr:='0' else if aval.R=255 then lr:='1' else Str(aval.R/255:0:6,lr);
  if aval.G=0 then lg:='0' else if aval.G=255 then lg:='1' else Str(aval.G/255:0:6,lg);
  if aval.B=0 then lb:='0' else if aval.B=255 then lb:='1' else Str(aval.B/255:0:6,lb);
  result:=lr+' '+lg+' '+lb;
end;

function TRGMDL.GetMaterial():string;
var
  sl:TStringList;
  ls:string;
  i,j:integer;
begin
  result:='';
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
      sl.Add('      ambient  '+RGBToFloat(FMaterials[i].ambient));
      sl.Add('      diffuse ' +RGBToFloat(FMaterials[i].diffuse));
      sl.Add('      specular '+RGBToFloat(FMaterials[i].specular));
      sl.Add('      emissive '+RGBToFloat(FMaterials[i].emissive));
      // animation (duration requires)
      ls:='';
      for j:=0 to 4 do
        if FMaterials[i].textures[j]>=0 then
          ls:=ls+' '+FTextures[FMaterials[i].textures[j]]
        else
          break;
      if ls<>'' then
      begin    
        sl.Add('');
        sl.Add('      texture_unit');
        sl.Add('      {');
        sl.Add('        anim texture'+ls);
        sl.Add('      }');
      end;
      for j:=5 to 16 do
      begin
        if FMaterials[i].textures[j]>=0 then
        begin
          sl.Add('');
          sl.Add('      texture_unit');
          sl.Add('      {');
          sl.Add('        texture '+FTextures[FMaterials[i].textures[j]]);
          sl.Add('      }');
        end;
      end;
      sl.Add('    }');
      sl.Add('  }');
      sl.Add('}');
    end;

    result:=sl.Text;
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
    Str(aValue:0:6,result);
  end;

var
  i,j,lofs:integer;
begin
  WriteLine('<mesh>');

  WriteLine('  <sharedgeometry vertexcount="'+IntToStr(FVertexCount)+'">');

  WriteLine('    <vertexbuffer positions="true" normals="true" texture_coord_dimensions_0="2" texture_coords="1">');
  for i:=0 to FVertexCount-1 do
  begin
    WriteLine('      <vertex>');

    WriteLine('        <position'+
         ' x="'+FloatToStr(FVertices[i].x)+
        '" y="'+FloatToStr(FVertices[i].y)+
        '" z="'+FloatToStr(FVertices[i].z)+'" />');

    WriteLine('        <normal'+
         ' x="'+FloatToStr(FNormals[i].x)+
        '" y="'+FloatToStr(FNormals[i].y)+
        '" z="'+FloatToStr(FNormals[i].z)+'" />');

    WriteLine('        <texcoord'+
         ' u="'+FloatToStr(FNormals[i].x)+
        '" v="'+FloatToStr(FNormals[i].y)+'" />');

    WriteLine('      </vertex>');
  end;
  WriteLine('    </vertexbuffer>');

  WriteLine('  </sharedgeometry>');

  WriteLine('  <submeshes>');
  for i:=0 to High(FSubMeshes) do
  begin
    if FSubMeshes[i].numface=0 then continue;


    WriteLine('    <submesh material="'+FMaterials[FSubMeshes[i].material].name+
        '" usesharedvertices="true" use32bitindexes="true" operationtype="triangle_list">');

    WriteLine('      <faces count="'+IntToStr(FSubMeshes[i].numface)+'">');

    lofs:=FSubMeshes[i].ofsface;
    for j:=0 to FSubMeshes[i].numface-1 do
    begin
      WriteLine('        <face'+
         ' v1="'+(IntToStr(FFaces[lofs+j].X))+
        '" v2="'+(IntToStr(FFaces[lofs+j].Y))+
        '" v3="'+(IntToStr(FFaces[lofs+j].Z))+'" />');
    end;
    
    WriteLine('      </faces>');
    WriteLine('    </submesh>');
  end;
  WriteLine('  </submeshes>');

  if Length(FBones)>0 then
  begin
    WriteLine('  <boneassignments>');
    for i:=0 to High(FBones) do
      WriteLine('    <vertexboneassignment'+
         ' vertexindex="'+IntToStr  (FBones[i].vertex)+
        '" boneindex="'  +IntToStr  (FBones[i].bone)+
        '" weight="'     +FloatToStr(FBones[i].weight)+'" />');
    WriteLine('  </boneassignments>');
  end;

  if FSkeleton<>'' then
    WriteLine('  <skeletonlink name="'+FSkeleton+'" />');

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
      WriteLine('usemtl '+FMaterials[FSubMeshes[i].material].name);

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

function TRGMDL.ReadDataCatalog:integer;
var
  i:integer;
  ldata:TDataCatalog;
begin
  result:=FStream.ReadWord();
  LogLn();
  Log('>Data Catalog, blocks',result);

  for i:=0 to result-1 do
  begin
    FStream.Read(ldata,SizeOf(ldata));
{
    Log('block #',i);
    Log('  w[0] (0)',ldata._map   );  // [map / channel]
    Log('  w[1] siz',ldata._size  );  // data size code
    Log('  w[2] typ',ldata._type  );  // data type code
    Log('  w[3] ofs',ldata._offset);  // data offset
    Log('  w[4] ###',ldata._number);  // copy # ?
}  end;
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

  LogLn();
  Log('float x',FStream.ReadFloat());
  Log('float y',FStream.ReadFloat());
  Log('float z',FStream.ReadFloat());

  //===== Vertices =====

  FVertexCount:=FStream.ReadDword();
  LogLn();
  Log('vertexCount',FVertexCount);
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

  // check block types 8 and 9
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

   // Block size=1; type=7; #=0
  LogLn();
  Log(HexStr(FStream.Position,8),'UV index');
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
  if (FVersion=$0E) and (FAddBlock>5) then // Block size=1; type=7; #=1
  begin
    LogLn();
    Log(HexStr(FStream.Position,8),'UV-2 index');
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

  //===== ???Normals??? =====

  lcnt:=FStream.ReadWord();  // 0001
  if lcnt<>1 then Log('!!!Before normals is not 1',lcnt);
  
  // normals?

  SetLength(FNormals,FVertexCount);

  LogLn();
  Log(HexStr(FStream.Position,8),'3x float (normals) index');
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

  LogLn();
  Log('dword (0)',FStream.ReadDWord());
  Log('dword (0)',FStream.ReadDWord());

  // ===== Faces =====

  i:=FStream.ReadDWord();        // total items
  SetLength(FFaces,i);

  lcnt:=FStream.ReadDWord();     // total submeshes
  SetLength(FSubMeshes,lcnt);
  
  LogLn();
  Log('Faces, '+IntToStr(i)+' items in '+IntToStr(lcnt)+' submesh[es]','');

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
  LogLn();
  Log('Vertices '+IntToStr(FVertexCount)+' x60 offset',HexStr(FStream.Position,8));
  for i:=0 to FVertexCount-1 do
  begin
    FVertices[i].X:=FStream.ReadFloat();    // X
    FVertices[i].Y:=FStream.ReadFloat();    // Y
    FVertices[i].Z:=FStream.ReadFloat();    // Z

    FStream.ReadFloat();    // type 9
    FStream.ReadFloat();    // type 9
    FStream.ReadFloat();    // type 9
    FStream.ReadFloat();    // type 9
    FStream.ReadFloat();    // type 8
    FStream.ReadFloat();    // type 8
    FStream.ReadFloat();    // type 8

    FNormals[i].X:=FStream.ReadFloat();     // NX
    FNormals[i].Y:=FStream.ReadFloat();     // NY
    FNormals[i].Z:=FStream.ReadFloat();     // NZ

    FUVs[i].X:=FStream.ReadFloat();         // U
    FUVs[i].Y:=FStream.ReadFloat();         // V
  end;

  // M_SUBMESH
  lcnt :=FStream.ReadDWord();    // submeshes
  SetLength(FSubMeshes,lcnt);
  LogLn();
  Log('SubMeshes',lcnt);

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
  LogLn();
  FStream.Read(FBounds,SizeOf(FBounds));
  Log('minx',FBounds.minx);
  Log('miny',FBounds.miny);
  Log('minz',FBounds.minz);
  Log('maxx',FBounds.maxx);
  Log('maxy',FBounds.maxy);
  Log('maxz',FBounds.maxz);

  // M_MESH_SKELETON_LINK
  FSkeleton:=ReadText(FStream);
  if FSkeleton<>'' then
  begin
    LogLn();
    Log('skeletonName',FSkeleton);
  end;

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


procedure TRGMDL.ReadTextures;
var
  ls:string;
  i,j,lcnt:integer;
begin
  lcnt:=FStream.ReadDWord();
  LogLn();
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

{
typ siz  A B  C D
 01 80   7+13+2+8  B:1+      3+3+3+3
 02 92   7+13+5+8                          +3C
 03 94   8+13+5+8                    +1A
 07 104 10+14+5+9  B:1+1+    3+3+3+3 +2A+1B   +1D
 08 114 10+17+5+10 B:1+1+  3+3+3+3+3    +3B   +1D
 09 118 12+17+5+10                   +2A
 -----------------
 0E 160 15+19+6+17 B:1+1+2+3+3+3+3+3 +3A+2B+1C+7D
}
function TRGMDL.ReadMaterialInfo(aver:integer):boolean;

  function LogTexture(const descr:AnsiString; idx:integer):integer;
  var
    ls:AnsiString;
  begin
    result:=idx;
    if idx>=0 then ls:=FTextures[idx] else ls:='';
    Log('{'+descr+'} = '+IntToStr(idx),ls);
  end;

var
  mtl:PMaterial;
  i,ltmp:integer;
begin
  if not (aver in [$01,$02,$03, $07,$08,$09, $0E]) then exit(false);

  SetLength(FMaterials,FStream.ReadDWord());
  LogLn();
  Log('Materials',Length(FMaterials));

  ReadTextures();

  for i:=0 to High(FMaterials) do
  begin
    mtl:=@FMaterials[i];
    mtl^.name:=ReadText(FStream);
    LogLn();
    Log('name',mtl^.name); // material name

    ltmp:=FStream.ReadWord();
    if ltmp<>i then Log('!!!! number is not like order',ltmp);
    Log('{00} w material #?'      ,ltmp);          // pass # ?
    Log('{01} w (part of #?)',FStream.ReadWord());
    Log('{02} w can be >1'   ,FStream.ReadWord()); // LayerBlendOperation?
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
      Log('{14+ 1} w' ,Int16(FStream.ReadWord())); // 1
      Log('{14+ 2} w' ,Int16(FStream.ReadWord())); // 1
    end;

    if aver>=8 then
    begin
      FStream.Read(mtl^.add,3*2);
      Log('unknown',
        ' '+IntToStr(mtl^.add.R)+   // 0-1
        ' '+IntToStr(mtl^.add.G)+   // 0-1
        ' '+IntToStr(mtl^.add.B));  // 0-1
    end;

    // ambient?
    FStream.Read(mtl^.ambient,3*2);
    LogLn();
    Log('ambient',
      ' '+IntToStr(mtl^.ambient.R)+
      ' '+IntToStr(mtl^.ambient.G)+
      ' '+IntToStr(mtl^.ambient.B));

    // diffuse?
    FStream.Read(mtl^.diffuse,3*2);
    Log('diffuse',
      ' '+IntToStr(mtl^.diffuse.R)+
      ' '+IntToStr(mtl^.diffuse.G)+
      ' '+IntToStr(mtl^.diffuse.B));

    // emissive? specular?
    FStream.Read(mtl^.specular,3*2);
    Log('specular',
      ' '+IntToStr(mtl^.specular.R)+
      ' '+IntToStr(mtl^.specular.G)+
      ' '+IntToStr(mtl^.specular.B));

    // specular? emissive?
    FStream.Read(mtl^.emissive,3*2);
    Log('emissive',
      ' '+IntToStr(mtl^.emissive.R)+
      ' '+IntToStr(mtl^.emissive.G)+
      ' '+IntToStr(mtl^.emissive.B));

    //--------------------------------
    Log('>values','');
    Log('{00} f' ,FStream.ReadFloat()); // low and mid
    Log('{01} f' ,FStream.ReadFloat()); // low
    if aver>=2 then
    begin
      Log('{02} f' ,FStream.ReadFloat()); // mid 30. usually
      Log('{03} f' ,FStream.ReadFloat()); // low
      Log('{04} f' ,FStream.ReadFloat()); // low
    end;
    if aver>=14 then
      Log('{05} f' ,FStream.ReadFloat()); // high brightness? shiness? anim duration?
    //--------------------------------
    Log('>textures','');
    FillChar(mtl^.textures,SizeOf(mtl^.textures),255);
    
    // order number like texture_unit name
    if aver>=14 then // anim texture
    begin
      mtl^.textures[00]:=LogTexture('14 00',Int32(FStream.ReadDWord()));      // 10 14+ normals
      mtl^.textures[01]:=LogTexture('14 01',Int32(FStream.ReadDWord()));      // 11 14+
      mtl^.textures[02]:=LogTexture('14 02',Int32(FStream.ReadDWord()));      // 12 14+
      mtl^.textures[03]:=LogTexture('14 03',Int32(FStream.ReadDWord()));      // 13 14+
      mtl^.textures[04]:=LogTexture('14 04',Int32(FStream.ReadDWord()));      // 14 14+
    end;
    mtl^.textures[ 5]:=LogTexture('base',Int32(FStream.ReadDWord()));         // 00 base/diffuse
    mtl^.textures[ 6]:=LogTexture('??  ',Int32(FStream.ReadDWord()));         // 01 ??
    if aver>=8 then
      mtl^.textures[7]:=LogTexture('8 env dark',Int32(FStream.ReadDWord())); // 09 8+ environment dark (ambient)
    mtl^.textures[ 8]:=LogTexture('env ',Int32(FStream.ReadDWord()));       // 02 environment "ref"
    mtl^.textures[ 9]:=LogTexture('glow',Int32(FStream.ReadDWord()));       // 03 glow
    mtl^.textures[10]:=LogTexture('norm',Int32(FStream.ReadDWord()));       // 04 normal
    mtl^.textures[11]:=LogTexture('   5',Int32(FStream.ReadDWord()));       // 05
    mtl^.textures[12]:=LogTexture('   6',Int32(FStream.ReadDWord()));       // 06
    mtl^.textures[13]:=LogTexture('spec',Int32(FStream.ReadDWord()));       // 07 specular / surface?
    if aver>=7 then
      mtl^.textures[14]:=LogTexture('??7+',Int32(FStream.ReadDWord()));       // 08 7+
    if aver>=14 then
    begin
      mtl^.textures[15]:=LogTexture('14 paint  ',Int32(FStream.ReadDWord())); // 15 14+ paint
      mtl^.textures[16]:=LogTexture('14 surface',Int32(FStream.ReadDWord())); // 16 14+ paint surface
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

    Log('first  (1)' ,FStream.ReadWord());
    Log('second (0)',FStream.ReadWord());
    if FVersion=14 then // type=$0E - RGO
      Log('v.0E add (1)' ,FStream.ReadWord());

    FAddBlock:=ReadDataCatalog();
  
    LogLn;
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
  FSkeleton :='';

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
