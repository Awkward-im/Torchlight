unit formChar;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  Spin, ExtCtrls, Buttons, Grids, SpinEx, ListFilterEdit,
  rgglobal, tlsave, tlsgchar, rgdb, formSkills, formItems, formEffects;

type
  tCharInfoType = (ciPlayer, ciPet, ciUnit);

  { TfmChar }

  TfmChar = class(TForm)
    bbNewClass: TBitBtn;
    bbUpdate: TBitBtn;
    seSkin: TSpinEdit;

    lblCustomClass: TLabel;
    lblSkin: TLabel;
    lbNewClass: TListBox;
    lfeNewClass: TListFilterEdit;

    pnlTop: TPanel;
    pcCharInfo: TPageControl;

    // Stats
    tsStat: TTabSheet;

    cbKeepBase: TCheckBox;
    gbBaseStats: TGroupBox;
    seStrength : TSpinEditEx;  lblStrength  : TLabel;
    seDexterity: TSpinEditEx;  lblDexterity : TLabel;
    seFocus    : TSpinEditEx;  lblFocus     : TLabel;
    seVitality : TSpinEditEx;  lblVitality  : TLabel;

    seFreePoints: TSpinEditEx; lblFreePoints: TLabel;
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
    rbMale  : TRadioButton;
    rbFemale: TRadioButton;
    rbUnisex: TRadioButton;

    edName: TEdit;  lblName: TLabel;
    lblSuffix: TLabel;

    bbManual: TBitBtn;
    edClassId: TEdit;
    edNewClass: TEdit;
    edClass: TEdit;lblNewClass      : TLabel;
    cbMorph    : TComboBox;  lblMorph  : TLabel;
    edMorphTime: TEdit;      lblMorphTime: TLabel;  lblMorphNote: TLabel;
    seScale: TFloatSpinEdit;  lblScale: TLabel;

    cbCheater: TCheckBox;

    // Wardrobe
    tsWardrobe: TTabSheet;

    gbWardrobe: TGroupBox;
    lblWardFace     : TLabel;    cbWardFace     : TComboBox;
    lblWardHair     : TLabel;    cbWardHair     : TComboBox;
    lblWardColor    : TLabel;    cbWardColor    : TComboBox;
    lblWardFeature1 : TLabel;    cbWardFeature1 : TComboBox;
    lblWardFeature2 : TLabel;    cbWardFeature2 : TComboBox;
    lblWardFeature3 : TLabel;    cbWardFeature3 : TComboBox;
    lblWardGloves   : TLabel;    cbWardGloves   : TComboBox;
    lblWardHead     : TLabel;    cbWardHead     : TComboBox;
    lblWardTorso    : TLabel;    cbWardTorso    : TComboBox;
    lblWardPants    : TLabel;    cbWardPants    : TComboBox;
    lblWardShoulders: TLabel;    cbWardShoulders: TComboBox;
    lblWardBoots    : TLabel;    cbWardBoots    : TComboBox;

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

    sgStats: TStringGrid;

    gbCoords: TGroupBox;
    edX: TEdit;  lblX: TLabel;
    edY: TEdit;  lblY: TLabel;
    edZ: TEdit;  lblZ: TLabel;

    edArea    : TEdit;  lblArea    : TLabel;
    edWaypoint: TEdit;  lblWaypoint: TLabel;

    lbModList: TListBox; lblModList: TLabel;

    // Other
    tsOtherInfo: TTabSheet;

    // Items
    tsItems: TTabSheet;
    
    procedure bbManualClick(Sender: TObject);
    procedure bbNewClassClick(Sender: TObject);
    procedure bbUpdateClick(Sender: TObject);
    procedure cbKeepBaseClick(Sender: TObject);
    procedure cbWardFaceChange(Sender: TObject);
    procedure lbNewClassSelectionChange(Sender: TObject; User: boolean);
    procedure seFreePointsChange(Sender: TObject);
    procedure sgStatsEditingDone(Sender: TObject);
    procedure StatChange(Sender: TObject);
    procedure cbCheckPointsClick(Sender: TObject);
    procedure cbSpellChange   (Sender: TObject);
    procedure cbSpellLvlChange(Sender: TObject);
    procedure cbMorphChange(Sender: TObject);
    procedure ToSetUpdate(Sender: TObject);
    procedure rbGenderClick(Sender: TObject);
    procedure seFameChange (Sender: TObject);
    procedure seLevelChange(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

  private
    FEffects:TfmEffects;

    OldCheckPointsState:boolean;

    FKind:tCharInfoType;
    FConfigured:boolean;

    FSkillForm:TfmSkills;
    FItems    :TfmItems;

    FSGame:TTLSaveFile;
    FChar :TTLCharacter;

    // can be global
    WardrobeData  : TWardrobeData;
    WardIdx:array [0..11] of integer;
    ClassWardrobe : array [0..11,0..49] of integer;

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

    FFreeStatPoints:integer;
    FUserStatPoints:integer;

    procedure ChangeClass(idx: integer);
    procedure DrawCharIcon(const aname: string; aImg: TImage);
    procedure DrawIconInt(const aname, adir: string; aImg: TImage);
    procedure DrawPetIcon(aclass: TRGID; aImg: TImage);
    procedure FillClassList(setindex: boolean);
    procedure FillPetList;
    procedure FillPetInfo;
    procedure FillPlayerInfo;
    procedure FillWardMatrix(const alist:string);
    procedure UpdateModList;
    function GetClassIndex(id: TRGID): integer;

    function GetMainFlag:boolean;
    function GetWardTitle(idx: integer; aval: integer): string;
    procedure SetupVisualPart;

    procedure SetCharSpell(cb: TComboBox; idx: integer);
    procedure GetCharSpell(cb: TComboBox; idx: integer);
    procedure InitSpellBlock;
    function  SearchAltGender(aclass: TRGID): integer;
    procedure SetWardCombo(acb: TComboBox; aidx: integer; aval: integer);
    procedure UpdatePetInfo();
    procedure UpdatePlayerInfo();
    procedure UpdatePetView(idx:integer);

    procedure PreCalcStat;
    procedure RecalcFreePoints;
    procedure SetConfigured(aval:boolean);
    procedure UpdatePlayerView(aid: TRGID; const aclass: string);

  public
    constructor Create(AOwner:TComponent; atype:tCharInfoType); overload;
    procedure FillInfo(aChar:TTLCharacter; aSGame:TTLSaveFile=nil);

    property IsMain    :boolean   read GetMainFlag;
    property Configured:boolean   read FConfigured write SetConfigured;
    property SkillForm :TfmSkills read FSkillForm  write FSkillForm;
  end;

var
  fmChar: TfmChar;

implementation

{$R *.lfm}

uses
  INIFiles,
  addons,
  formSettings,
  unitGlobal;

resourcestring
  rsDefault = 'Default';

  rsStrength   = 'Strength';
  rsDexterity  = 'Dexterity';
  rsFocus      = 'Focus';
  rsVitality   = 'Vitality';

  rsCasual  = 'Casual';
  rsNormal  = 'Normal';
  rsVeteran = 'Veteran';
  rsExpert  = 'Expert';

  rsMale   = 'male';
  rsFemale = 'female';

const
  sStats       = 'Stats';
  sCheckPoints = 'checkpoints';

const
  dirSpellIcon = 'skills'; // 'spells';
  dirCharIcon  = 'characters';
  dirPetIcon   = 'pets';

//----- Support -----

function TfmChar.GetMainFlag:boolean;
begin
  result:=(FChar.Sign=$FF);
end;

procedure TfmChar.SetConfigured(aval:boolean);
begin
  FConfigured:=aval;
  SkillForm.Configured:=false;
end;

procedure TfmChar.DrawIconInt(const aname,adir:string; aImg:TImage);
var
  licon:string;
begin
  if aname='' then
  begin
    aImg.Picture.Clear;
    exit;
  end;

  licon:=SearchForFileName(fmSettings.IconDir+'\'+adir+'\',UpCase(aname));

  if licon<>'' then
  begin
    try
      aImg.Picture.LoadFromFile(licon);
    except
      licon:='';
    end;
  end;

  if licon='' then
    try
      aImg.Picture.LoadFromFile(fmSettings.IconDir+'\unknown.png');
    except
      aImg.Picture.Clear;
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
      edExperience.Text:=IntToStr(ExpGate[seLevel.Value-2]+1);

    FLevel:=seLevel.Value;
    if FChar.CharType=ctPlayer then
    begin
      RecalcFreePoints;

      edHealthBonus.Text:=IntToStr((HPTier[seLevel.Value-1]+5) div 10);
      edManaBonus  .Text:=IntToStr((MPTier[seLevel.Value-1]+5) div 10);
    end;

    if FSkillForm<>nil then FSkillForm.Level:=FLevel;
  end;
end;

{%REGION Class change}
function TfmChar.GetClassIndex(id:TRGID):integer;
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

function TfmChar.SearchAltGender(aclass:TRGID):integer;
var
  ls:string;
  i,idx:integer;
begin
  result:=-1;
  // 1 - search source index
  idx:=GetClassIndex(aclass);
  if idx<0 then
    exit; // MUST NOT happend

  // 2 - check alter name
  ls:=Copy(FClasses[idx].name,1);
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
    if (i<>idx) and (FClasses[i].title=ls) then
    begin
      // really, need to check both mod list too
      result:=i;
      exit;
    end;
  end;
end;

procedure TfmChar.rbGenderClick(Sender: TObject);
var
  lname:string;
  idx,i:integer;
begin
  if not FConfigured then exit;

  lname:=edClass.Text;
  if lbNewClass.ItemIndex<0 then
  begin
    idx:=-1;
    i:=Length(lname);
    if (i>2) and (lname[i-1]='_') then
    begin
      if      rbFemale.Checked then lname[i]:='F'
      else if rbMale  .Checked then lname[i]:='M';
    end;
  end
  else
  begin
    idx:=IntPtr(lbNewClass.Items.Objects[lbNewClass.ItemIndex]);
    if (rbMale  .Checked and (FClasses[idx].gender='F')) or
       (rbFemale.Checked and (FClasses[idx].gender='M')) then
    begin
      idx:=SearchAltGender(FClasses[idx].id);
      if idx>=0 then
        lname:=FClasses[idx].name;
    end;
  end;

  FillClassList(false);

  if idx>=0 then
    for i:=0 to lbNewClass.Items.Count-1 do
    begin
      if IntPtr(lbNewClass.Items.Objects[i])=idx then
      begin
        lbNewClass.ItemIndex:=i;
        break;
      end;
    end;
  if lbNewClass.ItemIndex<0 then edNewClass.Text:=lname;

end;

procedure TfmChar.ChangeClass(idx:integer);
var
  lname:string;
  lid:TRGID;
  i:integer;
begin
  if idx<0 then
  begin
    lname:=edNewClass.Text;
    if lname<>'' then
      for i:=0 to High(FClasses) do
      begin
        if FClasses[i].name=lname then
        begin
          idx:=i;
          break;
        end;
      end;
  end;

  if idx>=0 then
  begin
    lid:=FClasses[idx].id;
    FillWardMatrix(RGDBGetClassWardrobe(lid));
    edNewClass.Text:=FClasses[idx].name;
    FSkillForm.PlayerClass:=lid;
  end
  else
  begin
//    ResetAllSkills;
    lid:=RGIdEmpty;
  end;

  UpdatePlayerView(lid,edNewClass.Text);

  bbUpdate.Enabled:=true;
end;

procedure TfmChar.bbManualClick(Sender: TObject);
var
  i,idx:integer;
begin
  lbNewClass.ItemIndex:=-1;
  for i:=0 to lbNewClass.Items.Count-1 do
  begin
    idx:=IntPtr(lbNewClass.Items.Objects[i]);
    if FClasses[idx].name=edNewClass.Text then
    begin
      lbNewClass.ItemIndex:=i;
      bbNewClassClick(Sender);
      exit;
    end;
  end;

  ChangeClass(-1);
end;

procedure TfmChar.bbNewClassClick(Sender: TObject);
var
  idx:integer;
begin
  if lbNewClass.ItemIndex<0 then exit;
  idx:=IntPtr(lbNewClass.Items.Objects[lbNewClass.ItemIndex]);
  if FClasses[idx].id=FChar.ID then exit;

  ChangeClass(idx);
end;

procedure TfmChar.lbNewClassSelectionChange(Sender: TObject; User: boolean);
var
  licon:string;
  lid:TRGID;
  idx:integer;
begin
  if lbNewClass.ItemIndex>=0 then
    idx:=IntPtr(lbNewClass.Items.Objects[lbNewClass.ItemIndex])
  else
    idx:=-1;

  if FChar.CharType=ctPlayer then
  begin
    Val(edClassId.Text,lid);
    if (idx>=0) and (FClasses[idx].Id<>lid) then
      licon:=FClasses[idx].icon
    else
      licon:='';
    DrawIconInt(licon,dirCharIcon,imgMorph);
  end;

  if FChar.CharType=ctPet then
  begin
    UpdatePetView(idx);

    bbUpdate.Enabled:=true;
  end;

end;
{%ENDREGION Class change}

{%REGION Player}
procedure TfmChar.DrawCharIcon(const aname:string; aImg:TImage);
begin
  if aname='' then
    DrawIconInt(edClass.Text+'icon',dirCharIcon,aImg)
  else
    DrawIconInt(aname,dirCharIcon,aImg);
end;

procedure TfmChar.PreCalcStat;
begin
  FUserStatPoints:=
      FFreeStatPoints                         // Free  points
      -((FChar.Level-1)*FStatPerLevel)        // Bonus points
      -(FBaseStr+FBaseDex+FBaseInt+FBaseVit)  // Base  points
      +(FStr+FDex+FInt+FVit);                 // Used  points
end;

procedure TfmChar.RecalcFreePoints;
begin
  FFreeStatPoints:=
      FUserStatPoints
      +((FLevel-1)*FStatPerLevel)             // Bonus points
      +(FBaseStr+FBaseDex+FBaseInt+FBaseVit)  // Base  points
      -(FStr+FDex+FInt+FVit);                 // Used  points

  seFreePoints.Value:=FFreeStatPoints;

  cbCheckPointsClick(Self);
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
  else{if Sender=seVitality  then}pStat:=@FVit;

  if lval=pStat^ then exit;

  bbUpdate.Enabled:=true;
  pStat^:=lval;

  RecalcFreePoints;
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

    if FSkillForm<>nil then FSkillForm.Fame:=FFame;
  end;
end;

procedure TfmChar.cbCheckPointsClick(Sender: TObject);
begin
  if (FFreeStatPoints<=0) and cbCheckPoints.Checked then
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

procedure TfmChar.seFreePointsChange(Sender: TObject);
begin
  if FFreeStatPoints<>seFreePoints.Value then
  begin
    FFreeStatPoints:=seFreePoints.Value;
    bbUpdate.Enabled:=true;
    PreCalcStat;
  end;
end;

procedure TfmChar.sgStatsEditingDone(Sender: TObject);
begin
  bbUpdate.Enabled:=true;
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

procedure TfmChar.UpdatePlayerView(aid:TRGID; const aclass:string);
var
  licon:string;
  i:integer;
begin
  // set gender buttons
  i:=GetClassIndex(aid);
  if i>=0 then
  begin
    rbMale  .Checked:=FClasses[i].gender='M';
    rbFemale.Checked:=FClasses[i].gender='F';
    rbUnisex.Checked:=not (FClasses[i].gender in ['F','M']);

    edClass.Text:=RGDBGetClass(aid);
    licon:=FClasses[i].icon;
  end
  else
  begin
    edClass.Text:=aclass;
    // trying to guess
    rbUnisex.Checked:=true;
    i:=Length(aclass);
    if (i>2) and (aclass[i-1]='_') then
    begin
      rbFemale.Checked:=aclass[i]='F';
      rbMale  .Checked:=aclass[i]='M';
    end;
    licon:=aclass;
    i:=-1;
  end;
  edClassId.Text:=TextId(aid);

  FillClassList(true);

  DrawCharIcon(licon,imgIcon);
end;

procedure TfmChar.FillClassList(setindex:boolean);
var
  ls:string;
  lid:TRGID;
  i:integer;
begin
  lfeNewClass.Items.Clear;
  lfeNewClass.Text:='';
  lfeNewClass.SortData:=true;

  lfeNewClass.Items.BeginUpdate;
  lfeNewClass.Items.Capacity:=Length(FClasses); //??

  for i:=0 to High(FClasses) do
  begin
    ls:=FClasses[i].title;
    if ls='' then continue;

    if (rbMale  .Checked and (FClasses[i].gender='M')) or
       (rbFemale.Checked and (FClasses[i].gender='F')) then
    begin
      lfeNewClass.Items.AddObject(FClasses[i].title,TObject(IntPtr(i)));
    end
    else if rbUnisex.Checked then
    begin
      if      FClasses[i].gender='M' then ls:=ls+' ('+rsMale  +')'
      else if FClasses[i].gender='F' then ls:=ls+' ('+rsFemale+')';
      lfeNewClass.Items.AddObject(ls,TObject(IntPtr(i)));
    end;
  end;
  lfeNewClass.Items.EndUpdate;
  lfeNewClass.ForceFilter(' ');
  lfeNewClass.ForceFilter('');

  lbNewClass.ItemIndex:=-1;

  if setindex then
  begin
    Val(edClassId.Text,lid);
    for i:=0 to lbNewClass.Items.Count-1 do
      if FClasses[IntPtr(lbNewClass.Items.Objects[i])].id=lid then
      begin
        lbNewClass.ItemIndex:=i;
        break;
      end;
  end;
end;

procedure TfmChar.FillPlayerInfo;
var
  licon,ls,ls1:string;
  i:integer;
begin
  SetLength(FClasses,0);
  RGDBGetClassList(FClasses);

  //--- Stat ---

  RGDBGetClassInfo(FChar.ID,licon,FBaseStr,FBaseDex,FBaseInt,FBaseVit);

  seLevel.MaxValue:=Length(ExpGate);
  seFame .MaxValue:=Length(FameGate);
  seFame .MinValue:=1;

  // Graphs

  RGDBGetClassGraphStat(FChar.ID,ls,ls1,FStatPerLevel);
  HPTier:=RGDBGetGraphArray(ls );
  MPTier:=RGDBGetGraphArray(ls1);

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

  FFreeStatPoints:=FChar.FreeStatPoints;
  seFreePoints.Value:=FFreeStatPoints;

  // To prevent Statpoints negative values
  cbCheckPointsClick(Self);
  PreCalcStat;

  edGold.Text:=IntToStr(FChar.Gold);

  // global
  cbNGState   .ItemIndex:=FSGame.NewGameCycle;
  cbDifficulty.ItemIndex:=ORD(FSGame.Difficulty);
  cbHardcore  .Checked  :=FSGame.Hardcore;

  //--- View ---

  UpdatePlayerView(FChar.ID, FSGame.ClassString);

  cbCheater.Checked:=FChar.Cheater=214;

  //--- Action ---

  InitSpellBlock();

  //--- Wardrobe ---

  if WardrobeData=nil then
    RGDBGetWardrobe(WardrobeData);

  FillWardMatrix(RGDBGetClassWardrobe(FChar.ID));

  //--- Statistic ---

  edArea    .Text:=FSGame.Area;
  edWaypoint.Text:=FSGame.Waypoint;

  //--- Skill related ---

  FSkillForm.Configured :=false;
  FSkillForm.PlayerClass:=FChar.ID;
  FSkillForm.Player     :=FChar;
end;

procedure TfmChar.UpdatePlayerInfo();
var
  lid:TRGID;
  i,idx:integer;
begin
  //--- Stats ---

  FChar.Strength  :=seStrength .Value;
  FChar.Dexterity :=seDexterity.Value;
  FChar.Focus     :=seFocus    .Value;
  FChar.Vitality  :=seVitality .Value;
  FChar.Gold      :=StrToIntDef(edGold.Text,0);

  if FFreeStatPoints>0 then
    FChar.FreeStatPoints:=FFreeStatPoints
  else
    FChar.FreeStatPoints:=0;

  // global
  FSGame.NewGameCycle:=cbNGState.ItemIndex;
  FSGame.Difficulty  :=TL2Difficulty(cbDifficulty.ItemIndex);
  FSGame.Hardcore    :=cbHardcore.Checked;

  //--- View ---

  if cbCheater.Checked then
    FChar.Cheater:=214
  else
    FChar.Cheater:=78;

  Val(edClassId.Text,lid);
  FChar.ID:=lid;
  FSGame.ClassString:=edClass.Text;

  if FSkillForm.bbUpdate.Enabled then
    FSkillForm.bbUpdateClick(Self)
  else
  begin
    if FSkillForm.FreeSkillPoints>0 then
      FChar.FreeSkillPoints:=FSkillForm.FreeSkillPoints
    else
      FChar.FreeSkillPoints:=0;
  end;

  //--- Wardrobe ---

  FChar.Face     :=cbWardFace     .ItemIndex-1;
  FChar.Hairstyle:=cbWardHair     .ItemIndex-1;
  FChar.HairColor:=cbWardColor    .ItemIndex-1;
  FChar.Feature1 :=cbWardFeature1 .ItemIndex-1;
  FChar.Feature2 :=cbWardFeature2 .ItemIndex-1;
  FChar.Feature3 :=cbWardFeature3 .ItemIndex-1;
  FChar.Gloves   :=cbWardGloves   .ItemIndex-1;
  FChar.Head     :=cbWardHead     .ItemIndex-1;
  FChar.Torso    :=cbWardTorso    .ItemIndex-1;
  FChar.Pants    :=cbWardPants    .ItemIndex-1;
  FChar.Shoulders:=cbWardShoulders.ItemIndex-1;
  FChar.Boots    :=cbWardBoots    .ItemIndex-1;

  //--- Statistic ---

  if sgStats.Modified then
  begin
    for i:=1 to sgStats.RowCount-1 do
    begin
      idx:=IntPtr(sgStats.Objects[0,i]);
      Val(sgStats.Cells[1,i],FChar.Stats[idx].value);
    end;
  end;
end;
{%ENDREGION Player}

{%REGION Pet}
procedure TfmChar.DrawPetIcon(aclass:TRGID; aImg:TImage);
begin
  DrawIconInt(RGDBGetPetIcon(aclass),dirPetIcon,aImg);
end;

procedure TfmChar.cbMorphChange(Sender: TObject);
var
  idx:integer;
begin
  idx:=IntPtr(cbMorph.Items.Objects[cbMorph.ItemIndex]);
  if idx<0 then
  begin
    imgMorph.Picture.Clear;
    idx:=IntPtr(lbNewClass.Items.Objects[lbNewClass.ItemIndex]);
  end
  else
  begin
    DrawPetIcon(FPets[idx].id,imgMorph);
    seScale.Value:=FPets[idx].scale;
  end;

  bbUpdate.Enabled:=true;
end;

procedure TfmChar.FillPetList;
var
  ls:string;
  i:integer;
begin
  SetLength(FPets,0);

  RGDBGetPetList(FPets);

  lfeNewClass.Clear;
  lfeNewClass.Text:='';
  lfeNewClass.SortData:=true;
  lfeNewClass.Items.BeginUpdate;
  lfeNewClass.Items.Capacity:=Length(FPets);
  for i:=0 to High(FPets) do
  begin
    ls:=FPets[i].title;
    if ls='' then ls:=FPets[i].name
    else ls:=ls+ ' ('+FPets[i].name+')';
    lfeNewClass.Items.AddObject(ls,TObject(IntPtr(i)));
  end;
  lfeNewClass.Items.EndUpdate;

  // Cheat to fill ListBox before form show
  lfeNewClass.ForceFilter(' ');
  lfeNewClass.ForceFilter('');

  // search after filling coz sorted
  lbNewClass.ItemIndex:=-1;
  for i:=0 to lbNewClass.Items.Count-1 do
    if FPets[IntPtr(lbNewClass.Items.Objects[i])].id=FChar.ID then
    begin
      lbNewClass.ItemIndex:=i;
      break;
    end;
end;

procedure TfmChar.UpdatePetView(idx:integer);
var
  lid:TRGID;
  lskins:integer;
begin
  if idx>=0 then
  begin
    lid:=FPets[idx].id;
    if cbMorph.ItemIndex<=0 then seScale.Value:=FPets[idx].scale;
  end
  else
  begin
    lid:=FChar.ID;
    if cbMorph.ItemIndex<=0 then seScale.Value:=FChar.scale;
  end;

  DrawPetIcon(lid,imgIcon);

  seSkin.Value:=0;
  lskins:=RGDBGetPetSkins(lid);
  seSkin .Visible:=lskins>1;
  lblSkin.Visible:=lskins>1;
  if lskins>1 then
  begin
    seSkin.MaxValue:=lskins-1;
    if FChar.Skin<lskins then
      seSkin.Value:=FChar.Skin;
  end;

  edClassId.Text:=TextId(lid);
  edClass  .Text:=RGDBGetPet(lid);
  if edClass.Text=HexStr(lid,16) then
     edClass.Text:=RGDBGetMob(lid);
end;

procedure TfmChar.FillPetInfo;
var
  i:integer;
begin
  //--- Stats ---

  seLevel.MaxValue:=Length(ExpGate);
  seFame .MaxValue:=1;

  //--- View ---

  FillPetList();

  if cbMorph.Visible then
  begin
    cbMorph.Items.Assign(lfeNewClass.Items);
    cbMorph.Items.InsertObject(0,'',TObject(IntPtr(-1)));

    cbMorph.ItemIndex:=0;
    if (FChar.MorphId<>RGIdEmpty) and
       (FChar.MorphId<>FChar.ID) then
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
  end;

  UpdatePetView(-1);

  //--- Action ---

  cbEnabled.Checked:=FChar.Enabled;
  edTownTime.Text:=IntToStr(round(FChar.TownTime));

  rbActionIdle   .Checked:=FChar.Action=Idle;
  rbActionAttack .Checked:=FChar.Action=Attack;
  rbActionDefence.Checked:=FChar.Action=Defence;

  if not FConfigured then
    InitSpellBlock();

end;

procedure TfmChar.UpdatePetInfo();
var
  lid:TRGID;
  idx:integer;
begin
  //--- View ---

  Val(edClass.Text,lid);
  FChar.ID:=lid;

  if cbMorph.Visible then
  begin
    idx:=IntPtr(cbMorph.Items.Objects[cbMorph.ItemIndex]);
    if idx>=0 then
      FChar.MorphId:=FPets[idx].id
    else
      FChar.MorphId:=RGIdEmpty;

    FChar.MorphTime:=StrToIntDef(edMorphTime.Text,0);
  end;

  if seSkin.Visible then FChar.Skin:=seSkin.Value;

  //--- Action ---

  FChar.Enabled :=cbEnabled.Checked;
  FChar.TownTime:=StrToIntDef(edTownTime.Text,0);

  if      rbActionIdle   .Checked then FChar.Action:=Idle
  else if rbActionAttack .Checked then FChar.Action:=Attack
  else if rbActionDefence.Checked then FChar.Action:=Defence;

end;

{%ENDREGION Pet}

{%REGION Spells}
procedure TfmChar.cbSpellChange(Sender: TObject);
var
  cb:TComboBox;
  licon:string;
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

        licon:=SearchForFileName(fmSettings.IconDir+'\'+dirSpellIcon+'\',UpCase(SpellList[idx].icon));
        if licon<>'' then
          try
            TImage(cb.Tag).Picture.LoadFromFile(licon);
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
  lid:TRGID;
  lspell:TTL2Spell;
begin
  lspell:=FChar.Spells[idx];
  cb.Text:=RGDBGetSkill(lspell.name,lid);
  cbSpellChange(cb);
  TComboBox(cb.Tag).Text:=IntToStr(lspell.level);
end;

procedure TfmChar.SetCharSpell(cb:TComboBox; idx:integer);
var
  lspell:TTL2Spell;
  lcb:TComboBox;
begin
  lcb:=TComboBox(cb.Tag);
  if (cb.ItemIndex>=0) and
     (IntPtr(cb.Items.Objects[cb.ItemIndex])>=0) then
  begin
    lspell.name :=SpellList[IntPtr( cb.Items.Objects[ cb.ItemIndex])].name;
    lspell.level:=          IntPtr(lcb.Items.Objects[lcb.ItemIndex]);
  end
  else
  begin
    lspell.name:=cb.Text;
    Val(lcb.Text,lspell.level);
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

  cbSpell2.Items:=cbSpell1.Items;
  cbSpell3.Items:=cbSpell1.Items;
  cbSpell4.Items:=cbSpell1.Items;
{
  cbSpell2.Items.Assign(cbSpell1.Items);
  cbSpell3.Items.Assign(cbSpell1.Items);
  cbSpell4.Items.Assign(cbSpell1.Items);
}
  GetCharSpell(cbSpell1,0);
  GetCharSpell(cbSpell2,1);
  GetCharSpell(cbSpell3,2);
  GetCharSpell(cbSpell4,3);
end;
{%ENDREGION Spells}

{%REGION Form}

//Setup Visible and ReadOnly for controls without setting dependency

procedure TfmChar.SetupVisualPart;
var
  lChar,lPet:boolean;
begin
  lChar:=FKind=ciPlayer;
  lPet :=FKind=ciPet;

  pnlTop.Visible:=lChar or lPet;

  //--- Stats ---

  gbGlobal     .Visible:=lChar;
  gbBaseStats  .Visible:=lChar;
  seFreePoints .Visible:=lChar;
  lblFreePoints.Visible:=lChar;
  lblDataNote  .Visible:=lChar;
  cbCheckPoints.Visible:=lChar;
  cbKeepBase   .Visible:=lChar;

  gbData.Enabled:=lChar or lPet;
  seFame.Enabled:=lChar;

  bbUpdate.Visible:=lChar or lPet;

  //--- View ---

  imgIcon  .Visible:=lChar or lPet;
  cbCheater.Visible:=lChar;

  lblNewClass    .Visible:=lChar or lPet;
  lfeNewClass    .Visible:=lChar or lPet;
  lbNewClass     .Visible:=lChar or lPet;
  bbNewClass     .Visible:=lChar; // auto for pets

  lblCustomClass.Visible:=lChar;
  edNewClass    .Visible:=lChar;
  bbManual      .Visible:=lChar;

  edName .ReadOnly:=not (lChar or lPet);
  seScale.ReadOnly:=not (lChar or lPet);

  lblSkin   .Visible:=lPet;
  seSkin    .Visible:=lPet;

  //--- Wardrobe ---

// tab choosing in FillInfo
//  gbWardrobe.Visible:=lChar;

  //--- Actions ---

  tsAction.TabVisible:=lChar or lPet;

  cbSpell1.Tag:=PtrUInt(cbSpellLvl1); cbSpellLvl1.Tag:=PtrUInt(Image1);
  cbSpell2.Tag:=PtrUInt(cbSpellLvl2); cbSpellLvl2.Tag:=PtrUInt(Image2);
  cbSpell3.Tag:=PtrUInt(cbSpellLvl3); cbSpellLvl3.Tag:=PtrUInt(Image3);
  cbSpell4.Tag:=PtrUInt(cbSpellLvl4); cbSpellLvl4.Tag:=PtrUInt(Image4);

  cbEnabled  .Visible:=lPet;
  gbAction   .Visible:=lPet;
  edTownTime .Visible:=lPet;
  lblTownTime.Visible:=lPet;

  //--- Statistic ---

  edArea     .Visible:=lChar;
  lblArea    .Visible:=lChar;
  edWaypoint .Visible:=lChar;
  lblWaypoint.Visible:=lChar;
  sgStats.Columns[1].ReadOnly:=not lChar;

  //--- Items
  tsItems.TabVisible:=not (lChar or lPet);
end;

procedure TfmChar.FormDestroy(Sender: TObject);
var
  config:TIniFile;
begin
  SetLength(FPets,0);
  SetLength(FClasses,0);

  SetLength(HPTier,0);
  SetLength(MPTier,0);

  if (FKind=ciPlayer) and (OldCheckPointsState<>cbCheckPoints.Checked) then
  begin
    config:=TMemIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);
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
  FItems:=nil;

  FEffects:=TfmEffects.Create(Self);
  FEffects.Parent :=tsOtherInfo;
  FEffects.Align  :=alClient;
  FEffects.Visible:=true;

  SetupVisualPart;

  case FKind of
    ciPlayer: begin
      config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);
      cbCheckPoints.Checked:=config.ReadBool(sStats,sCheckPoints,true);
      OldCheckPointsState:=cbCheckPoints.Checked;
      config.Free;

      cbDifficulty.Clear;
      cbDifficulty.AddItem(rsCasual ,nil);
      cbDifficulty.AddItem(rsNormal ,nil);
      cbDifficulty.AddItem(rsVeteran,nil);
      cbDifficulty.AddItem(rsExpert ,nil);

      pcCharInfo.ActivePage:=tsView;
    end;

    ciPet: begin
      pcCharInfo.ActivePage:=tsView;
    end;

    ciUnit: begin
      FItems:=TfmItems.Create(self);
      FItems.Parent :=tsItems;
      FItems.Align  :=alClient;
      FItems.Visible:=true;

      pcCharInfo.ActivePage:=tsView;
    end;
  end;
end;
{%ENDREGION Form}

{%REGION Wardrobe}
const
  WardNames:array [0..11] of string = (
    'FACE',
    'HAIR',
    'HAIRCOLOR',
    'FEATURE1',
    'FEATURE2',
    'FEATURE3',
    'GLOVES',
    'HEAD',
    'TORSO',
    'PANTS',
    'SHOULDERS',
    'BOOTS'
  );
function WardNameToIdx(const aname:string):integer;
var
  i:integer;
begin
  for i:=0 to High(WardNames) do
    if aname=WardNames[i] then exit(i);
  result:=-1;
end;

function TfmChar.GetWardTitle(idx:integer; aval:integer):string;
var
  i:integer;
begin
  result:='';
  if aval<0 then exit;
  aval:=ClassWardrobe[idx,aval];
  if aval<0 then exit;
  for i:=0 to High(WardrobeData) do
  begin
    if WardrobeData[i].id=aval then
    begin
      result:=WardrobeData[i].name;
      exit;
    end;
  end;
end;

procedure TfmChar.SetWardCombo(acb:TComboBox; aidx:integer; aval:integer);
var
  i:integer;
begin
  acb.Clear;
  acb.Items.Add(rsDefault);
  for i:=0 to WardIdx[aidx]-1 do
    acb.Items.Add(GetWardTitle(aidx,i));
  acb.ItemIndex:=aval+1;
end;

procedure TfmChar.FillWardMatrix(const alist:string);
var
  buf:array [0..15] of AnsiChar;
  pc:PAnsiChar;
  lcnt,i,j,lval,ltype:integer;
begin
  FillChar(ClassWardrobe,SizeOf(ClassWardrobe),#255);

  pc:=Pointer(alist);
  lcnt:=SplitCountA(pointer(alist),',');
  if lcnt>0 then
  begin
    FillChar(WardIdx,SizeOf(WardIdx),0);
    for i:=0 to lcnt-1 do
    begin
      // Get next ID
      j:=0;
      repeat
        while pc^=',' do inc(pc);
        buf[j]:=pc^;
        inc(j);
        inc(pc);
      until (pc^=',') or (pc^=#0);
      buf[j]:=#0;
      Val(buf,lval);
      // Get type by ID
      for j:=0 to High(WardrobeData) do
      begin
        // Add ID to matrix
        if WardrobeData[j].id=lval then
        begin
          ltype:=WardNameToIdx(WardrobeData[j]._type);
          ClassWardrobe[ltype,WardIdx[ltype]]:=lval;
          inc(WardIdx[ltype]);
          break;
        end;
      end;
    end;

    SetWardCombo(cbWardFace     , 0,FChar.Face     );
    SetWardCombo(cbWardHair     , 1,FChar.Hairstyle);
    SetWardCombo(cbWardColor    , 2,FChar.HairColor);
    SetWardCombo(cbWardFeature1 , 3,FChar.Feature1 );
    SetWardCombo(cbWardFeature2 , 4,FChar.Feature2 );
    SetWardCombo(cbWardFeature3 , 5,FChar.Feature3 );
    SetWardCombo(cbWardGloves   , 6,FChar.Gloves   );
    SetWardCombo(cbWardHead     , 7,FChar.Head     );
    SetWardCombo(cbWardTorso    , 8,FChar.Torso    );
    SetWardCombo(cbWardPants    , 9,FChar.Pants    );
    SetWardCombo(cbWardShoulders,10,FChar.Shoulders);
    SetWardCombo(cbWardBoots    ,11,FChar.Boots    );
  end;

end;

procedure TfmChar.cbWardFaceChange(Sender: TObject);
begin
  bbUpdate.Enabled:=true;
end;

{%ENDREGION Wardrobe}

//----- Fill Info -----

procedure TfmChar.UpdateModList;
var
  i:integer;
begin
  lbModList.Clear;
  if FChar.ModIds<>nil then
    for i:=0 to High(FChar.ModIds) do
      lbModList.AddItem(RGDBGetMod(FChar.ModIds[i]),nil);
  if FChar.ModNames<>nil then
    for i:=0 to High(FChar.ModNames) do
      lbModList.AddItem(FChar.ModNames[i],nil);
end;

// set visibility depending of settings and fill common data
procedure TfmChar.FillInfo(aChar:TTLCharacter; aSGame:TTLSaveFile=nil);
var
  ls:string;
  i:integer;
  lshowall,lChar,lPet:boolean;
begin
  if FConfigured and (FKind=ciPlayer) then
  begin
    UpdateModList();
    exit;
  end;

  FSGame:=aSGame;
  FChar :=aChar;

  lshowall:=fmSettings.cbShowAll.Checked;
  lChar:=FKind=ciPlayer;
  lPet :=FKind=ciPet;

  case FChar.CharType of
    ctPlayer: FillPlayerInfo();
    ctPet   : FillPetInfo();
  else
    edClass.Text:=RGDBGetMob(FChar.ID);
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

  imgMorph    .Visible:=lChar or (lPet and lshowall);
  edMorphTime .Visible:=lPet and lshowall;
  lblMorphTime.Visible:=lPet and lshowall;
  lblMorphNote.Visible:=lPet and lshowall;
  lblMorph    .Visible:=lPet and lshowall;
  cbMorph     .Visible:=lPet and lshowall;

  gbGender    .Visible:=lChar and lshowall;

  seScale     .Visible:=lshowall;
  lblScale    .Visible:=lshowall;

  //---
  seScale  .Value  :=FChar.Scale;
  edName   .Text   :=FChar.Name;
  edClassId.Text   :=TextId(FChar.ID);
  lblSuffix.Caption:=FChar.Suffix;

  //--- Wardrobe ---

  // skip pet/NPC wardrobe right now
  tsWardrobe.TabVisible:=lChar and lshowall;

  //--- Action ---

  //--- Other ---

  tsOtherInfo.TabVisible:=lshowall;

  if tsOtherInfo.TabVisible then
    FEffects.FillInfo(FChar);

  //--- Statistic ---

  //Show tab only for mod list (well, maybe coords too)

  edX.Text:=FloatToStrF(FChar.Coord.X,ffFixed,-8,2);
  edY.Text:=FloatToStrF(FChar.Coord.Y,ffFixed,-8,2);
  edZ.Text:=FloatToStrF(FChar.Coord.Z,ffFixed,-8,2);

  UpdateModList();

  sgStats.BeginUpdate;
  sgStats.Clear;
  sgStats.RowCount:=1+Length(FChar.Stats);
  for i:=0 to High(FChar.Stats) do
  begin
    sgStats.Objects[0,i+1]:=TObject(IntPtr(i));
    sgStats.Cells  [0,i+1]:=RGDBGetTL2Stat(FChar.Stats[i].id,ls);
    sgStats.Cells  [1,i+1]:=IntToStr      (FChar.Stats[i].value);
    sgStats.Cells  [2,i+1]:=RGDBGetMod(ls);
  end;
  sgStats.EndUpdate;

  //--- Items ---

  if tsItems.TabVisible then
    if FItems<>nil then
    begin
      FItems.FillInfo(FChar.Items, FChar);
    end;

  bbUpdate.Enabled:=false;
  FConfigured:=true;
//  seLevel.SetFocus;
end;

{%REGION Update}
procedure TfmChar.ToSetUpdate(Sender: TObject);
begin
  bbUpdate.Enabled:=true;
end;

procedure TfmChar.bbUpdateClick(Sender: TObject);
//var
//  ls:string;
begin
{
  ls:=Application.MainForm.Caption;
  ls[1]:='*';
  Application.MainForm.Caption:=ls;
}
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

  //--- Wardrobe

  //--- Action

  SetCharSpell(cbSpell1,0);
  SetCharSpell(cbSpell2,1);
  SetCharSpell(cbSpell3,2);
  SetCharSpell(cbSpell4,3);

  //--- Other

  //--- Statistic

  //--- Personal

  if FChar.CharType=ctPlayer then UpdatePlayerInfo();
  if FChar.CharType=ctPet    then UpdatePetInfo();

  bbUpdate.Enabled:=false;
  if FSGame<>nil then FSGame.Modified:=true;
  FChar.Changed:=true;
end;
{%ENDREGION Update}

end.
