unit formChar;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  Spin, ExtCtrls, Buttons, SpinEx,
  tl2save, tl2char, tl2db;

type

  { TfmChar }

  TfmChar = class(TForm)
    bbUpdate: TBitBtn;
    cbCheckPoints: TCheckBox;
    pcCharInfo: TPageControl;
    // Stats
    tsStat: TTabSheet;

    gbBaseStats: TGroupBox;
    seStrengh  : TSpinEditEx;  lblStrength  : TLabel;
    seDexterity: TSpinEditEx;  lblDexterity : TLabel;
    seFocus    : TSpinEditEx;  lblFocus     : TLabel;
    seVitality : TSpinEditEx;  lblVitality  : TLabel;

    lblFreePoints: TLabel;

    gbData: TGroupBox;
    seLevel: TSpinEditEx;  lblLevel     : TLabel;
    seFame : TSpinEditEx;  lblFame      : TLabel;
    edGold       : TEdit;  lblGold      : TLabel;
    edExperience : TEdit;  lblExperience: TLabel;
    edFameExp    : TEdit;  lblFameExp   : TLabel;
    edHealth     : TEdit;  lblHealth    : TLabel;
    edHealthBonus: TEdit;  lblHeathBonus: TLabel;
    edMana       : TEdit;  lblMana      : TLabel;
    edManaBonus  : TEdit;  lblManaBonus : TLabel;
    lblDataNote: TLabel;

    gbGlobal: TGroupBox;
    cbDifficulty: TComboBox;  lblDifficulty: TLabel;
    cbNGState   : TComboBox;  lblNGState   : TLabel;
    cbHardcore  : TCheckBox;

    // View
    tsView: TTabSheet;
    imgIcon: TImage;

    edName: TEdit;  lblName: TLabel;
    lblSuffix: TLabel;
    edClass: TEdit;

    edOriginal : TEdit;      lblOriginal : TLabel;
    cbImage    : TComboBox;  lblCurrent  : TLabel;
    edMorphTime: TEdit;      lblMorphTime: TLabel;  lblMorphNote: TLabel;

    edSkin: TEdit;  lblSkin: TLabel;  cbSkins: TComboBox;
    seScale: TFloatSpinEdit;  lblScale: TLabel;

    cbCheater: TCheckBox;

    gbWardrobe: TGroupBox;

    // Action
    tsAction: TTabSheet;
    cbEnabled: TCheckBox;

    gbAction: TGroupBox;
    rbActionIdle   : TRadioButton;
    rbActionAttack : TRadioButton;
    rbActionDefence: TRadioButton;

    gbSpells: TGroupBox;
    Image1: TImage;  cbSpell1: TComboBox;  cbSpellLvl1: TComboBox;
    Image2: TImage;  cbSpell2: TComboBox;  cbSpellLvl2: TComboBox;
    Image3: TImage;  cbSpell3: TComboBox;  cbSpellLvl3: TComboBox;
    Image4: TImage;  cbSpell4: TComboBox;  cbSpellLvl4: TComboBox;

    edTownTime: TEdit;  lblTownTime: TLabel;

    // Statistic
    tsStatistic: TTabSheet;

    gbCoords: TGroupBox;
    edX: TEdit;  lblX: TLabel;
    edY: TEdit;  lblY: TLabel;
    edZ: TEdit;  lblZ: TLabel;

    edArea    : TEdit;  lblArea    : TLabel;
    edWaypoint: TEdit;  lblWaypoint: TLabel;

    lbModList: TListBox;
    procedure bbUpdateClick(Sender: TObject);
    procedure cbCheckPointsClick(Sender: TObject);
    procedure cbSpellChange(Sender: TObject);
    procedure cbSpellLvlChange(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure seFameChange(Sender: TObject);
    procedure seLevelChange(Sender: TObject);
    procedure StatChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);

  private
    FSGame:TTL2SaveFile;
    FChar :TTL2Character;

    FSpells:tSkillArray;

    ExpGate   :TIntegerDynArray;
    FameGate  :TIntegerDynArray;
    HPperVit  :TIntegerDynArray;
    MPperFocus:TIntegerDynArray;

    HPTier       :TIntegerDynArray;
    MPTier       :TIntegerDynArray;
    FStatPerLevel:integer;

    FLevel,FFame :integer;
    FStr,FBaseStr:integer;
    FDex,FBaseDex:integer;
    FInt,FBaseInt:integer;
    FVit,FBaseVit:integer;

    FFreePoints:integer;

    procedure ClearGlobals;
    procedure FixData;

    function GetMainFlag:boolean;
    procedure ChangeVisibility;

    procedure GetCharSpell(cb: TComboBox; idx: integer);
    procedure LoadGlobals;
    procedure SetCharSpell(cb: TComboBox; idx: integer);

  public
    procedure FillInfo(aChar:TTL2Character; aSGame:TTL2SaveFile=nil);

    property IsMain:boolean read GetMainFlag;
  end;

