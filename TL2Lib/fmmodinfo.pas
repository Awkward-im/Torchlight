{TODO: Set modified if any edit field changed}
{TODO: restore edit fields if "Cancel" pressed. was saved by ok so just fill again}
{
fsModal in FormState
Application.ModalLevel

Action:=caFree
}
unit fmModInfo;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Buttons, ComCtrls, Grids, EditBtn, SpinEx, rgglobal, rgmod;

type

  { TMODInfoForm }

  TMODInfoForm = class(TForm)
    bbOK      : TBitBtn;
    bbCancel  : TBitBtn;
    ebTags: TEditButton;
    ebChanges: TEditButton;
    ebLongDescr: TEditButton;
    edPreview: TFileNameEdit;
    lblSteamNote: TLabel;
    lblSteamPreview: TLabel;
    lblSteamTags: TLabel;
    lblSteamChanges: TLabel;
    lblLongDescr: TLabel;
    lblNote   : TLabel;
    leTitle   : TLabeledEdit;
    leAuthor  : TLabeledEdit;
    leFilename: TLabeledEdit;
    leWebsite : TLabeledEdit;
    leDownload: TLabeledEdit;  lblDescr  : TLabel;
    memDescr  : TMemo;
    seVersion : TSpinEditEx;   lblVersion: TLabel;
    bbNewGUID : TBitBtn;
    edGUID    : TEdit;         lblGUID   : TLabel;
    PageControl  : TPageControl;
    sbSave: TSpeedButton;
    sbOpen: TSpeedButton;
    tsAdditional: TTabSheet;
    tsDescr      : TTabSheet;
    tsDelete     : TTabSheet;
    lbDelete     : TListBox;
    tsRequirement: TTabSheet;
    sgReq        : TStringGrid;

    procedure bbCancelClick (Sender: TObject);
    procedure bbNewGUIDClick(Sender: TObject);
    procedure bbOKClick     (Sender: TObject);
    procedure lbDeleteKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure sgReqKeyDown   (Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure sbSaveClick    (Sender: TObject);
    procedure sbOpenClick    (Sender: TObject);

    procedure UseEditor     (Sender: TObject);
    procedure OpenTagsEditor(Sender: TObject);
  private
    ffile:string;
    fmi:PTL2ModInfo;
    procedure EditorCancelClick(Sender: TObject);
    procedure EditorOKClick    (Sender: TObject);
    procedure TagsOKClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent; ami: PTL2ModInfo=nil; aRO: boolean=false); overload;

    function  LoadFromFile(const aFile:string):boolean;
    procedure SaveToFile  (const aFile:string);
    procedure LoadFromInfo(const ami: TTL2ModInfo);
    procedure SaveToInfo  (var   ami: TTL2ModInfo);
  end;

var
  MODInfoForm: TMODInfoForm;

implementation

{$R *.lfm}

uses
  LCLType;

procedure TMODInfoForm.bbNewGUIDClick(Sender: TObject);
var
  lguid:TGUID;
begin
  CreateGUID(lguid);
  edGUID.Text:=IntToStr(Int64(MurmurHash64B(lguid,16,0)));
end;

procedure TMODInfoForm.bbCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TMODInfoForm.bbOKClick(Sender: TObject);
begin
  if not seVersion.ReadOnly then
  begin
    if fmi<>nil then
    begin
      SaveToInfo(fmi^);
      fmi^.modified:=true;
    end;
  end;

  if not (fsModal in FormState) then Close;
end;

procedure TMODInfoForm.sbSaveClick(Sender: TObject);
var
  dlg:TSaveDialog;
begin
  dlg:=TSaveDialog.Create(nil);
  dlg.FileName  :=TL2ModData;
  dlg.DefaultExt:='.DAT';
  dlg.Filter    :='*.DAT|*.dat|All files|*.*';
  if dlg.Execute then
    SaveToFile(dlg.FileName);
  dlg.Free;
end;

procedure TMODInfoForm.sbOpenClick(Sender: TObject);
var
  dlg:TOpenDialog;
begin
  dlg:=TSaveDialog.Create(nil);
  dlg.FileName  :=TL2ModData;
  dlg.DefaultExt:='.DAT';
  dlg.Filter    :='*.DAT|*.dat|All files|*.*';
  if dlg.Execute then
  begin
    LoadFromFile(dlg.FileName);
  end;
  dlg.Free;
