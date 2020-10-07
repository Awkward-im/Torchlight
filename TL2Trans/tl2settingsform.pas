unit TL2SettingsForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, EditBtn,
  Buttons;

const
  DefDATFile    = 'TRANSLATION.DAT';
  DefaultExt    = '.DAT';
  DefaultFilter = 'DAT files|*.DAT';

type

  { TTL2Settings }

  TTL2Settings = class(TForm)
    bbFontEdit: TBitBtn;
    bbSaveSettings: TBitBtn;
    cbExportParts: TCheckBox;
    cbImportParts: TCheckBox;
    cbAutoAsPartial: TCheckBox;
    cbRemoveTags: TCheckBox;
    cbReopenProjects: TCheckBox;
    cbHidePartial: TCheckBox;
    cbShowDebug: TCheckBox;
    edFilterWords: TEdit;
    edImportDir: TDirectoryEdit;
    edDefaultFile: TFileNameEdit;
    edRootDir: TDirectoryEdit;
    edTransLang: TEdit;
    edWorkDir: TDirectoryEdit;
    gbTranslateYandex: TGroupBox;
    gbTranslateGoogle: TGroupBox;
    gbTranslation: TGroupBox;
    gbOther: TGroupBox;
    lblFilter: TLabel;
    lblFilterNote: TLabel;
    lblTranslators: TLabel;
    lblProgramLanguage: TLabel;
    lblAPIKeyGoogle: TLabel;
    lblGetAPIKeyGoogle: TLabel;
    lblImportDir: TLabel;
    lblLang: TLabel;
    lblYandexNote: TLabel;
    lblGetAPIKeyYandex: TLabel;
    lblAPIKeyYandex: TLabel;
    lbAddFileList: TListBox;
    lblAddFile: TLabel;
    lblDefaultFile: TLabel;
    lblRootDirectory: TLabel;
    lblWorkDirectory: TLabel;
    lbLanguage: TListBox;
    lbTranslators: TListBox;
    memAPIKeyYandex: TMemo;
    memAPIKeyGoogle: TMemo;
    sbAddonAdd: TSpeedButton;
    sbAddonDel: TSpeedButton;
    sbAddonDown: TSpeedButton;
    sbAddonUp: TSpeedButton;
    procedure bbSaveSettingsClick(Sender: TObject);
    procedure btnFontEditClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure gbTranslationClick(Sender: TObject);
    procedure lbLanguageSelectionChange(Sender: TObject; User: boolean);
    procedure lblGetAPIKeyGoogleClick(Sender: TObject);
    procedure lblGetAPIKeyYandexClick(Sender: TObject);
    procedure sbAddonAddClick(Sender: TObject);
    procedure sbAddonDelClick(Sender: TObject);
    procedure TL2ArrowDownClick(Sender: TObject);
    procedure TL2ArrowUpClick(Sender: TObject);
  private
    procedure ApplyLoadedLang(const alang:AnsiString);
    procedure ApplyLoadedTrans(const alang: AnsiString);
    procedure FillLocalesList;
    procedure FillTranslatorList;
    procedure LoadSettings();
    procedure SaveGUISettings;
    procedure SaveSettings();

  public
    procedure SaveTabs(asl:TStringList);
    procedure LoadTabs(asl:TStringList);
  end;

var
  TL2Settings:TTL2Settings;

//function TranslateYandex(const src:AnsiString):AnsiString;
function Translate(const src:AnsiString):AnsiString;

implementation

{$R *.lfm}
uses
  inifiles,

  LCLTranslator,
  LCLType,
  LCLIntf,

  iso639,
  trclass,

  TL2Text,
  TL2DataModule;

resourcestring
  sNotRealized    = 'Not realized yet';
  sSettings       = 'Settings';

//----- Translation -----

function Translate(const src:AnsiString):AnsiString;
var
  ltr:TTranslateBase;
  ls:string;
  lcode:integer;
