require 'rubygems'
require 'mlp'
require 'mysql'
error=''


a = MLP.new(:hidden_layers => [1], :output_nodes => 10, :inputs => 156)

data = IO.readlines('5K.txt')
#print "first", my_array[0], "\n";
input = data[0].split.map(&:to_f)
output = data[1].split.map(&:to_f)
#print input;
error = a.train(input, output)
#print error;

ttest = data[2].split.map(&:to_f)
puts "#{data[3]} = > #{a.feed_forward(ttest).inspect}"


File.open("saved.net", 'w') {|f| f.write(Marshal.dump(a)) }
