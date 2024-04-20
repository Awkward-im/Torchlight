{
  change prop content
  check in event, changed or not.
  if was not in node, add, else find and change
  (check modified flag)
}
{TODO: hilight unsupported for current version nodes [and props]}
{TODO: combobox to choose game version (dict, panel view) on-the-fly}
{TODO: Add/Delete (at least) children on tree}
{TODO: Check and implement Timeline and Logic Group editors (maybe as text only)}
{TODO: implement Vector2,3,4 editor (button+form?)}

unit fmLayoutEdit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, ValEdit, Grids, SynEdit, SynHighlighterT, rgdictlayout;

type

  { TformLayoutEdit }

  TFormLayoutEdit = class(TForm)
    cbTxtPreview: TCheckBox;
    memHelp: TMemo;
    pnlTopLeft: TPanel;
    pnlHelp: TPanel;
    pnlPropEdit: TPanel;
    pnlTree: TPanel;
    pnlProps: TPanel;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    SynEdit: TSynEdit;
    tvLayout: TTreeView;
    veProp: TValueListEditor;
    procedure cbTxtPreviewChange(Sender: TObject);
    procedure tvLayoutSelectionChanged(Sender: TObject);
    procedure vePropSelection(Sender: TObject; aCol, aRow: Integer);
    procedure vePropValidateEntry(Sender: TObject; aCol, aRow: Integer;
      const OldValue: string; var NewValue: String);
  private
    FRoot:pointer;
    info:TRGObject;
    slLogic:TStringList;
    SynTSyn: TSynTSyn;

    procedure ClearPanel;
    function GetNodeId(anode:pointer):dword;
    procedure SaveEdited(anode: pointer);
    function SetPropValue(arow: integer; const aval: string): boolean;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure Clear;

    function BuildTree(adata:PByte):integer;
    function BuildPanel(anode:pointer):integer;
    function GetFile(out abuf: PByte; aver: integer): integer;
  end;

var
  formLayoutEdit: TFormLayoutEdit;


implementation

{$R *.lfm}

uses
  rgglobal,
  rgIO.Layout,
  rgIO.Text,
  rgnode;

resourcestring
  rsDefault   = '- default -';
  rsUndefined = 'UNDEFINED';
  rsTextPreview = 'This is text preview without children nodes.'+
    ' You can select child from tree.';

constructor TFormLayoutEdit.Create(aOwner: TComponent);
begin
  inherited Create(AOwner);

  info.Init;
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

function AddBranch(aroot:TTreeNode; anode:pointer):integer;
var
  lbranch:TTreeNode;
  lnode,lprop,lname:pointer;
  ltype,ltitle:PWideChar;
  i:integer;
begin
  result:=0;
  if CompareWide(GetNodeName(anode),'BASEOBJECT')=0 then
  begin
    lnode:=GetChild(anode,0); // PROPERTIES
    lprop:=FindNode(lnode,'DESCRIPTOR');
    if lprop<>nil then
    begin
      ltype:=AsString(lprop);
      lname:=FindNode(lnode,'NAME');
      if lname=nil then ltitle:=ltype else ltitle:=AsString(lname);
      lbranch:=aroot.Owner.AddChild(aroot,string(ltitle)+' ('+string(ltype)+')');
      lbranch.data:=anode;
      // type:=info.GetObjectId(ltype);

      if GetChildCount(anode)>1 then
      begin
        lnode:=GetChild(anode,1); // CHILDREN
        for i:=0 to GetChildCount(lnode)-1 do
        begin
          result:=result+AddBranch(lbranch,GetChild(lnode,i));
        end;
      end;
    end;
  end;
end;

function TFormLayoutEdit.BuildTree(adata:PByte):integer;
var
  lroot:TTreeNode;
  lnode:pointer;
  i:integer;
begin
  result:=0;

  Clear;

  tvLayout.Items.Clear;

  FRoot:=ParseLayoutMem(adata);
  if FRoot<>nil then
  begin
    tvLayout.BeginUpdate;

    info.Version:=GetLayoutVersion(adata);
    info.SelectScene('');

    lnode:=FindNode(FRoot,'OBJECTS');
    if lnode<>nil then
    begin
      lroot:=tvLayout.Items.AddChildObjectFirst(nil,'Layout',nil);
      for i:=0 to GetChildCount(lnode)-1 do
        result:=result+AddBranch(lroot,GetChild(lnode,i));
    end;

    lroot.Expand(false);
    lroot.Selected:=true;
    tvLayout.EndUpdate;
  end;

end;

procedure TFormLayoutEdit.tvLayoutSelectionChanged(Sender: TObject);
begin
  if tvLayout.Selected<>nil then
  begin
    if tvLayout.Selected.Data<>nil then
    begin
      BuildPanel(tvLayout.Selected.Data);
    end
    else
    begin
      ClearPanel;
    end;
  end;
end;

function TFormLayoutEdit.GetNodeId(anode:pointer):dword;
begin
  result:=info.GetObjectId(AsString(FindNode(GetChild(anode,0),'DESCRIPTOR')));
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
  memHelp.Lines[2]:=TypeToText(IntPtr(veProp.Objects[1,aRow-1]))+', '+
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
  if veProp.Visible or SynEdit.Visible then
  begin
    lnode:=tvLayout.Selected.Data;
    SaveEdited(lnode);
    BuildPanel(lnode);
  end;
end;

function TFormLayoutEdit.BuildPanel(anode:pointer):integer;
var
  lobj,lprop,lprops:pointer;
  lObjId:Int64;
  lname:PWideChar;
  pc,lpc:PAnsiChar;
  lid:dword;
  i,lidx,ltype:integer;
begin
  result:=0;
  ClearPanel();
  if anode=nil then exit;

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
    end;
  end
  else
  begin
    lid:=GetNodeId(anode);
    lobj:=info.GetObjectById(lid);
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
    veProp.Row:=1;
    veProp.SetFocus;
  end;
end;

function TFormLayoutEdit.GetFile(out abuf:PByte; aver:integer):integer;
begin
  result:=BuildLayoutMem(FRoot,abuf,aver);
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

end.

