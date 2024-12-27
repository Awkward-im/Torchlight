unit formScanAll;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ShellCtrls, ExtCtrls, EditBtn;

type

  { TfmScan }

  TfmScan = class(TForm)
    bbScan: TBitBtn;

    cbPets   : TCheckBox;
    cbMobs   : TCheckBox;
    cbQuests : TCheckBox;
    cbStats  : TCheckBox;
    cbRecipes: TCheckBox;
    cbItems  : TCheckBox;
    cbProps  : TCheckBox;
    cbSkills : TCheckBox;
    cbClasses: TCheckBox;

    cbUpdateAll: TCheckBox;
    cbDetailedLog: TCheckBox;
    cbWardrobe: TCheckBox;
    cbAdds: TCheckBox;
    edDirName: TDirectoryEdit;
    edFileName: TFileNameEdit;
    gbWhatToScan: TGroupBox;
    memLog: TMemo;
    pnlMain: TPanel;
    rbDirToScan: TRadioButton;
    rbFileToScan: TRadioButton;
    Splitter: TSplitter;
    procedure bbScanClick(Sender: TObject);
    procedure cbUpdateAllChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure rbDirToScanChange(Sender: TObject);
    procedure rbFileToScanChange(Sender: TObject);
  private
    db:pointer;
    gamever:integer;

    function  AddToLog(var adata:string):integer;
    procedure ProcessSingleMod(const aname: string);

  public

  end;

var
  fmScan: TfmScan;

implementation

{$R *.lfm}

{ TfmScan }

uses
  fmgameversion,
  rgpak,
  logging,
  rgglobal,
  rgscan,
  unitscan;

function TfmScan.AddToLog(var adata:string):integer;
begin
  memLog.Append(adata);
  adata:='';
  result:=0;
end;

procedure TfmScan.ProcessSingleMod(const aname:string);
var
  lms:pointer;
begin
  if cbDetailedLog.Checked then
    RGDebugLevel:=dlDetailed
  else
    RGDebugLevel:=dlNormal;

  if not Prepare(db,aname,lms, false, gamever) then
  begin
    memLog.Append('Can''t prepare "'+aname+'" scanning');
    exit;
  end;

  if cbUpdateAll.Checked then
  begin
    memLog.Append('Scanning all');
    ScanAll(lms);
    Application.ProcessMessages;
  end
  else
  begin

    // Adds
    if cbAdds.Checked then
    begin
      ScanAdds(lms);
      Application.ProcessMessages;
    end;

    // Wardrobe
    if cbWardrobe.Checked then
    begin
      ScanWardrobe(lms);
      Application.ProcessMessages;
    end;

    // Pets
    if cbPets.Checked then
    begin
      ScanPets(lms);
      Application.ProcessMessages;
    end;

    // Quests
    if cbQuests.Checked then
    begin
      ScanQuests(lms);
      Application.ProcessMessages;
    end;

    // Stats
    if cbStats.Checked then
    begin
      ScanStats(lms);
      Application.ProcessMessages;
    end;

    // Recipes
    if cbRecipes.Checked then
    begin
      ScanRecipes(lms);
      Application.ProcessMessages;
    end;

    // Mobs
    if cbMobs.Checked then
    begin
      ScanMobs(lms);
      Application.ProcessMessages;
    end;

    // Items
    if cbItems.Checked then
    begin
      ScanItems(lms);
      Application.ProcessMessages;
    end;

    // Props
    if cbProps.Checked then
    begin
      ScanProps(lms);
      Application.ProcessMessages;
    end;

    // Skills
    if cbSkills.Checked then
    begin
      ScanSkills(lms);
      Application.ProcessMessages;
    end;

    // Classes
    if cbClasses.Checked then
    begin
      ScanClasses(lms);
      Application.ProcessMessages;
    end;
  end;

  Finish(lms);
end;

function DoCheck(const adir,aname:string; aparam:pointer):integer;
var
  lext:string;
begin
//  lext:=TfmScan(aparam).edDirName.Text;
  if aname='EDITORMOD.MOD' then exit(0);
  result:=1 or sres_nocheck;
  lext:=ExtractExt(aname);
  if (lext='.MOD') or
     (lext='.PAK') or
     (lext='.ZIP') then
  begin
    with TfmScan(aparam) do
      ProcessSingleMod(edDirName.Text+adir+aname);
  end