end;

procedure TMODInfoForm.lbDeleteKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  ls:string;
  i:integer;
begin
  if Key=VK_DELETE then
  begin
    i:=0;
    while (i<lbDelete.Count) and not lbDelete.Selected[i] do inc(i);
    if i>0 then dec(i)
    else
    begin
      while (i<lbDelete.Count) and lbDelete.Selected[i] do inc(i);
      if i=lbDelete.Count then i:=-1;
    end;
    lbDelete.DeleteSelected();
    if i>=lbDelete.Count then i:=0;
    if i>=0 then
      lbDelete.Selected[i]:=true;
  end
  else if Key=VK_INSERT then
  begin
    InputQuery('Add file to delete','Enter filename with path',ls);
    lbDelete.AddItem(ls,nil);
  end;
end;

procedure TMODInfoForm.sgReqKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key=VK_DELETE then
  begin
    if sgReq.Row>0 then sgReq.DeleteRow(sgReq.Row);
  end
  else if Key=VK_INSERT then
  begin
    sgReq.RowCount:=sgReq.RowCount+1;
  end;
end;

constructor TMODInfoForm.Create(AOwner: TComponent; ami: PTL2ModInfo=nil; aRO: boolean=false);
begin
  inherited Create(AOwner);

  ffile:='';
  seVersion  .ReadOnly:=aRO;
  leTitle    .ReadOnly:=aRO;
  leAuthor   .ReadOnly:=aRO;
  leWebsite  .ReadOnly:=aRO;
  leDownload .ReadOnly:=aRO;
  leFilename .ReadOnly:=aRO;
  memDescr   .ReadOnly:=aRO;
  edGUID     .ReadOnly:=aRO;
  bbNewGUID  .Enabled :=not aRO;
  edPreview  .ReadOnly:=aRO;
  ebTags     .ReadOnly:=aRO;
  ebChanges  .ReadOnly:=aRO;
  ebLongDescr.ReadOnly:=aRO;

  if ami<>nil then
  begin
    fmi:=ami;
    LoadFromInfo(ami^);
  end;
  PageControl.ActivePage:=tsDescr;
end;

procedure TMODInfoForm.SaveToInfo(var ami:TTL2ModInfo);
var
  i,lcnt:integer;
begin
  ClearModInfo(ami);
//  MakeModInfo (ami);

  ami.title   :=StrToWide(leTitle   .Text);
  ami.author  :=StrToWide(leAuthor  .Text);
  ami.descr   :=StrToWide(memDescr  .Text);
  ami.website :=StrToWide(leWebsite .Text);
  ami.download:=StrToWide(leDownload.Text);
  if (edGUID.Text<>'') and (edGUID.Text<>'0') and (edGUID.Text<>'-1') then
    Val(edGUID.Text,ami.modid);
  if seVersion.Value>0 then
    ami.modver:=seVersion.Value;
  ami.filename:=FastStrToWide(leFilename.Text);

  if lbDelete.Items.Count>0 then
  begin
    SetLength(ami.dels,lbDelete.Items.Count);
    lcnt:=0;
    for i:=0 to lbDelete.Items.Count-1 do
    begin
      if lbDelete.Items[i]<>'' then
      begin
        ami.dels[lcnt]:=FastStrToWide(lbDelete.Items[i]);
        inc(lcnt);
      end;
    end;
    if lcnt<lbDelete.Items.Count then
      SetLength(ami.dels,lcnt);
  end;

  if sgReq.RowCount>1 then
  begin
    SetLength(ami.reqs,sgReq.RowCount-1);
    for i:=0 to sgReq.RowCount-2 do
    begin
      ami.reqs[i].name:=StrToWide(sgReq.Cells[0,i+1]);
      ami.reqs[i].id  :=StrToInt (sgReq.Cells[1,i+1]);
      if sgReq.Cells[2,i+1]<>'' then
        ami.reqs[i].ver:=StrToInt(sgReq.Cells[2,i+1])
      else
        ami.reqs[i].ver:=0;
    end;
  end;

  ami.steam_preview:=StrToWide(edPreview  .Text);
  ami.steam_tags   :=StrToWide(ebTags     .Text);
  ami.steam_descr  :=StrToWide(ebChanges  .Text);
  ami.long_descr   :=StrToWide(ebLongDescr.Text);