begin
  result:=src;

  if TL2Settings.cbRemoveTags.Checked then
    ls:=RemoveTags(src)
  else
    ls:=src;

  case LowerCase(TL2Settings.lbTranslators.Items[
                 TL2Settings.lbTranslators.ItemIndex]) of
    'google': begin
      ltr:=TTranslateGoogle.Create;
      ltr.Key:=TL2Settings.memAPIKeyGoogle.Text;
    end;
    'yandex': begin
      ltr:=TTranslateYandex.Create;
      ltr.Key:=TL2Settings.memAPIKeyYandex.Text;
    end;
    'bing'         : ltr:=TTranslateBing.Create;
    'babylon'      : ltr:=TTranslateBabylon.Create;
    'm-translate'  : ltr:=TTranslateMTranslate.Create;
    'translate.com': ltr:=TTranslateTranslate.Create;
    'mymemory'     : ltr:=TTranslateMyMemory.Create;
  else
    exit;
  end;

  try
    ltr.LangSrc :='en';
    ltr.LangDst :=TL2Settings.edTransLang.Text;
    ltr.Original:=src;
    lcode:=ltr.Translate;
    if lcode<>0 then
      ShowMessage('Error ('+IntToStr(lcode)+'): '+ltr.ResultNote)
    else
      result:=ltr.Translated;
  finally
    ltr.Free;
  end;
end;

{ TTL2Settings }

resourcestring
  sOpenAddon = 'Choose additional file';

var
  INIFileName:string;

const
  MinGroupHeight = 20;

const
  sNSBase       = 'Base';
  sSectSettings = 'Settings';
  sSectFont     = 'Font';
  sSectAddon    = 'Addons';
  sSectTabs     = 'Tabs';
  sTranslation  = 'Translation';

  sFile         = 'file';
  sTabs         = 'tabs';
  sTab          = 'tab';
  sAddFiles     = 'addfiles';
  sDefFile      = 'defaultfile';
  sRootDir      = 'rootdir';
  sWorkDir      = 'workdir';
  sImportDir    = 'importdir';
  sExportParts  = 'exportparts';
  sImportParts  = 'importparts';
  sFontName     = 'Name';
  sFontCharset  = 'Charset';
  sFontSize     = 'Size';
  sFontStyle    = 'Style';
  sFontColor    = 'Color';
  sTranslator   = 'Translator';
  sYAPIKey      = 'YandexAPIKey';
  sGAPIKey      = 'GoogleAPIKey';
  sTransLang    = 'Language';
  sPrgTransLang = 'PrgLanguage';
  sFilter       = 'filter';
  sAutoPartial  = 'autoaspartial';
  sReopenFiles  = 'reopenfiles';
  sRemoveTags   = 'removetags';
  sHidePartial  = 'hidepartial';
  sShowDebug    = 'showdebug';

  sGroupHeight  = 'groupheight';

const
  defFilter = 'a an the of by to for his her their';

const
  YandexKeyURL   = 'https://translate.yandex.com/developers/keys';
  GoogleKeyURL   = '';
  MyYandexAPIKey = 'trnsl.1.1.20200101T160123Z.3e57638fddd71006.49c9489591b0e6a07ab3e6cf12886b99fecdf26b';
//  AbramoffYandexAPIkey = 'trnsl.1.1.20140120T030428Z.c4c35e8a7d79c03e.defc651bed90c4424445c47be30e6b531bc4b063';
  MyLanguage     = 'ru';

//----- default settings -----

const
  DefFontName    = 'Arial Unicode MS'; // 'MS Sans Serif'
  DefFontCharset = DEFAULT_CHARSET;
  DefFontSize    = 10;
  DefFontStyle   = '';
  DefFontColor   = clWindowText;

//----- Settings -----

procedure TTL2Settings.SaveTabs(asl:TStringList);
var
  config:TIniFile;
  i,lcnt:integer;