var
  fmChar: TfmChar;

implementation

{$R *.lfm}

uses
  INIFiles,
  formSettings,
  tl2types;

resourcestring
  rsFreePoints = 'Free stat points';

  rsCasual  = 'Casual';
  rsNormal  = 'Normal';
  rsVeteran = 'Veteran';
  rsExpert  = 'Expert';

  rsStrength  = 'Strength';
  rsDexterity = 'Dexterity';
  rsFocus     = 'Focus';
  rsVitality  = 'Vitality';

const
  sStats       = 'Stats';
  sCheckPoints = 'checkpoints';

//----- Support -----

function splitInt(const astr:string; asep:char):TIntegerDynArray;
var
  p:PChar;
  i,lcnt:integer;
  isminus:boolean;
begin
  result:=nil;
  if astr='' then
    exit;

  // get array length

  p:=pointer(astr);
  if p^=asep then inc(p);
  lcnt:=0;
  while p^<>#0 do
  begin
    if p^=asep then inc(lcnt);
    inc(p);
  end;
  if (p-1)^<>asep then inc(lcnt);
  SetLength(result,lcnt);

  // fill array

  p:=pointer(astr);
  if p^=asep then inc(p);

  isminus:=false;
  result[0]:=0;
  i:=0;
  while p^<>#0 do
  begin
    if p^='-' then isminus:=true
    else if p^<>asep then result[i]:=result[i]*10+ORD(p^)-ORD('0')
    else
    begin
      if isminus then
      begin
        result[i]:=-result[i];
        isminus:=false;
      end;
      inc(i);
      if i<lcnt then result[i]:=0;
    end;
    inc(p);
  end;
end;

function TfmChar.GetMainFlag:boolean;
begin
  result:=(FChar.Sign=$FF);
end;

//----- Stat -----

procedure TfmChar.StatChange(Sender: TObject);
var
  lval:integer;
  pStat:PInteger;
begin
  lval:=(Sender as TSpinEditEx).Value;

  if      Sender=seStrengh   then pStat:=@FStr
  else if Sender=seDexterity then pStat:=@FDex
  else if Sender=seFocus     then pStat:=@FInt
  else if Sender=seVitality  then pStat:=@FVit;

  if      lval>pStat^ then dec(FFreePoints)
  else if lval<pStat^ then inc(FFreePoints)
  else exit;

  bbUpdate.Enabled:=true;
  pStat^:=lval;

  cbCheckPointsClick(Sender);

  if (Sender=seVitality) or (Sender=seFocus) then FixData;
end;

procedure TfmChar.seFameChange(Sender: TObject);
begin
  if FFame<>seFame.Value then
  begin
    bbUpdate.Enabled:=true;
    if seFame.Value=0 then
      edFameExp.Text:='0'
    else
      edFameExp.Text:=IntToStr(FameGate[seFame.Value-1]);
    FFame:=seFame.Value;
  end;
end;

procedure TfmChar.seLevelChange(Sender: TObject);
begin
  if FLevel<>seLevel.Value then
  begin
    bbUpdate.Enabled:=true;
    if seLevel.Value=1 then
      edExperience.Text:='0'
    else
      edExperience.Text:=IntToStr(ExpGate[seLevel.Value-2]);

    if FLevel<seLevel.Value then
      inc(FFreePoints,FStatPerLevel)
    else
     dec(FFreePoints,FStatPerLevel);
    cbCheckPointsClick(Sender);

    FLevel:=seLevel.Value;
    if FChar.IsChar then FixData;
  end;
end;

procedure TfmChar.cbCheckPointsClick(Sender: TObject);
begin
  if (FFreePoints<=0) and cbCheckPoints.Checked then
  begin
    seStrengh  .MaxValue:=seStrengh  .Value;
    seDexterity.MaxValue:=seDexterity.Value;
    seFocus    .MaxValue:=seFocus    .Value;
    seVitality .MaxValue:=seVitality .Value;
  end
  else
  begin
    seStrengh  .MaxValue:=999;
    seDexterity.MaxValue:=999;
    seFocus    .MaxValue:=999;
    seVitality .MaxValue:=999;
  end;
