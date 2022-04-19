unit fmComboMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  EditBtn, ExtCtrls, rgglobal;

type

  { TFormMain }

  TFormMain = class(TForm)
    bbAddDir: TBitBtn;
    bbDelete: TSpeedButton;
    bbModInfo: TBitBtn;
    bbSave: TBitBtn;
    cbPause: TCheckBox;
    cbPreset: TComboBox;
    lblPreset: TLabel;
    lblDescr: TLabel;
    lbModList    : TListBox;
    memDescription: TMemo;
    memLog: TMemo;
    sbUp    : TSpeedButton;
    sbDown  : TSpeedButton;
    bbAddFile   : TBitBtn;
    bbApply : TBitBtn;
    deOutputDir : TDirectoryEdit;
    lblDirHint: TLabel;
    ImageList: TImageList;
    lblModList: TLabel;

    procedure bbAddDirClick(Sender: TObject);
    procedure bbAddFileClick(Sender: TObject);
    procedure bbApplyClick(Sender: TObject);
    procedure bbDeleteClick(Sender: TObject);
    procedure bbModInfoClick(Sender: TObject);
    procedure bbSaveClick(Sender: TObject);
    procedure cbPresetChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lbModListClick(Sender: TObject);
    procedure sbDownClick(Sender: TObject);
    procedure sbUpClick(Sender: TObject);
  private
    slModList:TStringList;
    newModInfo:TTL2ModInfo;
    LastFileDir:string;

    function AddToLog(var adata: string): integer;
    procedure CheckTheButtons;
    procedure LoadPackSettings(const asect: string);
    procedure SavePackSettings;
    procedure ShowDescr(const fname: string);

  public

  end;

var
  FormMain: TFormMain;

implementation

{$R *.lfm}

uses
  fileutil,

  INIFiles,
  fmModInfo,
  rglogging,
  unitCombine,
  TL2Mod;

procedure TFormMain.LoadPackSettings(const asect:string);
var
  ini:TIniFile;
  ls:string;
  mi:TTL2ModInfo;
  i,lcnt,lidx:integer;
