unit formSkills;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, StdCtrls,
  Buttons, SpinEx, Types,
  tl2char, tl2types, tl2db;

type

  { TfmSkills }

  TfmSkills = class(TForm)
    bbUpdate: TBitBtn;
    btnReset: TButton;

    cbCheckLevel : TCheckBox;
    cbCheckPoints: TCheckBox;
    cbSaveFull   : TCheckBox;

    lblFreePoints: TLabel;

    lblName : TLabel;
    memDesc: TMemo;

    sgSkills: TStringGrid;
    seFreePoints: TSpinEditEx;

    procedure bbUpdateClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
    procedure cbSaveFullClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure seFreePointsChange(Sender: TObject);
    procedure sgSkillsDrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure sgSkillsEditButtonClick(Sender: TObject);
    procedure sgSkillsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure sgSkillsSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
  private
    FConfigured:boolean;

    FChar  :TTL2Character;  // reference to player (char level, free points, skills)
    FClass :TL2ID;          // class id (to change skill list)
    FSkills:tSkillArray;    // class skills data
    FIcons :array of array [boolean] of TPicture; // skill icons learned/not

    FTiers :tTierArray;     // tier array (!!must be global for mod build)

    FPoints    :integer;    // free points for current skill build
    FLevel     :integer;
    FFame      :integer;
    FSkLevel   :integer;
    FSkFame    :integer;
    FNewClass  :TL2ID;

    function ApplyBuild(const alist: TL2IdValList): integer;
    procedure ClearData;
    procedure CreateIconList();
    function  CheckTier(aval,aidx:integer):boolean;
    procedure DoLevelChange(doinc: boolean);
    function GetBuild(): TL2IdValList;
    procedure SetPlayerClass(const aclass: TL2ID);
    procedure SetFame (aval:integer);
    procedure SetLevel(aval:integer);
    procedure SetChar (achar:TTL2Character);

  public
    procedure RefreshInfo();

    property Configured:boolean read FConfigured write FConfigured;
    property FreeSkillPoints:integer read FPoints;
    property PlayerClass:TL2ID read FClass write FNewClass;
    property Fame :integer write SetFame;
    property Level:integer write SetLevel;
    property Player:TTL2Character read FChar write SetChar;
  end;


implementation

{$R *.lfm}

uses
  INIFiles,
  LCLType,
  formsettings;

const
  sSkills      = 'Skills';
  sCheckLevel  = 'checklevel';
  sCheckPoints = 'checkpoints';
  sSaveFull    = 'savefulllist';

const
  colIcon    = 0;
  colName    = 1;
  colPassive = 2;
  colMinus   = 3;
  colLevel   = 4;
  colPlus    = 5;


function TfmSkills.CheckTier(aval,aidx:integer):boolean;
var
  i,llevel:integer;
begin
  result:=true;
  llevel:=FChar.Level;
  for i:=0 to High(FTiers) do
  begin
    if FSkills[aidx].tier=FTiers[i].name then
    begin
      if (aval<Length(FTiers[i].levels)) and
         (FTiers[i].levels[aval]>llevel) then
        result:=false;
      break;
    end;
  end;
end;

procedure TfmSkills.FormCreate(Sender: TObject);
var
  config:TIniFile;
begin
  config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);
  cbCheckLevel .Checked:=config.ReadBool(sSkills,sCheckLevel ,true);
  cbCheckPoints.Checked:=config.ReadBool(sSkills,sCheckPoints,true);
  cbSaveFull   .Checked:=config.ReadBool(sSkills,sSaveFull   ,true);

  config.Free;

  LoadTiers(FTiers); //!! by mod so maybe make global
end;

procedure TfmSkills.FormDestroy(Sender: TObject);
var
  config:TIniFile;
  i:integer;
begin
  ClearData;

  for i:=0 to High(FTiers) do
    SetLength(FTiers[i].levels,0);
  SetLength(FTiers,0);

  config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);
  config.WriteBool(sSkills,sCheckLevel ,cbCheckLevel .Checked);
  config.WriteBool(sSkills,sCheckPoints,cbCheckPoints.Checked);
  config.WriteBool(sSkills,sSaveFull   ,cbSaveFull   .Checked);

  config.UpdateFile;
  config.Free;
end;

procedure TfmSkills.seFreePointsChange(Sender: TObject);
begin
  if FPoints<>seFreePoints.Value then
  begin
    FPoints:=seFreePoints.Value;
    bbUpdate.Enabled:=true;
  end;
end;

procedure TfmSkills.ClearData;
var
  i:integer;
begin
  SetLength(FSkills,0);

  for i:=0 to High(FIcons) do
  begin
    FIcons[i,false].Free;
    FIcons[i,true ].Free;
  end;
  SetLength(FIcons,0);
end;

procedure TfmSkills.CreateIconList();
var
  i:integer;
