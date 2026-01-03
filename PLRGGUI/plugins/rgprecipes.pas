unit RGPRecipes;

interface

uses
  RGCtrl,
  rgpBase;


function EditRecipes(var actrl:TRGController; idx:integer):integer;


implementation

uses
  RGGlobal;


function EditRecipes(var actrl:TRGController; idx:integer):integer;
begin
  result:=-1;
  if idx>=0 then
  begin
    if CompareWide(actrl.PathOfFile(idx),'MEDIA/RECIPES/',14)=0 then
    begin
    end;
  end;
end;

initialization
  RegisterPlugin(rgptEdit,'&Recipes',@EditRecipes);

end.
