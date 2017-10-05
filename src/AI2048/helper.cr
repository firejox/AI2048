macro max(a, b)
  %temp1 = {{a}}
  %temp2 = {{b}}
  if %temp1 > %temp2
     %temp1
  else
    %temp2
  end
end
