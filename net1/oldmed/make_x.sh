rm image_spam.net
echo "10 22500 1" > training.data 
for i in `ls xo/x/*`; do ./image2fann_invert $i 1 >> training.data; done
for i in `ls xo/o/*`; do ./image2fann_invert $i -1 >> training.data; done

echo "6 22500 1" > test.data 
for i in `ls xo/test/x/*`; do ./image2fann_invert $i 1 >> test.data; done
for i in `ls xo/test/o/*`; do ./image2fann_invert $i -1 >> test.data; done
./train
echo "done training. testing:"
./test