begin
  config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);

  config.EraseSection(sNSBase+':'+sSectTabs);

  lcnt:=0;
  for i:=0 to asl.Count-1 do
  begin
    if asl[i]<>'' then
    begin
      config.WriteString(sNSBase+':'+sSectTabs,sTab+IntToStr(i+1),asl[i]);
      inc(lcnt);
    end;
  end;
  config.WriteInteger(sNSBase+':'+sSectTabs,sTabs,lcnt);

  config.UpdateFile;
  config.Free;
end;

procedure TTL2Settings.LoadTabs(asl:TStringList);
var
  config:TIniFile;
  i,lcnt:integer;
begin
  config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);

  asl.Clear;
  lcnt:=config.ReadInteger(sNSBase+':'+sSectTabs,sTabs,0);
  for i:=1 to lcnt do
  begin
    asl.Add(config.ReadString(sNSBase+':'+sSectTabs,sTab+IntToStr(i),''));
  end;

  config.Free;
end;

procedure TTL2Settings.SaveGUISettings;
var
  config:TIniFile;
begin
  config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);

  config.WriteInteger(sNSBase+':'+sSectSettings,sGroupHeight,gbTranslation.Height);

  config.UpdateFile;
  config.Free;
end;

procedure TTL2Settings.SaveSettings();
var
  config:TIniFile;
  ls:AnsiString;
  lstyle:TFontStyles;
  i:integer;
begin
  config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);

  //--- Main
  config.WriteString(sNSBase+':'+sSectSettings,sDefFile  ,edDefaultFile.Text);
  config.WriteString(sNSBase+':'+sSectSettings,sRootDir  ,edRootDir    .Text);
  config.WriteString(sNSBase+':'+sSectSettings,sWorkDir  ,edWorkDir    .Text);
  config.WriteString(sNSBase+':'+sSectSettings,sImportDir,edImportDir  .Text);

  //--- Options
  config.WriteBool(sNSBase+':'+sSectSettings,sExportParts,cbExportParts   .Checked);
  config.WriteBool(sNSBase+':'+sSectSettings,sImportParts,cbImportParts   .Checked);
  config.WriteBool(sNSBase+':'+sSectSettings,sAutoPartial,cbAutoAsPartial .Checked);
  config.WriteBool(sNSBase+':'+sSectSettings,sReopenFiles,cbReopenProjects.Checked);
  config.WriteBool(sNSBase+':'+sSectSettings,sHidePartial,cbHidePartial   .Checked);

  //--- Addons
  config.EraseSection(sNSBase+':'+sSectAddon);
  config.WriteInteger(sNSBase+':'+sSectAddon,sAddFiles,lbAddFileList.Count);
  for i:=0 to lbAddFileList.Count-1 do
    config.WriteString(sNSBase+':'+sSectAddon,
    sFile+IntToStr(i),lbAddFileList.Items[i]);

  //--- Font
  config.WriteString (sNSBase+':'+sSectFont,sFontName   ,TL2DM.TL2Font.Name);
  config.WriteInteger(sNSBase+':'+sSectFont,sFontCharset,TL2DM.TL2Font.Charset);
  config.WriteInteger(sNSBase+':'+sSectFont,sFontSize   ,TL2DM.TL2Font.Size);
  config.WriteString (sNSBase+':'+sSectFont,sFontColor  ,ColorToString(TL2DM.TL2Font.Color));

  lstyle:=TL2DM.TL2Font.Style;
  ls:='';
  if fsBold      in lstyle then ls:='bold ';
  if fsItalic    in lstyle then ls:=ls+'italic ';
  if fsUnderline in lstyle then ls:=ls+'underline ';
  if fsStrikeOut in lstyle then ls:=ls+'strikeout ';
  config.WriteString(sNSBase+':'+sSectFont,sFontStyle,ls);

  //--- Translation
  ls:=lbLanguage.Items[lbLanguage.ItemIndex];
  config.WriteString(sNSBase+':'+sTranslation,sPrgTransLang,copy(ls,1,pos(' ',ls)-1));
  config.WriteString(sNSBase+':'+sTranslation,sTransLang,edTransLang.Text);

  config.WriteString(sNSBase+':'+sTranslation,sYAPIKey,memAPIKeyYandex.Text);
  config.WriteString(sNSBase+':'+sTranslation,sGAPIKey,memAPIKeyGoogle.Text);

  config.WriteString(sNSBase+':'+sTranslation,sTranslator,
    lbTranslators.Items[lbTranslators.ItemIndex]);

  //--- Other
  config.WriteBool(sNSBase+':'+sSectSettings,sRemoveTags,cbRemoveTags.Checked);
  config.WriteBool(sNSBase+':'+sSectSettings,sShowDebug ,cbShowDebug .Checked);

  //--- Special
  config.WriteString(sNSBase+':'+sSectSettings,sFilter,edFilterWords.Caption);

  config.UpdateFile;

  config.Free;
