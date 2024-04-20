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
  Buttons, ComCtrls, Grids, SpinEx, rgglobal, TL2Mod;

type

  { TMODInfoForm }

  TMODInfoForm = class(TForm)
    bbOK      : TBitBtn;
    bbCancel  : TBitBtn;
    bbSave    : TBitBtn;
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
    tsDescr      : TTabSheet;
    tsDelete     : TTabSheet;
    lbDelete     : TListBox;
    tsRequirement: TTabSheet;
    sgReq        : TStringGrid;

    procedure bbCancelClick (Sender: TObject);
    procedure bbNewGUIDClick(Sender: TObject);
    procedure bbOKClick     (Sender: TObject);
    procedure bbSaveClick   (Sender: TObject);
    procedure lbDeleteKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure sgReqKeyDown   (Sender: TObject; var Key: Word; Shift: TShiftState);

  private
    ffile:string;
    fmi:PTL2ModInfo;
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

procedure TMODInfoForm.bbSaveClick(Sender: TObject);
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

constructor TMODInfoForm.Create(AOwner: TComponent; ami: PTL2ModInfo=nil;
  aRO: boolean=false);
begin
  inherited Create(AOwner);

  ffile:='';
  seVersion .ReadOnly:=aRO;
  leTitle   .ReadOnly:=aRO;
  leAuthor  .ReadOnly:=aRO;
  leWebsite .ReadOnly:=aRO;
  leDownload.ReadOnly:=aRO;
  leFilename.ReadOnly:=aRO;
  memDescr  .ReadOnly:=aRO;
  edGUID    .ReadOnly:=aRO;
  bbNewGUID .Enabled :=not aRO;

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
end;

procedure TMODInfoForm.SaveToFile(const aFile:string);
var
  lmod:TTL2ModInfo;
begin
  FillChar(lmod,SizeOf(lmod),0);
  SaveToInfo(lmod);
  SaveModConfiguration(lmod, PChar(aFile));

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
end;

function TMODInfoForm.LoadFromFile(const aFile:string):boolean;
var
  lmod:TTL2ModInfo;
begin
  MakeModInfo(lmod);

  if LoadModConfiguration(PChar(aFile),lmod) then
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

end.
