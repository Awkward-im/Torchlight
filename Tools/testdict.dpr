uses dict;

var
  rgtags:TDictTranslate;
  i:integer;

procedure Fill(anopt:THashDict.TRGOptions);
begin
  RGTags.Options:=anopt;
  RGTags.Add('One'       ,'Один'       ,1);
  RGTags.Add('Two'       ,'Два'        ,2);
  RGTags.Add('Three'     ,'Три'        ,3);
  RGTags.Add('really two','Реально два',2);
  RGTags.Add('Three'     ,'Три'        ,4);
  RGTags.Add('Five'      ,'Пять'       ,5);
end;

procedure Trace;
var
  i:integer;
begin
  writeln('Count is ',RGTags.Count);
  for i:=0 to RGTags.Count-1 do
    writeln(RGTags.Hashes[i]:8,': ',WideString(RGTags.Tags[i]),#9'| ',WideString(RGTags.Values[i]));
end;

begin
{$if declared(UseHeapTrace)}
  SetHeapTraceOutput('Trace.log');
  HaltOnError := true;
{$endif}
  RGTags.Init;

  writeln('check hash');
  Fill([check_hash]);
  Trace;
  RGTags.Clear;

  writeln('check text');
  Fill([check_text]);
  Trace;
  RGTags.Clear;

  writeln('check hash and text');
  Fill([check_hash,check_text]);
  Trace;
  RGTags.Clear;

  writeln('check nothing');
  Fill([]);
  Trace;
  RGTags.Clear;

end.
