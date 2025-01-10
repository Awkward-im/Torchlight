{
  change prop content
  check in event, changed or not.
  if was not in node, add, else find and change
  (check modified flag)
}
{TODO: Checkbox for hide "default" values in ValueEditor}
{TODO: bool combo is for choose only, not text edit. Vector the same}
{TODO: label to show and combobox to choose game version (dict, panel view) on-the-fly}
{TODO: Check and implement Timeline and Logic Group editors (maybe as text only)}

unit fmLayoutEdit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, ValEdit, Grids, Menus, ActnList, SynEdit, SynHighlighterT,
  rgdictlayout, Types;

type

  { TformLayoutEdit }

  TFormLayoutEdit = class(TForm)
    actTreeRenameNode: TAction;
    actTreeDeleteNode: TAction;
    alLayEdit: TActionList;
    cbTxtPreview: TCheckBox;
    ilObjIcons: TImageList;
    memHelp: TMemo;
    miRenameNode: TMenuItem;
    miAddNode: TMenuItem;
    miDeleteNode: TMenuItem;
    pnlTopLeft: TPanel;
    pnlHelp: TPanel;
    pnlPropEdit: TPanel;
    pnlTree: TPanel;
    pnlProps: TPanel;
    mnuTree: TPopupMenu;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    SynEdit: TSynEdit;
    tvLayout: TTreeView;
    veProp: TValueListEditor;
    procedure actTreeDeleteNodeExecute(Sender: TObject);
    procedure actTreeRenameNodeExecute(Sender: TObject);
    procedure cbTxtPreviewChange(Sender: TObject);
    procedure tvLayoutContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure tvLayoutSelectionChanged(Sender: TObject);
    procedure vePropButtonClick(Sender: TObject; aCol, aRow: Integer);
    procedure vePropSelection(Sender: TObject; aCol, aRow: Integer);
    procedure vePropValidateEntry(Sender: TObject; aCol, aRow: Integer;
      const OldValue: string; var NewValue: String);
  private
    FRoot:pointer;
    PopupNode: TTreeNode;
    info:TRGObject;
    hostinfo:TRGObject;
    slLogic:TStringList;
    SynTSyn: TSynTSyn;
    SpecObject:boolean;

    function AddBranch(aroot: TTreeNode; anode: pointer): TTreeNode;
    procedure ClearPanel;
    function CreateLayoutNode(aid: dword; aparent: pointer): pointer;
    function CreateLayoutNode(aid: dword; aparentid: Int64): pointer;
    function GetImageFromType(aicon: PWideChar): integer;
    function PropCheck(aprop: PAnsiChar): boolean;
    procedure SaveEdited(anode: pointer);
    function SetPropValue(arow: integer; const aval: string): boolean;
    function BuildPanel(anode:pointer):integer;
    procedure BuildMenu;
    procedure DoAddNode(Sender: TObject);
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure Clear;

    function BuildTree(adata:PByte; aver:integer):integer;
    function GetFile(out abuf: PByte; aver: integer): integer;
  end;

var
  formLayoutEdit: TFormLayoutEdit;


implementation

{$R *.lfm}

uses
  Buttons,
  SpinEx,
  rgglobal,
  rgIO.Layout,
  rgIO.Text,
  rgnode;

resourcestring
  rsDefault     = '- default -';
  rsUndefined   = 'UNDEFINED';
  rsTextPreview = 'This is text preview without children nodes.'+
                  ' You can select child from tree.';
  rsAlter       = 'If property name marked as unsupported but have space or underscore,'+
                  ' try to switch them.';
  rsVersion     = 'WARNING!'#13#10'This layout file version differs from current project version.';
  rsUnsupObj    = 'This object is unsupported in current project version.';
  rsNewNameCap  = 'Change name of ';
  rsNewName     = 'Enter new name';