end;

procedure TTL2Settings.LoadSettings();
var
  config:TIniFile;
  ls:AnsiString;
  lstyle:TFontStyles;
  i,lcnt:integer;
begin
  config:=TIniFile.Create(INIFileName,[ifoEscapeLineFeeds,ifoStripQuotes]);

  //--- Main
  edDefaultFile.Text:=config.ReadString(sNSBase+':'+sSectSettings,sDefFile  ,DefDATFile);
  edRootDir    .Text:=config.ReadString(sNSBase+':'+sSectSettings,sRootDir  ,'');
  edWorkDir    .Text:=config.ReadString(sNSBase+':'+sSectSettings,sWorkDir  ,GetCurrentDir());
  edImportDir  .Text:=config.ReadString(sNSBase+':'+sSectSettings,sImportDir,edWorkDir.Text);

  //--- Options
  cbExportParts   .Checked:=config.ReadBool(sNSBase+':'+sSectSettings,sExportParts,false);
  cbImportParts   .Checked:=config.ReadBool(sNSBase+':'+sSectSettings,sImportParts,false);
  cbAutoAsPartial .Checked:=config.ReadBool(sNSBase+':'+sSectSettings,sAutoPartial,false);
  cbReopenProjects.Checked:=config.ReadBool(sNSBase+':'+sSectSettings,sReopenFiles,false);
  cbHidePartial   .Checked:=config.ReadBool(sNSBase+':'+sSectSettings,sHidePartial,false);

  //--- Addons
  lcnt:=config.ReadInteger(sNSBase+':'+sSectAddon,sAddFiles,0);
  lbAddFileList.Clear;
  for i:=0 to lcnt-1 do
  begin
    lbAddFileList.AddItem(
        config.ReadString(sNSBase+':'+sSectAddon,
        sFile+IntToStr(i),''),nil);
  end;

//--- Font
  TL2DM.TL2Font.Name   :=config.ReadString (sNSBase+':'+sSectFont,sFontName   ,DefFontName);
  TL2DM.TL2Font.Charset:=config.ReadInteger(sNSBase+':'+sSectFont,sFontCharset,DefFontCharset);
  TL2DM.TL2Font.Size   :=config.ReadInteger(sNSBase+':'+sSectFont,sFontSize   ,DefFontSize);
  TL2DM.TL2Font.Color  :=StringToColor(
      config.ReadString(sNSBase+':'+sSectFont,sFontColor,ColorToString(DefFontColor)));

  ls:=config.ReadString(sNSBase+':'+sSectFont,sFontStyle,DefFontStyle);
  lstyle:=[];
  if Pos('bold'     ,ls)<>0 then lstyle:=lstyle+[fsBold];
  if Pos('italic'   ,ls)<>0 then lstyle:=lstyle+[fsItalic];
  if Pos('underline',ls)<>0 then lstyle:=lstyle+[fsUnderline];
  if Pos('strikeout',ls)<>0 then lstyle:=lstyle+[fsStrikeOut];
  TL2DM.TL2Font.Style:=lstyle;

  //--- Other
  cbRemoveTags.Checked:=config.ReadBool(sNSBase+':'+sSectSettings,sRemoveTags,true);
  cbShowDebug .Checked:=config.ReadBool(sNSBase+':'+sSectSettings,sShowDebug ,false);

  //--- Special
  edFilterWords.Caption:=config.ReadString(sNSBase+':'+sSectSettings,sFilter,defFilter);

  //--- Translation
  memAPIKeyYandex.Text:=config.ReadString(sNSBase+':'+sTranslation,sYAPIKey,MyYandexAPIKey);
  memAPIKeyGoogle.Text:=config.ReadString(sNSBase+':'+sTranslation,sGAPIKey,'');

  edTransLang.Text:=config.ReadString(sNSBase+':'+sTranslation,sTransLang   ,MyLanguage);
  ApplyLoadedLang ( config.ReadString(sNSBase+':'+sTranslation,sPrgTransLang,'en'));
  ApplyLoadedTrans( config.ReadString(sNSBase+':'+sTranslation,sTranslator ,'Google'));

  //---
  i:=config.ReadInteger(sNSBase+':'+sSectSettings,sGroupHeight,MinGroupHeight);
  if i<MinGroupHeight then i:=MinGroupHeight;
  gbTranslation.Tag:=gbTranslation.Height;
  gbTranslation.Height:=i;

  config.Free;
