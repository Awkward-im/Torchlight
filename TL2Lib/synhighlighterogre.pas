unit SynHighlighterOgre;

interface

uses
  Classes, Graphics, SynEditTypes, SynEditHighlighter,
  SynEditHighlighterFoldBase, SynEditStrConst;

type
  TtkTokenKind = (tkNull, tkSpace, tkComment, tkSymbol, tkIdent,
      tkKeyword1, tkKeyword2, tkKeyword3, tkKeyword4, tkNumber);

  TRangeState = (rsComment, rsText);

type
  TProcTableProc = procedure of object;

  { TSynOgreSyn }

  TSynOgreSyn = class(TSynCustomFoldHighlighter)
  private
    fRange: TRangeState;
    fLine: PChar;
    Run: Longint;
    fTokenPos: Integer;
    fTokenID: TtkTokenKind;
    fLineNumber: Integer;

    fKeyword1Attri   : TSynHighlighterAttributes;
    fKeyword2Attri   : TSynHighlighterAttributes;
    fKeyword3Attri   : TSynHighlighterAttributes;
    fKeyword4Attri   : TSynHighlighterAttributes;
    fCommentAttri    : TSynHighlighterAttributes;
    fSymbolAttri     : TSynHighlighterAttributes;
    fNumberAttri     : TSynHighlighterAttributes;

    fProcTable: array [#0..#255] of TProcTableProc;
    fExtType:integer;

    procedure NullProc;
    procedure CarriageReturnProc;
    procedure LineFeedProc;
    procedure AnsiCProc;
    procedure SpaceProc;
    procedure SlashProc;
    procedure FoldOpenProc;
    procedure FoldCloseProc;
    procedure SymbolProc;
    procedure TextProc;
    procedure MakeMethodTables;
    function NextTokenIs(T: String): Boolean;
    function CheckKeyword(const astr:string):integer;

  protected
    function GetIdentChars: TSynIdentChars; override;
  public
    class function GetLanguageName: string; override;
  public
    constructor Create(AOwner: TComponent); override;
    function  GetDefaultAttribute(Index: integer): TSynHighlighterAttributes; override;
    function  GetEol: Boolean; override;
    function  GetRange: Pointer; override;
    function  GetTokenID: TtkTokenKind;
    procedure SetLine(const NewValue: string; LineNumber:Integer); override;
    function  GetToken: string; override;
    procedure GetTokenEx(out TokenStart: PChar; out TokenLength: integer); override;
    function  GetTokenAttribute: TSynHighlighterAttributes; override;
    function  GetTokenKind: integer; override;
    function  GetTokenPos: Integer; override;
    procedure Next; override;
    procedure SetRange(Value: Pointer); override;
    procedure ReSetRange; override;
    function  CheckType(const aext:string):boolean;

    property IdentChars;
  published
    property Keyword1Attri: TSynHighlighterAttributes read fKeyword1Attri write fKeyword1Attri;
    property Keyword2Attri: TSynHighlighterAttributes read fKeyword2Attri write fKeyword2Attri;
    property Keyword3Attri: TSynHighlighterAttributes read fKeyword3Attri write fKeyword3Attri;
    property Keyword4Attri: TSynHighlighterAttributes read fKeyword4Attri write fKeyword4Attri;
    property CommentAttri : TSynHighlighterAttributes read fCommentAttri  write fCommentAttri;
    property SymbolAttri  : TSynHighlighterAttributes read fSymbolAttri   write fSymbolAttri;
    property NumberAttri  : TSynHighlighterAttributes read fNumberAttri   write fNumberAttri;
  end;

implementation

const
  SYNS_LangOgre = 'Ogre';

const
  NameChars : set of char = ['0'..'9', 'a'..'z', 'A'..'Z', '_'];

constructor TSynOgreSyn.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  fCommentAttri  := TSynHighlighterAttributes.Create(@SYNS_AttrComment     , SYNS_XML_AttrComment);
  fNumberAttri   := TSynHighlighterAttributes.Create(@SYNS_AttrNumber      , SYNS_XML_AttrNumber);
  fSymbolAttri   := TSynHighlighterAttributes.Create(@SYNS_AttrSymbol      , SYNS_XML_AttrSymbol);
  fKeyword1Attri := TSynHighlighterAttributes.Create(@SYNS_AttrIdentifier  , SYNS_XML_AttrIdentifier);
  fKeyword2Attri := TSynHighlighterAttributes.Create(@SYNS_AttrReservedWord, SYNS_XML_AttrReservedWord);
  fKeyword3Attri := TSynHighlighterAttributes.Create(@SYNS_AttrKey         , SYNS_XML_AttrKey);
  fKeyword4Attri := TSynHighlighterAttributes.Create(@SYNS_AttrDataType    , SYNS_XML_AttrDataType);

  fKeyword1Attri.Foreground:=$000088;  fKeyword1Attri.Style:=[fsBold];
  fKeyword2Attri.Foreground:=$0000FF;  fKeyword1Attri.Style:=[fsBold];
  fKeyword3Attri.Foreground:=$FF0000;
  fKeyword4Attri.Foreground:=$0392EB;
  fCommentAttri .Foreground:=$008080;  fCommentAttri .Style:=[fsItalic];
  fSymbolAttri  .Foreground:=$000000;  fSymbolAttri  .Style:=[fsBold];
  fNumberAttri  .Foreground:=$FB00FF;

  AddAttribute(fKeyword1Attri);
  AddAttribute(fKeyword2Attri);
  AddAttribute(fKeyword3Attri);
  AddAttribute(fKeyword4Attri);
  AddAttribute(fCommentAttri);
  AddAttribute(fSymbolAttri);
  AddAttribute(fNumberAttri);

  SetAttributesOnChange(@DefHighlightChange);

  MakeMethodTables;
  fRange := rsText;
end;

procedure TSynOgreSyn.MakeMethodTables;
var
  i: Char;
begin
  for i:= #0 To #255 do begin
    case i of
    #0 : fProcTable[i] := @NullProc;
    #10: fProcTable[i] := @LineFeedProc;
    #13: fProcTable[i] := @CarriageReturnProc;
    #1..#9, #11, #12, #14..#32:
         fProcTable[i] := @SpaceProc;
    '{': fProcTable[i] := @FoldOpenProc;
    '}': fProcTable[i] := @FoldCloseProc;
    '/': fProcTable[i] := @SlashProc;
    ':', '(', ')', '-', '!', '.', ',', ';', '+', '[', ']', '<', '=', '>', '*':
         fProcTable[i] := @SymbolProc;
    else
         fProcTable[i] := @TextProc;
    end;
  end;
end;

procedure TSynOgreSyn.SetLine(const NewValue: string; LineNumber:Integer);
begin
  inherited;
  fLine := PChar(NewValue);
  Run := 0;
  fLineNumber := LineNumber;
  Next;
end;

procedure TSynOgreSyn.NullProc;
begin
  fTokenID := tkNull;
end;

procedure TSynOgreSyn.CarriageReturnProc;
begin
  fTokenID := tkSpace;
  Inc(Run);
  if fLine[Run] = #10 then Inc(Run);
end;

procedure TSynOgreSyn.LineFeedProc;
begin
  fTokenID := tkSpace;
  Inc(Run);
end;

procedure TSynOgreSyn.SpaceProc;
begin
  fTokenID := tkSpace;
  Inc(Run);
  while fLine[Run] <= #32 do
  begin
    if fLine[Run] in [#0, #10, #13] then break;
    Inc(Run);
  end;
end;

procedure TSynOgreSyn.FoldOpenProc;
begin
  fTokenId := tkSymbol;
  Inc(Run);
  StartCodeFoldBlock(nil,true);
end;

procedure TSynOgreSyn.FoldCloseProc;
begin
  fTokenId := tkSymbol;
  Inc(Run);
  EndCodeFoldBlock(true);
end;

procedure TSynOgreSyn.SlashProc;
begin
  Inc(Run);

//  fRange := rsText;

  if (fLine[Run] = '/') then
    while not (fLine[Run] in [#10, #13, #0]) do Inc(Run)
  else if (fLine[Run] = '*') then
  begin
    fRange := rsComment;
    inc(Run);

    while fLine[Run] <> #0 do
      case fLine[Run] of
        '*':
          if fLine[Run + 1] = '/' then
          begin
            inc(Run, 2);
            fRange := rsText;
            break;
          end else inc(Run);
        #10: break;
        #13: break;
      else
        inc(Run);
      end;
  end
  else
  begin
    fTokenID := tkSymbol;
    exit;
  end;

  fTokenID := tkComment;
end;

procedure TSynOgreSyn.AnsiCProc;
begin
  case FLine[Run] of
    #0:
      begin
        NullProc;
        exit;
      end;
    #10:
      begin
        LineFeedProc;
        exit;
      end;
    #13:
      begin
        CarriageReturnProc;
        exit;
      end;
  end;

  fTokenID := tkComment;

  while fLine[Run] <> #0 do
    case fLine[Run] of
      '*':
        if fLine[Run + 1] = '/' then
        begin
          inc(Run, 2);
          fRange := rsText;
          break;
        end
        else inc(Run);
      #10: break;
      #13: break;
    else inc(Run);
    end;
end;

procedure TSynOgreSyn.SymbolProc;
begin
  if (fLine[Run]='.') and (fLine[Run+1] in ['0'..'9']) then
    TextProc()
  else
  begin
    fTokenID := tkSymbol;
    Inc(Run);
  end;
end;

procedure TSynOgreSyn.TextProc;
var
  ls:string;
  lp,i:integer;
begin
  if not (fLine[Run] in (NameChars+['.'])) then
  begin
    SymbolProc();
    exit;
  end;

  fRange := rsText;
//  while not (fLine[Run] in (NameChars+[#13,#10,#0])) do Inc(Run);
  lp:=Run;
  while fLine[Run] in (NameChars+['.']) do Inc(Run);

  ls:=Copy(fLine+lp,1,Run-lp);
  fTokenId:=tkNumber;
  for lp:=1 to Length(ls) do
  begin
    if not (ls[lp] in ['0'..'9','.']) then
    begin
      i:=CheckKeyword(ls);
      if i<0 then fTokenId:=tkIdent
      else
        case i of
          0: fTokenId:=tkKeyword1;
          1: fTokenId:=tkKeyword2;
          2: fTokenId:=tkKeyword3;
          3: fTokenId:=tkKeyword4;
        end;

      break;
    end;
  end;

end;

procedure TSynOgreSyn.Next;
begin
  fTokenPos := Run;
  if fRange=rsComment then
  begin
    AnsiCProc;
    exit;
  end;
{
  if (fTokenID = tkSymbol) and (fRange = rsText) then
    TextProc()
  else
}
    fProcTable[fLine[Run]]();
end;

function TSynOgreSyn.NextTokenIs(T : String) : Boolean;
var I, Len : Integer;
begin
  Result:= True;
  Len:= Length(T);
  for I:= 1 to Len do
    if (fLine[Run + I] <> T[I]) then
    begin
      Result:= False;
      Break;
    end;
end;

function TSynOgreSyn.GetDefaultAttribute(Index: integer): TSynHighlighterAttributes;
begin
  case Index of
    SYN_ATTR_NUMBER    : Result := fNumberAttri;
    SYN_ATTR_IDENTIFIER: Result := fKeyword2Attri;
    SYN_ATTR_KEYWORD   : Result := fKeyword1Attri;
//    SYN_ATTR_WHITESPACE: Result := fSpaceAttri;
    SYN_ATTR_SYMBOL    : Result := fSymbolAttri;
  else
    Result := nil;
  end;
end;

function TSynOgreSyn.GetEol: Boolean;
begin
  Result := fTokenId = tkNull;
end;

function TSynOgreSyn.GetToken: string;
var
  len: Longint;
begin
  Result := '';
  Len := (Run - fTokenPos);
  SetString(Result, (FLine + fTokenPos), len);
end;

procedure TSynOgreSyn.GetTokenEx(out TokenStart: PChar; out TokenLength: integer);
begin
  TokenLength:=Run-fTokenPos;
  TokenStart:=FLine + fTokenPos;
end;

function TSynOgreSyn.GetTokenID: TtkTokenKind;
begin
  Result := fTokenId;
end;

function TSynOgreSyn.GetTokenAttribute: TSynHighlighterAttributes;
begin
  case fTokenID of
    tkKeyword1   : Result:= fKeyword1Attri;
    tkKeyword2   : Result:= fKeyword2Attri;
    tkKeyword3   : Result:= fKeyword3Attri;
    tkKeyword4   : Result:= fKeyword4Attri;
    tkComment    : Result:= fCommentAttri;
    tkSymbol     : Result:= fSymbolAttri;
    tkNumber     : Result:= fNumberAttri;
  else
    Result := nil;
  end;
end;

function TSynOgreSyn.GetTokenKind: integer;
begin
  Result := Ord(fTokenId);
end;

function TSynOgreSyn.GetTokenPos: Integer;
begin
  Result := fTokenPos;
end;

function TSynOgreSyn.GetRange: Pointer;
begin
  CodeFoldRange.RangeType:=Pointer(PtrUInt(Integer(fRange)));
  Result := inherited;
end;

procedure TSynOgreSyn.SetRange(Value: Pointer);
begin
  inherited;
  fRange := TRangeState(Integer(PtrUInt(CodeFoldRange.RangeType)));
end;

procedure TSynOgreSyn.ReSetRange;
begin
  inherited;
  fRange:= rsText;
end;

function TSynOgreSyn.GetIdentChars: TSynIdentChars;
begin
  Result := NameChars + TSynSpecialChars;
end;

class function TSynOgreSyn.GetLanguageName: string;
begin
  Result := SYNS_LangOgre;
end;

const
  extTypes : array [0..10] of record
    ext:string;
    idx:integer;
  end = (
   (ext:'.MATERIAL'  ; idx:0),
   (ext:'.PROGRAM'   ; idx:0),
   (ext:'.COMPOSITOR'; idx:0),
   (ext:'.OVERLAY'   ; idx:1),
   (ext:'.PARTICLE'  ; idx:2),
   (ext:'.PU'        ; idx:2),
   (ext:'.CG'  ; idx:3),
   (ext:'.CGFX'; idx:3),
   (ext:'.FX'  ; idx:3),
   (ext:'.HLSL'; idx:3),
   (ext:'.GLSL'; idx:3)
  );

function TSynOgreSyn.CheckType(const aext: string): boolean;
var
  i:integer;
begin
  for i:=0 to High(extTypes) do
  begin
    if aext=extTypes[i].ext then
    begin
      fExtType:=extTypes[i].idx;
      exit(true);
    end;
  end;
  fExtType:=-1;
  result:=false;
end;

const
  StrArray : array [0..3,0..3] of array of string = (
    (
      (
        'compositor',
        'target',
        'target_output',
        'compositor_logic',
        'scheme',
        'vertex_program',
        'geometry_program',
        'fragment_program',
        'default_params',
        'material',
        'technique',
        'pass',
        'texture_unit',
        'vertex_program_ref',
        'geometry_program_ref',
        'fragment_program_ref',
        'shadow_caster_vertex_program_ref',
        'shadow_receiver_fragment_program_ref',
        'shadow_receiver_vertex_program_ref',
        'abstract',
        'import',
        'from',
        'cg',
        'hlsl',
        'glsl'
      ),
      (
        'input',
        'texture',
        'render_quad',
        'source',
        'syntax',
        'manual_named_constants',
        'entry_point',
        'profiles',
        'includes_skeletal_animation',
        'includes_morph_animation',
        'includes_pose_animation',
        'uses_vertex_texture_fetch',
        'uses_adjacency_information',
        'target',
        'preprocessor_defines',
        'column_major_matrices',
        'attach',
        'input_operation_type',
        'output_operation_type',
        'max_output_vertices',
        'delegate',
        'param_indexed',
        'param_indexed_auto',
        'param_named',
        'param_named_auto',
        'lod_distances',
        'receive_shadows',
        'transparency_casts_shadows',
        'set',
        'set_texture_alias',
        'scheme',
        'lod_index',
        'shadow_caster_material',
        'shadow_receiver_material',
        'gpu_vendor_rule',
        'gpu_device_rule',
        'ambient',
        'diffuse',
        'specular',
        'emissive',
        'scene_blend',
        'separate_scene_blend',
        'depth_check',
        'depth_write',
        'depth_func',
        'depth_bias',
        'iteration_depth_bias',
        'alpha_rejection',
        'alpha_to_coverage',
        'light_scissor',
        'light_clip_planes',
        'illumination_stage',
        'transparent_sorting',
        'normalise_normals',
        'cull_hardware',
        'cull_software',
        'lighting',
        'shading',
        'polygon_mode',
        'polygon_mode_overrideable',
        'fog_override',
        'colour_write',
        'max_lights',
        'start_light',
        'iteration',
        'point_size',
        'point_sprites',
        'point_size_attenuation',
        'point_size_min',
        'point_size_max',
        'texture_alias',
        'texture',
        'anim_texture',
        'cubic_texture',
        'tex_coord_set',
        'tex_address_mode',
        'tex_border_colour',
        'filtering',
        'max_anisotropy',
        'mipmap_bias',
        'colour_op',
        'colour_op_ex',
        'colour_op_multipass_fallback',
        'alpha_op_ex',
        'env_map',
        'scroll',
        'scroll_anim',
        'rotate',
        'rotate_anim',
        'scale',
        'wave_xform',
        'transform',
        'binding_type',
        'content_type'
      ),
      (
        'PF_A8R8G8B8',
        'PF_R8G8B8A8',
        'PF_R8G8B8',
        'PF_FLOAT16_RGBA',
        'PF_FLOAT16_RGB',
        'PF_FLOAT16_R',
        'PF_FLOAT32_RGBA',
        'PF_FLOAT32_RGB',
        'local_scope',
        'chain_scope',
        'global_scope',
        'PF_FLOAT32_R',
        'int',
        'half',
        'float',
        'float2',
        'float3',
        'float4',
        'float3x3',
        'float3x4',
        'float4x3',
        'float4x4',
        'double',
        'include',
        'exclude',
        'true',
        'false',
        'on',
        'off',
        'none',
        'vertexcolour',
        'add',
        'modulate',
        'alpha_blend',
        'colour_blend',
        'one',
        'zero',
        'dest_colour',
        'src_colour',
        'one_minus_dest_colour',
        'one_minus_src_colour',
        'dest_alpha',
        'src_alpha',
        'one_minus_dest_alpha',
        'one_minus_src_alpha',
        'always_fail',
        'always_pass',
        'less',
        'less_equal',
        'equal',
        'not_equal',
        'greater_equal',
        'greater',
        'clockwise',
        'anticlockwise',
        'back',
        'front',
        'flat',
        'gouraud',
        'phong',
        'solid',
        'wireframe',
        'points',
        'type',
        'linear',
        'exp',
        'exp2',
        'colour',
        'density',
        'start',
        'end',
        'once',
        'once_per_light',
        'per_light',
        'per_n_lights',
        'point',
        'directional',
        'spot',
        '1d',
        '2d',
        '3d',
        'cubic',
        'PF_L8',
        'PF_L16',
        'PF_A8',
        'PF_A4L4',
        'PF_BYTE_LA',
        'PF_R5G6B5',
        'PF_B5G6R5',
        'PF_R3G3B2',
        'PF_A4R4G4B4',
        'PF_A1R5G5B5',
        'PF_R8G8B8',
        'PF_B8G8R8',
        'PF_A8R8G8B8',
        'PF_A8B8G8R8',
        'PF_B8G8R8A8',
        'PF_R8G8B8A8',
        'PF_X8R8G8B8',
        'PF_X8B8G8R8',
        'PF_A2R10G10B10',
        'PF_A2B10G10R10',
        'PF_FLOAT16_R',
        'PF_FLOAT16_RGB',
        'PF_FLOAT16_RGBA',
        'PF_FLOAT32_R',
        'PF_FLOAT32_RGB',
        'PF_FLOAT32_RGBA',
        'PF_SHORT_RGBA',
        'combinedUVW',
        'separateUV',
        'vertex',
        'fragment',
        'named',
        'shadow',
        'wrap',
        'clamp',
        'mirror',
        'border',
        'bilinear',
        'trilinear',
        'anisotropic',
        'replace',
        'source1',
        'source2',
        'modulate_x2',
        'modulate_x4',
        'add_signed',
        'add_smooth',
        'subtract',
        'blend_diffuse_alpha',
        'blend_texture_alpha',
        'blend_current_alpha',
        'blend_manual',
        'dotproduct',
        'blend_diffuse_colour',
        'src_current',
        'src_texture',
        'src_diffuse',
        'src_specular',
        'src_manual',
        'spherical',
        'planar',
        'cubic_reflection',
        'cubic_normal',
        'xform_type',
        'scroll_x',
        'scroll_y',
        'scale_x',
        'scale_y',
        'wave_type',
        'sine',
        'triangle',
        'square',
        'sawtooth',
        'inverse_sawtooth',
        'base',
        'frequency',
        'phase',
        'amplitude',
        'arbfp1',
        'arbvp1',
        'glslv',
        'glslf',
        'gp4vp',
        'gp4gp',
        'gp4fp',
        'fp20',
        'fp30',
        'fp40',
        'vp20',
        'vp30',
        'vp40',
        'ps_1_1',
        'ps_1_2',
        'ps_1_3',
        'ps_1_4',
        'ps_2_0',
        'ps_2_a',
        'ps_2_b',
        'ps_2_x',
        'ps_3_0',
        'ps_3_x',
        'vs_1_1',
        'vs_2_0',
        'vs_2_a',
        'vs_2_x',
        'vs_3_0',
        '1d',
        '2d',
        '3d',
        '4d'
      ),
      (
        'gamma',
        'pooled',
        'no_fsaa',
        'depth_pool',
        'scope',
        'target_width',
        'target_height',
        'target_width_scaled',
        'target_height',
        'scaled',
        'previous',
        'world_matrix',
        'inverse_world_matrix',
        'transpose_world_matrix',
        'inverse_transpose_world_matrix',
        'world_matrix_array_3x4',
        'view_matrix',
        'inverse_view_matrix',
        'transpose_view_matrix',
        'inverse_transpose_view_matrix',
        'projection_matrix',
        'inverse_projection_matrix',
        'transpose_projection_matrix',
        'inverse_transpose_projection_matrix',
        'worldview_matrix',
        'inverse_worldview_matrix',
        'transpose_worldview_matrix',
        'inverse_transpose_worldview_matrix',
        'viewproj_matrix',
        'inverse_viewproj_matrix',
        'transpose_viewproj_matrix',
        'inverse_transpose_viewproj_matrix',
        'worldviewproj_matrix',
        'inverse_worldviewproj_matrix',
        'transpose_worldviewproj_matrix',
        'inverse_transpose_worldviewproj_matrix',
        'texture_matrix',
        'render_target_flipping',
        'light_diffuse_colour',
        'light_specular_colour',
        'light_attenuation',
        'spotlight_params',
        'light_position',
        'light_direction',
        'light_position_object_space',
        'light_direction_object_space',
        'light_distance_object_space',
        'light_position_view_space',
        'light_direction_view_space',
        'light_power',
        'light_diffuse_colour_power_scaled',
        'light_specular_colour_power_scaled',
        'light_number',
        'light_diffuse_colour_array',
        'light_specular_colour_array',
        'light_diffuse_colour_power_scaled_array',
        'light_specular_colour_power_scaled_array',
        'light_attenuation_array',
        'spotlight_params_array',
        'light_position_array',
        'light_direction_array',
        'light_position_object_space_array',
        'light_direction_object_space_array',
        'light_distance_object_space_array',
        'light_position_view_space_array',
        'light_direction_view_space_array',
        'light_power_array',
        'light_count',
        'light_casts_shadows',
        'ambient_light_colour',
        'surface_ambient_colour',
        'surface_diffuse_colour',
        'surface_specular_colour',
        'surface_emissive_colour',
        'surface_shininess',
        'derived_ambient_light_colour',
        'derived_scene_colour',
        'derived_light_diffuse_colour',
        'derived_light_specular_colour',
        'derived_light_diffuse_colour_array',
        'derived_light_specular_colour_array',
        'fog_colour',
        'fog_params',
        'camera_position',
        'camera_position_object_space',
        'lod_camera_position',
        'lod_camera_position_object_space',
        'time_0_x',
        'costime_0_x',
        'sintime_0_x',
        'tantime_0_x',
        'time_0_x_packed',
        'time_0_1',
        'costime_0_1',
        'sintime_0_1',
        'tantime_0_1',
        'time_0_1_packed',
        'time_0_2pi',
        'costime_0_2pi',
        'sintime_0_2pi',
        'tantime_0_2pi',
        'time_0_2pi_packed',
        'frame_time',
        'fps',
        'viewport_width',
        'viewport_height',
        'inverse_viewport_width',
        'inverse_viewport_height',
        'viewport_size',
        'texel_offsets',
        'view_direction',
        'view_side_vector',
        'view_up_vector',
        'fov',
        'near_clip_distance',
        'far_clip_distance',
        'texture_viewproj_matrix',
        'texture_viewproj_matrix_array',
        'texture_worldviewproj_matrix',
        'texture_worldviewproj_matrix_array',
        'spotlight_viewproj_matrix',
        'spotlight_worldviewproj_matrix',
        'scene_depth_range',
        'shadow_scene_depth_range',
        'shadow_colour',
        'shadow_extrusion_distance',
        'texture_size',
        'inverse_texture_size',
        'packed_texture_size',
        'pass_number',
        'pass_iteration_number',
        'animation_parametric',
        'custom'
      )
    ),

    (
      (
        'template',
        'element',
        'container',
        'zorder'
      ),
      (
        'metrics_mode',
        'caption',
        'width',
        'height',
        'font_name',
        'char_height',
        'space_width',
        'colour',
        'material',
        'transparent',
        'uv_coords',
        'top',
        'left',
        'vert_align',
        'horz_align',
        'alignment',
        'border_material',
        'border_size',
        'border_topleft_uv',
        'border_top_uv',
        'border_topright_uv',
        'border_left_uv',
        'border_right_uv',
        'border_bottomleft_uv',
        'border_bottom_uv',
        'border_bottomright_uv'
      ),
      (
        'pixels',
        'relative',
        'true',
        'false',
        'center',
        'bottom',
        'right'
      ),
      (
        'Panel',
        'BorderPanel',
        'TextArea'
      )
    ),

    (
      (
        'particle_system',
        'emitter',
        'affector'
      ),
      (
        'quota',
        'material',
        'particle_width',
        'particle_height',
        'cull_each',
        'billboard_type',
        'billboard_origin',
        'billboard_rotation_type',
        'common_direction',
        'common_up_vector',
        'renderer',
        'sorted',
        'local_space',
        'point_rendering',
        'accurate_facing',
        'iteration_interval',
        'nonvisible_update_timeout',
        'angle',
        'colour',
        'colour_range_start',
        'colour_range_end',
        'direction',
        'emission_rate',
        'position',
        'velocity',
        'velocity_min',
        'velocity_max',
        'time_to_live',
        'time_to_live_min',
        'time_to_live_max',
        'duration',
        'duration_min',
        'duration_max',
        'repeat_delay',
        'repeat_delay_min',
        'repeat_delay_max',
        'width',
        'height',
        'depth',
        'inner_width',
        'inner_height',
        'inner_depth',
        'emit_emitter_quota',
        'name',
        'emit_emitter',
        'force_vector',
        'force_application',
        'red',
        'green',
        'blue',
        'alpha',
        'red1',
        'red2',
        'green1',
        'green2',
        'blue1',
        'blue2',
        'alpha1',
        'alpha2',
        'state_change',
        'rate',
        'rotation_speed_range_start',
        'rotation_speed_range_end',
        'rotation_range_start',
        'rotation_range_end',
        'time0',
        'colour0',
        'time1',
        'colour1',
        'time2',
        'colour2',
        'time3',
        'colour3',
        'time4',
        'colour4',
        'time5',
        'colour5',
        'image',
        'plane_point',
        'plane_normal',
        'bounce',
        'randomness',
        'scope',
        'keep_velocity'
      ),
      (
        'true',
        'false',
        'point',
        'oriented_common',
        'oriented_self',
        'perpendicular_common',
        'perpendicular_self',
        'top_left',
        'top_center',
        'top_right',
        'center_left',
        'center',
        'center_right',
        'bottom_left',
        'bottom_center',
        'bottom_right',
        'vertex',
        'texcoord',
        'on',
        'off',
        'average',
        'add'
      ),
      (
        'Point',
        'Box',
        'Cylinder',
        'Ellipsoid',
        'HollowEllipsoid',
        'Ring',
        'LinearForce',
        'ColourFader',
        'ColourFader2',
        'Scaler',
        'Rotator',
        'ColourInterpolator',
        'ColourImage',
        'DeflectorPlane',
        'DirectionRandomiser'
      )
    ),

    (
      (
        'struct',
        'discard',
        'returntechnique',
        'pass',
        'compile',
        'trunc',
        'arbfp1',
        'arbvp1',
        'fp20',
        'fp30',
        'fp40',
        'glslf',
        'glslg',
        'glslv',
        'gp4',
        'gp4fp',
        'gp4gp',
        'gp4vp',
        'hlslf',
        'hlslv',
        'ps_1_1',
        'ps_1_2',
        'ps_1_3',
        'ps_2_0',
        'ps_2_x',
        'ps_3_0',
        'ps_4_0',
        'vp20',
        'vp30',
        'vp40',
        'vs_4_0',
        'gs_4_0',
        'x',
        'y',
        'z',
        'w',
        'xy',
        'xz',
        'xw',
        'yz',
        'yw',
        'zw',
        'xyz',
        'xyw',
        'xzw',
        'yzw',
        'xyzw',
        'r',
        'g',
        'b',
        'a',
        'rg',
        'rb',
        'ra',
        'gb',
        'ga',
        'ba',
        'rgb',
        'rga',
        'rba',
        'gba',
        'rgba',
        'argb'
      ),
      (
        'return',
        'bool',
        'const',
        'static',
        'uniform',
        'varying',
        'register',
        'in',
        'inout',
        'interface',
        'out',
        'void',
        'while',
        'for',
        'do',
        'if',
        'else',
        'typedef',
        '_SEQ',
        '_SGE',
        '_SGT',
        '_SLE',
        '_SLT',
        '_SNE',
        'HPOS',
        'POSITION',
        'PSIZ',
        'WPOS',
        'COLOR',
        'COLOR0',
        'COLOR1',
        'COLOR2',
        'COLOR3',
        'COL0',
        'COL1',
        'BCOL0',
        'BCOL1',
        'FOGP',
        'FOGC',
        'NRML',
        'NORMAL',
        'TEXCOORD0',
        'TEXCOORD1',
        'TEXCOORD2',
        'TEXCOORD3',
        'TEXCOORD4',
        'TEXCOORD5',
        'TEXCOORD6',
        'TEXCOORD7',
        'TANGENT0',
        'TANGENT1',
        'TANGENT2',
        'TANGENT3',
        'TANGENT4',
        'TANGENT5',
        'TANGENT6',
        'TANGENT7',
        'TEX0',
        'TEX1',
        'TEX2',
        'TEX3',
        'TEX4',
        'TEX5',
        'TEX6',
        'TEX7',
        'DEPR',
        'DEPTH',
        'ATTR0',
        'ATTR1',
        'ATTR2',
        'ATTR3',
        'ATTR4',
        'ATTR5',
        'ATTR6',
        'ATTR7',
        'ATTR8',
        'ATTR9',
        'ATTR10',
        'ATTR11',
        'ATTR12',
        'ATTR13',
        'ATTR14',
        'ATTR15',
        'POINT',
        'POINT_OUT',
        'LINE',
        'LINE_ADJ',
        'LINE_OUT',
        'TRIANGLE_OUT',
        'TRIANGLE',
        'TRIANGLE_ADJ'
      ),
      (
        'int1',
        'int2',
        'int3',
        'int4',
        'float',
        'float1',
        'float2',
        'float3',
        'float4',
        'float1x1',
        'float1x2',
        'float1x3',
        'float1x4',
        'float2x1',
        'float2x2',
        'float2x3',
        'float2x4',
        'float3x1',
        'float3x2',
        'float3x3',
        'float3x4',
        'float4x1',
        'float4x2',
        'float4x3',
        'float4x4',
        'fixed',
        'fixed1',
        'fixed2',
        'fixed3',
        'fixed4',
        'half',
        'half1',
        'half2',
        'half3',
        'half4'
      ),
      (
        'sincos',
        'abs',
        'acos',
        'asin',
        'atan',
        'atan2',
        'ceil',
        'clamp',
        'cos',
        'cosh',
        'cross',
        'ddx',
        'ddy',
        'degrees',
        'dot',
        'exp',
        'exp2',
        'floor',
        'fmod',
        'frexp',
        'frac',
        'isfinite',
        'isinf',
        'isnan',
        'ldexp',
        'log',
        'log2',
        'log10',
        'max',
        'min',
        'mix',
        'mul',
        'lerp',
        'modf',
        'noise',
        'pow',
        'radians',
        'round',
        'rsqrt',
        'sign',
        'sin',
        'sinh',
        'smoothstep',
        'step',
        'sqrt',
        'tan',
        'tanh',
        'distance',
        'fresnel',
        'length',
        'normalize',
        'reflect',
        'reflectn',
        'refract',
        'refractn',
        'tex1D',
        'f1tex1D',
        'f2tex1D',
        'f3tex1D',
        'f4tex1D',
        'h1tex1D',
        'h2tex1D',
        'h3tex1D',
        'h4tex1D',
        'x1tex1D',
        'x2tex1D',
        'x3tex1D',
        'x4tex1D',
        'tex1Dbias',
        'tex2Dbias',
        'tex3Dbias',
        'texRECTbias',
        'texCUBEbias',
        'tex1Dlod',
        'tex2Dlod',
        'tex3Dlod',
        'texRECTlod',
        'texCUBElod',
        'tex1Dproj',
        'f1tex1Dproj',
        'f2tex1Dproj',
        'f3tex1Dproj',
        'f4tex1Dproj',
        'h1tex1Dproj',
        'h2tex1Dproj',
        'h3tex1Dproj',
        'h4tex1Dproj',
        'x1tex1Dproj',
        'x2tex1Dproj',
        'x3tex1Dproj',
        'x4tex1Dproj',
        'tex2D',
        'f1tex2D',
        'f2tex2D',
        'f3tex2D',
        'f4tex2D',
        'h1tex2D',
        'h2tex2D',
        'h3tex2D',
        'h4tex2D',
        'x1tex2D',
        'x2tex2D',
        'x3tex2D',
        'x4tex2D',
        'tex2Dproj',
        'f1tex2Dproj',
        'f2tex2Dproj',
        'f3tex2Dproj',
        'f4tex2Dproj',
        'h1tex2Dproj',
        'h2tex2Dproj',
        'h3tex2Dproj',
        'h4tex2Dproj',
        'x1tex2Dproj',
        'x2tex2Dproj',
        'x3tex2Dproj',
        'x4tex2Dproj',
        'tex3D',
        'f1tex3D',
        'f2tex3D',
        'f3tex3D',
        'f4tex3D',
        'h1tex3D',
        'h2tex3D',
        'h3tex3D',
        'h4tex3D',
        'x1tex3D',
        'x2tex3D',
        'x3tex3D',
        'x4tex3D',
        'tex3Dproj',
        'f1tex3Dproj',
        'f2tex3Dproj',
        'f3tex3Dproj',
        'f4tex3Dproj',
        'h1tex3Dproj',
        'h2tex3Dproj',
        'h3tex3Dproj',
        'h4tex3Dproj',
        'x1tex3Dproj',
        'x2tex3Dproj',
        'x3tex3Dproj',
        'x4tex3Dproj',
        'tex1CUBE',
        'f1texCUBE',
        'f2texCUBE',
        'f3texCUBE',
        'f4texCUBE',
        'h1texCUBE',
        'h2texCUBE',
        'h3texCUBE',
        'h4texCUBE',
        'x1texCUBE',
        'x2texCUBE',
        'x3texCUBE',
        'x4texCUBE',
        'texCUBEproj',
        'f1texCUBEproj',
        'f2texCUBEproj',
        'f3texCUBEproj',
        'f4texCUBEproj',
        'h1texCUBEproj',
        'h2texCUBEproj',
        'h3texCUBEproj',
        'h4texCUBEproj',
        'x1texCUBEproj',
        'x2texCUBEproj',
        'x3texCUBEproj',
        'x4texCUBEproj',
        'f1texCUBE',
        'f2texCUBE',
        'f3texCUBE',
        'f4texCUBE',
        'h1texCUBE',
        'h2texCUBE',
        'h3texCUBE',
        'h4texCUBE',
        'x1texCUBE',
        'x2texCUBE',
        'x3texCUBE',
        'x4texCUBE',
        'texRECT',
        'f1texRECT',
        'f2texRECT',
        'f3texRECT',
        'f4texRECT',
        'h1texRECT',
        'h2texRECT',
        'h3texRECT',
        'h4texRECT',
        'x1texRECT',
        'x2texRECT',
        'x3texRECT',
        'x4texRECT',
        'texRECTproj',
        'f1texRECTproj',
        'f2texRECTproj',
        'f3texRECTproj',
        'f4texRECTproj',
        'h1texRECTproj',
        'h2texRECTproj',
        'h3texRECTproj',
        'h4texRECTproj',
        'x1texRECTproj',
        'x2texRECTproj',
        'x3texRECTproj',
        'x4texRECTproj',
        'f1texRECT',
        'f2texRECT',
        'f3texRECT',
        'f4texRECT',
        'h1texRECT',
        'h2texRECT',
        'h3texRECT',
        'h4texRECT',
        'x1texRECT',
        'x2texRECT',
        'x3texRECT',
        'x4texRECT',
        'texcompare2D',
        'f1texcompare2D',
        'f1texcompare2D',
        'f1texcompare2D',
        'h1texcompare2D',
        'h1texcompare2D',
        'h1texcompare2D',
        'x1texcompare2D',
        'x1texcompare2D',
        'x1texcompare2D',
        'pack_2half',
        'unpack_2half',
        'pack_4clamp1s',
        'unpack_4clamp1s',
        'application2vertex',
        'vertex2fragment',
        'sampler1D',
        'sampler1DARRAY',
        'sampler2D',
        'sampler2DARRAY',
        'sampler3D',
        'samplerCUBE',
        'samplerRECT'
      )
    )
  );

function TSynOgreSyn.CheckKeyword(const astr:string):integer;
var
  i,j:integer;
begin
  result:=-1;

  if fExtType<0 then exit;
  for i:=0 to 3 do
  begin
    for j:=0 to High(StrArray[fExtType,i]) do
      if StrArray[fExtType,i,j]=astr then
        exit(i);
  end;
end;

initialization
  RegisterPlaceableHighlighter(TSynOgreSyn);

end.

