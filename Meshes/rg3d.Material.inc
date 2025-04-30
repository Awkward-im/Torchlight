{}
{NOTE: GetMaterial replaces texture extensions to DDS}

const
  // texture indexes
  txtBase         = 5;
  //
  txtEnvDiffuse   = 7;
  txtEnvSpecular  = 8;
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

function TRGMesh.GetMTL():string;
var
  sl:TStringList;
//  ls:string;
  i,j:integer;
begin
  result:='';
  sl:=TStringList.Create;
  try

    for i:=0 to High(FMaterials) do
    begin
      sl.Add('newmtl '+FMaterials[i].name);
      sl.Add('Ka '+RGBToFloat(FMaterials[i].ambient));
      sl.Add('Kd '+RGBToFloat(FMaterials[i].diffuse));
      sl.Add('Ks '+RGBToFloat(FMaterials[i].specular));
      sl.Add('');

      for j:=5 to 16 do
      begin
        if (FTextures<>nil) and (FMaterials[i].textures[j]>=0) then
        begin
        end;
      end;
    end;

    result:=sl.Text;
  finally
    FreeAndNil(sl);
  end;
end;

function TRGMesh.GetMaterial():string;
var
  sl:TStringList;
//  ls:string;
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
      sl.Add('      specular '+RGBToFloat(FMaterials[i].specular)+' 0');
      sl.Add('      emissive '+RGBToFloat(FMaterials[i].emissive));
      // animation (duration requires)
(*
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
        sl.Add('        anim_texture'+ls);
        sl.Add('      }');
      end;
*)
      for j:=5 to 16 do
      begin
        if (FTextures<>nil) and (FMaterials[i].textures[j]>=0) then
        begin
          sl.Add('');
          sl.Add('      texture_unit');
          sl.Add('      {');
          //!!!!
          sl.Add('        texture '+ChangeFileExt(FTextures[FMaterials[i].textures[j]],'.dds'));
//          sl.Add('        texture '+FTextures[FMaterials[i].textures[j]]);

          case j of
            txtEnvDiffuse: begin
              sl.Add('        env_map spherical'); // "content_type shadow" ?
              sl.Add('        colour_op modulate');
            end;
            txtEnvSpecular: begin
              sl.Add('        env_map spherical');
              sl.Add('        colour_op add');
            end;
            txtGlow: begin
              sl.Add('        colour_op add');
            end;
            txtNormal: begin
              sl.Add('        colour_op replace');
//              sl.Add('        colour_op modulate');
            end;
            txtSpecular: begin
              sl.Add('        colour_op add');
//              sl.Add('        colour_op alpha_blend');
            end;
            txtPaint: begin
            end;
            txtPaintSurface: begin
            end;
          end;

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

procedure TRGMesh.SaveMaterial(const aFileName:String);
var
  f:file of byte;
  ls:string;
begin
  AssignFile(f, aFileName);
  Rewrite(f);
  if IOResult=0 then
  begin
    ls:=GetMaterial();
    BlockWrite(f,ls[1],Length(ls));
    CloseFile(f);
  end;
end;


procedure TRGMesh.ReadTextures(var aptr:PByte);
var
  ls:string;
  i,j,lcnt:integer;