//  else if (UpCase(aname)='MOD.DAT') then
  else if (UpCase(aname)='MEDIA/') then
  begin
    with TfmScan(aparam) do
      if (adir='\') or (adir='/') then
        ProcessSingleMod(edDirName.Text)
      else
        ProcessSingleMod(edDirName.Text+adir);
  end
  else
    exit(0);
end;

procedure TfmScan.bbScanClick(Sender: TObject);
var
  lf:TfmGameVer;
  lp,i:integer;
  lpath,ldbname:string;
  ls:string[7];
begin
  if (rbDirToScan .Checked and (edDirName .Text='')) or
     (rbFileToScan.Checked and (edFileName.Text='')) then
  begin
    ShowMessage('Nothing choosed to scan');
    exit;
  end;

  if rbFileToScan.Checked then
  begin
    gamever:=RGPAKGetVersion(edFileName.Text);
  end
  else
   gamever:=verUnk;

  if not (gamever in [verTL1, verTL2]) then
  begin
    lf:=TfmGameVer.Create(self);
    lf.Classic:=true;
    lf.ShowModal;
    gamever:=lf.Version;
    lf.Free;
  end;

  memLog.Append('Preparing for scan as '+GetGameName(gamever));

  if      gamever=verTL1 then ldbname:=TL1DataBase
  else if gamever=verTL2 then ldbname:=TL2DataBase;

  if not RGOpenBase(db,ldbname,gamever) then
  begin
    memLog.Append('Can''t prepare database');
    exit;
  end;

  if rbDirToScan.Checked then
  begin
    if not (edDirName.Text[Length(edDirName.Text)] in ['/', '\']) then
      edDirName.Text:=edDirName.Text+'/';
    lp:=Length(edDirName.Text)-7;
    ls:='';
    if lp>0 then
    begin
      for i:=1 to 7 do
      begin
        if edDirName.Text[lp+i]='\' then
          ls:=ls+'/'
        else
          ls:=ls+UpCase(edDirName.Text[lp+i]);
      end;
    end;

    if ls='/MEDIA/' then
      lpath:=Copy(edDirName.Text,1,lp)
    else if DirectoryExists(edDirName.Text+'MEDIA/') then
      lpath:=edDirName.Text
    else
    begin
      memLog.Append('MEDIA folder not found');
      exit;
    end;

    MakeRGScan(lpath,'',['.PAK','.MOD','.ZIP','.DAT','.ADM'],nil,Self,@DoCheck);

  end
  else //if rbFileToScan then
    ProcessSingleMod(edFileName.Text);

  memLog.Append('Saving...');

  if not RGCloseBase(db,ldbname) then
    memLog.Append('Error while save database');
  memLog.Append('Done!');

end;

procedure TfmScan.cbUpdateAllChange(Sender: TObject);
begin
  cbAdds    .Enabled:=not cbUpdateAll.Checked;
  cbWardrobe.Enabled:=not cbUpdateAll.Checked;
  cbPets    .Enabled:=not cbUpdateAll.Checked;
  cbQuests  .Enabled:=not cbUpdateAll.Checked;
  cbStats   .Enabled:=not cbUpdateAll.Checked;
  cbRecipes .Enabled:=not cbUpdateAll.Checked;
  cbMobs    .Enabled:=not cbUpdateAll.Checked;
  cbItems   .Enabled:=not cbUpdateAll.Checked;
  cbProps   .Enabled:=not cbUpdateAll.Checked;
  cbSkills  .Enabled:=not cbUpdateAll.Checked;
  cbClasses .Enabled:=not cbUpdateAll.Checked;
end;

procedure TfmScan.FormCreate(Sender: TObject);
begin
  if not FileExists(TL2DataBase) then
    ShowMessage('TL2 Database file not found.'#13#10+
    'Better to use base game file scan first.');

  if not FileExists(TL1DataBase) then
    ShowMessage('TL1 Database file not found.'#13#10+
    'Better to use base game file scan first.');

  cbUpdateAllChange(cbUpdateAll);

  RGLog.OnAdd:=@AddToLog;
end;

procedure TfmScan.rbDirToScanChange(Sender: TObject);
begin
  edFileName.Enabled:=false;
  edDirName .Enabled:=true;
end;

procedure TfmScan.rbFileToScanChange(Sender: TObject);
begin
  edDirName .Enabled:=false;
  edFileName.Enabled:=true;
end;

end.