end;

procedure TfmChar.FixData;
begin
  lblFreePoints.Caption:=rsFreePoints+': '+IntToStr(FFreePoints);

  edHealthBonus.Text:=IntToStr((HPTier[seLevel.Value-1]+5) div 10);
  edManaBonus  .Text:=IntToStr((MPTier[seLevel.Value-1]+5) div 10);
end;

procedure TfmChar.ClearGlobals;
begin
  SetLength(ExpGate   ,0);
  SetLength(FameGate  ,0);
  SetLength(HPperVit  ,0);
  SetLength(MPperFocus,0);
end;

procedure TfmChar.LoadGlobals;
var
  i:integer;
begin
  if Length(ExpGate)=0 then
  begin
    ExpGate:=GetGraphArray('EXPERIENCEGATE');
    if Length(ExpGate)=0 then
      ExpGate:=Copy(DefaultExpGate);
  end;
  if Length(FameGate)=0 then
  begin
    FameGate:=GetGraphArray('FAMEGATE');
    if Length(FameGate)=0 then
      FameGate:=Copy(DefaultFameGate);
  end;
  if Length(HPperVit)=0 then
  begin
    HPperVit:=GetGraphArray('HP_PLAYER_BONUS_VITALITY');
    if Length(HPperVit)=0 then
    begin
      SetLength(HPperVit,1000);
      for i:=0 to 999 do
        HPperVit[i]:=DefaultHPperVit*i;
    end;
  end;
  if Length(MPperFocus)=0 then
  begin
    MPperFocus:=GetGraphArray('MANA_PLAYER_BONUS_FOCUS');
    if Length(MPperFocus)=0 then
    begin
      SetLength(MPperFocus,1000);
      for i:=0 to 999 do
        MPperFocus[i]:=DefaultMPperFocus*i;
    end;
  end;
end;

//----- Action -----

procedure TfmChar.cbSpellChange(Sender: TObject);
var
  cb:TComboBox;
  i,idx:integer;
begin
  bbUpdate.Enabled:=true;

  with (Sender as TComboBox) do
  begin
    cb:=TComboBox(Tag);
    cb.Clear;
    TImage(cb.Tag).Picture.Clear;
    if ItemIndex>0 then
    begin
      idx:=IntPtr(Items.Objects[ItemIndex]);
      if idx>=0 then
      begin
        for i:=1 to FSpells[idx].level do
          cb.Items.AddObject(IntToStr(i),TObject(IntPtr(i)));
        cb.ItemIndex:=0;
        try
          TImage(cb.Tag).Picture.LoadFromFile(
             fmSettings.edIconDir.Text+'\skills\'+FSpells[idx].icon+'.png');
        except
        end;
      end;
    end;
  end;
end;

procedure TfmChar.cbSpellLvlChange(Sender: TObject);
begin
  bbUpdate.Enabled:=true;;
end;

procedure TfmChar.GetCharSpell(cb: TComboBox; idx: integer);
var
  lid:TL2ID;
  lspell:TTL2Spell;
begin
  lspell:=FChar.Spells[idx];
  cb.Text:=GetTL2Skill(lspell.name,lid);
  cbSpellChange(cb);
  TComboBox(cb.Tag).Text:=IntToStr(lspell.level);
end;

procedure TfmChar.SetCharSpell(cb: TComboBox; idx: integer);
var
  lspell:TTL2Spell;
  lcb:TComboBox;
begin
  if cb.ItemIndex>=0 then
  begin
    lcb:=TComboBox(cb.Tag);
    lspell.name :=FSpells[IntPtr(cb .Items.Objects[cb .ItemIndex])].name;
    lspell.level:=        IntPtr(lcb.Items.Objects[lcb.ItemIndex]);
  end
  else
  begin
    lspell.name :='';
    lspell.level:=0;
  end;
  FChar.Spells[idx]:=lspell;
end;

//----- Form -----

procedure TfmChar.FormDestroy(Sender: TObject);
var
  config:TIniFile;
begin
  ClearGlobals;
  SetLength(FSpells,0);

  config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);
  config.WriteBool(sStats,sCheckPoints,cbCheckPoints.Checked);

  config.UpdateFile;
  config.Free;
