{}
{NOTE: GetMaterial replaces texture extensions to DDS}
{TODO: Save and check Uppercase texture names}
{$IFDEF Interface}

const
  // texture indexes
  txtDiffuse      =  0; // alias: 'DiffuseTexture2D'
  txtUnknown1     =  1; // alias: 'DistortionMask2D'??
  txtEnvDiffuse   =  2;
  txtEnvSpecular  =  3;
  txtGlow         =  4; // alias: 'EmissiveMap2D' ? Illumination
  txtNormal       =  5; // alias: 'NormalTexture2D'
  txtOutline      =  6; // alias: 'OutlineMap2D'
  txtUnknown3     =  7; // alias: 'DistortionMask2D'?? MEDIA/SHAREDTEXTURES/WHITE.DDS
  txtSpecular     =  8; // alias: 'SpecularMap2D'
  txtUnknown4     =  9; // alias: 'DistortionMask2D'??
  txtPaint        = 10; // MEDIA/SHAREDTEXTURES/WHITE.DDS
  txtPaintSurface = 11; // MEDIA/SHAREDTEXTURES/NEUTRAL.DDS

  txtLast         = 11;

type
  PMaterial = ^TMaterial;
  TMaterial = record
    name    :string;
    // colors
    diffuse :TVector3;
    ambient :TVector3;
    specular:TVector3;
    emissive:TVector3;
    textures:array [0..txtLast] of integer;

    id      :integer; // usually, is order number
    // material
    shadows     :boolean;
    cast_shadows:boolean;
    // pass
    depth_write:boolean;
    depth_check:boolean;
  end;

{$ELSE}

const
  TxtAliasList:array [0..txtLast, boolean] of string = (
    ('const_DiffuseTexture'       ,'DiffuseTexture2D'),
    ('const_DistortionMaskTexture','DistortionMask2D'), // not really
    ('',''),
    ('',''),
    ('const_EmissiveTexture'      ,'EmissiveMap2D'   ),
    ('const_NormalmapTexture'     ,'NormalTexture2D' ),
    ('const_OutlineTexture'       ,'OutlineMap2D'    ),
    ('',''), // 'DistortionMask2D'
    ('const_SpecularTexture'      ,'SpecularMap2D'   ),
    ('',''), // 'DistortionMask2D'
    ('',''),
    ('','')
  );

type
  THobTexture = record
    material:integer;
    alias   :integer;
    texture :integer;
  end;
  THobTextureList = array of THobTexture;

type
  TRGB = packed record // byte used, word is in file
    R:Word;
    G:Word;
    B:Word;
  end;

procedure SetMaterialDefaults(amtl:PMaterial);
var
  i:integer;
begin
  FillChar(amtl^,SizeOf(TMaterial),0);
  for i:=0 to txtLast do amtl^.textures[i]:=-1;
{
  lf_03:=30.0;
  lf_04:=1.0;
  lf_05:=1.0;
  lf_06:=-1.0;

  lf_07=0.0;
  lf_08=0.0;
  lf_09=0.0;
  lf_10=0.0;
}
end;

procedure FloatToRGB(const acolor:TVector3; var argb:TRGB);
begin
  if acolor.X=0 then argb.R:=0 else if acolor.X=1.0 then argb.R:=255 else argb.R:=round(acolor.X*255);
  if acolor.Y=0 then argb.G:=0 else if acolor.Y=1.0 then argb.G:=255 else argb.G:=round(acolor.Y*255);
  if acolor.Z=0 then argb.B:=0 else if acolor.Z=1.0 then argb.B:=255 else argb.B:=round(acolor.Z*255);
end;

procedure RGBToFloat(const aval:TRGB; var acolor:TVector3);
begin
  if aval.R=0 then acolor.X:=0 else if aval.R=255 then acolor.X:=1.0 else acolor.X:=aval.R/255;
  if aval.G=0 then acolor.Y:=0 else if aval.G=255 then acolor.Y:=1.0 else acolor.Y:=aval.G/255;
  if aval.G=0 then acolor.Z:=0 else if aval.B=255 then acolor.Z:=1.0 else acolor.Z:=aval.B/255;
end;

function RGBToStr(const aval:TVector3):string;
var
  lr,lg,lb:string;
