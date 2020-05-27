unit ojUtils;

interface
uses System.classes, System.SysUtils;

function pg_size_pretty(Size: Int64): string;

implementation



function pg_size_pretty(Size: Int64): string;
var v_size: Int64;
    v_limit, v_limit2: Int64;
    function half_rounded(Value: Int64): Int64;
    begin
      //  Divide by two and round towards positive infinity.
      //  define half_rounded(x)   (((x) + ((x) < 0 ? 0 : 1)) / 2)
      if Value < 0
      then result:= Value div 2
      else result:= (Value + 1) div 2;
    end;
begin
  //  https://doxygen.postgresql.org/dbsize_8c_source.html
  v_size:= Size;
  v_limit:= 10 * 1024;
  v_limit2:= v_limit * 2 - 1;

  if Abs(v_size) < v_limit then
    result:= format('%d bytes', [v_size])
  else
  begin
    //  keep one extra bit for rounding
    v_size:= v_size shr 9;
    if Abs(v_size) < v_limit2 then
      result:= format('%d kB', [half_rounded(v_size)])
    else
    begin
      v_size:= v_size shr 10;
      if Abs(v_size) < v_limit2 then
        result:= format('%d MB', [half_rounded(v_size)])
      else
      begin
        v_size:= v_size shr 10;
        if Abs(v_size) < v_limit2 then
          result:= format('%d GB', [half_rounded(v_size)])
        else
        begin
          v_size:= v_size shr 10;
          result:= format('%d TB', [half_rounded(v_size)])
        end;
      end;
    end;
  end;

end;

end.