end;

procedure TfmChar.FormCreate(Sender: TObject);
var
  config:TIniFile;
  i:integer;
begin
  //--- Local settings

  config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);
  cbCheckPoints.Checked:=config.ReadBool(sStats,sCheckPoints,true);
  config.Free;

  //--- Global settings

  LoadGlobals;

//  ExpGate:=GetGraphArray('EXPERIENCEGATE');

  //--- Database

  CreateSpellList(FSpells);

  //--- Visual part

  //----- Stat

  cbDifficulty.Clear;
  cbDifficulty.AddItem(rsCasual ,nil);
  cbDifficulty.AddItem(rsNormal ,nil);
  cbDifficulty.AddItem(rsVeteran,nil);
  cbDifficulty.AddItem(rsExpert ,nil);

  cbNGState.Clear;
  cbNGState.AddItem('NG'  ,nil);
  cbNGState.AddItem('NG+' ,nil);
  cbNGState.AddItem('NG+2',nil);
  cbNGState.AddItem('NG+3',nil);
  cbNGState.AddItem('NG+4',nil);
  cbNGState.AddItem('NG+5',nil);

  //----- Action

  cbSpell1.Clear;
  cbSpell1.Sorted:=true;
  cbSpell1.Items.BeginUpdate;
  cbSpell1.Items.Capacity:=Length(FSpells);
  cbSpell1.Items.AddObject('',TObject(-1));
  for i:=0 to High(FSpells) do
    cbSpell1.Items.AddObject(FSpells[i].title,TObject(IntPtr(i)));
  cbSpell1.Items.EndUpdate;
  cbSpell2.Items.Assign(cbSpell1.Items);
  cbSpell3.Items.Assign(cbSpell1.Items);
  cbSpell4.Items.Assign(cbSpell1.Items);

  cbSpell1.Tag:=PtrUInt(cbSpellLvl1); cbSpellLvl1.Tag:=PtrUInt(Image1);
  cbSpell2.Tag:=PtrUInt(cbSpellLvl2); cbSpellLvl2.Tag:=PtrUInt(Image2);
  cbSpell3.Tag:=PtrUInt(cbSpellLvl3); cbSpellLvl3.Tag:=PtrUInt(Image3);
  cbSpell4.Tag:=PtrUInt(cbSpellLvl4); cbSpellLvl4.Tag:=PtrUInt(Image4);

  pcCharInfo.ActivePage:=tsStat;
end;

procedure TfmChar.ChangeVisibility;
var
  lChar,lPet:boolean;
begin
  lChar:=FChar.IsChar;
  lPet :=FChar.IsPet;

  // Stats
  gbGlobal     .Visible:=lChar;
  gbBaseStats  .Visible:=lChar;
  lblFreePoints.Visible:=lChar;
  lblDataNote  .Visible:=lChar;
  cbCheckPoints.Visible:=lChar;

  gbData.Enabled:=lChar or lPet;
  seFame.Enabled:=lChar;

  bbUpdate.Visible:=lChar or lPet;

  // View
  imgIcon     .Visible:=lChar or lPet;
  edMorphTime .Visible:=lChar or lPet;
  lblMorphTime.Visible:=lChar or lPet;
  lblMorphNote.Visible:=lChar or lPet;
  lblCurrent  .Visible:=lChar or lPet;
  cbImage     .Visible:=lChar or lPet;

  gbWardrobe.Visible:=lChar;
  cbCheater .Visible:=lChar;
  edClass   .Visible:=lChar;

  edSkin .Visible:=lPet;
  lblSkin.Visible:=lPet;
  cbSkins.Visible:=lPet;

  edName    .ReadOnly:=not (lChar or lPet);
  seScale   .ReadOnly:=not (lChar or lPet);

  // Actions
  tsAction.TabVisible:=lChar or lPet;

  cbEnabled  .Visible:=lPet;
  gbAction   .Visible:=lPet;
  edTownTime .Visible:=lPet;
  lblTownTime.Visible:=lPet;

  // Statistic
  edArea     .Visible:=lChar;
  lblArea    .Visible:=lChar;
  edWaypoint .Visible:=lChar;
  lblWaypoint.Visible:=lChar;
end;

procedure TfmChar.FillInfo(aChar:TTL2Character; aSGame:TTL2SaveFile=nil);
var
  licon,ls,ls1:string;
  i:integer;