constructor TFormLayoutEdit.Create(aOwner: TComponent);
begin
  inherited Create(AOwner);

  info.Init;
  hostinfo.Init;
  slLogic:=TStringList.Create;
  slLogic.Add('False');
  slLogic.Add('True');

  SynTSyn:=TSynTSyn.Create(Self);
  SynEdit.Highlighter:=SynTSyn;
  FRoot:=nil;
end;

procedure TFormLayoutEdit.Clear;
begin
  if FRoot<>nil then DeleteNode(FRoot);
end;

destructor TFormLayoutEdit.Destroy;
begin
  Clear;
  slLogic.Free;

  inherited Destroy;
end;

{$include objicons.inc}
function TFormLayoutEdit.GetImageFromType(aicon:PWideChar):integer;
var
  i:integer;
begin
  for i:=0 to High(ObjIcons) do
  begin
    if CompareWide(ObjIcons[i].name,aicon)=0 then
      exit(ObjIcons[i].id);
  end;
  result:=-1;
end;

function TFormLayoutEdit.AddBranch(aroot:TTreeNode; anode:pointer):TTreeNode;
var
  lnode,lprop,lname:pointer;
  ltype,ltitle:PWideChar;
  i:integer;
begin
  result:=nil;
  if CompareWide(GetNodeName(anode),'BASEOBJECT')=0 then
  begin
    lnode:=GetChild(anode,0); // PROPERTIES
    lprop:=FindNode(lnode,'DESCRIPTOR');
    if lprop<>nil then
    begin
      ltype:=AsString(lprop);
      lname:=FindNode(lnode,'NAME');
      if lname=nil then ltitle:=ltype else ltitle:=AsString(lname);
      result:=aroot.Owner.AddChild(aroot,string(ltitle)+' ('+string(ltype)+')');
      result.data:=anode;
      result.ImageIndex:=GetImageFromType(info.GetObjectIcon(info.GetObjectId(ltype)));
      // type:=info.GetObjectId(ltype);

      if GetChildCount(anode)>1 then
      begin
        lnode:=GetChild(anode,1); // CHILDREN
        for i:=0 to GetChildCount(lnode)-1 do
        begin
          AddBranch(result,GetChild(lnode,i));
        end;
      end;
    end;
  end;
end;

const
  toskip:array [0..3] of PAnsiChar = (
    'DESCRIPTOR', 'NAME', 'ID', 'PARENTID'
  );

function TFormLayoutEdit.PropCheck(aprop:PAnsiChar):boolean;
var
  buf:array [0..127] of WideChar;
  i:integer;
  lid:dword;
begin
  if hostinfo.GetObjectName=nil then exit(false);
  if SpecObject then exit(true);

  for i:=0 to 3 do
    if StrComp(aprop, toskip[i])=0 then exit(true);

  i:=0;
  while aprop[i]<>#0 do
  begin
    buf[i]:=WideChar(Ord(aprop[i]));
    inc(i);
  end;
  buf[i]:=#0;

  if hostinfo.GetPropInfoByName(buf,rgUnknown,lid)=rgUnknown then exit(false);

  result:=true;
end;

function TFormLayoutEdit.BuildTree(adata:PByte; aver:integer):integer;
var
  lroot:TTreeNode;
  lnode:pointer;
  i:integer;
begin
  result:=0;

  hostinfo.Version:=ABS(aver);
  hostinfo.SelectScene('');

  Clear;

  tvLayout.Items.Clear;

  FRoot:=ParseLayoutMem(adata);
  if FRoot=nil then
    FRoot:=AddGroup(nil,'Layout');

  begin
    tvLayout.BeginUpdate;

    info.Version:=ABS(GetLayoutVersion(adata));
    if info.Version=verUnk then info.Version:=aver;
    info.SelectScene('');
    BuildMenu;
    TSynTSyn(SynEdit.Highlighter).OnPropCheck:=@PropCheck;

    lnode:=FindNode(FRoot,'OBJECTS');
    if lnode=nil then
      lnode:=AddGroup(FRoot,'OBJECTS');

    lroot:=tvLayout.Items.AddChildObjectFirst(nil,'Layout',FRoot);
    for i:=0 to GetChildCount(lnode)-1 do
      AddBranch(lroot,GetChild(lnode,i));

    lroot.Expand(false);
    lroot.Selected:=true;
    tvLayout.EndUpdate;
  end;

  result:=tvLayout.Items.Count;