end;

procedure TTL2Settings.ApplyLoadedLang(const alang:AnsiString);
var
  ls:AnsiString;
  i,idx:integer;
begin
  idx:=0;
  for i:=0 to lbLanguage.Items.Count-1 do
  begin
    ls:=lbLanguage.Items[i];
    if alang=copy(ls,1,pos(' ',ls)-1) then
    begin
      idx:=i;
      break;
    end;
  end;
  lbLanguage.ItemIndex:=idx;
//  lbLanguageSelectionChange(Sender: TObject; User: boolean);
//  SetDefaultLang(copy(ls,1,pos(' ',ls)-1));
end;

procedure TTL2Settings.ApplyLoadedTrans(const alang:AnsiString);
var
  ls:AnsiString;
  i,idx:integer;
begin
  idx:=0;
  ls:=LowerCase(alang);
  for i:=0 to lbTranslators.Items.Count-1 do
  begin
    if ls=LowerCase(lbTranslators.Items[i]) then
    begin
      idx:=i;
      break;
    end;
  end;
  lbTranslators.ItemIndex:=idx;
end;

//----- Other -----

procedure TTL2Settings.bbSaveSettingsClick(Sender: TObject);
begin
  SaveSettings;
end;

procedure TTL2Settings.btnFontEditClick(Sender: TObject);
var
  FontDialog:TFontDialog;
begin
  FontDialog:=TFontDialog.Create(nil);
  try
    FontDialog.Font.Assign(TL2DM.TL2Font);
    if FontDialog.Execute then
    begin
      TL2DM.TL2Font.Assign(FontDialog.Font);
      Application.MainForm.Font.Assign(TL2DM.TL2Font);
    end;
  finally
    FontDialog.Free;
  end;
end;

procedure TTL2Settings.gbTranslationClick(Sender: TObject);
begin
  if gbTranslation.Height>MinGroupHeight then
  begin
    gbTranslation.Tag:=gbTranslation.Height;
    gbTranslation.Height:=MinGroupHeight;
  end
  else
  begin
    gbTranslation.Height:=gbTranslation.Tag;
  end;
end;

//----- Addon file list -----

