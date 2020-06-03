unit formChar;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  Spin, ExtCtrls, Buttons, Grids, SpinEx,
  tl2types, tl2save, tl2char, tl2db, formSkills;

type
  tCharInfoType = (ciPlayer, ciPet, ciUnit);

  { TfmChar }

  TfmChar = class(TForm)
    bbUpdate: TBitBtn;
    cbKeepBase: TCheckBox;
    pnlTop: TPanel;
    pcCharInfo: TPageControl;
    sePoints: TSpinEditEx;
    sgStats: TStringGrid;
    // Stats
    tsStat: TTabSheet;

    gbBaseStats: TGroupBox;
    seStrength : TSpinEditEx;  lblStrength  : TLabel;
    seDexterity: TSpinEditEx;  lblDexterity : TLabel;
    seFocus    : TSpinEditEx;  lblFocus     : TLabel;
    seVitality : TSpinEditEx;  lblVitality  : TLabel;

    lblFreePoints: TLabel;
    cbCheckPoints: TCheckBox;

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
    imgIcon : TImage;
    imgMorph: TImage;

    gbGender: TGroupBox;
    rbMale : TRadioButton;
    rbFemale: TRadioButton;
    rbUnisex: TRadioButton;

    edName: TEdit;  lblName: TLabel;
    lblSuffix: TLabel;
    edClass: TEdit;
    cbClass      : TComboBox;  lblNew      : TLabel;
    cbMorph    : TComboBox;  lblCurrent  : TLabel;
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
    procedure cbKeepBaseClick(Sender: TObject);
    procedure sePointsChange(Sender: TObject);
    procedure StatChange(Sender: TObject);
    procedure cbCheckPointsClick(Sender: TObject);
    procedure cbSpellChange   (Sender: TObject);
    procedure cbSpellLvlChange(Sender: TObject);
    procedure cbMorphChange(Sender: TObject);
    procedure cbClassChange(Sender: TObject);
    procedure ToSetUpdate(Sender: TObject);
    procedure rbGenderClick(Sender: TObject);
    procedure seFameChange (Sender: TObject);
    procedure seLevelChange(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

  private
    FKind:tCharInfoType;
    FConfigured:boolean;
    FSkillForm:TfmSkills;

    FSGame:TTL2SaveFile;
    FChar :TTL2Character;

    FClasses:tClassArray;
    FPets   :tPetArray;

    HPTier       :TIntegerDynArray;
    MPTier       :TIntegerDynArray;
    FStatPerLevel:integer;

    FLevel,FFame :integer;
    FStr,FBaseStr:integer;
    FDex,FBaseDex:integer;
    FInt,FBaseInt:integer;
    FVit,FBaseVit:integer;

    FFreePoints:integer;

    procedure DrawPetIcon(aclass: TL2ID; aImg: TImage);
    procedure FillPetInfo;
    procedure FillPlayerInfo;
    procedure FixData;
    function GetClassIndex(id: TL2ID): integer;

    function GetMainFlag:boolean;
    procedure SetupVisualPart;

    procedure SetCharSpell(cb: TComboBox; idx: integer);
    procedure GetCharSpell(cb: TComboBox; idx: integer);
    procedure InitSpellBlock;
    function SearchAltGender(aclass: TL2ID): integer;
    procedure UpdatePetInfo();
    procedure UpdatePlayerInfo();

  public
    constructor Create(AOwner:TComponent; atype:tCharInfoType); overload;
    procedure FillInfo(aChar:TTL2Character; aSGame:TTL2SaveFile=nil);

    property IsMain    :boolean read GetMainFlag;
    property Configured:boolean read FConfigured write FConfigured;
  end;

var
  fmChar: TfmChar;

implementation

{$R *.lfm}

uses
  INIFiles,
  formSettings,
  unitGlobal;

resourcestring
  rsStrength  = 'Strength';
  rsDexterity = 'Dexterity';
  rsFocus     = 'Focus';
  rsVitality  = 'Vitality';

const
  sStats       = 'Stats';
  sCheckPoints = 'checkpoints';

//----- Support -----

function TfmChar.GetMainFlag:boolean;
begin
  result:=(FChar.Sign=$FF);
end;

function TfmChar.GetClassIndex(id:TL2ID):integer;
var
  i:integer;
begin
  for i:=0 to High(FClasses) do
  begin
    if FClasses[i].id=id then
    begin
      result:=i;
      exit;
    end;
  end;
  result:=-1;
end;

function TfmChar.SearchAltGender(aclass:TL2ID):integer;
var
  ls:string;
  i,idx:integer;
begin
  result:=-1;
  // 1 - search source index
  idx:=GetClassIndex(aclass);
  if idx<0 then exit; // MUST NOT happend

  // 2 - check alter name
  ls:=FClasses[idx].name;
  i:=Length(ls);
  if (i>2) and (ls[i-1]='_') then
  begin
    if      ls[i]='F' then ls[i]:='M'
    else if ls[i]='M' then ls[i]:='F'
    else i:=-1;
  end;
  // 3 - search alter index
  if i>0 then
  begin
    for i:=0 to High(FClasses) do
    begin
      if FClasses[i].name=ls then
      begin
        result:=i;
        exit;
      end;
    end;
  end;
  // 4 - check by titles
  ls:=FClasses[idx].title;
  for i:=0 to High(FClasses) do
  begin
    if (FClasses[i].title=ls) and
       (FClasses[i].id<>aclass) then
    begin
      // really, need to check both mod list too
      result:=i;
      exit;
    end;
  end;
end;

procedure TfmChar.ToSetUpdate(Sender: TObject);
begin
  bbUpdate.Enabled:=true;
end;

//--- Player ---

procedure TfmChar.FixData;
begin
  sePoints.Value:=FFreePoints;

  edHealthBonus.Text:=IntToStr((HPTier[seLevel.Value-1]+5) div 10);
  edManaBonus  .Text:=IntToStr((MPTier[seLevel.Value-1]+5) div 10);
end;

procedure TfmChar.StatChange(Sender: TObject);
var
  lval:integer;
  pStat:PInteger;
begin
  lval:=(Sender as TSpinEditEx).Value;

  if      Sender=seStrength  then pStat:=@FStr
  else if Sender=seDexterity then pStat:=@FDex
  else if Sender=seFocus     then pStat:=@FInt
  else if Sender=seVitality  then pStat:=@FVit;

  if      lval>pStat^ then dec(FFreePoints)
  else if lval<pStat^ then inc(FFreePoints)
  else exit;

  bbUpdate.Enabled:=true;
  pStat^:=lval;

  cbCheckPointsClick(Sender);

  FixData;
end;

procedure TfmChar.seFameChange(Sender: TObject);
begin
  if FFame<>seFame.Value then
  begin
    bbUpdate.Enabled:=true;
    if seFame.Value=0 then
      edFameExp.Text:='0'
    else
      edFameExp.Text:=IntToStr(FameGate[seFame.Value-1]+1);
    FFame:=seFame.Value;
  end;
end;

procedure TfmChar.cbCheckPointsClick(Sender: TObject);
begin
  if (FFreePoints<=0) and cbCheckPoints.Checked then
  begin
    seStrength .MaxValue:=seStrength .Value;
    seDexterity.MaxValue:=seDexterity.Value;
    seFocus    .MaxValue:=seFocus    .Value;
    seVitality .MaxValue:=seVitality .Value;
  end
  else
  begin
    seStrength .MaxValue:=999;
    seDexterity.MaxValue:=999;
    seFocus    .MaxValue:=999;
    seVitality .MaxValue:=999;
  end;
end;

procedure TfmChar.rbGenderClick(Sender: TObject);
var
  licon:string;
  idx:integer;
begin
  if cbClass.ItemIndex<0 then exit;

//  idx:=SearchAltGeder();
  idx:=IntPtr(cbClass.Items.Objects[cbClass.ItemIndex]);

  licon:=FClasses[idx].icon;
  try
    if licon='' then licon:='\unknown' else licon:='\characters\'+licon;
    imgIcon.Picture.LoadFromFile(fmSettings.edIconDir.Text+licon+'.png');
  except
    imgIcon.Picture.Clear;
  end;

  bbUpdate.Enabled:=true;
end;

//--- Common ---

procedure TfmChar.sePointsChange(Sender: TObject);
begin
  FFreePoints:=sePoints.Value;
end;

procedure TfmChar.seLevelChange(Sender: TObject);
begin
  if FLevel<>seLevel.Value then
  begin
    bbUpdate.Enabled:=true;
    if seLevel.Value=1 then
      edExperience.Text:='0'
    else
      edExperience.Text:=IntToStr(ExpGate[seLevel.Value-2]+1);

    if FChar.IsChar then
    begin
      if FLevel<seLevel.Value then
        inc(FFreePoints,FStatPerLevel)
      else
       dec(FFreePoints,FStatPerLevel);
      cbCheckPointsClick(Sender);

      FixData;
    end;

    FLevel:=seLevel.Value;
  end;
end;

procedure TfmChar.cbClassChange(Sender: TObject);
var
  idx:integer;
begin
  idx:=IntPtr(cbClass.Items.Objects[cbClass.ItemIndex]);

  if FChar.IsChar then
  begin
    //!!!!!!!!!!!!!!!!!!!!!!!
  end;

  if FChar.IsPet then
  begin
    DrawPetIcon(FPets[idx].id,imgIcon);
    if cbMorph.ItemIndex=0 then
      seScale.Value:=FPets[idx].scale;
  end;

  bbUpdate.Enabled:=true;
end;

//--- Pet ---

procedure TfmChar.DrawPetIcon(aclass:TL2ID; aImg:TImage);
var
  licon:string;
begin
  licon:=GetPetIcon(aclass);
  if licon='' then licon:='\unknown' else licon:='\pets\'+licon;
  try
    aImg.Picture.LoadFromFile(fmSettings.edIconDir.Text+licon+'.png');
  except
    aImg.Picture.Clear;
  end;
end;

procedure TfmChar.cbMorphChange(Sender: TObject);
var
  idx:integer;
begin
  idx:=IntPtr(cbMorph.Items.Objects[cbMorph.ItemIndex]);
  if idx<0 then
  begin
    imgMorph.Picture.Clear;
    idx:=IntPtr(cbClass.Items.Objects[cbClass.ItemIndex]);
  end
  else
  begin
    DrawPetIcon(FPets[idx].id,imgMorph);
  end;
  seScale.Value:=FPets[idx].scale;

  bbUpdate.Enabled:=true;
end;

//----- Spell block -----

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
        for i:=1 to SpellList[idx].level do
          cb.Items.AddObject(IntToStr(i),TObject(IntPtr(i)));
        cb.ItemIndex:=0;
        try
          TImage(cb.Tag).Picture.LoadFromFile(
             fmSettings.edIconDir.Text+'\skills\'+SpellList[idx].icon+'.png');
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

procedure TfmChar.GetCharSpell(cb:TComboBox; idx:integer);
var
  lid:TL2ID;
  lspell:TTL2Spell;
begin
  lspell:=FChar.Spells[idx];
  cb.Text:=GetTL2Skill(lspell.name,lid);
  cbSpellChange(cb);
  TComboBox(cb.Tag).Text:=IntToStr(lspell.level);
end;

procedure TfmChar.SetCharSpell(cb:TComboBox; idx:integer);
var
  lspell:TTL2Spell;
  lcb:TComboBox;
begin
  if (cb.ItemIndex>=0) and
     (IntPtr(cb.Items.Objects[cb.ItemIndex])>=0) then
  begin
    lcb:=TComboBox(cb.Tag);
    lspell.name :=SpellList[IntPtr(cb .Items.Objects[cb .ItemIndex])].name;
    lspell.level:=          IntPtr(lcb.Items.Objects[lcb.ItemIndex]);
  end
  else
  begin
    lspell.name :='';
    lspell.level:=0;
  end;
  FChar.Spells[idx]:=lspell;
end;

procedure TfmChar.InitSpellBlock;
var
  i:integer;
begin
  cbSpell1.Clear;
  cbSpell1.Sorted:=true;
  cbSpell1.Items.BeginUpdate;
  cbSpell1.Items.Capacity:=Length(SpellList);
  cbSpell1.Items.AddObject('',TObject(-1));
  for i:=0 to High(SpellList) do
    cbSpell1.Items.AddObject(SpellList[i].title,TObject(IntPtr(i)));
  cbSpell1.Items.EndUpdate;

  cbSpell2.Items.Assign(cbSpell1.Items);
  cbSpell3.Items.Assign(cbSpell1.Items);
  cbSpell4.Items.Assign(cbSpell1.Items);

  GetCharSpell(cbSpell1,0);
  GetCharSpell(cbSpell2,1);
  GetCharSpell(cbSpell3,2);
  GetCharSpell(cbSpell4,3);
end;

//----- Form -----

procedure TfmChar.SetupVisualPart;
var
  lChar,lPet:boolean;
begin
  lChar:=FKind=ciPlayer;
  lPet :=FKind=ciPet;

  pnlTop.Visible:=lChar or lPet;

  // Stats
  gbGlobal     .Visible:=lChar;
  gbBaseStats  .Visible:=lChar;
  lblFreePoints.Visible:=lChar;
  sePoints     .Visible:=lChar;
  lblDataNote  .Visible:=lChar;
  cbCheckPoints.Visible:=lChar;

  gbData.Enabled:=lChar or lPet;
  seFame.Enabled:=lChar;

  bbUpdate.Visible:=lChar or lPet;

  // View
  imgIcon.Visible:=lChar or lPet;
  cbClass.Visible:=lChar or lPet;
  lblNew .Visible:=lChar or lPet;

  edMorphTime .Visible:=lPet;
  lblMorphTime.Visible:=lPet;
  lblMorphNote.Visible:=lPet;
  lblCurrent  .Visible:=lPet;
  cbMorph     .Visible:=lPet;
  imgMorph    .Visible:=lPet;
  edSkin      .Visible:=lPet;
  lblSkin     .Visible:=lPet;
  cbSkins     .Visible:=false;//lPet;

  gbWardrobe.Visible:=lChar;
  cbCheater .Visible:=lChar;
  gbGender  .Visible:=lChar;

  edName    .ReadOnly:=not (lChar or lPet);
  seScale   .ReadOnly:=not (lChar or lPet);

  // Actions
  tsAction.TabVisible:=lChar or lPet;

  cbSpell1.Tag:=PtrUInt(cbSpellLvl1); cbSpellLvl1.Tag:=PtrUInt(Image1);
  cbSpell2.Tag:=PtrUInt(cbSpellLvl2); cbSpellLvl2.Tag:=PtrUInt(Image2);
  cbSpell3.Tag:=PtrUInt(cbSpellLvl3); cbSpellLvl3.Tag:=PtrUInt(Image3);
  cbSpell4.Tag:=PtrUInt(cbSpellLvl4); cbSpellLvl4.Tag:=PtrUInt(Image4);

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

procedure TfmChar.FormDestroy(Sender: TObject);
var
  config:TIniFile;
begin
  SetLength(FPets,0);
  SetLength(FClasses,0);

  SetLength(HPTier,0);
  SetLength(MPTier,0);

  if FKind=ciPlayer then
  begin
    config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);
    config.WriteBool(sStats,sCheckPoints,cbCheckPoints.Checked);

    config.UpdateFile;
    config.Free;
  end;

end;

constructor TfmChar.Create(AOwner:TComponent; atype:tCharInfoType);
var
  config:TIniFile;
begin
  inherited Create(AOwner);

  FKind:=atype;
  FConfigured:=false;

  SetupVisualPart;

  case FKind of

    ciPlayer: begin
      config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);
      cbCheckPoints.Checked:=config.ReadBool(sStats,sCheckPoints,true);
      config.Free;

      pcCharInfo.ActivePage:=tsStat;
    end;

    ciPet: begin
      pcCharInfo.ActivePage:=tsView;
    end;

    ciUnit: begin
      pcCharInfo.ActivePage:=tsStat;
    end;
  end;
