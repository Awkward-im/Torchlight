uses
  sysutils,
  classes,
  RGDatNode,
  RGGlobal,
  RGDict,
  TL2Memory;

var
  otags,ctags:pointer;
  hashes:TStringList;


procedure CheckTags;
var
  sobj,gobj,llobj,lobj:pointer;
  ls,lsh:String;
  lhash:dword;
  lh,lobjs,lchilds,i,jj,j:integer;
begin

  for lobjs:=0 to otags^.childcount-1 do
  begin
    // for all scenes
    if otags^.children^[lobjs].Name='SCENE' then
    begin
      sobj:=@otags^.children^[lobjs];
      for lchilds:=0 to sobj^.childcount-1 do
      begin
        // for object group
        if sobj^.children^[lchilds].Name='OBJECT GROUP' then
        begin
          gobj:=@sobj^.children^[lchilds];
          
          // for all objects
          for i:=0 to gobj^.childcount-1 do
          begin
            lobj:=@gobj^.children^[i];

            for j:=0 to lobj^.childcount-1 do
            begin
              llobj:=@lobj^.children^[j];
              if (llobj^.nodetype=ntGroup) and CompareWide(llobj^.Name,'PROPERTY') then
              begin
                for jj:=0 to llobj^.childcount-1 do
                begin
                  if CompareWide(llobj^.children^[jj].Name,'NAME') then
                  begin
                    ls:=StringReplace(String(WideString(llobj^.children^[jj].AsString)),' ','_',[rfReplaceAll]);
                    lhash:=RGHash(pointer(@ls[1]),length(ls));
                    Str(lhash,lsh);
//    writeln(ls);
                    for lh:=0 to hashes.count-1 do
                    begin
                      if lsh=hashes[lh] then
                      begin
    writeln(#9'<STRING>:',ls,#13#10#9'<INTEGER>:',integer(lhash));
                      end;
                    end;

                    break;
                  end;
                end;
              end;
            end;
          end;

          break;
        end;
      end;
    end;
  end;
end;

begin
  hashes:=TStringList.Create;
  hashes.Sorted:=True;
  hashes.LoadFromFile('hashes.txt');

  otags:=ParseDatFile('objects.dat');

  CheckTags;

  DeleteNode(otags);

  hashes.Free;
end.