end;

procedure TMODInfoForm.SaveToFile(const aFile:string);
var
  lmod:TTL2ModInfo;
begin
  FillChar(lmod,SizeOf(lmod),0);
  SaveToInfo(lmod);
  SaveModConfig(lmod, PChar(aFile));

  ClearModInfo(lmod);
end;

procedure TMODInfoForm.LoadFromInfo(const ami:TTL2ModInfo);
var
  i:integer;
begin
  leTitle   .Text:=WideToStr(ami.title   );
  leAuthor  .Text:=WideToStr(ami.author  );
  memDescr  .Text:=WideToStr(ami.descr   );
  leWebsite .Text:=WideToStr(ami.website );
  leDownload.Text:=WideToStr(ami.download);
  edGUID    .Text:=IntToStr (ami.modid   );
  seVersion.Value:=ami.modver;
  leFilename.Text:=FastWideToStr(ami.filename);

  lbDelete.Clear;
  for i:=0 to High(ami.dels) do
  begin
    lbDelete.AddItem(FastWideToStr(ami.dels[i]),nil);
  end;

  sgReq.RowCount:=Length(ami.reqs)+1;
  for i:=0 to High(ami.reqs) do
  begin
    sgReq.Cells[0,i+1]:=WideToStr(ami.reqs[i].name);
    sgReq.Cells[1,i+1]:=IntToStr (ami.reqs[i].id);
    sgReq.Cells[2,i+1]:=IntToStr (ami.reqs[i].ver);
  end;

  edPreview  .Text:=WideToStr(ami.steam_preview);
  ebTags     .Text:=WideToStr(ami.steam_tags);
  ebChanges  .Text:=WideToStr(ami.steam_descr);
  ebLongDescr.Text:=WideToStr(ami.long_descr);
end;

function TMODInfoForm.LoadFromFile(const aFile:string):boolean;
var
  lmod:TTL2ModInfo;
begin
  MakeModInfo(lmod);

  if LoadModConfig(PChar(aFile),lmod) then
  begin
    LoadFromInfo(lmod);
    ffile:=aFile;
  end
  else if ReadModInfo(PChar(aFile),lmod) then
  begin
    LoadFromInfo(lmod);
    ffile:=aFile;
  end
  else
    ffile:='';

  ClearModInfo(lmod);

  result:=ffile<>'';
end;

{%REGION Editor}
procedure TMODInfoForm.EditorCancelClick(Sender:TObject);
begin
  (Sender as TBitBtn).Owner.Free;
end;

procedure TMODInfoForm.EditorOKClick(Sender:TObject);
var
  lpanel:TPanel;