end;

//----- Fill Info -----
{
// no N and F - add _(male) or _(female)
// if      gender='M' then ls:=' (male)'
// else if gender='F' then ls:=' (female)'
// else ls:='';
procedure TfmChar.FillClassGender();
var
  ls:string;
  lAltGender:Char; // 'M' or 'F'
begin
  ls:='';
  cbClass.BeginUpdate;
  cbClass.Clear;
  for i:=0 to High(FClasses) do
  begin
    if FClasses[i].gender<>lAltGender then
      cbClass.Items.AddObject(FClasses[i].title+ls,i);
  end;
  cbClass.EndUpdate;
end;
}
procedure TfmChar.FillPlayerInfo;
var
  licon,ls,ls1:string;
  i:integer;
begin
  //--- Stat ---

  GetClassInfo(FChar.ClassId,licon,FBaseStr,FBaseDex,FBaseInt,FBaseVit);

  seLevel.MaxValue:=Length(ExpGate);
  seFame .MaxValue:=Length(FameGate);
  seFame .MinValue:=1;

  // Graphs

  GetClassGraphStat(FChar.ClassId,ls,ls1,FStatPerLevel);
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

  FFreePoints:=FChar.FreeStatPoints;
  sePoints.Value:=FFreePoints;

  // Stats
  lblStrength .Caption:='('+IntToStr(FBaseStr)+') '+rsStrength;
  lblDexterity.Caption:='('+IntToStr(FBaseDex)+') '+rsDexterity;
  lblFocus    .Caption:='('+IntToStr(FBaseInt)+') '+rsFocus;
  lblVitality .Caption:='('+IntToStr(FBaseVit)+') '+rsVitality;

  // keep for Up/Down changes
  FStr:=FChar.Strength ; seStrength .Value:=FStr;
  FDex:=FChar.Dexterity; seDexterity.Value:=FDex;
  FInt:=FChar.Focus    ; seFocus    .Value:=FInt;
  FVit:=FChar.Vitality ; seVitality .Value:=FVit;
  // To prevent Statpoints negative values
  cbCheckPointsClick(Self);

  edGold.Text:=IntToStr(FChar.Gold);

  // global
  cbNGState   .ItemIndex:=FSGame.NewGameCycle;
  cbDifficulty.ItemIndex:=ORD(FSGame.Difficulty);
  cbHardcore  .Checked  :=FSGame.Hardcore;

  //--- View ---

  GetClassList(FClasses);

  cbClass.Clear;
  cbClass.Sorted:=true;
  cbClass.Items.BeginUpdate;
  cbClass.Items.Capacity:=Length(FClasses);
  for i:=0 to High(FClasses) do
    cbClass.Items.AddObject(FClasses[i].title,TObject(IntPtr(i)));
  cbClass.Items.EndUpdate;

  edClass.Text:=GetTL2Class(FChar.ClassId);//FSGame.ClassString;
  cbClass.Text:=edClass.Text;

  // set gender buttons
  i:=GetClassIndex(FChar.ClassId);
  if i>=0 then
  begin
    rbMale  .Checked:=FClasses[i].gender='M';
    rbFemale.Checked:=FClasses[i].gender='F';
    rbUnisex.Checked:=not (FClasses[i].gender in ['F','M']);
  end;

  cbCheater.Checked:=FChar.Cheater=214;

  try
    if licon='' then licon:='\unknown' else licon:='\characters\'+licon;
    imgIcon.Picture.LoadFromFile(fmSettings.edIconDir.Text+licon+'.png');
  except
    imgIcon.Picture.Clear;
  end;

  //----- Action

  InitSpellBlock();

  //--- Statistic ---

  edArea    .Text:=FSGame.Area;
  edWaypoint.Text:=FSGame.Waypoint;

