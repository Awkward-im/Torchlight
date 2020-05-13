unit TL2DataModule;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls,
  Graphics;

type

  { TTL2DataModule }

  TTL2DataModule = class(TDataModule)
    TL2ImageList: TImageList;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private

  public
    TL2Font: TFont;

  end;

var  TL2DM: TTL2DataModule;

function RemoveColor(const textin:AnsiString; var textout:AnsiString):boolean;
function InsertColor(const aselected, acolor:AnsiString):AnsiString;


implementation

{$R *.lfm}

function InsertColor(const aselected, acolor:AnsiString):AnsiString;
var
  ls:AnsiString;
  l:integer;
begin
  if aselected<>'' then
  begin
    ls:=aselected;
    l:=Length(ls);
    if ((l<2  ) or (ls[l-1]<>'|') or (ls[l]<>'u')) and
       ((l<>10) or (ls[  1]<>'|') or (ls[2]<>'c')) then
      ls:=ls+'|u';
    if (l<10) or (ls[1]<>'|') or (ls[2]<>'c') then
      ls:=acolor+ls
    else
    begin
      ls[ 3]:=acolor[ 3];
      ls[ 4]:=acolor[ 4];
      ls[ 5]:=acolor[ 5];
      ls[ 6]:=acolor[ 6];
      ls[ 7]:=acolor[ 7];
      ls[ 8]:=acolor[ 8];
      ls[ 9]:=acolor[ 9];
      ls[10]:=acolor[10];
    end;
    result:=ls;
  end
  else
    result:=acolor;
end;

function RemoveColor(const textin:AnsiString; var textout:AnsiString):boolean;
var
  ls:AnsiString;
  i,j:integer;
begin
  result:=false;
  i:=1;
  j:=1;
  SetLength(ls,Length(textin));
  while i<=Length(textin) do
  begin
    if textin[i]<>'|' then
    begin
      ls[j]:=textin[i];
      inc(i);
      inc(j);
    end
    else
    begin
      result:=true;
      inc(i);
      if      textin[i]='u' then inc(i)
      else if textin[i]='c' then inc(i,9);
    end;
  end;
  SetLength(ls,j);
  textout:=ls;
end;

{ TTL2DataModule }

procedure TTL2DataModule.DataModuleCreate(Sender: TObject);
begin
  TL2Font:=TFont.Create;
end;

procedure TTL2DataModule.DataModuleDestroy(Sender: TObject);
begin
  TL2Font.Free;
end;

end.
