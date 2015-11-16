#File.open("data/true.dat", "r").each_line do |line|
#  puts line
#end
File.open('data/train.tmp', 'r').each_line do |line|
  line = line.strip.split ' '
puts line[9]
end 