end;

procedure TfmChar.FillPetInfo;
var
  i:integer;
begin
  //--- Stats ---

  seLevel.MaxValue:=Length(ExpGate);
  seFame .MaxValue:=1;

  //--- View ---

  GetPetList(FPets);

  cbMorph.Clear;
  cbMorph.Sorted:=true;
  cbMorph.Items.BeginUpdate;
  cbMorph.Items.Capacity:=Length(FPets);
  cbMorph.Items.AddObject('',TObject(IntPtr(-1)));
  for i:=0 to High(FPets) do
    cbMorph.Items.AddObject(FPets[i].title,TObject(IntPtr(i)));
  cbMorph.Items.EndUpdate;

  cbMorph.ItemIndex:=0;
  if (FChar.MorphId<>TL2IdEmpty) and
     (FChar.MorphId<>FChar.ClassId) then
  begin
    for i:=1 to cbMorph.Items.Count-1 do
      if FPets[IntPtr(cbMorph.Items.Objects[i])].id=FChar.MorphId then
      begin
        DrawPetIcon(FChar.MorphId,imgMorph);
        cbMorph.ItemIndex:=i;
        break;
      end;
  end;
  if cbMorph.ItemIndex<=0 then imgMorph.Picture.Clear;

  edMorphTime.Text:=IntToStr(Round(FChar.MorphTime));

  cbClass.Items.Assign(cbMorph.Items);
  cbClass.Items.Delete(0);

  cbClass.ItemIndex:=-1;
  for i:=0 to cbClass.Items.Count-1 do
    if FPets[IntPtr(cbClass.Items.Objects[i])].id=FChar.ClassId then
    begin
      cbClass.ItemIndex:=i;
      break;
    end;
