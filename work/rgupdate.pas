{
  keep ref to pak/man or not?
}
unit RGUpdate;

interface

uses
  rgglobal;

implementation

uses
  rgpak;

const
  act_delete = 0;
  act_data   = 1;
  act_file   = 2;

type
  // 0 - delete; 1 = data; 2 - file
  TUpdateElement = record
    path :PWideChar;
    case act:integer of
      act_data: (
        data :PByte;
        usize:cardinal;
//        psize:cardinal;
      );
      act_file: (
        fileu:PWideChar
      );
  end;

type
  TRGUpdateList = object
  private
    FList  :array of TUpdateElement;
    FPak   :PPAKInfo;
    FIndex :array of integer;
    FCount :integer; // amount of real elements
    FLength:integer; // amount of used space

    procedure Sort;
    function GetElementCount:integer;
    function GetListLength:integer;
    function GetElement(i:integer):TUpdateElement;

    function  CreateElement(apath:PWideChar):integer;
    procedure ClearElement(idx:integer);
  public
    procedure Create;
    procedure SetPAK(apak:PPAKInfo);
    function  Apply(afile:PWideChar):integer;
    procedure Clear;
    procedure Remove(apath:PWideChar);
    procedure Reset (apath:PWideChar);
    procedure Add(afile:PWideChar; apath:PWideChar);
    procedure Add(adata:PByte; asize:cardinal; apath:PWideChar);
    procedure Use(adata:PByte; asize:cardinal; apath:PWideChar);
    function  Search(apath:PWideChar):integer;

    property  Count :integer read GetElementCount;
    property  Length:integer read GetListLength;
    property  Element[i:integer]:TUpdateElement read GetElement; default;
  end;


procedure TRGUpdateList.Create;
begin
  FCount :=0;
  FLength:=0;
  FList  :=nil; //??
  FPak   :=nil;
end;

procedure TRGUpdateList.SetPAK(apak:PPAKInfo);
begin
  FPak:=apak;
end;

function TRGUpdateList.Search(apath:PWideChar):integer;
var
  i,lcnt:integer;
begin
  result:=-1;
  lcnt:=FCount;
  if lcnt=0 then exit;

  for i:=0 to FLength-1 do
  begin
    if FList[i].path<>nil then
    begin
      if CompareWide(FList[i].path,apath)=0 then exit(i);
      dec(lcnt);
      if lcnt=0 then exit;
    end;
  end;
end;

function TRGUpdateList.CreateElement(apath:PWideChar):integer;
var
  i:integer;
begin
  i:=Search(apath);
  // Fount element
  if i>=0 then
  begin
    ClearElement(i);
  end
  else
  begin
    i:=0;
    // search for empty space
    while i<FLength do
    begin
      if FList[i].path=nil then break;
    end;
    if i=FLength then
    begin
      // check for unused list space at the end
      if FLength=system.Length(FList) then //!!!! expand list
      begin
        SetLength(FList,FLength+16);
      end;
      inc(FLength);
    end;
  end;
  result:=i;
end;

procedure TRGUpdateList.ClearElement(idx:integer);
begin
  if idx>=0 then
  begin
    case FList[idx].act of 
      act_data: FreeMem(FList[idx].data);
      act_file: FreeMem(FList[idx].fileu);
    end;
  end;
end;

procedure TRGUpdateList.Clear;
var
  i:integer;
begin
  for i:=0 to FLength-1 do
  begin
    if FList[i].path<>nil then
    begin
      FreeMem(FList[i].path); FList[i].path:=nil;
      ClearElement(i);
    end;
  end;
end;

procedure TRGUpdateList.Reset(apath:PWideChar);
var
  i:integer;
begin
  i:=Search(apath);
  if i>=0 then
  begin
    FreeMem(FList[i].path); FList[i].path:=nil;
    ClearElement(i);
    dec(FCount);
  end;
end;

procedure TRGUpdateList.Remove(apath:PWideChar);
begin
  FList[CreateElement(apath)].act:=act_delete;
end;

procedure TRGUpdateList.Use(adata:PByte; asize:cardinal; apath:PWideChar);
var
  i:integer;
begin
  i:=CreateElement(apath);
  FList[i].data :=adata;
  FList[i].usize:=asize;
  FList[i].act  :=act_data;
end;

procedure TRGUpdateList.Add(adata:PByte; asize:cardinal; apath:PWideChar);
var
  i:integer;
begin
  i:=CreateElement(apath);
  GetMem(FList[i].data,asize);
  move(adata^,FList[i].data^,asize);
  FList[i].usize:=asize;
  FList[i].act:=act_data;
end;

procedure TRGUpdateList.Add(afile:PWideChar; apath:PWideChar);
var
  i:integer;
begin
  i:=CreateElement(apath);
  FList[i].fileu:=CopyWide(afile);
  FList[i].act:=act_file;
end;

procedure TRGUpdateList.Sort;
begin
end;

function TRGUpdateList.GetElementCount:integer;
begin
  result:=FCount;
end;

function TRGUpdateList.GetListLength:integer;
begin
  result:=FLength;
end;

function TRGUpdateList.GetElement(i:integer):TUpdateElement;
begin
end;

function TRGUpdateList.Apply(afile:PWideChar):integer;
begin
  result:=-1;
end;


end.