procedure TTL2Settings.sbAddonAddClick(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  fcnt:integer;
begin
  OpenDialog:=TOpenDialog.Create(nil);
  try
    OpenDialog.DefaultExt:=DefaultExt;
    OpenDialog.Filter    :=DefaultFilter;
    OpenDialog.Title     :=sOpenAddon;
    OpenDialog.InitialDir:=edWorkDir.Text;
    OpenDialog.Options   :=[ofNoChangeDir,ofAllowMultiSelect];

    if OpenDialog.Execute then
    begin
      for fcnt:=0 to OpenDialog.Files.Count-1 do
      lbAddFileList.AddItem(OpenDialog.Files[fcnt],nil);
//        lbAddFileList.AddItem(ExtractFileName(OpenDialog.Files[fcnt]),nil);

      lbAddFileList.ItemIndex:=lbAddFileList.Count-1;
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TTL2Settings.sbAddonDelClick(Sender: TObject);
begin
  if lbAddFileList.ItemIndex>=0 then
  begin
    lbAddFileList.DeleteSelected;
  end;
end;

procedure TTL2Settings.TL2ArrowDownClick(Sender: TObject);
var
  lidx:integer;
begin
  lidx:=lbAddFileList.ItemIndex;
  if (lidx>=0) and (lidx<(lbAddFileList.Count-1)) then
  begin
    lbAddFileList.Items.Move(lidx,lidx+1);
    lbAddFileList.ItemIndex:=lidx+1;
  end;
end;

procedure TTL2Settings.TL2ArrowUpClick(Sender: TObject);
var
  lidx:integer;
begin
  lidx:=lbAddFileList.ItemIndex;
  if lidx>0 then
  begin
    lbAddFileList.Items.Move(lidx,lidx-1);
    lbAddFileList.ItemIndex:=lidx-1;
  end;
end;

//----- Translation -----

procedure TTL2Settings.lblGetAPIKeyYandexClick(Sender: TObject);
begin
  OpenURL(YandexKeyURL);
end;

procedure TTL2Settings.lblGetAPIKeyGoogleClick(Sender: TObject);
begin
  ShowMessage(sNotRealized);
//  OpenURL(GoogleKeyURL);
end;

procedure TTL2Settings.lbLanguageSelectionChange(Sender: TObject; User: boolean);
var
  ls:AnsiString;
begin
  ls:=lbLanguage.Items[lbLanguage.ItemIndex];
  SetDefaultLang(copy(ls,1,pos(' ',ls)-1));
  Caption:=sSettings;
  if Parent<>nil then
    Parent.Caption:=sSettings;
end;

procedure TTL2Settings.FillLocalesList;
var
  sr:TSearchRec;
  lname:AnsiString;
  i:integer;
begin
  lbLanguage.Clear;
  lbLanguage.AddItem('en - English',nil);
  if FindFirst(ExtractFilePath(ParamStr(0))+'languages\*.po',faAnyFile,sr)=0 then
  begin
    repeat
      lname:=sr.Name;
      i:=Length(lname)-4;
      while (i>0) and (lname[i]<>'.') do dec(i);
      lname:=Copy(lname,i+1,Length(lname)-i-3);
      lbLanguage.AddItem(lname+' - '+iso639.GetLangName(lname),nil);
    until FindNext(sr)<>0;
    FindClose(sr);
  end;
//  lbLanguage.ItemIdex:=0;
end;

procedure TTL2Settings.FillTranslatorList;
begin
  lbTranslators.Clear;
  lbTranslators.AddItem('Google'       ,nil);
  lbTranslators.AddItem('Yandex'       ,nil);
  lbTranslators.AddItem('Bing'         ,nil);
  lbTranslators.AddItem('Babylon'      ,nil);
  lbTranslators.AddItem('M-Translate'  ,nil);
  lbTranslators.AddItem('Translate.com',nil);
  lbTranslators.AddItem('MyMemory'     ,nil);
  lbTranslators.ItemIndex:=0;
end;

//----- Base -----

procedure TTL2Settings.FormCreate(Sender: TObject);
begin
  TL2Settings:=Self;

  edDefaultFile.Filter:=DefaultFilter;
  edDefaultFile.DefaultExt:=DefaultExt;

  INIFileName:=ChangeFileExt(ParamStr(0),'.ini');

  FillLocalesList;
  FillTranslatorList;
  LoadSettings;
end;

procedure TTL2Settings.FormDestroy(Sender: TObject);
begin
  SaveGUISettings;
end;

end.