begin
  ini:=TIniFile.Create('combine.ini',[ifoEscapeLineFeeds,ifoStripQuotes]);

  deOutputDir.Text:=ini.ReadString(asect,'outdir','');

  ClearModInfo(newModInfo);
  newModInfo.author  :=StrToWide(ini.ReadString (asect,'mi.author'  ,''));
  newModInfo.title   :=StrToWide(ini.ReadString (asect,'mi.title'   ,''));
  newModInfo.descr   :=StrToWide(ini.ReadString (asect,'mi.descr'   ,''));
  newModInfo.website :=StrToWide(ini.ReadString (asect,'mi.website' ,''));
  newModInfo.download:=StrToWide(ini.ReadString (asect,'mi.download',''));
  newModInfo.modid   :=ini.ReadInteger(asect,'mi.guid'    ,-1);
  newModInfo.modver  :=ini.ReadInteger(asect,'mi.version' ,1);

  lbModList.Clear;
  lcnt:=ini.ReadInteger(asect,'count',0);
  for i:=0 to lcnt-1 do
  begin
    ls:=ini.ReadString(asect,'file'+IntToStr(i),'');
    if ls<>'' then
    begin
      if ls[Length(ls)] in ['\','/'] then
      begin
        lidx:=slModList.Add(ls);
        if LoadModConfiguration(PChar(ls+'MOD.DAT'),mi) then
        begin
          lbModList.AddItem(String(WideString(mi.title)),TObject(IntPtr(lidx)));
          ClearModInfo(mi);
        end
        else
          lbModList.AddItem(ExtractFileName(ls),TObject(IntPtr(lidx)));
      end
      else
      begin
        lidx:=slModList.Add(ls);
        if ReadModInfo(PChar(ls),mi) then
        begin
          lbModList.AddItem(String(WideString(mi.title)),TObject(IntPtr(lidx)));
          ClearModInfo(mi);
        end
        else
          lbModList.AddItem(ExtractFileName(ls),TObject(IntPtr(lidx)));
      end;
    end;
  end;

  ini.Free;

  CheckTheButtons;
  lbModList.ItemIndex:=lbModList.Count-1;
  lbModListClick(Self);
end;

procedure TFormMain.SavePackSettings;
var
  ini:TIniFile;
  lsect:string;
  i:integer;
begin
  ini:=TIniFile.Create('combine.ini',[ifoEscapeLineFeeds,ifoStripQuotes]);
  lsect:=ExtractFileName(deOutputDir.Text);

  ini.WriteString('base','last',lsect);

  ini.WriteString(lsect,'outdir',deOutputDir.Text);

  ini.WriteString (lsect,'mi.author'  ,WideToStr(newModInfo.author));
  ini.WriteString (lsect,'mi.title'   ,WideToStr(newModInfo.title));
  ini.WriteString (lsect,'mi.descr'   ,WideToStr(newModInfo.descr));
  ini.WriteString (lsect,'mi.website' ,WideToStr(newModInfo.website));
  ini.WriteString (lsect,'mi.download',WideToStr(newModInfo.download));
  ini.WriteInteger(lsect,'mi.guid'    ,newModInfo.modid);
  ini.WriteInteger(lsect,'mi.version' ,newModInfo.modver);

  ini.WriteInteger(lsect,'count',lbModList.Count);
  for i:=0 to lbModList.Count-1 do
    ini.WriteString(lsect,'file'+IntToStr(i),
        slModList[IntPtr(lbModList.Items.Objects[i])]);

  ini.UpdateFile;
  ini.Free;

  if cbPreset.Items.IndexOf(lsect)<=0 then
  begin
    cbPreset.Items.Add(lsect);
    cbPreset.ItemIndex:=cbPreset.Items.Count-1;
  end;

end;

function TFormMain.AddToLog(var adata:string):integer;
begin
  memLog.Append(adata);
  adata:='';
  result:=0;
end;

procedure TFormMain.bbApplyClick(Sender: TObject);
var
  f:Text;
  lptr:TRGLogOnAdd;
  i:integer;
begin
  {TODO: maybe remove autosave}
  SavePackSettings;

  memLog.Clear;

  DeleteDirectory(deOutputDir.Text,true);

  SaveModConfiguration(newModInfo,PChar(deOutputDir.Text+'\MOD.DAT'));

  lptr:=RGLog.OnAdd;
  RGLog.OnAdd:=@AddToLog;
  for i:=0 to lbModList.Count-1 do
  begin
    Application.ProcessMessages;
    if AddMod(deOutputDir.Text,
      slModList[IntPtr(lbModList.Items.Objects[i])])=0 then
    begin
      memLog.Append('Something wrong. Break.');
      break;
    end;
    if cbPause.Checked and (i<(lbModList.Count-1)) then
    begin
      if MessageDlg('Next source...','Do you want to continue combine process?',
        mtConfirmation,[mbOk,mbCancel],0,mbOk)<>mrOk then break;
    end;
  end;
  RGLog.OnAdd:=lptr;

  memLog.Append('Done!');
//  memLog.Lines.SaveToFile(deOutputDir.Text+'\combine.log');
  AssignFile(f,deOutputDir.Text+'\combine.log');
  Rewrite(f);
  Writeln(f,memLog.Text);
  CloseFile(f);
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

procedure TFormMain.bbSaveClick(Sender: TObject);
begin
  SavePackSettings;
end;

procedure TFormMain.cbPresetChange(Sender: TObject);
begin
  LoadPackSettings(cbPreset.Text);
end;

procedure TFormMain.CheckTheButtons;
begin
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
    ld.InitialDir:=LastFileDir;
    ld.DefaultExt:='.MOD';
    ld.Filter    :='MOD files|*.MOD';
    ld.Title     :='Choose MOD files to add';
    ld.Options   :=[ofAllowMultiSelect];
    if (ld.Execute) and (ld.Files.Count>0) then
    begin
      LastFileDir:=ExtractFileDir(ld.Files[0]);
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
      CheckTheButtons;
    end;
  finally
    ld.Free;
  end;
  lbModList.ItemIndex:=lbModList.Count-1;
  lbModListClick(Self);
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
      CheckTheButtons;
    end;
  finally
    ld.Free;
  end;
  lbModList.ItemIndex:=lbModList.Count-1;
  lbModListClick(Self);
end;

procedure TFormMain.ShowDescr(const fname:string);
var
  mi:TTL2ModInfo;
  l:boolean;
begin
  memDescription.Clear;
  memDescription.Append('Source: '+fname);

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
    lbModList.Selected[lbModList.ItemIndex]:=true;
    ShowDescr(slModList[IntPtr(lbModList.Items.Objects[lbModList.ItemIndex])]);
  end
  else
    memDescription.Clear;
end;

procedure TFormMain.bbDeleteClick(Sender: TObject);
var
  i:integer;
begin
  { TODO : Delete data or not from string list }
  i:=lbModList.ItemIndex;
  lbModList.DeleteSelected;
  if i>=lbModList.Count then i:=lbModList.Count-1;
  lbModList.ItemIndex:=i;
  lbModListClick(Self);

  bbDelete.Enabled:=lbModList.Count>0;
  bbApply .Enabled:=lbModList.Count>0;
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

procedure TFormMain.FormCreate(Sender: TObject);
var
  ini:TIniFile;
  sl:TStringList;
  lsect:string;
begin
  slModList:=TStringList.Create;
  slModList.Capacity:=128;
  MakeModInfo(newModInfo);

  ini:=TIniFile.Create('combine.ini',[ifoEscapeLineFeeds,ifoStripQuotes]);
  sl:=TStringList.Create;
  ini.ReadSections(sl);
  cbPreset.Items.Assign(sl);
  cbPreset.Enabled:=cbPreset.Items.Count>0;

  if cbPreset.Enabled then
  begin
    lsect:=ini.ReadString('base','last','');
    if lsect<>'' then
      cbPreset.ItemIndex:=cbPreset.Items.IndexOf(lsect)
    else
      cbPreset.ItemIndex:=0;
    cbPresetChange(self);
  end;

  sl.Free;

  ini.Free;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  ClearModInfo(newModInfo);
  slModList.Free;
end;

end.