//  cbClass.Enabled:=cbClass.ItemIndex>=0;

  DrawPetIcon(FChar.ClassId,imgIcon);

  edClass.Text:=GetTL2Pet(FChar.ClassId);
  if edClass.Text=HexStr(FChar.ClassId,16) then
     edClass.Text:=GetTL2Mob(FChar.ClassId);

  edSkin.Text:=IntToStr(ShortInt(FChar.Skin));

  //--- Action ---

  cbEnabled.Checked:=FChar.Enabled;
  edTownTime.Text:=IntToStr(round(FChar.TownTime));

  rbActionIdle   .Checked:=FChar.Action=Idle;
  rbActionAttack .Checked:=FChar.Action=Attack;
  rbActionDefence.Checked:=FChar.Action=Defence;

  if not FConfigured then
    InitSpellBlock();

  //--- Statistic ---

end;

procedure TfmChar.FillInfo(aChar:TTL2Character; aSGame:TTL2SaveFile=nil);
var
  ls:string;
  i:integer;
begin
  if FConfigured and (FKind=ciPlayer) then exit;

  FSGame:=aSGame;
  FChar :=aChar;

  if      FChar.IsChar then FillPlayerInfo()
  else if FChar.IsPet  then FillPetInfo()
  else
  begin
    edClass.Text:=GetTL2Mob(FChar.ClassId);
    seLevel.MaxValue:=999;
    seFame .MaxValue:=1;
  end;

  //--- Stats ---

  FLevel:=FChar.Level    ; seLevel.Value:=FLevel;
  FFame :=FChar.FameLevel; seFame .Value:=FFame;

  edExperience .Text :=IntToStr(FChar.Experience);
  edFameExp    .Text :=IntToStr(FChar.FameExp);
  edHealth     .Text :=IntToStr(Round(FChar.Health));
  edHealthBonus.Text :=IntToStr(FChar.HealthBonus);
  edMana       .Text :=IntToStr(Round(FChar.Mana));
  edManaBonus  .Text :=IntToStr(FChar.ManaBonus);

  //--- View ---

  edName.Text      :=FChar.Name;
  lblSuffix.Caption:=FChar.Suffix;

  seScale.Value:=FChar.Scale;

  //--- Action ---

  //--- Statistic ---

  edX.Text:=FloatToStrF(FChar.Position.X,ffFixed,-8,2);
  edY.Text:=FloatToStrF(FChar.Position.Y,ffFixed,-8,2);
  edZ.Text:=FloatToStrF(FChar.Position.Z,ffFixed,-8,2);

  lbModList.Clear;
  for i:=0 to High(FChar.ModIds) do
    lbModList.AddItem(GetTL2Mod(FChar.ModIds[i]),nil);

  sgStats.BeginUpdate;
  sgStats.Clear;
  sgStats.RowCount:=1+Length(FChar.Stats);
  for i:=0 to High(FChar.Stats) do
  begin
    sgStats.Cells[0,i+1]:=GetTL2Stat(FChar.Stats[i].id,ls);
    sgStats.Cells[1,i+1]:=IntToStr  (FChar.Stats[i].value);
    sgStats.Cells[2,i+1]:=GetTL2Mod(ls);
  end;

  sgStats.EndUpdate;

  bbUpdate.Enabled:=false;
  FConfigured:=true;