end;

procedure TFormLayoutEdit.tvLayoutSelectionChanged(Sender: TObject);
var
  lpc,pc:PAnsiChar;
begin
  if tvLayout.Selected<>nil then
  begin
    if tvLayout.Selected.Data<>FRoot then
    begin
      TSynTSyn(SynEdit.Highlighter).OnPropCheck:=@PropCheck;
      BuildPanel(tvLayout.Selected.Data);
    end
    else
    begin
      ClearPanel;
      if cbTxtPreview.Checked then
      begin
        pc:=nil;
        if NodeToUtf8(FRoot,pc) then
        begin
          TSynTSyn(SynEdit.Highlighter).OnPropCheck:=nil;
          if (PDword(pc)^ and $00FFFFFF)=SIGN_UTF8 then lpc:=pc+3 else lpc:=pc;
          SynEdit.Text:=lpc;
          FreeMem(pc);
          SynEdit.Modified:=false;
          SynEdit.Visible:=true;
        end;
      end;

      if (hostinfo.Version<>verUnk) and (info.Version<>hostinfo.Version) then
      begin
        memHelp.Text:=rsVersion;
        memHelp.Lines.Add('"'+GetGameName(info.Version)+
                     '" vs "'+GetGameName(hostinfo.Version)+'"');
      end;
    end;
  end;
end;

function GetDefaultPropValue(atype:integer):string;
begin
  //!!!!!!!!!!!!!!!!!!!!
  result:=rsDefault;
exit;
  case atype of
    rgInteger,
    rgInteger64,
    rgUnsigned: result:='0';
    rgFloat,
    rgDouble  : result:='0.0';
    rgBool    : result:='False';
    rgVector2 : result:='0.0, 0.0';
    rgVector3 : result:='0.0, 0.0, 0.0';
    rgVector4 : result:='0.0, 0.0, 0.0, 0.0';
  else
    result:='';
  end;
end;

function GetPropText(aprop:pointer):string;
begin
  case GetNodeType(aprop) of
    rgUnsigned : result:=IntToStr(AsUnsigned(aprop));
    rgInteger  : result:=IntToStr(AsInteger(aprop));
    rgInteger64: result:=IntToStr(AsInteger64(aprop));
    rgBool     : if AsBool(aprop) then result:='True' else result:='False';
    rgFloat    : result:=FloatToStr(AsFloat(aprop));
    rgDouble   : result:=FloatToStr(AsFloat(aprop));
    rgString,
    rgTranslate,
    rgNote: result:=AsString(aprop);
    rgVector2: result:=FloatToStr(AsVector(aprop)^.X)+', '+
                       FloatToStr(AsVector(aprop)^.Y);
    rgVector3: result:=FloatToStr(AsVector(aprop)^.X)+', '+
                       FloatToStr(AsVector(aprop)^.Y)+', '+
                       FloatToStr(AsVector(aprop)^.Z);
    rgVector4: result:=FloatToStr(AsVector(aprop)^.X)+', '+
                       FloatToStr(AsVector(aprop)^.Y)+', '+
                       FloatToStr(AsVector(aprop)^.Z)+', '+
                       FloatToStr(AsVector(aprop)^.W);
  else
    result:='something another';
  end;
end;

procedure TFormLayoutEdit.vePropSelection(Sender: TObject; aCol, aRow: Integer);
begin
//  memHelp.Lines[2]:='Property '+veProp.Keys[aRow];
  memHelp.Lines[2]:=FastWideToStr(TypeToText(IntPtr(veProp.Objects[1,aRow-1])))+', '+
      info.GetPropDescr(IntPtr(veProp.Objects[0,aRow-1]));