begin
  SetLength(FIcons,Length(FSkills));
  for i:=0 to High(FIcons) do
  begin
    FIcons[i,false]:=TPicture.Create;
    FIcons[i,true ]:=TPicture.Create;
    try
      FIcons[i,false].LoadFromFile(fmSettings.edIconDir.Text+'\skills\'+FSkills[i].icon+'.png');
      FIcons[i,true ].LoadFromFile(fmSettings.edIconDir.Text+'\skills\'+FSkills[i].icon+'_gray.png');
    except
    end;
  end;
end;

procedure TfmSkills.sgSkillsDrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
var
  lRect:TRect;
  bmp:TBitmap;
  idx:integer;
  isgray:boolean;
begin
  if (aCol=colIcon) and (aRow>0) then
  begin
    idx:=IntPtr(sgSkills.Objects[0,aRow]);
    isgray:=sgSkills.Cells[colLevel,aRow]='0';
    if FIcons<>nil then
    begin
      bmp:=FIcons[idx,isgray].Bitmap;
      if (bmp=nil) and isgray then bmp:=FIcons[idx,false].Bitmap;
      if bmp<>nil then
      begin
        lRect:=aRect;
        InflateRect(lRect,-1,-1);
        sgSKills.Canvas.StretchDraw(lRect,bmp);
      end;
    end;
  end;
end;

procedure TfmSkills.sgSkillsSelectCell(Sender: TObject;
          aCol, aRow: Integer; var CanSelect: Boolean);
var
  licon,ltier:string;
  idx:integer;
begin
  if (FSkills<>nil) and (aRow>0) then
  begin
    idx:=IntPtr(sgSkills.Objects[0,aRow]);

    lblName.Caption:=FSkills[idx].title;
    memDesc.Text   :=GetSkillInfo(FSkills[idx].id,ltier,licon);
  end;
end;

procedure TfmSkills.sgSkillsEditButtonClick(Sender: TObject);
begin
  if      sgSkills.Col=colMinus then DoLevelChange(false)
  else if sgSkills.Col=colPlus  then DoLevelChange(true)
end;

procedure TfmSkills.sgSkillsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if ((Key=VK_RETURN) or (Key=VK_SPACE)) and
     (sgSkills.Col in [colMinus, colPlus]) then
    sgSkillsEditButtonClick(Sender);

  if sgSkills.Col=colLevel then
  begin
    case Key of
      VK_OEM_MINUS, VK_SUBTRACT: DoLevelChange(false);
      VK_OEM_PLUS , VK_ADD     : DoLevelChange(false);
    end;
  end;
end;

procedure TfmSkills.DoLevelChange(doinc:boolean);
var
  lval,idx:integer;
  lchanged:boolean;
begin
  lchanged:=false;
  lval:=StrToInt(sgSkills.Cells[colLevel,sgSkills.Row]);

  if not doinc then
  begin
    if lval>0 then
    begin
      dec(lval);
      inc(FPoints);
      lchanged:=true;
    end;
  end

  else
  begin
    if ((FPoints>0) or not (cbCheckPoints.Checked)) then
    begin
      idx:=IntPtr(sgSkills.Objects[0,sgSkills.Row]);
      if (FSkills=nil) or // !!
         ((lval<FSkills[idx].level) and
         ((not cbCheckLevel.Checked) or CheckTier(lval,idx))) then
      begin
        inc(lval);
        dec(FPoints);
        lchanged:=true;
      end;
    end;
  end;

  if lchanged then
  begin
    sgSkills.Cells[colLevel,sgSkills.Row]:=IntToStr(lval);
    seFreePoints.Value:=FPoints;
    bbUpdate.Enabled:=true;
  end;
end;

procedure TfmSkills.cbSaveFullClick(Sender: TObject);
begin
  bbUpdate.Enabled:=true;
end;

procedure TfmSkills.btnResetClick(Sender: TObject);
var
  i,j:integer;
begin
  if FSkills<>nil then //!!
  begin
    for i:=1 to sgSkills.RowCount-1 do
    begin
      j:=IntPtr(sgSkills.Objects[0,i]);
      j:=FSkills[j].learn;

      inc(FPoints,StrToInt(sgSkills.Cells[colLevel,i])-j);
      sgSkills.Cells[colLevel,i]:=IntToStr(j);
    end;
{
  end
  else
  begin
    for i:=1 to sgSkills.RowCount-1 do
    begin
      inc(FPoints,StrToInt(sgSkills.Cells[colLevel,i]));
      sgSkills.Cells[colLevel,i]:='0';
    end;
}
  end;
  sgSkills.Refresh;
  seFreePoints.Value:=FPoints;
  bbUpdate.Enabled:=true;
end;

procedure TfmSkills.SetPlayerClass(const aclass:TL2ID);
var
  lbuild:TL2IdValList;
  i,j:integer;
begin
  if FClass=aclass then
    exit;

  if FConfigured then
    lbuild:=GetBuild();

  btnResetClick(Self);

  FClass:=aclass;
  GetClassGraphSkill(FClass,FSkLevel,FSkFame);

  sgSkills.BeginUpdate;
  sgSkills.Clear;

  ClearData;
  CreateSkillList(aclass,FSkills);
  CreateIconList();

  sgSkills.Columns[colIcon   ].Visible:=FSkills<>nil;
  sgSkills.Columns[colPassive].Visible:=FSkills<>nil;
  if FSkills<>nil then
  begin
    sgSkills.RowCount:=1+Length(FSkills);
    j:=1;
    for i:=0 to High(FSkills) do
    begin
      // skip unlearnabled
      if (FSkills[i].tier<>'') and
         (FSkills[i].tier[1]<>',') then
      begin
        sgSkills.Objects[0,j]:=TObject(IntPtr(i));

        sgSkills.Cells[colName   ,j]:=FSkills[i].title;
        sgSkills.Cells[colPassive,j]:=FSkills[i].passive;
        sgSkills.Cells[colMinus  ,j]:='-';
        sgSkills.Cells[colLevel  ,j]:=IntToStr(FSkills[i].learn);
        sgSkills.Cells[colPlus   ,j]:='+';
        inc(j);
      end;
    end;
    sgSkills.RowCount:=j;
  end
  else
  begin
    sgSkills.RowCount:=1+Length(FChar.Skills);
  end;
  for i:=1 to sgSkills.RowCount-1 do
  begin
    sgSkills.Cells[colMinus,i]:='-';
    sgSkills.Cells[colPlus ,i]:='+';
  end;

  if FConfigured then
    ApplyBuild(lbuild);

  sgSkills.EndUpdate;

  bbUpdate.Enabled:=true;
end;

procedure TfmSkills.SetChar(achar:TTL2Character);
begin
  FChar:=achar;
  SetPlayerClass(FChar.ClassId);
end;

function TfmSkills.ApplyBuild(const alist:TL2IdValList):integer;
var
  ls:string;
  i,j,idx:integer;
begin
  result:=0;
//  if FSkills=nil then exit;

  sgSkills.BeginUpdate;

  for i:=1 to sgSkills.RowCount-1 do
  begin
    if FSkills<>nil then
    begin
      idx:=IntPtr(sgSkills.Objects[0,i]);

      for j:=0 to High(alist) do
      begin
        if alist[j].id=FSkills[idx].id then
        begin
          // calculate used skillpoints (counting initially learned too)
          dec(FPoints,alist[j].value-FSkills[idx].learn);
          inc(result ,alist[j].value-FSkills[idx].learn);
          Str(alist[j].value,ls);
          sgSkills.Cells[colLevel,i]:=ls;
          break;
        end;
      end;
    end
    else
    begin
      sgSkills.Cells[colName ,i]:=IntToStr(FChar.Skills[i-1].id); // !! 10 or 16
      sgSkills.Cells[colLevel,i]:=IntToStr(FChar.Skills[i-1].value);
    end;
  end;
  sgSkills.EndUpdate;
end;

function TfmSkills.GetBuild():TL2IdValList;
var
  lcnt,i:integer;
begin
  SetLength(result,sgSkills.RowCount-1);
  lcnt:=0;
  for i:=1 to sgSkills.RowCount-1 do
  begin
    result[lcnt].value:=StrToInt(sgSkills.Cells[colLevel,i]);
    if cbSaveFull.Checked or (result[lcnt].value>0) then
    begin
      if FSkills<>nil then // !!
        result[lcnt].id:=FSkills[IntPtr(sgSkills.Objects[0,i])].id
      else
      begin
        // check 10 or 16 base system?
        result[lcnt].id:=StrToInt64(sgSkills.Cells[colName,i]);
      end;
      inc(lcnt);
    end;
  end;
  SetLength(result,lcnt);
end;


procedure TfmSkills.SetFame(aval:integer);
begin
  inc(FPoints,(aval-FFame)*FSkFame);
  FFame:=aval;

  bbUpdate.Enabled:=true;
end;

procedure TfmSkills.SetLevel(aval:integer);
begin
  inc(FPoints,(aval-FLevel)*FSkLevel);
  FLevel:=aval;

  bbUpdate.Enabled:=true;
end;


procedure TfmSkills.RefreshInfo();
begin

  //--- new class (or not)

  SetPlayerClass(FNewClass);

  //--- new build

  if not FConfigured then
  begin
    FConfigured:=true;

    ApplyBuild(FChar.Skills);
    FPoints:=FChar.FreeSkillPoints;
    FFame  :=FChar.FameLevel;
    FLevel :=FChar.Level;

    bbUpdate.Enabled:=false;
  end;

  seFreePoints.Value:=FPoints;
end;

procedure TfmSkills.bbUpdateClick(Sender: TObject);
begin
  FChar.Skills:=GetBuild();

  if FPoints>0 then
    FChar.FreeSkillPoints:=FPoints
  else
    FChar.FreeSkillPoints:=0;

  //!! what about statistic? need to check!
  //!! what about STAT (history?) need to clear!
  FChar.Changed:=true;

  bbUpdate.Enabled:=false;
end;

end.
