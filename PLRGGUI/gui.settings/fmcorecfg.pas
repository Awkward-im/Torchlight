unit fmCoreCfg;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, EditBtn,
  Buttons, INIFiles;

type

  { TCoreCfgForm }

  TCoreCfgForm = class(TForm)
    bbFontEdit: TBitBtn;
    cbSingleMod: TCheckBox;
    lblOutDir     : TLabel;
    deOutDir      : TDirectoryEdit;
    cbSaveDateTime: TCheckBox;
    cbUnpackTree  : TCheckBox;
    cbMODDAT      : TCheckBox;
    cbFastScan    : TCheckBox;
    cbTest        : TCheckBox;
    cbUseFName    : TCheckBox;

    gbDecoding: TGroupBox;
    rbGUTSStyle : TRadioButton;
    rbTextRename: TRadioButton;
    rbBinOnly   : TRadioButton;
    rbTextOnly  : TRadioButton;
    cbSaveUTF8  : TCheckBox;

    procedure bbFontEditClick(Sender: TObject);
    procedure cbSingleModClick(Sender: TObject);
    procedure CoreOptChanged(Sender: TObject);
    procedure CoreDirChanged(Sender: TObject; var Value: String);
    procedure FormCreate(Sender: TObject);
  private

  public
    procedure FillSettings;

  end;

var
  CoreCfgForm: TCoreCfgForm;

procedure LoadGUISettings(acfg: TIniFile=nil);
procedure SaveGUISettings(acfg: TIniFile=nil);


implementation

{$R *.lfm}

uses
  rggui.core,
  rggui.shared,
  rgpreview;

var
  FGUISettingsChanged:boolean;

const
  sSectSrcFont  = 'srcfont';
  sFontName     = 'Name';
  sFontCharset  = 'Charset';
  sFontSize     = 'Size';
  sFontStyle    = 'Style';
  sFontColor    = 'Color';

procedure TCoreCfgForm.CoreOptChanged(Sender: TObject);
begin
       if Sender=cbUnpackTree   then cfgUnpackTree  :=cbUnpackTree  .Checked
  else if Sender=cbSaveUTF8     then cfgSaveUTF8    :=cbSaveUTF8    .Checked
  else if Sender=cbMODDAT       then cfgMakeMODDAT  :=cbMODDAT      .Checked
  else if Sender=cbFastScan     then cfgFastScan    :=cbFastScan    .Checked
  else if Sender=cbUseFName     then cfgUsePakName  :=cbUseFName    .Checked
  else if Sender=cbSaveDateTime then cfgSaveDateTime:=cbSaveDateTime.Checked

  else if Sender=rbBinOnly      then cfgSaveMode    :=smBinary
  else if Sender=rbTextOnly     then cfgSaveMode    :=smText
  else if Sender=rbTextRename   then cfgSaveMode    :=smRename
  else if Sender=rbGUTSStyle    then cfgSaveMode    :=smGUTS

  else if Sender=deOutDir       then cfgUnpackDir   :=deOutDir.Text;
end;

procedure TCoreCfgForm.bbFontEditClick(Sender: TObject);
var
  lfont:TFont;
  FontDialog:TFontDialog;
begin
  FontDialog:=TFontDialog.Create(nil);
  try
    lfont:=GetPreviewFont();
    FontDialog.Font.Assign(lfont);
    if FontDialog.Execute then
    begin
      lfont.Assign(FontDialog.Font);
      SetPreviewFont(lfont);
      FGUISettingsChanged:=true;
    end;
  finally
    FontDialog.Free;
  end;
end;

procedure TCoreCfgForm.cbSingleModClick(Sender: TObject);
begin
  if cbSingleMod.Checked then cfgGUIPlugin:='1' else cfgGUIPlugin:='0';
  FGUISettingsChanged:=true;
end;

procedure TCoreCfgForm.CoreDirChanged(Sender: TObject; var Value: String);
begin
  cfgUnpackDir:=deOutDir.Text;
end;

procedure TCoreCfgForm.FormCreate(Sender: TObject);
begin
  cbSingleMod.Checked:=cfgGUIPlugin='1';
  FGUISettingsChanged:=false;
end;