end;

procedure TFormLayoutEdit.ClearPanel();
begin
  veProp .Clear; veProp .Visible:=false;
  SynEdit.Clear; SynEdit.Visible:=false;
  memHelp.Text:='';
end;

procedure TFormLayoutEdit.SaveEdited(anode:pointer);
var
  lenode,lchild:pointer;
begin
  if SynEdit.Visible and SynEdit.Modified then
  begin
    UTF8ToNode(PAnsiChar(SynEdit.Text), 0, lenode);
    if lenode<>nil then
    begin
      lchild:=CutNode(GetChild(anode,1));
      DeleteNode(GetChild(anode,0));

      AddNode(anode, CutNode(GetChild(lenode,0)));
      DeleteNode(lenode);

      AddNode(anode, lchild);
    end;
    SynEdit.Modified:=false;
  end;
end;

procedure TFormLayoutEdit.cbTxtPreviewChange(Sender: TObject);
var
  lnode:pointer;
begin
  lnode:=tvLayout.Selected.Data;
  if lnode=fRoot then
    tvLayoutSelectionChanged(tvLayout)
  else if veProp.Visible or SynEdit.Visible then
  begin
    SaveEdited(lnode);
    BuildPanel(lnode);
  end;
end;

function TFormLayoutEdit.BuildPanel(anode:pointer):integer;
var
  lprop,lprops:pointer;
  lObjId:Int64;
  lname:PWideChar;
  pc,lpc:PAnsiChar;
  lptr:pointer;
  lid:dword;
  i,lidx,ltype:integer;