begin
//  if (aval.X=0) and (aval.Y=0) and (aval.Z=0) then exit('');

  Str(aval.X:0:6,lr); FixFloatStr(lr);
  Str(aval.Y:0:6,lg); FixFloatStr(lg);
  Str(aval.Z:0:6,lb); FixFloatStr(lb);
  result:=lr+' '+lg+' '+lb;
end;

procedure GetFloatValue(var aval:PAnsiChar; var adst:Single);
var
  lval:string[31];
  lidx:integer;
begin
  if aval^=#0 then
  begin
    adst:=0;
    exit;
  end;

  lidx:=1;
  while not (aval^ in ['+','-','.','0'..'9']) do inc(aval);
  repeat
    lval[lidx]:=aval^;
    inc(lidx);
    inc(aval);
  until aval^ in [#0,#9,' ',','];
  lval[0]:=AnsiChar(lidx-1);
  Val(lval, adst);
end;

function SplitColor(pc:PAnsiChar; var color:TVector3):boolean;
begin
  result:=false;
  while (pc^=' ') or (pc^=#9) do inc(pc);
  if pc^<>#0 then
  begin
    if strlcomp(pc,'vertexcolour',12)=0 then exit;

    GetFloatValue(pc,color.X);
    GetFloatValue(pc,color.Y);
    GetFloatValue(pc,color.Z);

    result:=true;
  end;
end;
{
function GetTextureUsage(code:integer):AnsiString;
begin
  if      (code and TU_STATIC_WRITE_ONLY )=TU_STATIC_WRITE_ONLY  then result:='TU_STATIC_WRITE_ONLY'
  else if (code and TU_DYNAMIC_WRITE_ONLY)=TU_DYNAMIC_WRITE_ONLY then result:='TU_DYNAMIC_WRITE_ONLY'
  else if (code and TU_STATIC )<>0 then result:='TU_STATIC'
  else if (code and TU_DYNAMIC)<>0 then result:='TU_DYNAMIC'
  else result:='';

  if (code and TU_AUTOMIPMAP)<>0 then
    if result='' then result:='TU_AUTOMIPMAP'       else result:=result+' or TU_AUTOMIPMAP';
  if (code and TU_RENDERTARGET)<>0 then
    if result='' then result:='TU_RENDERTARGET'     else result:=result+' or TU_RENDERTARGET';
  if (code and TU_NOT_SAMPLED)<>0 then
    if result='' then result:='TU_NOT_SAMPLED'      else result:=result+' or TU_NOT_SAMPLED';
  if (code and TU_UNORDERED_ACCESS)<>0 then
    if result='' then result:='TU_UNORDERED_ACCESS' else result:=result+' or TU_UNORDERED_ACCESS';
end;
}

{%REGION Export materials}
function TRGMesh.GetMTL():string;
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
      sl.Add('newmtl '+FMaterials[i].name);
      ls:=RGBToStr(FMaterials[i].diffuse ); if ls<>'' then sl.Add('Kd '+ls);
      ls:=RGBToStr(FMaterials[i].ambient ); if ls<>'' then sl.Add('Ka '+ls);
      ls:=RGBToStr(FMaterials[i].specular); if ls<>'' then sl.Add('Ks '+ls);
      sl.Add('');

      for j:=0 to txtLast do
      begin
        if (FTextures<>nil) and (FMaterials[i].textures[j]>=0) then
        begin
          ls:=ChangeFileExt(FTextures[FMaterials[i].textures[j]],'.dds');
          case j of
            txtDiffuse: begin
              sl.Add('map_Kd '+ls);
            end;
            txtEnvDiffuse: begin
            end;
            txtEnvSpecular: begin
            end;
            txtGlow: begin
              //??
              sl.Add('map_Ka '+ls);
            end;
            txtNormal: begin
            end;
            txtSpecular: begin
              sl.Add('map_Ks '+ls);
            end;
          end;

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
  mtl:PMaterial;
  ls:string;
  i,j:integer;
begin
  result:='';
  sl:=TStringList.Create;
  try

    for i:=0 to High(FMaterials) do
    begin
      mtl:=@FMaterials[i];
      sl.Add('material '+mtl^.name);
      sl.Add('{');
//      if not mtl^.shadows then sl.Add('  receive_shadows off');
//      if mtl^.castshadows then sl.Add('  transparency_cast_shadows on');
      sl.Add('  technique');
      sl.Add('  {');
      sl.Add('    pass');
      sl.Add('    {');
//      if not mtl^.depth_write then sl.Add('      depth_write off');
//      if not mtl^.depth_check then sl.Add('      depth_check off');
      ls:=RGBToStr(mtl^.diffuse ); if ls<>'' then sl.Add('      diffuse ' +ls);      // 1 1 1 1
      ls:=RGBToStr(mtl^.ambient ); if ls<>'' then sl.Add('      ambient  '+ls);      // 1 1 1 1
      ls:=RGBToStr(mtl^.specular); if ls<>'' then sl.Add('      specular '+ls+' 0'); // 0 0 0 0
      ls:=RGBToStr(mtl^.emissive); if ls<>'' then sl.Add('      emissive '+ls);      // 0 0 0 0

      if FTextures<>nil then
      begin
        for j:=0 to txtLast do
        begin
          if mtl^.textures[j]>=0 then
          begin
            if (j=txtEnvDiffuse) or (j=txtEnvSpecular) then continue;
            
            sl.Add('');
            sl.Add('      texture_unit');
            sl.Add('      {');
            //!!!!
            sl.Add('        texture '+ChangeFileExt(FTextures[mtl^.textures[j]],'.dds'));
  //          sl.Add('        texture '+FTextures[FMaterials[i].textures[j]]);

            case j of
              txtEnvDiffuse: begin
                sl.Add('        env_map spherical'); // "content_type shadow" ?
                sl.Add('        colour_op modulate'); // scene_blend modulate
                // alpha_blend + scene_blend alpha_blend
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
//                sl.Add('        colour_op alpha_blend'); // scene_blend alpha_blend
              end;
              txtPaint: begin
              end;
              txtPaintSurface: begin
              end;
              txtOutline: begin
              end;
            end;

            sl.Add('      }');
          end;
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
{%ENDREGION Export materials}

{%REGION Read materials}

//===== RG/RGO =====

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
  lrgb:TRGB;
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
    mtl^.id  :=memReadDWord(aptr);
    LogLn();
    Log('name'      ,mtl^.name); // material name
    Log('material #',mtl^.id);
    if mtl^.id<>i then Log('!!!! number is not like order',mtl^.id);

{
 1 - Illumination (glow) txt_glow (+txtPaint [Detail])
 7 - glass
 8 - Gloss
 2 - Specular
 3 - Glass
 4 - Detail, Mod2x, Illumination (2nd texture)
 11 - Flesh
 12 - Hair

}
{ render type?
eye = 1
eye gloss = 8
hair = 12
teeth = 11
face = 11
clothing = 1
body = 11
goggles = 1
lashes = 1
}
    if aver>=10 then
      Log('{01} ',memReadWord(aptr));
    if aver>=9 then
      Log('{02} SceneBlendAdd',memReadWord(aptr));  // 1: SceneBlend=SBT_ADD else SBT_REPLACE (default)
    
    if aver>=12 then
    begin
      Log('{03}',memReadWord(aptr));                // NotCulling
      Log('{04}',memReadWord(aptr));                // signed, 0 for lower version
    end;
{
    if aver>=8 then memReadWord(aptr);              // unused, Hob only
}
    mtl^.depth_write:=memReadWord(aptr)<>0;         // DepthWriteEnabled
    Log('{05} DepthWrite',ORD(mtl^.depth_write));
    if aver>=9 then Log('{06}',memReadWord(aptr));
    mtl^.depth_check:=memReadWord(aptr)<>0;         // DepthCheckEnabled
    Log('{07} DepthCheck',ORD(mtl^.depth_check));
    Log('{08}',memReadWord(aptr));                  // $8000 mask and equ=0
    Log('{09}',memReadWord(aptr));                  // Shadow depth texture. Texture addressingmode=2
    if aver>=3 then Log('{10}',memReadWord(aptr));
    if aver>=5 then Log('{11}',memReadWord(aptr));
    if aver>=6 then Log('{12}',memReadWord(aptr));  // distort

    Log('{13} UseAlphaReject',memReadWord(aptr));   // use alpha reject
{
    if l_13 > 0
      Ogre::Pass::setAlphaRejectFunction(Pass, 6);
      Ogre::Pass::setAlphaRejectValue(Pass, l_14);
      Ogre::Material::setSceneBlending(0);
}

    //??
    Log('{14} AlphaRejectValue',memReadWord(aptr)); // AlphaRejectValue function=6 CMPF_GREATER_EQUAL
    if aver>=4 then
      ltmp:=memReadWord(aptr);                      // -1 ogreTechnique
//    else ltmp:=-1;
//  l_technique:=Technique.<method>( fmax(-1,fmin(99,ltmp)) )
    Log('{15} Technique',Int16(ltmp));

    if aver>=8 then
    begin
      Log('{16}',memReadWord(aptr));                // cast to dword
      Log('{17}',memReadWord(aptr));
      if aver>=10 then
      begin
        Log('ver 10+ unused',memReadWord(aptr));    //?? unused
        Log('ver 10+ unused',memReadWord(aptr));    //?? unused
      end;
      Log('ver 8+ unused',memReadWord(aptr));       //?? unused
    end;

    memRead(aptr,lrgb,3*2);
    RGBtoFloat(lrgb,mtl^.ambient);
    Log('diffuse',
      ' '+IntToStr(lrgb.R)+
      ' '+IntToStr(lrgb.G)+
      ' '+IntToStr(lrgb.B));

    // ?? unused
    memRead(aptr,lrgb,3*2);
    RGBtoFloat(lrgb,mtl^.diffuse);
    Log('ambient',
      ' '+IntToStr(lrgb.R)+
      ' '+IntToStr(lrgb.G)+
      ' '+IntToStr(lrgb.B));

    // Specular RGB*lf_03
    memRead(aptr,lrgb,3*2);
    RGBtoFloat(lrgb,mtl^.specular);
    Log('specular',
      ' '+IntToStr(lrgb.R)+
      ' '+IntToStr(lrgb.G)+
      ' '+IntToStr(lrgb.B));

    // SelfIllumination (SpecularColor2)
    memRead(aptr,lrgb,3*2);
    RGBtoFloat(lrgb,mtl^.emissive);
    Log('emissive',
      ' '+IntToStr(lrgb.R)+
      ' '+IntToStr(lrgb.G)+
      ' '+IntToStr(lrgb.B));

    Log('{01} f' ,memReadFloat(aptr));  // shiness Hob - ignore
    Log('{02} f' ,memReadFloat(aptr));  // Hob - ignore
{
    lf_03 = 30.0;
    lf_04 = 1.0;
    lf_05 = 1.0;
    lf_06 = -1.0;
    lf_07 = 0.0;
    lf_08 = 0.0;
    lf_09 = 0.0;
    lf_10 = 0.0;
}
    if aver>=2 then
    begin
      Log('{03} f' ,memReadFloat(aptr)); // brightness of specular (RGB specular*lf_03)
      Log('{04} f' ,memReadFloat(aptr)); // 
      Log('{05} f' ,memReadFloat(aptr)); // 
    end;
    if aver>=13 then
    begin
      Log('{06} f' ,memReadFloat(aptr)); // Intensity
    end;
    if aver>=14 then
    begin
      Log('{07} f' ,memReadFloat(aptr)); // SpecularMultiplier
      Log('{08} f' ,memReadFloat(aptr)); // SpecularMultiplier2
      Log('{09} f' ,memReadFloat(aptr)); // PrimaryShift
      Log('{10} f' ,memReadFloat(aptr)); // SecondaryShift
      Log('{11} f' ,memReadFloat(aptr)); //?? unused
    end;

    mtl^.textures[txtDiffuse     ]:=LogTexture('diff'    ,Int32(memReadDWord(aptr)));
    mtl^.textures[txtUnknown1    ]:=LogTexture('unknown' ,Int32(memReadDWord(aptr)));
    mtl^.textures[txtEnvDiffuse  ]:=LogTexture('env diff',Int32(memReadDWord(aptr)));
    if aver>=8 then                      // not in Hob
      mtl^.textures[txtEnvSpecular ]:=LogTexture('env spec',Int32(memReadDWord(aptr)));
    mtl^.textures[txtGlow        ]:=LogTexture('glow'    ,Int32(memReadDWord(aptr)));
    mtl^.textures[txtNormal      ]:=LogTexture('normals' ,Int32(memReadDWord(aptr)));
    mtl^.textures[txtOutline     ]:=LogTexture('outline' ,Int32(memReadDWord(aptr)));
    mtl^.textures[txtUnknown3    ]:=LogTexture('unknown' ,Int32(memReadDWord(aptr)));
    mtl^.textures[txtSpecular    ]:=LogTexture('specular',Int32(memReadDWord(aptr)));
    if aver>=7 then
      mtl^.textures[txtUnknown4    ]:=LogTexture('unknown',Int32(memReadDWord(aptr)));
    if aver>=13 then
    begin
      mtl^.textures[txtPaint       ]:=LogTexture('paint'  ,Int32(memReadDWord(aptr)));
      mtl^.textures[txtPaintSurface]:=LogTexture('surface',Int32(memReadDWord(aptr)));
    end;
  end;

  result:=true;
end;

//===== Hob =====

function {TRGMesh.}ReadHobMaterial(var aptr:PByte; amtl:PMaterial; const ahtl:THobTextureList):boolean;
const
  type_int    = 1;
  type_float  = 2;
  type_float4 = 3;
  type_four   = 4;

var
  lname,ls,lsv:string;
  lr,lg,lb,lalpha:single;
  lint,i,lcnt,ltype:integer;
  lidx,k:integer;
begin
  result:=false;
  // M_SUBMESH_NAME_TABLE_ELEMENT = 0xA100,
  amtl^.name:=memReadText (aptr);       // material export name
  amtl^.id  :=memReadDWord(aptr);       // number?
  Log(amtl^.name,amtl^.id);

  lcnt:=memReadDWord(aptr);
  for i:=0 to lcnt-1 do
  begin
    ltype:=memReadDWord(aptr);
    case ltype of

      type_int: begin
        lname:=memReadText (aptr);
        lint :=memReadDWord(aptr);

        Log('/* '+IntToStr(i)+' */ param_named '+lname+' int '+IntToStr(lint));

        if lint=1 then
        begin
          // flags
               if lname='const_WriteDepth' then amtl^.depth_write:=true
          else if lname='const_CheckDepth' then amtl^.depth_check:=true
          ;

          // textures
          lidx:=0;
          while lidx<=txtLast do
          begin
            if TxtAliasList[lidx,false]=lname then break;
            inc(lidx);
          end;
          if lidx<=txtLast then
            for k:=0 to High(ahtl) do
            begin
              if (ahtl[k].material=amtl^.id) and (ahtl[k].alias=lidx) then
              begin
                amtl^.textures[lidx]:=ahtl[k].texture;
                break;
              end;
            end;
{               
               if lname='const_DiffuseTexture'        then begin lidx:=txtDiffuse ; ls:='DiffuseTexture2D' end
          else if lname='const_SpecularTexture'       then begin lidx:=txtSpecular; ls:='SpecularMap2D'    end
          else if lname='const_OutlineTexture'        then begin lidx:=txtOutline ; ls:='OutlineMap2D'     end
          else if lname='const_EmissiveTexture'       then begin lidx:=txtGlow    ; ls:='EmissiveMap2D'    end
          else if lname='const_NormalmapTexture'      then begin lidx:=txtNormal  ; ls:='NormalTexture2D'  end
          else if lname='const_DistortionMaskTexture' then begin lidx:=txtUnknown4; ls:='DistortionMask2D' end //!!
          else lidx:=-1;
          if lidx>=0 then
          begin
            for k:=0 to High(ahtl) do
            begin
              if (ahtl[k].material=amtl^.id) and (ahtl[k].alias=ls) then
              begin
                amtl^.textures[lidx]:=ahtl[k].texture;
                break;
              end;
            end;
          end;
}
        end;

      end;

      type_float: begin
        lname:=memReadText(aptr);
        lsv:=FloatToStr(memReadFloat(aptr)); FixFloatStr(lsv);
        Log('/* '+IntToStr(i)+' */ param_named '+lname+' float '+lsv);
      end;

      type_float4: begin
        lname :=memReadText (aptr);
        lr    :=memReadFloat(aptr);
        lg    :=memReadFloat(aptr);
        lb    :=memReadFloat(aptr);
        lalpha:=memReadFloat(aptr);
        if      lname='const_DiffuseColor'  then with amtl^.diffuse  do begin X:=lr; Y:=lg; Z:=lb; end
        else if lname='const_SpecularColor' then with amtl^.specular do begin X:=lr; Y:=lg; Z:=lb; end
        else if lname='const_EmissiveColor' then with amtl^.emissive do begin X:=lr; Y:=lg; Z:=lb; end
//          else if lname='const_AmbientHemisphereTop'    then with mtl^.ambient do begin X:=lr; Y:=lg; Z:=lb; end
//          else if lname='const_AmbientHemisphereBottom' then with mtl^.add     do begin X:=lr; Y:=lg; Z:=lb; end
        ;
        ls:='/* '+IntToStr(i)+' */ param_named '+lname+' float4';
        lsv:=FloatToStr(lr    ); FixFloatStr(lsv); ls:=ls+' '+lsv;
        lsv:=FloatToStr(lg    ); FixFloatStr(lsv); ls:=ls+' '+lsv;
        lsv:=FloatToStr(lb    ); FixFloatStr(lsv); ls:=ls+' '+lsv;
        lsv:=FloatToStr(lalpha); FixFloatStr(lsv); ls:=ls+' '+lsv;
        Log(ls);
      end;

      type_four: Log('/* '+IntToStr(i)+' type = 4 */');

    else
      Log('/* '+IntToStr(i)+' Unknown const type '+IntToStr(ltype)+' */');
    end;
  end;
  result:=true;
end;

function TRGMesh.ReadHobMaterials(var aptr:PByte; aver:integer):boolean;
var
  mtl:PMaterial;
  ltxt:THobTextureList;
  ls:AnsiString;
  i,j,k:integer;
  ltxtcount,ltextcount,lidx:integer;
  lcnt,lcnt1:integer;
begin
  result:=true;

  SetLength(ltxt,100);
  SetLength(FTextures,100);
  ltxtcount :=0;
  ltextcount:=0;

  // M_SUBMESH_TEXTURE_ALIAS
  lcnt:=memReadWord(aptr);
  Log('>material textures',lcnt);

  for j:=0 to lcnt-1 do
  begin
    Log('  Material',j);
    // base textures
    lcnt1:=memReadWord(aptr);
    for i:=0 to lcnt1-1 do
    begin
      if ltxtcount=Length(ltxt) then SetLength(ltxt,Length(ltxt)+50);
      with ltxt[ltxtcount] do
      begin
        material:=j;
        ls:=memReadText(aptr);  // char* aliasName;
        for k:=0 to txtLast do
          if TxtAliasList[k][true]=ls then
          begin
            alias:=k;
            break;
          end;
      end;
      ls:=memReadText(aptr);         // char* textureName;
      // search file name in table and add if new
      lidx:=0;
      while lidx<ltextcount do
      begin
        if FTextures[i]=ls then break;
        inc(lidx);
      end;
      if lidx=ltextcount then
      begin
        if ltextcount=Length(FTextures) then SetLength(FTextures,Length(FTextures)+50);
        FTextures[ltextcount]:=ls;
        inc(ltextcount);
      end;
      ltxt[ltxtcount].texture:=lidx;

      Log('    '+TxtAliasList[ltxt[ltxtcount].alias,true],ls);
      inc(ltxtcount);
    end;
  end;
  SetLength(FTextures,ltextcount);
  SetLength(ltxt,ltxtcount);

  // materials
  lcnt:=memReadWord(aptr);
  SetLength(FMaterials,lcnt);
  Log('materials',lcnt);

  for j:=0 to lcnt-1 do
  begin
    mtl:=@FMaterials[j];
    SetMaterialDefaults(mtl);

    LogLn;
    Log('  Material',j);
    Log('hash',HexStr(memReadDWord(aptr),8));

    ls:=memReadText(aptr); //ShaderName?
    Log(ls+' (size of next data, mat+consts)',HexStr(memReadDWord(aptr),8));

    result:=result and ReadHobMaterial(aptr,mtl,ltxt);
  end;
  LogLn;
  SetLength(ltxt,0);
end;

//===== TL =====

procedure TRGMesh.ReadMaterialSimple(abuf:PByte; asize:integer);
var
  lptr:PByte;
  lmat:PMaterial;
  pc:PAnsiChar;
  ls:AnsiString;
  i,idx,stage:integer;
  isMaterial,isTech,isPass,isTexture:boolean;
begin
  stage:=0;

  isMaterial:=false;
  isTech    :=false;
  isPass    :=false;
  isTexture :=false;

  lptr:=abuf;
  while lptr<(abuf+asize) do
  begin
    pc:=GetLine(lptr);
    while (pc^=' ') or (pc^=#9) do inc(pc);
    if pc^<>#0 then
    begin
      if pc^='{' then inc(stage)
      else if pc^='}' then
      begin
        if stage=0 then break // error
        else if stage=1 then
        begin
          isMaterial:=false;
        end
        else if stage=2 then
        begin
          isTech:=false;
        end
        else if stage=3 then
        begin
          isPass:=false;
        end
        else if stage=4 then
        begin
          if isTexture then
          begin
            // place to choose texture type by additional properties
            isTexture:=false;
          end;
        end;
        dec(stage);
      end
      else
      begin
        if stage=0 then
        begin
          if strlcomp(pc,'material',8)=0 then
          begin
            isMaterial:=true;
            inc(pc,9);
            while (pc^=' ') or (pc^=#9) do inc(pc);
            // split to 2 strings coz FMaterials can be reassigned inside AddMaterial
            idx:=AddMaterial(pc);
            lmat:=@FMaterials[idx];
          end;
        end
        else if stage=1 then
        begin
          if isMaterial then
          begin
            if strlcomp(pc,'technique',9)=0 then
              isTech:=true;
          end;
        end
        else if stage=2 then
        begin
          if isTech then
          begin
            if strlcomp(pc,'pass',4)=0 then
              isPass:=true;
          end;
        end
        else if stage=3 then
        begin
          if isPass then
          begin
            if strlcomp(pc,'texture_unit',12)=0 then
              isTexture:=true
            else if strlcomp(pc,'diffuse' ,7)=0 then SplitColor(pc+8,lmat^.diffuse)
            else if strlcomp(pc,'ambient' ,7)=0 then SplitColor(pc+8,lmat^.ambient)
            else if strlcomp(pc,'specular',8)=0 then SplitColor(pc+9,lmat^.specular)
            else if strlcomp(pc,'emissive',8)=0 then SplitColor(pc+9,lmat^.emissive)
          end;
        end
        else if stage=4 then
        begin
          if isTexture then
          begin
            if strlcomp(pc,'texture',7)=0 then
            begin
              inc(pc,8);
              while (pc^=' ') or (pc^=#9) do inc(pc);
              ls:=pc;
              idx:=-1;
              for i:=0 to High(FTextures) do
              begin
                if FTextures[i]=ls then
                begin
                  idx:=i;
                  break;
                end;
              end;
              if idx<0 then
              begin
                idx:=Length(FTextures);
                SetLength(FTextures,idx+1);
                FTextures[idx]:=ls;
              end;
              //!! Keep just first texture
              if lmat^.Textures[txtDiffuse]<0 then
                 lmat^.Textures[txtDiffuse]:=idx;
            end;
          end;
        end
      end;
    end;
  end;
end;

{%ENDREGION Read materials}

function TRGMesh.AddMaterial(const aname:string):integer;
var
  ls:string;
  i:integer;
begin
  ls:=aname;

  if FVersion in [90,91] then
  begin
    i:=Pos('_DELETEME',ls); if i>0 then SetLength(ls,i-1);
    i:=Pos('Skinned'  ,ls); if i>0 then SetLength(ls,i-1);
    if Pos('MEDIA/'   ,ls)=1 then ls:=ExtractName(ls);
    if ls[1]='_' then Delete(ls,1,1);
  end;

  for i:=0 to High(FMaterials) do
    if FMaterials[i].name=ls then exit(i); 

  result:=Length(FMaterials);
  SetLength(FMaterials,result+1);
  SetMaterialDefaults(@FMaterials[result]);

  FMaterials[result].name:=ls;
end;

function TRGMesh.GetMaterial(aid:integer):PMaterial;
var
  i:integer;
begin
  for i:=0 to High(FMaterials) do
    if FMaterials[i].id=aid then exit(@FMaterials[i]);
  result:=nil;
end;

//===== *.MATERIAL processing =====

procedure TRGMesh.WriteRGMaterial(astream:TStream; aver:integer);
begin
  // write texture list
  // write materials
end;

procedure TRGMesh.WriteHobMaterial(astream:TStream);
begin
  // build THobTextureList
  // write materials
end;

{$ENDIF}