procedure TCoreCfgForm.FillSettings;
begin
  deOutDir      .Text   :=cfgUnpackDir;
  cbUnpackTree  .Checked:=cfgUnpackTree;
  cbUseFName    .Checked:=cfgUsePakName;
  cbMODDAT      .Checked:=cfgMakeMODDAT;
  cbFastScan    .Checked:=cfgFastScan;
  cbSaveDateTime.Checked:=cfgSaveDateTime;
  cbSaveUTF8    .Checked:=cfgSaveUTF8;
  case cfgSaveMode of
    smBinary: rbBinOnly  .Checked:=true;
    smText  : rbTextOnly .Checked:=true;
    smGUTS  : rbGUTSStyle.Checked:=true;
  else // smRename
    rbTextRename.Checked:=true;
  end;
end;

procedure LoadFont(acfg:TIniFile; const asect:AnsiString; afont:TFont);
var
  ls:AnsiString;
  lstyle:TFontStyles;
begin
//  lfont:=GetPreviewFont();
  afont.Name   :=acfg.ReadString (asect,sFontName   ,defFontName);
  afont.Charset:=acfg.ReadInteger(asect,sFontCharset,defFontCharset);
  afont.Size   :=acfg.ReadInteger(asect,sFontSize   ,defFontSize);
  afont.Color  :=StringToColor(
                 acfg.ReadString (asect,sFontColor,ColorToString(defFontColor)));

  ls:=acfg.ReadString(asect,sFontStyle,defFontStyle);
  lstyle:=[];
  if Pos('bold'     ,ls)<>0 then lstyle:=lstyle+[fsBold];
  if Pos('italic'   ,ls)<>0 then lstyle:=lstyle+[fsItalic];
  if Pos('underline',ls)<>0 then lstyle:=lstyle+[fsUnderline];
  if Pos('strikeout',ls)<>0 then lstyle:=lstyle+[fsStrikeOut];
  afont.Style:=lstyle;
end;

procedure SaveFont(acfg:TIniFile; const asect:AnsiString; afont:TFont);
var
  ls:AnsiString;
  lstyle:TFontStyles;
begin
  acfg.WriteString (asect,sFontName   ,afont.Name);
  acfg.WriteInteger(asect,sFontCharset,afont.Charset);
  acfg.WriteInteger(asect,sFontSize   ,afont.Size);
  acfg.WriteString (asect,sFontColor  ,ColorToString(afont.Color));

  lstyle:=afont.Style;
  ls:='';
  if fsBold      in lstyle then ls:='bold ';
  if fsItalic    in lstyle then ls:=ls+'italic ';
  if fsUnderline in lstyle then ls:=ls+'underline ';
  if fsStrikeOut in lstyle then ls:=ls+'strikeout ';
  acfg.WriteString(asect,sFontStyle,ls);
end;

procedure LoadGUISettings(acfg: TIniFile=nil);
var
  config:TIniFile;
  lfont:TFont;
begin
  if acfg=nil then
	  config:=TIniFile.Create(ConfigName,[ifoEscapeLineFeeds,ifoStripQuotes])
  else
    config:=acfg;

  lfont:=GetPreviewFont();
  LoadFont(config,sSectSrcFont,lfont);
  SetPreviewFont(lfont);

  if acfg=nil then config.Free;

  FGUISettingsChanged:=false;
end;

procedure SaveGUISettings(acfg:TIniFile=nil);
var
  config:TIniFile;
begin
  if not FGUISettingsChanged then exit;

  if acfg=nil then
    config:=TMemIniFile.Create(ConfigName,[ifoEscapeLineFeeds,ifoStripQuotes])
  else
    config:=acfg;
(*
  config.WriteBool   (sSectSettings,sShowCategory,bShowCategory);
  config.WriteBool   (sSectSettings,sShowTime    ,bShowTime    );
  config.WriteBool   (sSectSettings,sShoPacked   ,bShowPacked  );
  config.WriteBool   (sSectSettings,sShowSource  ,bShowSource  );
*)
//  fmFilterForm.SaveSettings(config);
// must be in main form settings
//  config.WriteBool   (sSectSettings,sShowPreview ,actShowPreview.Checked);
// really, this option too
//  config.WriteBool(sSectSettings,sPreview,cbPreview.Checked);

  config.WriteString(sSectSettings,sGUIDir,cfgGUIPlugin);
  SaveFont(config,sSectSrcFont,GetPreviewFont());

  FGUISettingsChanged:=false;

  if acfg=nil then
  begin
	  config.UpdateFile;
  	config.Free;
  end;
end;

end.

