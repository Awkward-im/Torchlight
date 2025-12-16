{
  Unit for preview processing
}
{TODO: (Check!) Delete several files = set right selection (clear+set on current)}
{TODO: Soundpreview: replace Start and Stop buttons by one (move caption text to resourcestrings}
{TODO: imageset, info panel, checkbox to show as picture or as text. but format? DAT or XML?}
{TODO: 3d view, change texture by choosing file}
{TODO: preview bytes values as different types}
{TODO: make dump text/bytes search}
{TODO: change dump text area encoding}
{TODO: preview as dump by choice?}
{TODO: PreviewSource: autoformat if no block spaces. Add to synedit with line by line}
{TODO: save as for editor}

{TODO: make public preview list with autochanging, not rebuild at moment}
{TODO: notify if preview list was changed (new added, old closed)}
unit rgPreview;

interface

uses
  Graphics,
  Forms,
  rgglobal,
  rgctrl;


function MakePreview(var actrl:TRGController; aidx:integer):TForm;
procedure ClosePreviews (actrl:PRGController=nil);
function  GetPreviewList(actrl:PRGController=nil):TObjectDynArray;
procedure SetPreviewFont(const afont:TFont);
function  GetPreviewFont():TFont;


implementation

uses
  Classes,
  SysUtils,

  StdCtrls,

  RGFileType

  ,DMViewer
  ,rgvdump
  ,rgvimageset
  ,rgvmesh
  ,rgvlayout
  ,rgvsound
  ,rgvimage
  ,rgvtext
  ;

resourcestring
  rsSize            = 'Size';
  rsOffset          = 'Offset';
  rsTime            = 'Time';

function GetPreviewFont():TFont; inline;
begin
  if Viewer=nil then Viewer:=TViewer.Create(nil{Application.MainForm});
  result:=Viewer.Font;
end;

procedure SetPreviewFont(const afont:TFont); inline;
begin
  if Viewer=nil then Viewer:=TViewer.Create(nil{Application.MainForm});
  Viewer.Font.Assign(afont);
end;

function MakePreview(var actrl:TRGController; aidx:integer):TForm;
var
  lrec:TRGFullInfo;
  lblInfo1,lblInfo2:TLabel;
  ldir,lname,lext:string;
begin
  result:=nil;
  if aidx<0 then exit;
  if actrl.UpdateState(aidx)=stateDelete then exit;

  if Viewer=nil then Viewer:=TViewer.Create(nil{Application.MainForm});

  ldir :=WideToStr(actrl.PathOfFile(aidx));
  lname:=WideToStr(actrl.Files[aidx]^.Name);
  lext :=ExtractExt(lname);
  RGLog.Reserve('Processing '+ldir+lname);

  actrl.GetFullInfo(aidx,lrec);
  //if (lrec.offset=0) or (lrec.size_s=0) then exit;
{}
  if lrec.ftype=typeDirectory then exit;

  if (lrec.ftype and $FF) in [typeUnknown,typeFont,typeOther,typeFX] then
  begin
    if RGTypeExtIsText(lext) then
      result:=PreviewText(actrl,aidx)
    else
      result:=PreviewDump(actrl,aidx);
  end

  else if lrec.ftype=typeLayout then
  begin
{
    if GetLayoutVersion(FUData)=verUnk then
      result:=PreviewText(actrl,aidx)
    else
}
      result:=PreviewLayout(actrl,aidx);
  end

  else if lrec.ftype=typeImageset then
  begin
    result:=PreviewImageset(actrl,aidx);
  end

  // Text
  else if lrec.ftype=typeUI then result:=PreviewText(actrl,aidx)
{
  else if lrec.ftype=typeFX then
  begin
    if RGTypeExtIsText(lext) then
      result:=PreviewText(actrl,aidx)
    else
      result:=PreviewDump(actrl,aidx)
  end
}
  // DAT, RAW, ANIMATION, TEMPLATE
  else if (lrec.ftype and $FF)=typeData then result:=PreviewSource(actrl,aidx)

  // Image
  else if lrec.ftype=typeImage then result:=PreviewImage(actrl,aidx)

  // Models
  else if lrec.ftype=typeModel then
  begin
    if lext='.SKELETON' then
      result:=PreviewDump(actrl,aidx)
    else
      result:=PreviewModel(actrl,aidx);
  end

  // Sound
  else if lrec.ftype=typeSound then result:=PreviewSound(actrl,aidx)

  else
    result:=PreviewDump(actrl,aidx);
{}

  if result=nil then exit;

  result.Caption:=ldir+lname;

  with TBaseViewer(result) do
    if pnlInfo.ControlCount=0 then
//      if pnlInfo.ComponentCount=0 then
    begin
      lblInfo1:=TLabel.Create(result);
      lblInfo1.Parent:=pnlInfo;
      lblInfo1.Left  :=8;
      lblInfo1.Top   :=3;
  //    lblInfo1.AutoSize:=true;

      lblInfo2:=TLabel.Create(result);
      lblInfo2.Parent:=pnlInfo;
      lblInfo2.Left  :=8;
      lblInfo2.Top   :=19;

      lblInfo1.Caption:=rsSize+': '+IntToStr(lrec.size_s)+'; '+
                        rsOffset+': '+'0x'+HexStr(lrec.offset,8);
      try
        lblInfo2.Caption:=rsTime+': '+DateTimeToStr(FileTimeToDateTime(lrec.ftime));
      except
        lblInfo2.Caption:=rsTime+': '+'0x'+HexStr(lrec.ftime,16);
      end;
    end;
end;

procedure ClosePreviews(actrl:PRGController=nil);
var
  i:integer;
begin
  if Viewer<>nil then
    for i:=Viewer.ComponentCount-1 downto 0 do
    begin
      if Viewer.Components[i] is TBaseViewer then
        if (actrl=nil) or (TBaseViewer(Viewer.Components[i]).ctrl=actrl) then
          (Viewer.Components[i] as TForm).Free;
    end;
end;

function GetPreviewList(actrl:PRGController=nil):TObjectDynArray;
var
  i,lcnt:integer;
begin
  result:=nil;

  if Viewer<>nil then
  begin
    lcnt:=0;
    for i:=Viewer.ComponentCount-1 downto 0 do
    begin
      if Viewer.Components[i] is TBaseViewer then
        if (actrl=nil) or (TBaseViewer(Viewer.Components[i]).ctrl=actrl) then
          inc(lcnt);
    end;
    if lcnt>0 then
    begin
      SetLength(result,lcnt);
      for i:=Viewer.ComponentCount-1 downto 0 do
      begin
        if Viewer.Components[i] is TBaseViewer then
          if (actrl=nil) or (TBaseViewer(Viewer.Components[i]).ctrl=actrl) then
          begin
            dec(lcnt);
            result[lcnt]:=Viewer.Components[i];
          end;
      end;
    end;
  end;
end;

finalization
  ClosePreviews();
end.
