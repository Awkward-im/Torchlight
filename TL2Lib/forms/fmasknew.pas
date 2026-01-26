{
mrNone = 0;
mrOK = mrNone + 1;
mrCancel = mrNone + 2;
mrAbort = mrNone + 3;
mrRetry = mrNone + 4;
mrIgnore = mrNone + 5;
mrYes = mrNone + 6;
mrNo = mrNone + 7;
mrAll = mrNone + 8;
mrNoToAll = mrNone + 9;
mrYesToAll = mrNone + 10;
mrClose = mrNone + 11;
mrContinue = mrNone + 12;
mrTryAgain = mrNone + 13;
}
unit fmAskNew;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  RGGlobal, RGCtrl;

type

  { TAskForm }

  TAskForm = class(TForm)
    bbSkip     : TBitBtn;
    bbOverwrite: TBitBtn;
    bbCompare  : TBitBtn;
    bbRename   : TBitBtn;
    bbSaveAs   : TBitBtn;
    bbStop     : TBitBtn;
    cbForAll: TCheckBox;
    lblFileName  : TLabel;
    lblNewSize   : TLabel;
    lblNewSizeNum: TLabel;
    lblOldSize   : TLabel;
    lblOldSizeNum: TLabel;
  private

  public
    constructor Create(const fname:string; aoldsize,anewsize:integer{; amode:integer}); overload;
    constructor Create(
                aSrcCtrl:PRGController; aSrcIdx:integer;
                aDstCtrl:PRGController; aDstIdx:integer); overload;
    function ModalToAction(aresult: integer): TRGDoubleAction;
  end;

var
  AskForm: TAskForm;

implementation

{$R *.lfm}

uses
  RGFileType;

constructor TAskForm.Create(const fname:string; aoldsize,anewsize:integer{; amode:integer}); overload;
var
  lext:string;
begin
  Create(nil);

  lext:=ExtractExt(fname);
  bbCompare.Visible:=
      (lext='.DAT') or
      (lext='.TEMPLATE') or
      (lext='.HIE') or
      (lext='.LAYOUT') or
      (lext='.ANIMATION') or
      (lext='.WDAT');
  lblFileName.Caption:=fname;
  lblOldSizeNum.Caption:=IntToStr(aoldsize);
  lblNewSizeNum.Caption:=IntToStr(anewsize);

end;

constructor TAskForm.Create(
    aSrcCtrl:PRGController; aSrcIdx:integer;
    aDstCtrl:PRGController; aDstIdx:integer); overload;
var
  ls:AnsiString;
  ltype:integer;
begin
  Create(nil);

  ltype:=aSrcCtrl^.Files[aSrcIdx]^.ftype;
  bbCompare.Visible:=(ltype=typeData) or (ltype=typeLayout);
  lblFileName.Caption:=FastWideToStr(aDstCtrl^.PathOfFile(aDstIdx))+
                       FastWideToStr(aDstCtrl^.NameOfFile(aDstIdx));
  with aSrcCtrl^.Files[aSrcIdx]^ do
  begin
    ls:='';
    if ftime<>0 then
    begin
      try
        ls:=' '+DateTimeToStr(FileTimeToDateTime(ftime));
      except
      end;
    end;
    lblOldSizeNum.Caption:=IntToStr(size)+ls;
  end;

  with aDstCtrl^.Files[aDstIdx]^ do
  begin
    ls:='';
    if ftime<>0 then
    begin
      try
        ls:=' '+DateTimeToStr(FileTimeToDateTime(ftime));
      except
      end;
    end;
    lblNewSizeNum.Caption:=IntToStr(size)+ls;
  end;
end;

function TAskForm.ModalToAction(aresult:integer):TRGDoubleAction;
begin
  case aresult of
    mrOk    : if cbForAll.Checked then result:=da_overwriteall else result:=da_overwrite;
    mrCancel: result:=da_stop;
    mrRetry : result:=da_compare;
    mrIgnore: if cbForAll.Checked then result:=da_skipall      else result:=da_skip;
    mrYes   : result:=da_renameold;
    mrNo    : result:=da_saveas;
  end;
end;

end.