end;

//----- Update -----

procedure TfmChar.UpdatePlayerInfo();
begin
  //--- Stats

  FChar.Strength  :=seStrength .Value;
  FChar.Dexterity :=seDexterity.Value;
  FChar.Focus     :=seFocus    .Value;
  FChar.Vitality  :=seVitality .Value;
  FChar.Gold      :=StrToIntDef(edGold.Text,0);

  if FFreePoints>0 then
    FChar.FreeStatPoints:=FFreePoints
  else
    FChar.FreeStatPoints:=0;

  // global
  FSGame.NewGameCycle:=cbNGState.ItemIndex;
  FSGame.Difficulty  :=TTL2Difficulty(cbDifficulty.ItemIndex);
  FSGame.Hardcore    :=cbHardcore.Checked;

  //--- View

  if cbCheater.Checked then
    FChar.Cheater:=214
  else
    FChar.Cheater:=78;

  FChar.ClassId:=FClasses[IntPtr(cbClass.Items.Objects[cbClass.ItemIndex])].id;

  if (FSkillForm<>nil) and (FSkillForm.bbUpdate.Enabled) then
    FSkillForm.bbUpdateClick(Self);
end;

procedure TfmChar.UpdatePetInfo();
var
  idx:integer;
begin
  //--- View
  if cbClass.ItemIndex>=0 then
  begin
    FChar.ClassId:=FPets[IntPtr(cbClass.Items.Objects[cbClass.ItemIndex])].id;
  end;

  idx:=IntPtr(cbMorph.Items.Objects[cbMorph.ItemIndex]);
  if idx>=0 then
    FChar.MorphId:=FPets[idx].id
  else
    FChar.MorphId:=TL2IdEmpty;

  FChar.MorphTime:=StrToIntDef(edMorphTime.Text,0);
  FChar.Skin     :=Byte(StrToIntDef(edSkin.Text,-1));

  //--- Action

  FChar.Enabled :=cbEnabled.Checked;
  FChar.TownTime:=StrToIntDef(edTownTime.Text,0);

  if      rbActionIdle   .Checked then FChar.Action:=Idle
  else if rbActionAttack .Checked then FChar.Action:=Attack
  else if rbActionDefence.Checked then FChar.Action:=Defence;

