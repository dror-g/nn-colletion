require 'rubygems'
require 'mlp'
require 'mysql'
error=''
v1=ARGV[0]
v2=ARGV[1]


a = MLP.new(:hidden_layers => [6], :output_nodes => 1, :inputs => 9)
#a = MLP.new(:hidden_layers => [12], :output_nodes => 1, :inputs => 9)
#a = MLP.new(:hidden_layers => [12], :output_nodes => 1, :inputs => 12)
#    eee = Mysql.new 'localhost', 'root', 'qrstrL1$', 'seal'
#mega = eee.query("SELECT D from train group by D")
mega=[["#{v1}"]]
mega.each do |me|
puts "were at megarow #{me}"
count = 0

#    ccc = Mysql.new 'localhost', 'root', 'qrstrL1$', 'seal'
#master = ccc.query("SELECT D from train group by D")
master=[["#{v1}"],["#{v2}"]]
master.each do |m| 
#puts "masterrow is #{m} and megarow is #{me}"
#puts "masterrow is #{v2} and megarow is #{v1}"

#301.times do |e|

  #puts "Error after iteration \t#{error}"# if e%20 == 0
wak=[]
zu=[]
begin

    con = Mysql.new 'localhost', 'root', 'qrstrL1$', 'seal'

	if m[0] == me[0]
 	  rs = con.query("SELECT X,Y,Z from train where D = '#{m[0]}' limit 30")
    rs.each do
        wak << rs.fetch_row.map(&:to_f)
	   end
	else
  	 #rs = con.query("SELECT X,Y,Z from train where D = '#{m[0]}' limit 6")
  	 rs = con.query("SELECT X,Y,Z from train where D = '#{m[0]}' limit 30")
    	rs.each do
        wak << rs.fetch_row.map(&:to_f)
#puts wak[0]
    	end
#puts wak
	end
    #puts "There are #{n_rows} rows in the result set"
    #n_rows.times do
	rescue Mysql::Error => err
    	puts err.errno
    	puts err.error
	ensure
   	 con.close if con
end

#3.times do |e|

(0..9).step(3) do |i|
zu=[wak[i],wak[i+1],wak[i+2]]
zu=zu.flatten(1)

#wak=wak.flatten(1)
#puts m[0]
#puts i
#puts "zu #{zu}"
#puts m[0]
#n_rows.each do |i|
#(0..n_rows).step(3) do |i|


#puts i
#zu[0] = wak.join(",")
#zu[0] = wak[0].concat( wak[1] )
#zu[0] = zu[0].concat( wak[2] )
#zu[0] = zu[0].concat( wak[3] )
#puts zu[0]


#zu[0] = wak[i].concat( wak[i+1] )
#zu[0] = wak[i].concat( wak[i+2] )

#zu[0] = wak[i].concat( wak[i+3] )
#zu[0] = wak[i].concat( wak[i+4] )
#zu[0] = wak[i].concat( wak[i+5] )
#zu[0] = wak[i].concat( wak[i+6] )
#zu[0].pop
#zu[0].pop
#zu[0] = zu[0][0..-3]
#zu[0].delete_at(9)
#zu[0] = zu[0][0..-3]
#puts zi[0]
	if m[0] == me[0]
	  #error = a.train([zu[0]], [9.0])
	  error = a.train(zu, [9.0])
#puts "good"
#puts "0" if e%20 == 0
#puts "sample 0" 
#puts zu[0]
#puts zu[0].class
#puts zi[0]
#puts "--------------"
	else
  	  error = a.train(zu, [0.0])
#puts "bad" 
#puts zu[0]
#puts zu[0]
#puts "--------------"
	end

#  puts "Error after iteration #{e}:\t#{error}" if e%1000 == 0
#end
#break unless error > 0.000001
#  puts "Error after iteration \t#{error}"# if e%20 == 0
end
#count=count+1
#puts count 
#break if count == 2
#next if count == 2
#obj = Marshal.load(File.read('nets/7vs52'))
#end
#File.open("nets/#{me[0]}", 'w') {|f| f.write(Marshal.dump(a)) }
#  puts "Error after iteration \t#{error}"# if e%20 == 0
#File.open("nets/#{me[0]}", 'w') {|f| f.write(Marshal.dump(a)) }
end
puts "done. saving"
File.open("nets/#{v1}vs#{v2}", 'w') {|f| f.write(Marshal.dump(a)) }
  #puts "Error after iteration \t#{error}"# if e%20 == 0
#break
end
#puts "Test data"
#puts "[0] = > #{obj.feed_forward([0.006537767,0.044810944,0.08689782,0.0061291564,0.044810944,0.08689782,0.006537767,0.044810944,0.08689782]).inspect}"
#puts "[1] = > #{obj.feed_forward([0.003405087,0.08308413,0.041405845,0.0038136974,0.08390134,0.042495475,0.0027240697,0.08471856,0.04018002]).inspect}"
#puts "[1] = > #{a.feed_forward([-0.012258313,0.06973618,0.056252027,-0.0156634,0.08076866,0.055162396,-0.006946377,0.076954966,0.04481094]).inspect}"
#puts "[0] = > #{a.feed_forward([0.033097446,-0.09139254,0.13089154,0.038954194,-0.04535576,0.043312707,0.015935807,-0.02969236,0.09220976]).inspect}"
