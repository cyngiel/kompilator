program example(input, output);
var x, y: integer;
var g,h:real;
 
function sum(a,b: integer) : integer;
begin
 sum := a + b
end;
 
begin
  write(sum(sum(sum(3, 4), 2),sum(3, 4)))
end.