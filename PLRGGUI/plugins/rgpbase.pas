{
  This is common unit for plugins
}
{TODO: register with imageindex for iconlist}
{TODO: make imagelist for menus/buttons}
unit rgpBase;

interface

uses
  RGCtrl;


type
  TPluginProc = function(var actrl:TRGController; idx:integer):integer;

const
  rgptEdit = 0;
  rgptTool = 1;

procedure RegisterPlugin(atype:integer; const atitle:AnsiString; aproc:TPluginProc);
{
var
  CurCtrl:PRGController=nil;
  CurIdx:integer=-1;
}
type
  TPluginListElement = record
    proc :TPluginProc;
    title:AnsiString;
    menu :integer;
  end;
const
  plcount:integer=0;
  pluginlist:array of TPluginListElement=nil;


implementation


const
  listbase = 32;
  listincr = 16;

procedure RegisterPlugin(atype:integer; const atitle:AnsiString; aproc:TPluginProc);
begin
  if pluginlist=nil then
    SetLength(pluginlist,listbase)
  else if plcount=Length(pluginlist) then
    SetLength(pluginlist,plcount+listincr);

  with pluginlist[plcount] do
  begin
    proc :=aproc;
    title:=atitle;
    menu :=atype;
  end;
  inc(plcount);
end;

{ move initialization to declaration to ability of register in plugin initialization section
initialization
  pluginlist:=nil;
  plcount:=0;
}
finalization
  SetLength(pluginlist,0);
end.