begin
  lpanel:=((Sender as TBitBtn).Owner as TPanel);
  (lpanel.Owner as TEditButton).Text:=
     StringReplace((lpanel.Controls[2] as TMemo).Text,#13#10,'\n',[rfReplaceAll]);
  lpanel.Free;
end;

procedure TMODInfoForm.UseEditor(Sender:TObject);
var
  lForm:TPanel;
  ly:integer;
begin
  lForm:=TPanel.Create(Sender as TEditButton);
  lForm.Parent:=(Sender as TEditButton).Parent;
  lForm.Align :=alClient;

  with TBitBtn.Create(lForm) do
  begin
    Parent :=lForm;
    Kind   :=bkOk;
    Default:=True;
    Top    :=lForm.ClientHeight-4-Height;
    Left   :=lForm.ClientWidth -2-Width;
    Anchors:=[akRight,akBottom];
    OnClick:=@EditorOKClick;
    ly:=Top;
  end;

  with TBitBtn.Create(lForm) do
  begin
    Parent :=lForm;
    Kind   :=bkCancel;
    Top    :=ly;
    Left   :=2;
    Anchors:=[akLeft,akBottom];
    OnClick:=@EditorCancelClick;
  end;

  with TMemo.Create(lForm) do
  begin
    Parent    :=lForm;
    ScrollBars:=ssAutoBoth;
    SetBounds(1,1,lForm.ClientWidth-2,ly-8);
    Anchors   :=[akTop,akLeft,akRight,akBottom];
    Text      :=StringReplace((Sender as TEditButton).Text,'\n',#13#10,[rfReplaceAll]);
    Visible   :=true;
  end;

  lForm.Show;
end;
{%ENDREGION Editor}

{%REGION Tags}
procedure TMODInfoForm.TagsOKClick(Sender:TObject);
var
  lpanel:TPanel;
  cg:TCheckGroup;
  ls:string;
  i:integer;
begin
  ls:='';
  lpanel:=((Sender as TBitBtn).Owner as TPanel);
  cg:=lpanel.Controls[0] as TCheckGroup;
  for i:=0 to cg.Items.Count-1 do
  begin
    if cg.Checked[i] then
    begin
      if ls<>'' then ls:=ls+', ';
      ls:=ls+cg.Items[i];
    end;
  end;
  (lpanel.Owner as TEditButton).Text:=ls;
  lpanel.Free;
end;

procedure TMODInfoForm.OpenTagsEditor(Sender:TObject);
var
  lForm:TPanel;
  cg:TCheckGroup;
  ltags:string;
  aval:PAnsiChar;
  lval:array [0..31] of AnsiChar;
  i,j,lcnt,lidx:integer;
begin
  lForm:=TPanel.Create(Sender as TEditButton);
  lForm.Parent:=(Sender as TEditButton).Parent;
  lForm.Align :=alClient;

  cg:=TCheckGroup.Create(lForm);
  cg.Parent:=lForm;
  cg.Visible:=False;
  cg.Align :=alClient;
  cg.Caption:='Steam tags';
  cg.ColumnLayout:=clVerticalThenHorizontal;
  cg.Items.AddStrings([
      'Armor',
      'Art',
      'Audio',
      'Balance',
      'Bosses',
      'Characters',
      'Classes',
      'Co-op',
      'Game Modes',
      'Gameplay',
      'Items',
      'Levels',
      'Maps',
      'Merchants',
      'Models',
      'Monsters',
      'Multiplayer',
      'Music',
      'Pets',
      'Pvp',
      'Quests',
      'Recipes',
      'Skills',
      'Socketables',
      'Story',
      'Textures',
      'UI',
      'Weapons']);
  cg.ChildSizing.LeftRightSpacing:=2;
  cg.ChildSizing.TopBottomSpacing:=4;
  cg.Columns:=3;

  with TBitBtn.Create(lForm) do
  begin
    Parent :=lForm;
    Kind   :=bkOk;
    Caption:='';
    Layout :=blGlyphBottom;
    Spacing:=0;
    Default:=True;
    Width  :=24;
    Height :=24;
    Top    :=lForm.ClientHeight-4-Height;
    Left   :=lForm.ClientWidth -6-Width;
    Anchors:=[akRight,akBottom];
    OnClick:=@TagsOKClick;
    j:=Top;
  end;

  with TBitBtn.Create(lForm) do
  begin
    Parent :=lForm;
    Kind   :=bkCancel;
    Caption:='';
    Layout :=blGlyphBottom;
    Spacing:=0;
    Width  :=24;
    Height :=24;
    Top    :=j;
    Left   :=lForm.ClientWidth-6-(4+Width)*2;
    Anchors:=[akRight,akBottom];
    OnClick:=@EditorCancelClick;
  end;

  ltags:=(Sender as TEditButton).Text;
  if ltags<>'' then
  begin
    aval:=Pointer(ltags);
    lcnt:=SplitCountA(aval,',');
    if lcnt>0 then
    begin
      for i:=0 to lcnt-1 do
      begin
        lidx:=0;
        repeat
          while (aval^=',') or (aval^=' ') do inc(aval);
          lval[lidx]:=aval^;
          inc(lidx);
          inc(aval);
        until (aval^=',') or (aval^=' ') or (aval^=#0);
        lval[lidx]:=#0;

        for j:=0 to cg.Items.Count-1 do
        begin
          if lval=cg.Items[j] then
          begin
            cg.Checked[j]:=true;
            break;
          end;
        end;

      end;
    end;
  end;

  cg.Visible:=True;
  lForm.Show;
end;

{%ENDREGION Tags}

end.
