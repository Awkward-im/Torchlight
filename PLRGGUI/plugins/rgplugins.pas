{
  Unit for link plugins to program
}
unit RGPlugins;

interface

uses
  Menus,
  rgpRecipes;

procedure FillEditMenu(ami:TMenuItem);


implementation

uses
  Classes,
  rgglobal,
  rgctrl,
  rggui.core,
  rggui.shared,
  fmPanel,
  rgpBase;

procedure OnMenuItemClick(dummy:pointer; Sender: TObject);
var
  lproc:TPluginProc;
  lctrl:PRGController;
begin
  if (ActiveCtrl>=0) and (ActiveCtrl<CtrlCount) then lctrl:=CtrlList[ActiveCtrl].Ctrl;
  if (lctrl=nil) then exit;

  lproc:=pluginlist[TMenuItem(Sender).Tag].proc;
  lproc(lctrl^,GetActiveFile(lctrl,TPanelForm(Panels[ActivePanel]).ListIndex));
end;

procedure FillEditMenu(ami:TMenuItem);
var
  lmi:TMenuItem;
  i:integer;
begin
  if plcount=0 then exit;

  lmi:=TMenuItem.Create(ami);
  lmi.Caption:='-';
  ami.Add(lmi);

  for i:=0 to plcount-1 do
  begin
    if pluginlist[i].menu=rgptEdit then
    begin
      lmi:=TMenuItem.Create(ami);
      lmi.Caption:=pluginlist[i].title;
      lmi.Tag    :=i;
      lmi.OnClick:=TNotifyEvent(MakeMethod(nil,@OnMenuItemClick));
      ami.Add(lmi);
    end;
  end;

end;

end.