begin
  FSGame:=aSGame;
  FChar :=aChar;

  ChangeVisibility;

  // here coz selevel assign can call OnChange event
  if aChar.IsChar then
    GetClassInfo(aChar.ClassId,licon,FBaseStr,FBaseDex,FBaseInt,FBaseVit);

  // Stats

  if aChar.IsChar or aChar.IsPet then
  begin
    seLevel.MaxValue:=Length(ExpGate);
  end
  else
    seLevel.MaxValue:=999;

  if aChar.IsChar then
  begin
    // graph_stat, graph_hp, graph_mp
    GetClassGraphStat(aChar.ClassId,ls,ls1,FStatPerLevel);
    HPTier:=GetGraphArray(ls );
    MPTier:=GetGraphArray(ls1);

    if Length(HPTier)=0 then
    begin
      SetLength(HPTier,100);
      for i:=0 to 99 do
        HPTier[i]:=DefaultHPbase+i*DefaultHPperLevel;
    end;
    if Length(MPTier)=0 then
    begin
      SetLength(MPTier,100);
      for i:=0 to 99 do
        MPTier[i]:=DefaultMPbase+i*DefaultMPperLevel;
    end;

    seFame.MaxValue:=Length(FameGate);

    FFreePoints:=aChar.FreeStatPoints;
    lblFreePoints.Caption:=rsFreePoints+': '+IntToStr(FFreePoints);

    lblStrength .Caption:='('+IntToStr(FBaseStr)+') '+rsStrength;
    lblDexterity.Caption:='('+IntToStr(FBaseDex)+') '+rsDexterity;
    lblFocus    .Caption:='('+IntToStr(FBaseInt)+') '+rsFocus;
    lblVitality .Caption:='('+IntToStr(FBaseVit)+') '+rsVitality;
    // keep for Up/Down changes
    FStr:=aChar.Strength ; seStrengh  .Value:=FStr;
    FDex:=aChar.Dexterity; seDexterity.Value:=FDex;
    FInt:=aChar.Focus    ; seFocus    .Value:=FInt;
    FVit:=aChar.Vitality ; seVitality .Value:=FVit;
    // To prevent Statpoints negative values
    cbCheckPointsClick(Self);

    edGold.Text:=IntToStr(aChar.Gold);

    // global
    cbNGState   .ItemIndex:=aSGame.NewGameCycle;
    cbDifficulty.ItemIndex:=ORD(aSGame.Difficulty);
    cbHardcore  .Checked  :=aSGame.Hardcore;
  end
  else
  begin
    seFame .MaxValue:=1;
  end;

  FLevel:=aChar.Level    ; seLevel.Value:=FLevel;
  FFame :=aChar.FameLevel; seFame .Value:=FFame;

  edExperience .Text :=IntToStr(aChar.Experience);
  edFameExp    .Text :=IntToStr(aChar.FameExp);
  edHealth     .Text :=IntToStr(Round(aChar.Health));
  edHealthBonus.Text :=IntToStr(aChar.HealthBonus);
  edMana       .Text :=IntToStr(Round(aChar.Mana));
  edManaBonus  .Text :=IntToStr(aChar.ManaBonus);

  // View

  edName.Text      :=aChar.Name;
  lblSuffix.Caption:=aChar.Suffix;

  edMorphTime.Text:=IntToStr(round(aChar.MorphTime));

  if aChar.IsChar then
  begin
    cbCheater.Checked:=aChar.Cheater=214;
    edOriginal.Text:=GetTL2Class(aChar.ClassId);
    edClass   .Text:=aSGame.ClassString;
    try
      if licon='' then licon:='\unknown' else licon:='\characters\'+licon;
      imgIcon.Picture.LoadFromFile(fmSettings.edIconDir.Text+licon+'.png');
    except
      imgIcon.Picture.Clear;
    end;
  end

  else if aChar.IsPet then
  begin
    edOriginal.Text:=GetTL2Pet(aChar.ClassId);
    if edOriginal.Text=HexStr(aChar.ClassId,16) then
       edOriginal.Text:=GetTL2Mob(aChar.ClassId);
    try
      licon:=GetPetIcon(aChar.ClassId);
      if licon='' then licon:='\unknown' else licon:='\pets\'+licon;
      imgIcon.Picture.LoadFromFile(fmSettings.edIconDir.Text+licon+'.png');
    except
      imgIcon.Picture.Clear;
    end;
    edSkin.Text:=IntToStr(ShortInt(aChar.Skin));
  end

  else
    edOriginal.Text:=GetTL2Mob(aChar.ClassId);

  seScale.Value:=aChar.Scale;
  edMorphTime.Text:=IntToStr(Round(aChar.MorphTime));

  // Action

  if tsAction.TabVisible then
  begin
    cbEnabled.Checked:=aChar.Enabled;
    edTownTime.Text:=IntToStr(round(aChar.TownTime));

    rbActionIdle   .Checked:=aChar.Action=Idle;
    rbActionAttack .Checked:=aChar.Action=Attack;
    rbActionDefence.Checked:=aChar.Action=Defence;

    GetCharSpell(cbSpell1,0);
    GetCharSpell(cbSpell2,1);
    GetCharSpell(cbSpell3,2);
    GetCharSpell(cbSpell4,3);
  end;

  // Statistic

  edX.Text:=FloatToStrF(aChar.Position.X,ffFixed,-8,2);
  edY.Text:=FloatToStrF(aChar.Position.Y,ffFixed,-8,2);
  edZ.Text:=FloatToStrF(aChar.Position.Z,ffFixed,-8,2);

  lbModList.Clear;
  for i:=0 to High(aChar.ModIds) do
    lbModList.AddItem(GetTL2Mod(aChar.ModIds[i]),nil);

  if aChar.IsChar then
  begin
    edArea    .Text:=aSGame.Area;
    edWaypoint.Text:=aSGame.Waypoint;
  end;
