unit TL2DataModule;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Forms,
  StdCtrls, Graphics, Menus;

type

  { TTL2DataModule }

  TTL2DataModule = class(TDataModule)
    mnuClosePage: TMenuItem;
    TL2ImageList: TImageList;
    procedure DataModuleCreate (Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private

  public
    TL2Font: TFont;
    TL2Popup: TPopupMenu;

  end;

var  TL2DM: TTL2DataModule;

function FillParamPopup(amemo:TMemo; const asrc:AnsiString):boolean;
function FillColorPopup(amemo:TMemo; const asrc:AnsiString):boolean;

//function CreateFileTab(const adata:TTL2Translation; aRef:integer; aOwner:TWinControl):TForm;

resourcestring
  rsSeveralRefs = 'This text presents in several (about %d) places.';
  rsNoRef       = 'Text don''t have any references';


implementation

uses
  TL2Text,
  rgglobal,
  rgpak,
  rgfile;

{$R *.lfm}

function MakeMethod(Data, Code:Pointer):TMethod;
begin
  Result.Data:=Data;
  Result.Code:=Code;
end;

{
  Application.QueueAsyncCall
  
  IN: menu mnuPopup; memo memTrans or memEdit directly
    selected text
  OUT: Fill* - boolean (now false); memo directly
    result text? how to get it from popup

}

procedure PopupParamChanged(Self:pointer; Sender:TObject);
var
  lEdit:tMemo;
begin
  lEdit:=TMemo((Sender as TMenuItem).Owner.Tag);
  lEdit.SelText:=Copy((Sender as TMenuItem).Caption,4);
end;

function FillParamPopup(amemo:TMemo; const asrc:AnsiString):boolean;
const
  maxparams=10;
var
  lPopItem:TMenuItem;
  params :array [0..maxparams-1] of String[31];
  i,lcnt,llen:integer;
begin
  result:=false;

  lcnt:=0;
  llen:=Length(asrc);
  i:=1;

  repeat
    if asrc[i]='[' then
    begin
      params[lcnt]:='';
      repeat
        params[lcnt]:=params[lcnt]+asrc[i];
        inc(i);
      until (i>llen) or (asrc[i]=']');
      if i<=llen then
      begin
        inc(i);
        params[lcnt]:=params[lcnt]+']';
        // for case of [[param]]
        if (i<=llen) and (asrc[i]=']') then
        begin
          params[lcnt]:=params[lcnt]+']';
          inc(i);
        end;
        inc(lcnt);
        if lcnt=maxparams then break;
      end;
    end
    else if asrc[i]='<' then
    begin
      params[lcnt]:='';
      repeat
        params[lcnt]:=params[lcnt]+asrc[i];
        inc(i);
      until (i>llen) or (asrc[i]='>');
      if i<=llen then
      begin
        inc(i);
        params[lcnt]:=params[lcnt]+'>';
        inc(lcnt);
        if lcnt=maxparams then break;
      end;
    end
    else
      inc(i);
  until i>llen;

  if lcnt=0 then exit;
  
  if lcnt=1 then
  begin
    amemo.SelText:=params[0];
  end
  else
  begin  
    if TL2DM.TL2Popup=nil then
      TL2DM.TL2Popup:=TPopupMenu.Create(nil)
    else
      TL2DM.TL2Popup.Items.Clear;
    TL2DM.TL2Popup.Tag:=IntPtr(amemo);
    for i:=0 to lcnt-1 do
    begin
      lPopItem:=TMenuItem.Create(TL2DM.TL2Popup);
      if i<9 then
        lPopItem.Caption:='&'+IntToStr(i+1)+' '+params[i]
      else
        lPopItem.Caption:='&0 '+params[i];
      lPopItem.OnClick:=TNotifyEvent(MakeMethod({nil}TL2DM.TL2Popup,@PopupParamChanged));
      TL2DM.TL2Popup.Items.Add(lPopItem);
    end;

    TL2DM.TL2Popup.PopUp;
  end;
end;

procedure PopupColorChanged(Self:pointer; Sender:TObject);
var
  lEdit:tMemo;
begin
  lEdit:=TMemo((Sender as TMenuItem).Owner.Tag);
  lEdit.SelText:=InsertColor(lEdit.SelText,Copy((Sender as TMenuItem).Caption,4));
end;

function FillColorPopup(amemo:TMemo; const asrc:AnsiString):boolean;
const
  maxcolors=10;
var
  lPopItem:TMenuItem;
  colors :array [0..maxcolors-1] of String[10]; //#124'cAARRGGBB', 10 times per text must be enough
  i,llcnt,lcnt,llen:integer;
begin
  result:=false;

  //-- Fill colors array
  lcnt:=0;
  llen:=Length(asrc)-10;
  i:=1;
  repeat
    if (asrc[i]=#124) then
    begin
      inc(i);
      if (asrc[i]='c') then
      begin
        inc(i);
        SetLength(colors[lcnt],10);
        colors[lcnt][ 1]:=#124;
        colors[lcnt][ 2]:='c';
        colors[lcnt][ 3]:=asrc[i]; inc(i);
        colors[lcnt][ 4]:=asrc[i]; inc(i);
        colors[lcnt][ 5]:=asrc[i]; inc(i);
        colors[lcnt][ 6]:=asrc[i]; inc(i);
        colors[lcnt][ 7]:=asrc[i]; inc(i);
        colors[lcnt][ 8]:=asrc[i]; inc(i);
        colors[lcnt][ 9]:=asrc[i]; inc(i);
        colors[lcnt][10]:=asrc[i]; inc(i);

        llcnt:=0;
        while llcnt<lcnt do
        begin
          if colors[lcnt]=colors[llcnt] then
            break;
          inc(llcnt);
        end;
        if llcnt=lcnt then
        begin
          inc(lcnt);
          if lcnt=maxcolors then break;
        end;
      end
      else
        inc(i);
    end
    else
      inc(i);
  until i>llen;

  if lcnt=0 then
    exit;

  //-- replace without confirmations if one color only
  if lcnt=1 then
  begin
    amemo.SelText:=InsertColor(amemo.SelText,colors[0]);
  end
  //-- Create and call menu if several colors
  else
  begin
    if TL2DM.TL2Popup=nil then
      TL2DM.TL2Popup:=TPopupMenu.Create(nil)
    else
      TL2DM.TL2Popup.Items.Clear;

    TL2DM.TL2Popup.Tag:=IntPtr(amemo);
    for i:=0 to lcnt-1 do
    begin
      lPopItem:=TMenuItem.Create(TL2DM.TL2Popup);
      if i<9 then
        lPopItem.Caption:='&'+IntToStr(i+1)+' '+colors[i]
      else
        lPopItem.Caption:='&0 '+colors[i];
      lPopItem.OnClick:=TNotifyEvent(MakeMethod({nil}TL2DM.TL2Popup,@PopupColorChanged));
      TL2DM.TL2Popup.Items.Add(lPopItem);
    end;

    TL2DM.TL2Popup.PopUp;
  end;
end;


//  TCloseEvent = procedure(Sender: TObject; var CloseAction: TCloseAction) of object;

procedure TabClose(dummy:pointer; Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction:=caFree;
end;
{
function CreateFileTab(const adata:TTL2Translation; aRef:integer; aOwner:TWinControl):TForm;
var
  lform:TForm;
  lmemo:TMemo;
  sl:TStringList;
  lp:TRGPAK;
  lbuf:PByte;
  lpw:PUnicodeChar;
  ls,lpath:AnsiString;
  i,lstart,lline,lpos:integer;
begin
  result:=nil;

  if aref<0 then exit;

  lpath:=adata.Refs.GetFile(aref); // no need to check for empty, must be filled always
  ls   :=adata.Refs.GetRoot(aref);

  // still need to differentiate directory and PAK
  if ls[Length(ls)]='/' then
  begin
    sl:=TStringList.Create;
    try
      sl.LoadFromFile(ls+lpath);
    except
      sl.Free;
      exit;
    end;
  end
  else
  begin
    lp:=TRGPAK.Create();
    sl:=nil;
    if lp.GetInfo(ls,piParse) then
    begin
      lpw:=nil;
      lbuf:=nil;
      i:=lp.UnpackFile(lpath,PByte(lbuf));
      if i>0 then
      begin
        if DecompileFile(lbuf,i,lpath,lpw) then
        begin
          sl:=TStringList.Create;
          sl.Text:=WideToStr(lpw);
          FreeMem(lbuf);
          FreeMem(lpw);
        end;
      end;
    end;
    lp.Free;
    if sl=nil then exit;
  end;

  lline:=adata.Refs.GetLine(aRef)-1;
  lstart:=0;
  for i:=0 to sl.Count-1 do
  begin
    sl[i]:=StringReplace(sl[i],#9,'  ',[rfReplaceAll]);
    if i<lline then inc(lstart,Length(sl[i])+2); // text+crlf
  end;

  lform:=TForm.Create(aOwner{(Self.Parent.Parent as TPageControl).AddTabSheet});
  lform.Parent:=aOwner;
  if aOwner<>nil then
  begin
    lform.BorderStyle:=bsNone;
    lform.Align      :=alClient;
  end
  else
  begin
    lform.OnClose:=TCloseEvent(MakeMethod(lform,@TabClose));
  end;
  lform.Visible:=true;     //!!!SetFocus works on visible control only

  lmemo:=tMemo.Create(lform);
  lmemo.Parent    :=lform;
  lmemo.Align     :=alClient;
  lmemo.WordWrap  :=False;
  lmemo.ReadOnly  :=True;
  lmemo.Scrollbars:=ssBoth;
  lmemo.Lines.Assign(sl);  // lmemo.Text:=sl.Text;
  lmemo.Visible   :=true;

  lpos:=0;
  if lline<=lmemo.Lines.Count then
  begin
    ls:=adata.Refs.GetTag(aRef);
    lpos:=Pos(ls+':',sl[lline]);
    if lpos>0 then
    begin
      lmemo.SelStart :=lstart+lpos-1;
      lmemo.SelLength:=Length(ls)+1;
    end;
  end;
  sl.Free;
  
  lmemo.SetFocus;          // works on visible control only

  result:=lform;
end;
}

procedure TTL2DataModule.DataModuleCreate(Sender: TObject);
begin
  TL2Font:=TFont.Create;
end;

procedure TTL2DataModule.DataModuleDestroy(Sender: TObject);
begin
  TL2Font.Free;
  TL2Popup.Free;
end;

end.