end;

procedure TfmChar.bbUpdateClick(Sender: TObject);
begin

  //--- Stat

  FChar.Level      :=seLevel.Value;
  FChar.FameLevel  :=seFame .Value;
  FChar.Experience :=StrToInt(edExperience .Text);
  FChar.FameExp    :=StrToInt(edFameExp    .Text);
  FChar.HealthBonus:=StrToInt(edHealthBonus.Text);
  FChar.ManaBonus  :=StrToInt(edManaBonus  .Text);
  FChar.Health     :=StrToIntDef(edHealth.Text,FChar.HealthBonus);
  FChar.Mana       :=StrToIntDef(edMana  .Text,FChar.ManaBonus);

  //--- View

  FChar.Name :=edName .Text;
  FChar.Scale:=seScale.Value;

  //--- Action

  SetCharSpell(cbSpell1,0);
  SetCharSpell(cbSpell2,1);
  SetCharSpell(cbSpell3,2);
  SetCharSpell(cbSpell4,3);

  //--- Statistic

  //--- Personal

  if FChar.IsChar then UpdatePlayerInfo();
  if FChar.IsPet  then UpdatePetInfo();

  bbUpdate.Enabled:=false;
  FChar.Changed:=true;
end;

procedure TfmChar.cbKeepBaseClick(Sender: TObject);
begin
  if cbKeepBase.Checked then
  begin
    //!! recalc value different
    seStrength .MinValue:=FBaseStr;
    seDexterity.MinValue:=FBaseDex;
    seFocus    .MinValue:=FBaseInt;
    seVitality .MinValue:=FBaseVit;
    //!! check what "OnChange" called
  end
  else
  begin
    seStrength .MinValue:=1;
    seDexterity.MinValue:=1;
    seFocus    .MinValue:=1;
    seVitality .MinValue:=1;
  end;
end;

end.
