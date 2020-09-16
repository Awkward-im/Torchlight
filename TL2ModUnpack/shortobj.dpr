uses
  TL2DatNode,
  rgglobal;

var
  slout:PTL2Node;

procedure ProcessObjects;
var
  sobj,gobj,lprop,lnode,lobj:PTL2Node;
  lscene,lobject,lproperty:PTL2Node;
  lobjs,lchilds,i,j,k:integer;
begin
  if objInfo=nil then LoadObjectInfo;

  for lobjs:=0 to objInfo^.childcount-1 do
  begin
    // for all scenes
    if objInfo^.children^[lobjs].Name='SCENE' then
    begin
      lscene:=AddGroup(slout,'SCENE');

      sobj:=@objInfo^.children^[lobjs];
      for lchilds:=0 to sobj^.childcount-1 do
      begin
        gobj:=@(sobj^.children^[lchilds]);
        if      CompareWide(gobj^.Name,'NAME'        ) then AddText    (lscene,'NAME',gobj^.AsString,ntString)
        else if CompareWide(gobj^.Name,'ID'          ) then AddUnsigned(lscene,'ID'  ,gobj^.AsUnsigned)
        else if CompareWide(gobj^.Name,'OBJECT GROUP') then
        begin
          // for all objects
          for i:=0 to gobj^.childcount-1 do
          begin
            lobject:=AddGroup(lscene,'OBJECT');
            lobj:=@gobj^.children^[i];
            // get object ID
            for j:=0 to lobj^.childcount-1 do
            begin
              lprop:=@lobj^.children^[j];

              if      CompareWide(lprop^.Name,'NAME'    ) then AddText   (lobject,'NAME',lprop^.AsString,ntString)
              else if CompareWide(lprop^.Name,'ID'      ) then AddInteger(lobject,'ID'  ,lprop^.AsInteger)
              else if CompareWide(lprop^.Name,'PROPERTY') then
              begin
                lproperty:=AddGroup(lobject,'PROPERTY');

                // for all properties
                for k:=0 to lprop^.childcount-1 do
                begin
                  lnode:=@lprop^.children^[k];

                  if      CompareWide(lnode^.Name,'NAME'      ) then AddText   (lproperty,'NAME'      ,lnode^.AsString,ntString)
                  else if CompareWide(lnode^.Name,'ID'        ) then AddInteger(lproperty,'ID'        ,lnode^.AsInteger)
                  else if CompareWide(lnode^.Name,'TYPEOFDATA') then AddText   (lproperty,'TYPEOFDATA',lnode^.AsString,ntString);
                end;

              end;

            end;
          end;
        end;
      end;
    end;
  end;
end;

begin
  slout:=AddGroup(nil,'LayoutObjects');
  objinfo:=nil;
  ProcessObjects;
  WriteDatTree(slout,'objout.dat');
  DeleteNode(slout);
end.