begin
  lcnt:=memReadDWord(aptr);
  LogLn();
  Log('Textures',lcnt);
  SetLength(FTextures,lcnt);
  for i:=0 to lcnt-1 do
  begin
    ls:=memReadText(aptr);
    j:=memReadDWord(aptr);
    
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
 0D 140 15+19+6+12 B:1+1+2+3+3+3+3+3 +3A+2B+1C+2D
 0E 160 15+19+6+17                            +5D
}
function TRGMesh.ReadRGMaterial(var aptr:PByte; aver:integer):boolean;

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
  SetLength(FMaterials,memReadDWord(aptr));
  LogLn();
  Log('Materials',Length(FMaterials));

  ReadTextures(aptr);

  for i:=0 to High(FMaterials) do
  begin
    mtl:=@FMaterials[i];
    mtl^.name:=memReadText(aptr);
    LogLn();
    Log('name',mtl^.name); // material name

    ltmp:=memReadWord(aptr);
    if ltmp<>i then Log('!!!! number is not like order',ltmp);
    Log('{00} w material #?'      ,ltmp);          // pass # ?
    Log('{01} w (part of #?)',memReadWord(aptr));
    Log('{02} w can be >1'   ,memReadWord(aptr)); // LayerBlendOperation?
                                                   // can be 14, so not alpha_rejection
    Log('{03} w' ,memReadWord(aptr));
    Log('{04} w' ,memReadWord(aptr));
    Log('{05} w' ,memReadWord(aptr));
    Log('{06} w' ,memReadWord(aptr));
    if aver>=3 then
      Log('{07} w' ,memReadWord(aptr));
    if aver>=7 then
    begin
      Log('{08} w' ,memReadWord(aptr));
      Log('{09} w' ,memReadWord(aptr));
    end;
    if aver>=9 then
    begin
      Log('{10} w' ,memReadWord(aptr));
      Log('{11} w' ,memReadWord(aptr));
    end;
    if aver>=13 then
    begin
      Log('{12} w' ,memReadWord(aptr));
      Log('{13} w' ,memReadWord(aptr));
      Log('{14} w' ,memReadWord(aptr));
    end;
    //--------------------------------
    Log('>colors?','');
    Log('{00} w' ,Int16(memReadWord(aptr))); // alpha_rejection value?
{
    enum CompareFunction : uint8
      0  CMPF_ALWAYS_FAIL,  //!< Never writes a pixel to the render target
      1  CMPF_ALWAYS_PASS,  //!< Always writes a pixel to the render target
      2  CMPF_LESS,         //!< Write if (new_Z < existing_Z)
      3  CMPF_LESS_EQUAL,   //!< Write if (new_Z <= existing_Z)
      4  CMPF_EQUAL,        //!< Write if (new_Z == existing_Z)
      5  CMPF_NOT_EQUAL,    //!< Write if (new_Z != existing_Z)
      6  CMPF_GREATER_EQUAL,//!< Write if (new_Z >= existing_Z)
      7  CMPF_GREATER       //!< Write if (new_Z >= existing_Z)
}

    if aver>=7 then
      Log('{7+ 1} w' ,Int16(memReadWord(aptr))); // can be -1

    if aver>=13 then
    begin
      Log('{13+ 1} w' ,Int16(memReadWord(aptr))); // 1
      Log('{13+ 2} w' ,Int16(memReadWord(aptr))); // 1
    end;

    if aver>=8 then
    begin
      memRead(aptr,mtl^.add,3*2);
      Log('unknown',
        ' '+IntToStr(mtl^.add.R)+   // 0-1
        ' '+IntToStr(mtl^.add.G)+   // 0-1
        ' '+IntToStr(mtl^.add.B));  // 0-1
    end;
