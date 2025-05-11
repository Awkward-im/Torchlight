{}
{NOTE: GetMaterial replaces texture extensions to DDS}
{$IFDEF Interface}

const
  // texture indexes
  txtDiffuse      = 0;
  txtUnknown1     = 1;
  txtEnvDiffuse   = 2;
  txtEnvSpecular  = 3;
  txtGlow         = 4;
  txtNormal       = 5;
  txtUnknown2     = 6;
  txtUnknown3     = 7;
  txtSpecular     = 8;
  txtUnknown4     = 9;
  txtPaint        = 10;
  txtPaintSurface = 11;

  txtLast         = 11;

type
  PMaterial = ^TMaterial;
  TMaterial = record
    name    :string;
    ambient :TVector3;
    diffuse :TVector3;
    specular:TVector3;
    emissive:TVector3;
    add     :TVector3;
    textures:array [0..txtLast] of integer;

    // material
    shadows     :boolean;
    cast_shadows:boolean;
    // pass
    depth_write:boolean;
    depth_check:boolean;
  end;

{$ELSE}

type
  THobTexture = record
    _type:string;
    _file:string;
    _material:integer;
  end;

type
  TRGB = packed record // byte used, word is in file
    R:Word;
    G:Word;
    B:Word;
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
      ls:=RGBToStr(FMaterials[i].ambient ); if ls<>'' then sl.Add('Ka '+ls);
      ls:=RGBToStr(FMaterials[i].diffuse ); if ls<>'' then sl.Add('Kd '+ls);
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
      ls:=RGBToStr(mtl^.ambient ); if ls<>'' then sl.Add('      ambient  '+ls);      // 1 1 1 1
      ls:=RGBToStr(mtl^.diffuse ); if ls<>'' then sl.Add('      diffuse ' +ls);      // 1 1 1 1
      ls:=RGBToStr(mtl^.specular); if ls<>'' then sl.Add('      specular '+ls+' 0'); // 0 0 0 0
      ls:=RGBToStr(mtl^.emissive); if ls<>'' then sl.Add('      emissive '+ls);      // 0 0 0 0

      if FTextures<>nil then
      begin
        for j:=0 to txtLast do
        begin
          if mtl^.textures[j]>=0 then
          begin
            sl.Add('');
            sl.Add('      texture_unit');
            sl.Add('      {');
            //!!!!
            sl.Add('        texture '+ChangeFileExt(FTextures[mtl^.textures[j]],'.dds'));
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
 01 80   7+13+02+8  B:1+      3+3+3+3
 02 92   7+13+05+8                           +3C
 03 94   8+13+05+8                     +1A
 07 104 10+14+05+9  B:1+1+    3+3+3+3  +2A+1B   +1D
 08 114 10+17+05+10 B:1+1+  3+3+3+3+3     +3B   +1D
 09 118 12+17+05+10                    +2A
 -----------------
 0D 140 15+19+06+12 B:1+1+2+3+3+3+3+3  +3A+2B+1C+2D
 0E 160 15+19+11+12                          +5C
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
    LogLn();
    Log('name',mtl^.name); // material name

    ltmp:=memReadWord(aptr);
    if ltmp<>i then Log('!!!! number is not like order',ltmp);
    Log('{00} w material #'   ,ltmp);
    Log('{01} w (part of 00?)',memReadWord(aptr));
    Log('{02} w can be >1'    ,memReadWord(aptr));
    Log('{03} w (part of 02?)',memReadWord(aptr));
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

    LogLn();
    Log('>alpha?','');

    Log('{00} w' ,Int16(memReadWord(aptr))); // alpha_rejection value?
{
    enum CompareFunction : uint8
      0  CMPF_ALWAYS_FAIL,  //!< Never  writes a pixel to the render target
      1  CMPF_ALWAYS_PASS,  //!< Always writes a pixel to the render target
      2  CMPF_LESS,         //!< Write if (new_Z <  existing_Z)
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

    LogLn();
    Log('>colors?','');

    if aver>=8 then
    begin
      memRead(aptr,lrgb,3*2);
      RGBtoFloat(lrgb,mtl^.add);
      Log('unknown',
        ' '+IntToStr(lrgb.R)+
        ' '+IntToStr(lrgb.G)+
        ' '+IntToStr(lrgb.B));
    end;

    // ambient?
    memRead(aptr,lrgb,3*2);
    RGBtoFloat(lrgb,mtl^.ambient);
    Log('ambient',
      ' '+IntToStr(lrgb.R)+
      ' '+IntToStr(lrgb.G)+
      ' '+IntToStr(lrgb.B));

    // diffuse?
    memRead(aptr,lrgb,3*2);
    RGBtoFloat(lrgb,mtl^.diffuse);
    Log('diffuse',
      ' '+IntToStr(lrgb.R)+
      ' '+IntToStr(lrgb.G)+
      ' '+IntToStr(lrgb.B));

    // emissive? specular?
    memRead(aptr,lrgb,3*2);
    RGBtoFloat(lrgb,mtl^.specular);
    Log('specular',
      ' '+IntToStr(lrgb.R)+
      ' '+IntToStr(lrgb.G)+
      ' '+IntToStr(lrgb.B));

    // specular? emissive?
    memRead(aptr,lrgb,3*2);
    RGBtoFloat(lrgb,mtl^.emissive);
    Log('emissive',
      ' '+IntToStr(lrgb.R)+
      ' '+IntToStr(lrgb.G)+
      ' '+IntToStr(lrgb.B));

    //--------------------------------

    LogLn();
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
    if aver>=14 then
    begin
      Log('{E1} f' ,memReadFloat(aptr));
      Log('{E2} f' ,memReadFloat(aptr));
      Log('{E3} f' ,memReadFloat(aptr));
      Log('{E4} f' ,memReadFloat(aptr));
      Log('{E5} f' ,memReadFloat(aptr)); // need to check for non-zero
    end;

    //--------------------------------

    LogLn();
    Log('>textures','');
    // initialize by -1
    FillChar(mtl^.textures,SizeOf(mtl^.textures),255);
    
    // order number like texture_unit name
    mtl^.textures[txtDiffuse     ]:=LogTexture('diff',Int32(memReadDWord(aptr)));
    mtl^.textures[txtUnknown1    ]:=LogTexture('??  ',Int32(memReadDWord(aptr)));
    if aver>=8 then
      mtl^.textures[txtEnvDiffuse]:=LogTexture('8 env',Int32(memReadDWord(aptr)));
    mtl^.textures[txtEnvSpecular ]:=LogTexture('env spec',Int32(memReadDWord(aptr)));
    mtl^.textures[txtGlow        ]:=LogTexture('glow',Int32(memReadDWord(aptr)));
    mtl^.textures[txtNormal      ]:=LogTexture('norm',Int32(memReadDWord(aptr)));
    mtl^.textures[txtUnknown2    ]:=LogTexture('   5',Int32(memReadDWord(aptr)));
    mtl^.textures[txtUnknown3    ]:=LogTexture('   6',Int32(memReadDWord(aptr)));
    mtl^.textures[txtSpecular    ]:=LogTexture('spec',Int32(memReadDWord(aptr)));
    if aver>=7 then
      mtl^.textures[txtUnknown4]:=LogTexture('??7+',Int32(memReadDWord(aptr)));
    if aver>=13 then
    begin
      mtl^.textures[txtPaint       ]:=LogTexture('14 paint  ',Int32(memReadDWord(aptr)));
      mtl^.textures[txtPaintSurface]:=LogTexture('14 surface',Int32(memReadDWord(aptr)));
    end;
  end;

  result:=true;
end;


function TRGMesh.ReadHobMaterial(var aptr:PByte; aver:integer):boolean;
const
  type_int    = 1;
  type_float  = 2;
  type_float4 = 3;
  type_four   = 4;

var
  mtl:PMaterial;
  lname,ls,lsv:string;
  ltxt:array of THobTexture;
  lr,lg,lb,lalpha:single;
  lint,i,j,lcnt1,lcnt,ltype:integer;
  //textures
  lcount,ltxtcount:integer;
  lidx,k,l:integer;
begin
  result:=false;

  SetLength(ltxt,100);
  ltxtcount:=0;

  lcnt1:=memReadWord(aptr);
  Log('>material textures',lcnt1);

  for j:=0 to lcnt1-1 do
  begin
    Log('  Material',j);
    // base textures
    lcnt:=memReadWord(aptr);
    for i:=0 to lcnt-1 do
    begin
      if ltxtcount=Length(ltxt) then SetLength(ltxt,Length(ltxt)+50);
      ls :=memReadText(aptr);
      lsv:=memReadText(aptr);
      with ltxt[ltxtcount] do
      begin
        _material:=j;
        _type    :=ls;
        _file    :=lsv;
      end;
      inc(ltxtcount);
      Log('    '+ls,lsv);
    end;
  end;

  lcnt1:=memReadWord(aptr);
  SetLength(FMaterials,lcnt1);
  Log('materials',lcnt1);

  SetLength(FTextures,ltxtcount);
  lcount:=0;

  for j:=0 to lcnt1-1 do
  begin
    mtl:=@FMaterials[j];
    FillChar(mtl^,SizeOf(TMaterial),0);
    for i:=0 to txtLast do
      mtl^.textures[i]:=-1;

    LogLn;
    Log('  Material',j);
    Log('checksum?',HexStr(memReadDWord(aptr),8));

    ls:=memReadText(aptr);
    Log(ls+' (size of next data, mat+consts)',HexStr(memReadDWord(aptr),8));

    mtl^.name:=memReadText(aptr);       // material/pass name
    Log(ls,memReadDWord(aptr));         // number?

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
               if lname='const_WriteDepth' then mtl^.depth_write:=true
          else if lname='const_CheckDepth' then mtl^.depth_check:=true
          ;

          // textures
{
  1 - get block with material=i
  2 - search texture with name
  3 - add to Textures block (skip if exists)
  4 - save number
}
            lidx:=-1;
                 if lname='const_DiffuseTexture'        then begin lidx:=txtDiffuse ; ls:='DiffuseTexture2D' end
            else if lname='const_SpecularTexture'       then begin lidx:=txtSpecular; ls:='SpecularMap2D' end
            else if lname='const_OutlineTexture'        then begin lidx:=0          ; ls:='OutlineMap2D' end
            else if lname='const_EmissiveTexture'       then begin lidx:=0          ; ls:='EmissiveMap2D' end
            else if lname='const_NormalmapTexture'      then begin lidx:=txtNormal  ; ls:='NormalTexture2D' end
            else if lname='const_DistortionMaskTexture' then begin lidx:=0          ; ls:='DistortionMask2D' end
            ;
            if lidx>0 then
            begin
              lint:=-1;
              for k:=0 to ltxtcount-1 do
              begin
                if (ltxt[k]._material=j) and (ltxt[k]._type=ls) then
                begin
                  // search for existing texture
                  for l:=0 to lcount-1 do
                  begin
                    if FTextures[l]=ltxt[k]._file then
                    begin
                      lint:=l;
                      break;
                    end;
                  end;
                  // add texture
                  if lint<0 then
                  begin
                    FTextures[lcount]:=ltxt[k]._file;
                    lint:=lcount;
                    inc(lcount);
                  end;
                  FMaterials[j].textures[lidx]:=lint;
                  break;
                end;
              end;
            end;
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
          if      lname='const_DiffuseColor'  then with mtl^.diffuse  do begin X:=lr; Y:=lg; Z:=lb; end
          else if lname='const_SpecularColor' then with mtl^.specular do begin X:=lr; Y:=lg; Z:=lb; end
          else if lname='const_EmissiveColor' then with mtl^.emissive do begin X:=lr; Y:=lg; Z:=lb; end
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
  end;
  LogLn;
  SetLength(ltxt,0);
end;

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
  end;

  for i:=0 to High(FMaterials) do
    if FMaterials[i].name=ls then exit(i); 

  result:=Length(FMaterials);
  SetLength(FMaterials,result+1);
//  FillChar(FMaterials[result].textures,SizeOf(FMaterials[result].textures),255);
  for i:=0 to txtLast do
    FMaterials[result].textures[i]:=-1;

  FMaterials[result].name:=ls;
end;

{$ENDIF}
