require 'rubygems'
require 'mlp'
require 'mysql'
obj = Marshal.load(File.read('nets/7'))
wak=[]
zu=[]
begin
    
    con = Mysql.new 'localhost', 'root', 'qrstrL1$', 'seal'

  #rs = con.query("SELECT X,Y,Z from test where S = '100011' limit 50")
  rs = con.query("SELECT X,Y,Z from train where D = '7' limit 3")
    n_rows = rs.num_rows
    puts "There are #{n_rows} rows in the result set"
    #n_rows.times do
    3.times do
        wak << rs.fetch_row.map(&:to_f)
    end
rescue Mysql::Error => e
    puts e.errno
    puts e.error
ensure
    con.close if con
end
#puts wak[0..2]
#puts wak[0]
zu[0] = wak[0].concat( wak[1] )
zu[0] = wak[0].concat( wak[2] )
puts zu[0]


#puts "Test data"
puts "[0] = > #{obj.feed_forward(zu[0]).inspect}"
#puts "[0] = > #{obj.feed_forward([0.006537767,0.044810944,0.08689782,0.0061291564,0.044810944,0.08689782,0.006537767,0.044810944,0.08689782]).inspect}"
#puts "[1] = > #{obj.feed_forward([0.003405087,0.08308413,0.041405845,0.0038136974,0.08390134,0.042495475,0.0027240697,0.08471856,0.04018002]).inspect}"
#puts "[1] = > #{a.feed_forward([-0.012258313,0.06973618,0.056252027,-0.0156634,0.08076866,0.055162396,-0.006946377,0.076954966,0.04481094]).inspect}"
#puts "[0] = > #{a.feed_forward([0.033097446,-0.09139254,0.13089154,0.038954194,-0.04535576,0.043312707,0.015935807,-0.02969236,0.09220976]).inspect}"
