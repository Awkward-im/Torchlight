unit fmComboMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons, EditBtn,
  rgglobal;

type

  { TFormMain }

  TFormMain = class(TForm)
    bbAddDir: TBitBtn;
    bbDelete: TSpeedButton;
    bbModInfo: TBitBtn;
    memLog: TMemo;
    lbModList    : TListBox;
    sbUp    : TSpeedButton;
    sbDown  : TSpeedButton;
    bbAddFile   : TBitBtn;
    bbApply : TBitBtn;
    deOutputDir : TDirectoryEdit;
    lblDirHint: TLabel;
    memDescription: TMemo;
    lblDescr      : TLabel;
    ImageList: TImageList;
    lblModList: TLabel;

    procedure bbAddDirClick(Sender: TObject);
    procedure bbApplyClick(Sender: TObject);
    procedure bbDeleteClick(Sender: TObject);
    procedure bbAddFileClick(Sender: TObject);
    procedure bbModInfoClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lbModListClick(Sender: TObject);
    procedure sbDownClick(Sender: TObject);
    procedure sbUpClick(Sender: TObject);
  private
    slModList:TStringList;
    newModInfo:TTL2ModInfo;

    procedure ShowDescr(const fname: string);

  public

  end;

var
  FormMain: TFormMain;

implementation

{$R *.lfm}

uses
  fmModInfo,
  TL2Mod;

procedure TFormMain.bbApplyClick(Sender: TObject);
begin
end;

procedure TFormMain.bbDeleteClick(Sender: TObject);
var
  i:integer;
begin
  { TODO : Delete data or not from string list }
  i:=lbModList.ItemIndex;
  lbModList.DeleteSelected;
  if i>=lbModList.Count then i:=lbModList.Count-1;
  if i>=0 then lbModList.ItemIndex:=i;

  bbDelete.Enabled:=lbModList.Count>0;
  bbApply .Enabled:=lbModList.Count>0;
end;

procedure TFormMain.bbAddFileClick(Sender: TObject);
var
  ld:TOpenDialog;
  mi:TTL2ModInfo;
  i,lidx:integer;
begin
  ld:=TOpenDialog.Create(nil);
  try
    ld.DefaultExt:='.MOD';
    ld.Filter    :='MOD files|*.MOD';
    ld.Title     :='Choose MOD files to add';
    ld.Options   :=[ofAllowMultiSelect];
    if (ld.Execute) and (ld.Files.Count>0) then
    begin
      for i:=0 to ld.Files.Count-1 do
      begin
//        if slModList.IndexOf(ld.Files[i])<0 then
        begin
          lidx:=slModList.Add(ld.Files[i]);
          if ReadModInfo(PChar(ld.Files[i]),mi) then
          begin
            lbModList.AddItem(String(WideString(mi.title)),TObject(IntPtr(lidx)));
            ClearModInfo(mi);
          end
          else
            lbModList.AddItem(ExtractFileName(ld.Files[i]),TObject(IntPtr(lidx)));
        end;
      end;
      bbDelete.Enabled:=true;
    end;
  finally
    ld.Free;
  end;
end;

procedure TFormMain.bbModInfoClick(Sender: TObject);
begin
  with TMODInfoForm.Create(Self,false) do
  begin
    LoadFromInfo(newModInfo);
    if ShowModal=mrOk then
      SaveToInfo(newModInfo);
  end;
end;

procedure TFormMain.bbAddDirClick(Sender: TObject);
var
  ld:TSelectDirectoryDialog;
  ls:string;
  mi:TTL2ModInfo;
  i,lidx:integer;
begin
  ld:=TSelectDirectoryDialog.Create(nil);
  try
//    ld.InitialDir:=TL2Settings.edImportDir.Text;
    ld.FileName  :='';
    ld.Options   :=[ofAllowMultiSelect,ofEnableSizing,ofPathMustExist];
    if ld.Execute then
    begin
      for i:=0 to ld.Files.Count-1 do
      begin
        ls:=ld.Files[i];
        if ls[Length(ls)]<>'\' then ls:=ls+'\';
//        if slModList.IndexOf(ls)<0 then
        begin
          lidx:=slModList.Add(ls);
          if LoadModConfiguration(PChar(ls+'MOD.DAT'),mi) then
          begin
            lbModList.AddItem(String(WideString(mi.title)),TObject(IntPtr(lidx)));
            ClearModInfo(mi);
          end
          else
            lbModList.AddItem(ExtractFileName(ld.Files[i]),TObject(IntPtr(lidx)));
        end;
      end;
      bbDelete.Enabled:=true;
    end;
  finally
    ld.Free;
  end;
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  slModList:=TStringList.Create;
  slModList.Capacity:=128;
  FillChar(newModInfo,SizeOf(newModInfo),0);
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  ClearModInfo(newModInfo);
  slModList.Free;
end;

procedure TFormMain.ShowDescr(const fname:string);
var
  mi:TTL2ModInfo;
  l:boolean;
begin
  memDescription.Clear;
  if fname[Length(fname)]='\' then
    l:=LoadModConfiguration(PChar(fname+'MOD.DAT'),mi)
  else
    l:=ReadModInfo(PChar(fname),mi);

  if l then
  begin
    memDescription.Append('Name: '       +String(WideString(mi.title)));
    memDescription.Append('Author: '     +String(WideString(mi.author)));
    memDescription.Append('Description: '+String(WideString(mi.descr)));
    ClearModInfo(mi);
  end;
end;

procedure TFormMain.lbModListClick(Sender: TObject);
begin
  sbUp  .Enabled:=lbModList.ItemIndex>0;
  sbDown.Enabled:=(lbModList.ItemIndex>=0) and
                  (lbModList.ItemIndex<(lbModList.Count-1));

  if lbModList.ItemIndex>=0 then
  begin
    ShowDescr(slModList[IntPtr(lbModList.Items.Objects[lbModList.ItemIndex])]);
  end;
end;

procedure TFormMain.sbDownClick(Sender: TObject);
var
  i,llast:integer;
begin
  llast:=0;
  if not lbModList.Selected[lbModList.Count-1] then
  begin
    { TODO : Keep selection }
    for i:=lbModList.Count-2 downto 0 do
    begin
      if lbModList.Selected[i] then
      begin
        llast:=i+1;
        lbModList.Items.Move(i,llast);
      end;
    end;
    lbModList.ItemIndex:=llast;
    lbModListClick(Sender);
    bbApply.Enabled:=true;
  end;
end;

procedure TFormMain.sbUpClick(Sender: TObject);
var
  i,llast:integer;
begin
  llast:=0;
  if not lbModList.Selected[0] then
  begin
{ TODO : Keep selection }
    for i:=1 to lbModList.Count-1 do
    begin
      if lbModList.Selected[i] then
      begin
        llast:=i-1;
        lbModList.Items.Move(i,llast);
      end;
    end;
    lbModList.ItemIndex:=llast;
    lbModListClick(Sender);

    bbApply.Enabled:=true;
  end;

end;

end.

