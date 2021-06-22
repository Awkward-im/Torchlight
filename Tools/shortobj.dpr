uses
  classes,
  rgnode,
  rgdict,
  sysutils,
  rgglobal;

var
  sl,sl1,sl2:TStringList;
  slout:pointer;
  objInfo:pointer;

procedure ProcessObjects;
var
  l_scene,l_object,l_property,l_id,l_objid,l_type:string;
  l_scid,l_object1,l_objid1:string;

  sobj,gobj,lprop,lnode,lobj:pointer;
  lscene,lobject,lproperty:pointer;
  lobjs,lchilds,i,j,k:integer;
begin
  if objInfo=nil then objInfo:=ParseDATFile('objects.dat');

  for lobjs:=0 to GetChildCount(objInfo)-1 do
  begin
    // for all scenes
    if CompareWide(GetNodeName(GetChild(objInfo,lobjs)),'SCENE')=0 then
    begin
      lscene:=AddGroup(slout,'SCENE');

      sobj:=GetChild(objInfo,lobjs);
      for lchilds:=0 to GetChildCount(sobj)-1 do
      begin
        gobj:=GetChild(sobj,lchilds);

        if CompareWide(GetNodeName(gobj),'NAME')=0 then
        begin
          AddString    (lscene,'NAME',AsString(gobj));
          l_scene:=string(widestring(AsString(gobj)));
        end
        else if CompareWide(GetNodeName(gobj),'ID'          )=0 then
        begin
          Str(AsUnsigned(gobj),l_scid);
          AddUnsigned(lscene,'ID'  ,AsUnsigned(gobj))
        end
        else if CompareWide(GetNodeName(gobj),'OBJECT GROUP')=0 then
        begin
          sl2.Add('');
          sl2.Add('>'+l_scid+':'+l_scene);
          // for all objects
          for i:=0 to GetChildCount(gobj)-1 do
          begin
            lobject:=AddGroup(lscene,'OBJECT');
            lobj:=GetChild(gobj,i);
            l_object1:='';
            l_objid1 :='';
            // get object ID
            for j:=0 to GetChildCount(lobj)-1 do
            begin
              lprop:=GetChild(lobj,j);

              if (l_object1<>'') and (l_objid1<>'') then
              begin
                sl2.Add('');
                sl2.Add('  *'+l_objid1+':'+l_object1);
                l_objid1 :='';
                l_object1:='';
              end;

              if CompareWide(GetNodeName(lprop),'NAME')=0 then
              begin
                AddString(lobject,'NAME',AsString(lprop));
                l_object:=string(widestring(AsString(lprop)));
                l_object1:=l_object;
              end
              else if CompareWide(GetNodeName(lprop),'ID')=0 then
              begin
                AddInteger(lobject,'ID',AsInteger(lprop));
                Str(AsInteger(lprop),l_objid);
                l_objid1:=l_objid;

              end
              else if CompareWide(GetNodeName(lprop),'PROPERTY')=0 then
              begin
                lproperty:=AddGroup(lobject,'PROPERTY');

                // for all properties
                for k:=0 to GetChildCount(lprop)-1 do
                begin
                  lnode:=GetChild(lprop,k);

                  if CompareWide(GetNodeName(lnode),'NAME')=0 then
                  begin
                    l_property:=string(widestring(AsString(lnode)));
                    AddString(lproperty,'NAME',AsString(lnode))
                  end
                  else if CompareWide(GetNodeName(lnode),'ID')=0 then
                  begin
                    AddInteger(lproperty,'ID',AsInteger(lnode));
                    Str(AsInteger(lnode),l_id);
                  end
                  else if CompareWide(GetNodeName(lnode),'TYPEOFDATA')=0 then
                  begin
                    AddString(lproperty,'TYPEOFDATA',AsString(lnode));
                    l_type:=string(widestring(AsString(lnode)));
                   end;
                end;
                sl2.Add('    '+l_id+':'+l_type+':'+l_property);
                sl .Add(l_object+':'+l_objid+':'+l_property+':'+l_id+':'+l_type{+':'+l_scene});
                sl1.Add(l_scene +':'+l_objid+':'+l_object+':'+l_id+':'+l_property+':'+l_type{+':'+l_scene});
              end;

            end;
          end;
        end;
      end;
    end;
  end;
end;

begin
  sl:=TStringList.Create;
  sl.Sorted:=true;
  sl1:=TStringList.Create;
  sl1.Sorted:=true;
  sl2:=TStringList.Create;
  slout:=AddGroup(nil,'LayoutObjects');
  objinfo:=nil;
  ProcessObjects;
  WriteDatTree(slout,'objout.dat');
  DeleteNode(slout);
  sl.Sort;
  sl.SaveToFile('sortedtags.txt');
  sl.Free;
  sl1.Sort;
  sl1.SaveToFile('sortedcodetags.txt');
  sl1.Free;
  sl2.SaveToFile('compact.txt');
  sl2.Free;
end.