end;

procedure TfmChar.bbUpdateClick(Sender: TObject);
begin
  // Stats

  if FChar.IsChar then
  begin
    FChar.Strength  :=seStrengh .Value;
    FChar.Dexterity :=seDexterity.Value;
    FChar.Focus     :=seFocus    .Value;
    FChar.Vitality  :=seVitality .Value;
    FChar.Gold      :=StrToIntDef(edGold     .Text,0);

    if FFreePoints>=0 then
      FChar.FreeStatPoints:=FFreePoints
    else
      FChar.FreeStatPoints:=0;

    // global
    FSGame.NewGameCycle:=cbNGState.ItemIndex;
    FSGame.Difficulty  :=TTL2Difficulty(cbDifficulty.ItemIndex);
    FSGame.Hardcore    :=cbHardcore.Checked;
  end;

  FChar.Level      :=seLevel.Value;
  FChar.FameLevel  :=seFame .Value;
  FChar.Experience :=StrToInt(edExperience .Text);
  FChar.FameExp    :=StrToInt(edFameExp    .Text);
  FChar.HealthBonus:=StrToInt(edHealthBonus.Text);
  FChar.ManaBonus  :=StrToInt(edManaBonus  .Text);
  FChar.Health     :=StrToIntDef(edHealth.Text,FChar.HealthBonus);
  FChar.Mana       :=StrToIntDef(edMana  .Text,FChar.ManaBonus);

  // View

  FChar.Name:=edName.Text;
  FChar.Scale:=seScale.Value;
  FChar.MorphTime:=StrToInt(edMorphTime.Text);

  if FChar.IsChar then
  begin
    if cbCheater.Checked then
      FChar.Cheater:=214
    else
      FChar.Cheater:=78;
  end
  else
  begin
    FChar.Skin:=Byte(StrToIntDef(edSkin.Text,-1));
  end;
  {
    if FChar.OriginId<>TL2IdEmpty then
      lid:=FChar.OriginId
    else
      lid:=FChar.ImageId;
    edOriginal.Caption:=GetTL2Pet(lid);
   }

  // Action

  // not required coz Update button is for pets and chars only
  //  if tsAction.TabVisible then
  begin
    FChar.Enabled:=cbEnabled.Checked;
    FChar.TownTime:=StrToInt(edTownTime.Text);

    if      rbActionIdle   .Checked then FChar.Action:=Idle
    else if rbActionAttack .Checked then FChar.Action:=Attack
    else if rbActionDefence.Checked then FChar.Action:=Defence;

    SetCharSpell(cbSpell1,0);
    SetCharSpell(cbSpell2,1);
    SetCharSpell(cbSpell3,2);
    SetCharSpell(cbSpell4,3);
  end;

  // Statistic

{
  lbModList.Clear;
  for i:=0 to High(FChar.ModIds) do
    lbModList.AddItem(GetTL2Mod(FChar.ModIds[i]),nil);
}
  bbUpdate.Enabled:=false;
  FChar.Changed:=true;
end;

end.