// ambient, diffuse, emissive, specular

    // ambient?
    memRead(aptr,mtl^.ambient,3*2);
    LogLn();
    Log('ambient',
      ' '+IntToStr(mtl^.ambient.R)+
      ' '+IntToStr(mtl^.ambient.G)+
      ' '+IntToStr(mtl^.ambient.B));

    // diffuse?
    memRead(aptr,mtl^.diffuse,3*2);
    Log('diffuse',
      ' '+IntToStr(mtl^.diffuse.R)+
      ' '+IntToStr(mtl^.diffuse.G)+
      ' '+IntToStr(mtl^.diffuse.B));

    // emissive? specular?
    memRead(aptr,mtl^.specular,3*2);
    Log('specular',
      ' '+IntToStr(mtl^.specular.R)+
      ' '+IntToStr(mtl^.specular.G)+
      ' '+IntToStr(mtl^.specular.B));

    // specular? emissive?
    memRead(aptr,mtl^.emissive,3*2);
    Log('emissive',
      ' '+IntToStr(mtl^.emissive.R)+
      ' '+IntToStr(mtl^.emissive.G)+
      ' '+IntToStr(mtl^.emissive.B));

    //--------------------------------
    Log('>values','');
    Log('{00} f' ,memReadFloat(aptr)); // low and mid
    Log('{01} f' ,memReadFloat(aptr)); // low
    if aver>=2 then
    begin
      Log('{02} f' ,memReadFloat(aptr)); // mid 30. usually
      Log('{03} f' ,memReadFloat(aptr)); // low, can be a 0
      Log('{04} f' ,memReadFloat(aptr)); // low, can be a negative
    end;
    if aver>=13 then
      Log('{05} f' ,memReadFloat(aptr)); // high brightness? shiness? anim duration?
    //--------------------------------
    Log('>textures','');
    FillChar(mtl^.textures,SizeOf(mtl^.textures),255);
    
    // order number like texture_unit name
    if aver>=14 then // anim texture
    begin
      mtl^.textures[00]:=LogTexture('14 00',Int32(memReadDWord(aptr)));      // 10 14+ normals
      mtl^.textures[01]:=LogTexture('14 01',Int32(memReadDWord(aptr)));      // 11 14+
      mtl^.textures[02]:=LogTexture('14 02',Int32(memReadDWord(aptr)));      // 12 14+
      mtl^.textures[03]:=LogTexture('14 03',Int32(memReadDWord(aptr)));      // 13 14+
      mtl^.textures[04]:=LogTexture('14 04',Int32(memReadDWord(aptr)));      // 14 14+
    end;
    mtl^.textures[ 5]:=LogTexture('diff',Int32(memReadDWord(aptr)));         // 00 base/diffuse
    mtl^.textures[ 6]:=LogTexture('??  ',Int32(memReadDWord(aptr)));         // 01 ??
    if aver>=8 then
      mtl^.textures[7]:=LogTexture('8 env dark',Int32(memReadDWord(aptr))); // 09 8+ environment dark (ambient)
    mtl^.textures[ 8]:=LogTexture('env ',Int32(memReadDWord(aptr)));       // 02 environment "ref"
    mtl^.textures[ 9]:=LogTexture('glow',Int32(memReadDWord(aptr)));       // 03 glow
    mtl^.textures[10]:=LogTexture('norm',Int32(memReadDWord(aptr)));       // 04 normal
    mtl^.textures[11]:=LogTexture('   5',Int32(memReadDWord(aptr)));       // 05
    mtl^.textures[12]:=LogTexture('   6',Int32(memReadDWord(aptr)));       // 06
    mtl^.textures[13]:=LogTexture('spec',Int32(memReadDWord(aptr)));       // 07 specular / surface?
    if aver>=7 then
      mtl^.textures[14]:=LogTexture('??7+',Int32(memReadDWord(aptr)));       // 08 7+
    if aver>=13 then
    begin
      mtl^.textures[15]:=LogTexture('14 paint  ',Int32(memReadDWord(aptr))); // 15 14+ paint
      mtl^.textures[16]:=LogTexture('14 surface',Int32(memReadDWord(aptr))); // 16 14+ paint surface
    end;
  end;

  result:=true;
end;


function TRGMesh.ReadHobMaterial(var aptr:PByte; aver:integer):boolean;
var
  mtl:PMaterial;
  ls:string;
  i,lcnt,ltype:integer;
begin
  result:=false;

  SetLength(FMaterials,1);
  mtl:=@FMaterials[0];

  Log('w (1)',memReadWord(aptr)); // 0001

  // base textures
  lcnt:=memReadWord(aptr);
  for i:=0 to lcnt-1 do
  begin
    ls:=memReadText(aptr);
    Log(ls,memReadText(aptr));
  end;

  Log('w (1)',memReadWord(aptr)); //0001
  Log('checksum?',HexStr(memReadDWord(aptr),8));

  ls:=memReadText(aptr);
  Log(ls+' (size of next data, mat+consts)',HexStr(memReadDWord(aptr),8));

  mtl^.name:=memReadText(aptr);       // material/pass name
  Log(ls,memReadDWord(aptr)); // number?

  lcnt:=memReadDWord(aptr);

  for i:=0 to lcnt-1 do
  begin
    ltype:=memReadDWord(aptr);
    case ltype of
      1: begin
        ls:=memReadText(aptr);
        Log('{'+IntToStr(i)+'} '+ls,memReadDWord(aptr));
      end;
      2: begin
        ls:=memReadText(aptr);
        Log('{'+IntToStr(i)+'} '+ls,memReadFloat(aptr));
      end;
      3: begin
        Log('{'+IntToStr(i)+'} '+memReadText(aptr),'4x float');
        Log('  [0]',memReadFloat(aptr));
        Log('  [1]',memReadFloat(aptr));
        Log('  [2]',memReadFloat(aptr));
        Log('  [3]',memReadFloat(aptr));
      end;
      4: Log('{'+IntToStr(i)+'} type',ltype);
    else
      Log('{'+IntToStr(i)+'} Unknown const type',ltype);
    end;
  end;
end;

function TRGMesh.AddMaterial(const aname:string):integer;
var
  i:integer;
begin
  for i:=0 to High(FMaterials) do
    if FMaterials[i].name=aname then exit(i); 

  result:=Length(FMaterials);
  SetLength(FMaterials,result+1);
  FMaterials[result].name:=aname;
end;
