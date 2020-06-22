unit formModList;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TfmModList }

  TfmModList = class(TForm)
    lbBound: TListBox;
    lbRecent: TListBox;
    lbFull: TListBox;
  private

  public

  end;

var
  fmModList: TfmModList;

implementation

{$R *.lfm}

{ TfmModList }


end.

