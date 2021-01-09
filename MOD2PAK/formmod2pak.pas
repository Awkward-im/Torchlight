unit formMod2Pak;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  EditBtn;

type

  { TfmMod2Pak }

  TfmMod2Pak = class(TForm)
    bbAdd: TBitBtn;
    bbClose: TBitBtn;
    bbDelete: TBitBtn;
    bbApply: TBitBtn;
    deGameDir: TDirectoryEdit;
    ImageList: TImageList;
    lblDirNote: TLabel;
    lblDescr: TLabel;
    lblDirHint: TLabel;
    lbReserve: TListBox;
    lbActive: TListBox;
    memDescription: TMemo;
    sbActivate: TSpeedButton;
    sbDeactivate: TSpeedButton;
    sbUp: TSpeedButton;
    sbDown: TSpeedButton;
    stAdd: TStaticText;
    stReserve: TStaticText;
    stActive: TStaticText;
    procedure bbApplyClick(Sender: TObject);
    procedure bbDeleteClick(Sender: TObject);
    procedure bbAddClick(Sender: TObject);
    procedure deGameDirAcceptDirectory(Sender: TObject; var Value: String);
    procedure FormCreate(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
    procedure lbActiveClick(Sender: TObject);
    procedure lbReserveClick(Sender: TObject);
    procedure sbActivateClick(Sender: TObject);
    procedure sbDeactivateClick(Sender: TObject);
    procedure sbDownClick(Sender: TObject);
    procedure sbUpClick(Sender: TObject);
  private

    procedure FillList(const adir: string);
    procedure ShowDescr(const fname: string);
    function Split(const fin: string): boolean;

  public

  end;

var
  fmMod2Pak: TfmMod2Pak;

implementation

{$R *.lfm}

uses
  rgglobal,
  TL2Mod;

var
  fdtimes:integer;
  adtimes:array [0..99] of int64;

{ TfmMod2Pak }

procedure TfmMod2Pak.bbApplyClick(Sender: TObject);
var
  sr:TSearchRec;
  sl:TStringList;
  ldir,ls,lext:string;
  ldate:TDateTime;
  i,j,idx:integer;
begin
  ldir:=deGameDir.Text+'\PAKS\';
  sl:=TStringList.Create();
  if FindFirst(ldir+'*.PA?',faAnyFile,sr)=0 then
  begin
    repeat
      if UpCase(sr.Name)<>'DATA.PAK' then
        sl.Add(UpCase(sr.Name));
    until FindNext(sr)<>0;
  end;
  FindClose(sr);

  for i:=0 to sl.Count-1 do
  begin
    idx:=-1;
    lext:=ExtractFileExt(sl[i]);
    ls:=ExtractFilenameOnly(sl[i]);

    // process active files
    if lext='.PAK' then
    begin
      // already active
      for j:=0 to lbActive.Count-1 do
      begin
        if lbActive.Items[j]=ls then
        begin
          idx:=j;
          break;
        end;
      end;
      // search in reserved
      if idx<0 then
        for j:=0 to lbReserve.Count-1 do
        begin
          if lbReserve.Items[j]=ls then
          begin
            RenameFile(ldir+ls+'.PAK'    ,ldir+ls+'.PA_');
            RenameFile(ldir+ls+'.PAK.MAN',ldir+ls+'.PAK.MA_');
            idx:=j;
            break;
          end;
        end;
      if idx<0 then
      begin
        DeleteFile(ldir+ls+'.PAK');
        DeleteFile(ldir+ls+'.PAK.MAN');
        DeleteFile(ldir+ls+'.DAT');
      end;
    end

    // process reserved files
    else// if lext='.PA_' then
    begin
      // already reserved
      for j:=0 to lbReserve.Count-1 do
      begin
        if lbReserve.Items[j]=ls then
        begin
          idx:=j;
          break;
        end;
      end;
      //search in active
      if idx<0 then
        for j:=0 to lbActive.Count-1 do
        begin
          if lbActive.Items[j]=ls then
          begin
            RenameFile(ldir+ls+'.PA_'    ,ldir+ls+'.PAK');
            RenameFile(ldir+ls+'.PAK.MA_',ldir+ls+'.PAK.MAN');
            idx:=j;
            break;
          end;
        end;
      if idx<0 then
      begin
        DeleteFile(ldir+ls+'.PA_');
        DeleteFile(ldir+ls+'.PAK.MA_');
        DeleteFile(ldir+ls+'.DAT');
      end;
    end;
  end;

  // Active date changes
  ldate:=Now();
  for i:=0 to lbActive.Count-1 do
  begin
    ls:=lbActive.Items[i];
//  DATE ORDER IS FROM OLD TO NEW
    FileSetDate(ldir+ls+'.PAK'    ,ldate-lbActive.Count+i);
    FileSetDate(ldir+ls+'.PAK.MAN',ldate-lbActive.Count+i);
  end;

  sl.Free;

  bbApply.Enabled:=false;
end;

function MyFileSort(List: TStringList; Index1, Index2: Integer): Integer;
begin
  if adtimes[UIntPtr(List.Objects[Index1])]>adtimes[UIntPtr(List.Objects[Index2])] then
    result:=1
  else
    result:=-1;
end;

procedure TfmMod2Pak.FillList(const adir:string);
var
  sr:TSearchRec;
  ft1,ft2:Int64;
  sl:TStringList;
  ls,ldir:string;
  i:integer;
begin
  lbReserve.Clear;
  lbActive.Clear;

  if adir<>'' then
  begin
    ldir:=adir+'\PAKS\';
    // Inactive PAK files
    if FindFirst(ldir+'*.PA_',faAnyFile,sr)=0 then
    begin
      repeat
        ls:=ExtractFilenameOnly(sr.Name);
        ft1:=-1;
        if FileExists(ldir+ls+'.PAK') then
        begin
          ft1:=FileAge(ldir+sr.Name);
          ft2:=FileAge(ldir+ls+'.PAK');
          if ft1>ft2 then
          begin
            ft1:=-1;
            DeleteFile(ldir+ls+'.PAK');
            DeleteFile(ldir+ls+'.PAK.MAN');
          end
          else
          begin
            DeleteFile(ldir+sr.Name);
            DeleteFile(ldir+ls+'.PAK.MA_');
          end;
        end;
        // if need to add reserved
        if ft1<0 then
        begin
          if FileExists(ldir+ls+'.PAK.MA_') then
          begin
            lbReserve.AddItem(UpCase(ls),nil);
          end
          else
            ; //!! MAN file not found
        end;
      until FindNext(sr)<>0;
      FindClose(sr);
    end;

    // Active PAK files
    sl:=TStringList.Create;
    fdtimes:=0;
    if FindFirst(adir+'\PAKS\*.PAK',faAnyFile,sr)=0 then
    begin
      repeat
        if Upcase(sr.Name)<>'DATA.PAK' then
        begin
          if FileExists(adir+'\PAKS\'+sr.Name+'.MAN') then
          begin
            adtimes[fdtimes]:=sr.Time;
            inc(fdtimes);
            sl.AddObject(UpCase(ExtractFilenameOnly(sr.Name)),TObject(UIntPtr(fdtimes)));
          end
          else
            ; //!! MAN file not found
        end;
      until FindNext(sr)<>0;
      FindClose(sr);
      sl.CustomSort(@MyFileSort);
    end;
    for i:=0 to sl.Count-1 do
      lbActive.AddItem(sl[i],nil);
    sl.Free;
  end;
  
  sbActivate.Enabled:=lbReserve.Count>0;
  bbDelete  .Enabled:=lbReserve.Count>0;
  if lbReserve.Count>0 then
    lbReserve.ItemIndex:=0;
  lbReserveClick(Self);

  sbDeactivate.Enabled:=lbActive.Count>0;
  if lbActive.Count>0 then
    lbActive.ItemIndex:=0;
  lbActiveClick(Self);

  bbAdd  .Enabled:=adir<>'';
//  bbApply.Enabled:=adir<>'';
end;

procedure TfmMod2Pak.deGameDirAcceptDirectory(Sender: TObject; var Value: String);
begin
{$PUSH}
{$I-}
  if not DirectoryExists(Value+'\PAKS') then
    MkDir(Value+'\PAKS');
{$POP}
  FillList(Value);
end;

function TfmMod2Pak.Split(const fin:string):boolean;
var
  ffin,ffout: file of byte;
  mi:TTL2ModInfo;
  lfin,ldir:string;
  ltmp:pbyte;
  lsize,fsize,i,idx:integer;
begin
  result:=false;

  if Pos('.MOD',UpCase(fin))=(Length(fin)-3) then
  begin
    if ReadModInfo(PChar(fin),mi) then
    begin
      ldir:=deGameDir.Text+'\PAKS\';
      lfin:=ExtractFileNameOnly(fin);

      AssignFile(ffin,fin);
      Reset(ffin);
      fsize:=FileSize(ffin);

      // PAK file
      AssignFile(ffout,ldir+lfin+'.PA_');
      Rewrite(ffout);
      Seek(ffin,mi.offData);
      lsize:=mi.offMan-mi.offData;
      GetMem    (      ltmp ,lsize);
      BlockRead (ffin ,ltmp^,lsize);
      BlockWrite(ffout,ltmp^,lsize);
      CloseFile(ffout);

      // MAN file
      AssignFile(ffout,ldir+lfin+'.PAK.MA_');
      Rewrite(ffout);
      Seek(ffin,mi.offMan);
      fsize:=fsize-mi.offMan;
      if fsize>lsize then
        ReallocMem(ltmp,fsize);
      BlockRead (ffin ,ltmp^,fsize);
      BlockWrite(ffout,ltmp^,fsize);
      FreeMem(ltmp);
      CloseFile(ffout);

      CloseFile(ffin);

      // DAT file
      SaveModConfiguration(mi,PChar(ldir+lfin+'.DAT'));

      // List: skip if in list already
      idx:=-1;
      for i:=0 to lbActive.Count-1 do
      begin
        if lbActive.Items[i]=lfin then
        begin
          idx:=i;
          break;
        end;
      end;
      if idx<0 then
        for i:=0 to lbReserve.Count-1 do
        begin
          if lbReserve.Items[i]=lfin then
          begin
            idx:=i;
            break;
          end;
        end;
      if idx<0 then
      begin
        lbReserve.AddItem(lfin,nil);
        bbDelete  .Enabled:=true;
        sbActivate.Enabled:=true;
        if lbReserve.Count=1 then
        begin
          lbReserve.ItemIndex:=0;
          lbReserveClick(Self);
        end;
      end;

      result:=true;
      bbApply.Enabled:=true;
    end;
    ClearModInfo(mi);
  end;
end;

procedure TfmMod2Pak.FormDropFiles(Sender: TObject; const FileNames: array of string);
var
  i:integer;
begin
  for i:=0 to High(FileNames) do
  begin
    Split(FileNames[i]);
  end;
end;

procedure TfmMod2Pak.bbAddClick(Sender: TObject);
var
  dlgo:TOpenDialog;
  i:integer;
begin
  dlgo:=TOpenDialog.Create(nil);
  try
    dlgo.DefaultExt:='.MOD';
    dlgo.Filter    :='MOD files|*.MOD';
    dlgo.Title     :='Choose MOD files to convert';
    dlgo.Options   :=[ofAllowMultiSelect];
    if (dlgo.Execute) and (dlgo.Files.Count>0) then
    begin
      for i:=0 to dlgo.Files.Count-1 do
      begin
        Split(dlgo.Files[i]);
      end;
    end;
  finally
    dlgo.Free;
  end;
end;

procedure TfmMod2Pak.bbDeleteClick(Sender: TObject);
begin
  lbReserve.DeleteSelected;
  bbDelete.Enabled:=lbReserve.Count>0;
  bbApply.Enabled:=true;
end;

procedure TfmMod2Pak.sbActivateClick(Sender: TObject);
begin
  lbActive.AddItem(lbReserve.Items[lbReserve.ItemIndex],nil);
  lbReserve.DeleteSelected;
  lbActive.ItemIndex:=lbActive.Count-1;

  bbDelete    .Enabled:=lbReserve.Count>0;
  sbActivate  .Enabled:=lbReserve.Count>0;
  sbDeactivate.Enabled:=true;
  lbActiveClick(Self);

  bbApply.Enabled:=true;
end;

procedure TfmMod2Pak.sbDeactivateClick(Sender: TObject);
begin
  lbReserve.AddItem(lbActive.Items[lbActive.ItemIndex],nil);
  lbActive.DeleteSelected;
  lbReserve.ItemIndex:=lbReserve.Count-1;

  bbDelete    .Enabled:=true;
  sbActivate  .Enabled:=true;
  sbDeactivate.Enabled:=lbActive.Count>0;

  bbApply.Enabled:=true;
end;

procedure TfmMod2Pak.ShowDescr(const fname:string);
var
  mi:TTL2ModInfo;
begin
  memDescription.Clear;
  if LoadModConfiguration(PChar(deGameDir.Text+'\PAKS\'+fname+'.DAT'),mi) then
  begin
    memDescription.Append('Name: '       +String(WideString(mi.title)));
    memDescription.Append('Author: '     +String(WideString(mi.author)));
    memDescription.Append('Description: '+String(WideString(mi.descr)));
    ClearModInfo(mi);
  end;
end;

procedure TfmMod2Pak.lbActiveClick(Sender: TObject);
begin
  sbUp  .Enabled:=lbActive.ItemIndex>0;
  sbDown.Enabled:=(lbActive.ItemIndex>=0) and (lbActive.ItemIndex<(lbActive.Count-1));

  if lbActive.ItemIndex>=0 then
    ShowDescr(lbActive.Items[lbActive.ItemIndex]);
end;

procedure TfmMod2Pak.lbReserveClick(Sender: TObject);
begin
  if lbReserve.ItemIndex>=0 then
    ShowDescr(lbReserve.Items[lbReserve.ItemIndex]);
end;

procedure TfmMod2Pak.sbDownClick(Sender: TObject);
var
  lidx:integer;
begin
  lidx:=lbActive.ItemIndex;
  if (lidx>=0) and (lidx<(lbActive.Count-1)) then
  begin
    lbActive.Items.Move(lidx,lidx+1);
    lbActive.ItemIndex:=lidx+1;
    lbActiveClick(Sender);

    bbApply.Enabled:=true;
  end;
end;

procedure TfmMod2Pak.sbUpClick(Sender: TObject);
var
  lidx:integer;
begin
  lidx:=lbActive.ItemIndex;
  if lidx>0 then
  begin
    lbActive.Items.Move(lidx,lidx-1);
    lbActive.ItemIndex:=lidx-1;
    lbActiveClick(Sender);

    bbApply.Enabled:=true;
  end;
end;

procedure TfmMod2Pak.FormCreate(Sender: TObject);
var
  ldir:string;
begin
  ldir:=GetCurrentDir();
  if FileExists(ldir+'\PAKS\DATA.PAK') then
  begin
    deGameDir.Text:=ldir;
    FillList(ldir);
  end;
end;

end.