begin
  result:=0;
  ClearPanel();
  if anode=nil then exit;

  lid:=info.GetObjectId(AsString(FindNode(GetChild(anode,0),'DESCRIPTOR')));
  lname:=info.GetObjectName();
  if (CompareWide(lname,'Timeline'   )=0) or
     (CompareWide(lname,'Logic Group')=0) then
    SpecObject:=true
  else
    SpecObject:=false;

  lptr:=hostinfo.GetObjectByName(lname);

  if cbTxtPreview.Checked then
  begin
    pc:=nil;
    if NodeToUtf8(anode,pc,false) then
    begin
      if (PDword(pc)^ and $00FFFFFF)=SIGN_UTF8 then lpc:=pc+3 else lpc:=pc;
      SynEdit.Text:=lpc;
      FreeMem(pc);
      SynEdit.Modified:=false;
      SynEdit.Visible:=true;

      memHelp.Text:=rsTextPreview;
      if lptr=nil then
        memHelp.Lines.Add(rsUnsupObj)
      else
			  memHelp.Lines.Add(rsAlter);
    end;
  end
  else
  begin
    memHelp.Text:='Object ID=';
    memHelp.Lines.Add('-----');
    memHelp.Lines.Add('');

    veProp.BeginUpdate;
    veProp.Clear;
    veProp.RowCount:=info.GetPropsCount+1;

    // 1 - draw empty fields
    for i:=1 to info.GetPropsCount do
    begin
      ltype:=info.GetPropInfoByIdx(i-1,lid,lname);
      veProp.Keys   [i]:=lname;
      veProp.Cells[1,i]:=GetDefaultPropValue(ltype);
      if ltype=rgBool then
      begin
        veProp.ItemProps[i-1].EditStyle:=esPickList;
        veProp.ItemProps[i-1].PickList :=slLogic;
        // special
        if (CompareWide(lname,'VISIBLE')=0) or
           (CompareWide(lname,'ENABLED')=0) then
          veProp.Cells[1,i]:='True';
      end;
      if ltype in [rgVector2, rgVector3, rgVector4] then
      begin
        veProp.ItemProps[i-1].EditStyle:=esEllipsis;
      end;
      veProp.Objects[0,i-1]:=TObject(IntPtr(lid  ));
      veProp.Objects[1,i-1]:=TObject(IntPtr(ltype));
    end;

    // 2 - set values
    lprops:=GetChild(anode,0);
    lObjId:=-1;
    for i:=0 to GetChildCount(lprops)-1 do
    begin
      lprop:=GetChild(lprops,i);
      lname:=GetNodeName(lprop);
      if (lname[0]='I') and (lname[1]='D') and (lname[2]=#0) then
        lObjId:=AsInteger64(lprop)
      else if veProp.FindRow(lname,lidx) then
      begin
        {TODO: mark this row. bold key?}
        // if found, get value as text
        veProp.Cells[1,lidx]:=GetPropText(lprop);
      end;
    end;
    if lObjId=-1 then
      memHelp.Lines[0]:=memHelp.Lines[0]+rsUndefined
    else
      memHelp.Lines[0]:=memHelp.Lines[0]+IntToStr(lObjId);

    veProp.EndUpdate;
    veProp.Visible:=true;
    veProp.SetFocus;
    veProp.Row:=1;
    vePropSelection(veProp,1,1);
  end;
end;

function TFormLayoutEdit.GetFile(out abuf:PByte; aver:integer):integer;
begin
  result:=BuildLayoutMem(FRoot,abuf,aver);
end;

procedure TFormLayoutEdit.vePropButtonClick(Sender: TObject; aCol, aRow: Integer);
var
  lForm:TForm;
  fseX,fseY,fseZ,fseW:TFloatSpinEditEx;
  tr:TRect;
  d:Double;
  ls:string;
  lval:array [0..31] of AnsiChar;
  aval:PAnsiChar;
  ltype,i,lidx,lcnt:integer;
begin
  ltype:=IntPtr(veProp.Objects[1,aRow-1]);

  tr:=veProp.ClientToScreen(veProp.CellRect(aCol,aRow));
  lForm:=TForm.Create(Self);
  lForm.SetBounds(tr.Left,tr.Top,156,168);

  with TLabel.Create(lForm) do
  begin
    Parent :=lForm;
    Left      :=13;
    Top       :=15;
    Caption   :='X';
    Font.Style:=[fsBold];
  end;
  fseX:=TFloatSpinEditEx.Create(lForm);
  with fseX do
  begin
    Parent :=lForm;
    SetBounds(32,11,103,23);
    DecimalPlaces:=6;
  end;

  with TLabel.Create(lForm) do
  begin
    Parent :=lForm;
    Left      :=13;
    Top       :=47;
    Caption   :='Y';
    Font.Style:=[fsBold];
  end;
  fseY:=TFloatSpinEditEx.Create(lForm);
  with fseY do
  begin
    Parent :=lForm;
    SetBounds(32,43,103,23);
    DecimalPlaces:=6;
  end;

  with TLabel.Create(lForm) do
  begin
    Parent :=lForm;
    Left      :=13;
    Top       :=79;
    Caption   :='Z';
    Font.Style:=[fsBold];
  end;
  fseZ:=TFloatSpinEditEx.Create(lForm);
  with fseZ do
  begin
    Parent :=lForm;
    SetBounds(32,75,103,23);
    DecimalPlaces:=6;
    Enabled:=ltype in [rgVector3, rgVector4];
  end;

  with TLabel.Create(lForm) do
  begin
    Parent :=lForm;
    Left      :=13;
    Top       :=111;
    Caption   :='W';
    Font.Style:=[fsBold];
  end;
  fseW:=TFloatSpinEditEx.Create(lForm);
  with fseW do
  begin
    Parent :=lForm;
    SetBounds(32,107,103,23);
    DecimalPlaces:=6;
    Enabled:=(ltype=rgVector4);
  end;

  with TBitBtn.Create(lForm) do
  begin
    Parent :=lForm;
    Kind   :=bkCancel;
    Cancel :=True;
    Caption:='';
    Spacing:=0;
    Width  :=24;
    Height :=24;
    Top    :=138;
    Left   :=32;
    ModalResult:=mrCancel;
  end;

  with TBitBtn.Create(lForm) do
  begin
    Parent :=lForm;
    Kind   :=bkOK;
    Caption:='';
    Default:=True;
    Spacing:=0;
    Width  :=24;
    Height :=24;
    Top    :=138;
    Left   :=111;
    ModalResult:=mrOK;
  end;

  ls:=veProp.Cells[aCol, aRow];
  if ls<>'' then
  begin
    aval:=Pointer(ls);
    lcnt:=SplitCountA(aval,',');
    if lcnt>0 then
    begin
      for i:=0 to lcnt-1 do
      begin
        lidx:=0;
        repeat
          while (aval^=',') or (aval^=' ') do inc(aval);
          lval[lidx]:=aval^;
          inc(lidx);
          inc(aval);
        until (aval^=',') or (aval^=' ') or (aval^=#0);
        lval[lidx]:=#0;
        Val(lval,d);
        case i of
          0: fseX.Value:=d;
          1: fseY.Value:=d;
          2: fseZ.Value:=d;
          3: fseW.Value:=d;
        end;
      end;
    end;
  end;

  if lForm.ShowModal=mrOk then
  begin
    case ltype of
      rgVector2: ls:=
          FloatToStr(fseX.Value)+', '+
          FloatToStr(fseY.Value);
      rgVector3: ls:=
          FloatToStr(fseX.Value)+', '+
          FloatToStr(fseY.Value)+', '+
          FloatToStr(fseZ.Value);
      rgVector4: ls:=
          FloatToStr(fseX.Value)+', '+
          FloatToStr(fseY.Value)+', '+
          FloatToStr(fseZ.Value)+', '+
          FloatToStr(fseW.Value);
    end;
    veProp.Cells[1,aRow]:=ls;
    SetPropValue(aRow,ls);
  end;

  lForm.Free;
end;

procedure TFormLayoutEdit.vePropValidateEntry(Sender: TObject; aCol,
  aRow: Integer; const OldValue: string; var NewValue: String);
begin
  if NewValue<>OldValue then SetPropValue(ARow,NewValue);
end;

function TFormLayoutEdit.SetPropValue(arow:integer; const aval:string):boolean;
var
  lprops,lnode:pointer;
  lval,lname:UnicodeString;
  ltype:integer;
begin
  result:=true;
  lname :=UnicodeString(veProp.Keys[arow]);
  lval  :=UnicodeString(aval);
  lprops:=GetChild(tvLayout.Selected.Data,0);
  lnode :=FindNode(lprops,pointer(lname));
  ltype :=IntPtr(veProp.Objects[1,arow-1]);
  if lnode=nil then
  begin
    lnode:=AddNode(lprops,pointer(lname),ltype,pointer(lval));
  end
  else
  begin
    SetNodeValue(lnode,pointer(lval));
  end;
end;

procedure TFormLayoutEdit.tvLayoutContextPopup(Sender: TObject;
  MousePos: TPoint; var Handled: Boolean);
var
  oldid:dword;
begin
  PopupNode:=tvLayout.GetNodeAt(MousePos.X, MousePos.Y);
  if PopupNode<>nil then
  begin
    oldid:=info.GetObjectId();
    actTreeRenameNode.Enabled:=(PopupNode.Data<>FRoot);
    actTreeDeleteNode.Enabled:=(PopupNode.Data<>FRoot);
    miAddNode.Enabled:=(PopupNode.Data=FRoot) or
        info.CanObjectHaveChild(info.GetObjectId(
        AsString(FindNode(GetChild(PopupNode.Data,0),'DESCRIPTOR'))));
    mnuTree.PopUp;
    info.GetObjectById(oldid);
  end;
  Handled:=true;
end;

function TFormLayoutEdit.CreateLayoutNode(aid:dword; aparent:pointer):pointer;
var
  lnode:pointer;
  lid:Int64;
begin
  if aparent=FRoot then
  begin
    lid:=-1;
    lnode:=FindNode(aparent,'OBJECTS');
    if lnode=nil then
      lnode:=AddGroup(aparent,'OBJECTS');

    aparent:=lnode;
  end
  else
  begin
    lid:=AsInteger64(FindNode(GetChild(aparent,0),'ID'));
    if lid=0 then lid:=-1;

    if GetChildCount(aparent)<2 then
      aparent:=AddGroup(aparent,'CHILDREN')
    else
      aparent:=GetChild(aparent,1);
  end;

  result:=AddNode(aparent,CreateLayoutNode(aid,lid));
end;

function TFormLayoutEdit.CreateLayoutNode(aid:dword; aparentid:Int64):pointer;
var
  lprop:pointer;
  lguid:TGUID;
begin
  CreateGUID(lguid);
  result:=AddGroup(nil   ,'BASEOBJECT');
  lprop :=AddGroup(result,'PROPERTIES');
  AddString   (lprop,'DESCRIPTOR',info.GetObjectName(aid));
  AddString   (lprop,'NAME'      ,info.GetObjectName(aid));
  AddInteger64(lprop,'PARENTID'  ,aparentid);
  AddInteger64(lprop,'ID'        ,Int64(MurmurHash64B(lguid,16,0)));
end;

procedure TFormLayoutEdit.BuildMenu;
var
  lmi,lmisub:TMenuItem;
  lmenu:PWideChar;
  ls:AnsiString;
  i,j:integer;
begin
  miAddNode.Clear;

  for i:=0 to info.GetObjectCount-1 do
  begin
    lmenu:=info.GetObjectMenu(info.GetObjectIdByIdx(i));
    lmi:=TMenuItem.Create(miAddNode);
    lmi.Caption   :=info.GetObjectName();
    lmi.Tag       :=info.GetObjectId(nil);
    lmi.ImageIndex:=GetImageFromType(info.GetObjectIcon(lmi.Tag));
    lmi.OnClick   :=@DoAddNode;
    if lmenu<>nil then
    begin
      ls:=FastWideToStr(lmenu);
      lmisub:=nil;
      for j:=0 to miAddNode.Count-1 do
      begin
        if miAddNode.Items[j].Caption=ls then
        begin
          lmisub:=miAddNode.Items[j];
          break;
        end;
      end;
      if lmisub=nil then
      begin
        lmisub:=TMenuItem.Create(miAddNode);
        lmisub.Caption:=ls;
        miAddNode.Add(lmisub);
      end;
      lmisub.Add(lmi);
    end
    else
      miAddNode.Add(lmi);
  end;
end;

procedure TFormLayoutEdit.DoAddNode(Sender: TObject);
var
  lnode:pointer;
  lid:dword;
begin
  lnode:=PopupNode.Data;
  lid:=(Sender as TMenuItem).Tag;

  lnode:=CreateLayoutNode(lid,lnode);
  if lnode<>nil then
  begin
    tvLayout.Select(AddBranch(PopupNode,lnode));
  end;
end;

procedure TFormLayoutEdit.actTreeDeleteNodeExecute(Sender: TObject);
begin
  DeleteNode(PopupNode.Data);
  tvLayout.Select(PopupNode.Parent);
  PopupNode.Delete;
end;

procedure TFormLayoutEdit.actTreeRenameNodeExecute(Sender: TObject);
var
  lprop:pointer;
  ltype,lname:string;
begin
  lprop:=GetChild(PopupNode.Data,0);
  ltype:=AsString(FindNode(lprop,'DESCRIPTOR'));
  lprop:=FindNode(lprop,'NAME');
  lname:=AsString(lprop);

  if InputQuery(rsNewNameCap+ltype, rsNewName, lname) then
  begin
    AsString(lprop,PWideChar(WideString(lname)));
    PopupNode.Text:=lname+' ('+ltype+')';
  end;
  tvLayout.Select(PopupNode);
end;

end.
