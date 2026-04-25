unit fmGUISettings;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, StdCtrls,
  INIFiles, fmCoreCfg;

type

  { TGUICfgForm }

  TGUICfgForm = class(TCoreCfgForm)
    bbFontEdit : TBitBtn;
    cbPreview  : TCheckBox; // no sense in generic gui settings, single mod main form only
    cbSingleMod: TCheckBox;

    procedure bbFontEditClick(Sender: TObject);
    procedure cbPreviewChange(Sender: TObject);
    procedure cbSingleModClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public
  end;

var
  GUICfgForm: TGUICfgForm;

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

{ TGUICfgForm }

procedure TGUICfgForm.cbPreviewChange(Sender: TObject);
begin
  if cbPreview.Checked then
  begin
    ClosePreviews();
  end;
//  actShowPreview.Checked:=true; // will be inverted
//  actPreviewExecute(Sender);
end;

procedure TGUICfgForm.cbSingleModClick(Sender: TObject);
begin
  if cbSingleMod.Checked then cfgGUIPlugin:='1' else cfgGUIPlugin:='0';
  FGUISettingsChanged:=true;
end;

procedure TGUICfgForm.bbFontEditClick(Sender: TObject);
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

procedure TGUICfgForm.FormCreate(Sender: TObject);
begin
  cbSingleMod.Checked:=cfgGUIPlugin='1';
  FGUISettingsChanged:=false;
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

