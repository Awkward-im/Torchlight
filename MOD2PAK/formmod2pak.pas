unit formmod2pak;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons;

type

  { TfmMod2Pak }

  TfmMod2Pak = class(TForm)
    bbFile: TBitBtn;
    bbClose: TBitBtn;
    bbOrder: TBitBtn;
    memHelp: TMemo;
    memLog: TMemo;
    procedure bbFileClick(Sender: TObject);
    procedure bbOrderClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
  private
    FLastDir:string;
  public

  end;

var
  fmMod2Pak: TfmMod2Pak;

function Split(const fin,fout:string):boolean;


implementation

{$R *.lfm}

uses
  formReorder,
  rgglobal,
  TL2Mod;

function Split(const fin,fout:string):boolean;
var
  ffin,ffout: file of byte;
  mi:TTL2ModInfo;
  ltmp:pbyte;
  lsize,fsize:integer;
begin
  result:=false;

  if ReadModInfo(PChar(fin),mi) then
  begin
    Assign(ffin,fin);
    Reset(ffin);
    fsize:=FileSize(ffin);

    Assign(ffout,fout);
    Rewrite(ffout);
    Seek(ffin,mi.offData);
    lsize:=mi.offMan-mi.offData;
    GetMem    (      ltmp ,lsize);
    BlockRead (ffin ,ltmp^,lsize);
    BlockWrite(ffout,ltmp^,lsize);
    Close(ffout);

    Assign(ffout,fout+'.MAN');
    Rewrite(ffout);
    Seek(ffin,mi.offMan);
    fsize:=fsize-mi.offMan;
    if fsize>lsize then
      ReallocMem(ltmp,fsize);
    BlockRead (ffin ,ltmp^,fsize);
    BlockWrite(ffout,ltmp^,fsize);
    FreeMem(ltmp);
    Close(ffout);

    Close(ffin);

    result:=true;
  end;
  ClearModInfo(mi);
end;

{ TfmMod2Pak }

procedure TfmMod2Pak.FormDropFiles(Sender: TObject; const FileNames: array of string);
var
  ldir,ls,lso:string;
  ldlg:TSelectDirectoryDialog;
  i:integer;
begin
  ldir:='';

  ldlg:=TSelectDirectoryDialog.Create(nil);
  try
    ldlg.InitialDir:=ExtractFilePath(FileNames[0]);
    ldlg.FileName  :='';
    ldlg.Options   :=[ofEnableSizing,ofPathMustExist];
    if ldlg.Execute then ldir:=ldlg.FileName;
  finally
    ldlg.Free;
  end;

  for i:=0 to High(FileNames) do
  begin
    ls:=FileNames[i];
    if Pos('.MOD',UpCase(ls))=(Length(ls)-3) then
    begin
      lso:=ChangeFileExt(ls,'.PAK');
      if ldir<>'' then
        lso:=ldir+'\'+ExtractFileName(lso);
      if Split(ls,lso) then
      begin
        memLog.Append('File '+ls+' converted to '+lso);
        FLastDir:=ExtractFilePath(lso);
      end;
    end;
  end;
end;

procedure TfmMod2Pak.bbFileClick(Sender: TObject);
var
  dlgo:TOpenDialog;
  ldlg:TSelectDirectoryDialog;
  ldir,ls,lso:string;
  i:integer;
begin
  ldir:='';
  dlgo:=TOpenDialog.Create(nil);
  try
    dlgo.DefaultExt:='.MOD';
    dlgo.Filter    :='MOD files|*.MOD';
    dlgo.Title     :='Choose MOD files to convert';
    dlgo.Options   :=[ofAllowMultiSelect];
    if (dlgo.Execute) and (dlgo.Files.Count>0) then
    begin
      ldlg:=TSelectDirectoryDialog.Create(nil);
      try
        ldlg.InitialDir:=ExtractFilePath(dlgo.Files[0]);
        ldlg.FileName  :='';
        ldlg.Options   :=[ofEnableSizing,ofPathMustExist];
        if ldlg.Execute then ldir:=ldlg.FileName;
      finally
        ldlg.Free;
      end;

      for i:=0 to dlgo.Files.Count-1 do
      begin
        ls:=dlgo.Files[i];
        if Pos('.MOD',UpCase(ls))=(Length(ls)-3) then
        begin
          lso:=ChangeFileExt(ls,'.PAK');
          if ldir<>'' then
            lso:=ldir+'\'+ExtractFileName(lso);
          if Split(ls,lso) then
          begin
            memLog.Append('File '+ls+' converted to '+lso);
            FLastDir:=ExtractFilePath(lso);
          end;
        end;
      end;
    end;
  finally
    dlgo.Free;
  end;

end;

procedure TfmMod2Pak.bbOrderClick(Sender: TObject);
begin
  with TfmReorder.Create(Self, FLastDir) do ShowModal;
end;

procedure TfmMod2Pak.FormCreate(Sender: TObject);
var
  ldir,ls,lso:string;
  ldlg:TSelectDirectoryDialog;
  i:integer;
begin
  if ParamCount()>0 then
  begin
    ldir:='';

    ldlg:=TSelectDirectoryDialog.Create(nil);
    try
      ldlg.InitialDir:=ExtractFilePath(ParamStr(1));
      ldlg.FileName  :='';
      ldlg.Options   :=[ofEnableSizing,ofPathMustExist];
      if ldlg.Execute then ldir:=ldlg.FileName;
    finally
      ldlg.Free;
    end;

    for i:=0 to ParamCount()-1 do
    begin
      ls:=ParamStr(i);
      if Pos('.MOD',UpCase(ls))=(Length(ls)-3) then
      begin
        lso:=ChangeFileExt(ls,'.PAK');
        if ldir<>'' then
          lso:=ldir+'\'+ExtractFileName(lso);
        if Split(ls,lso) then
        begin
          memLog.Append('File '+ls+' converted to '+lso);
          FLastDir:=ExtractFilePath(lso);
        end;
      end;
    end;
  end;
end;

end.

