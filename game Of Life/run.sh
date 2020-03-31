# Example usage (with the common.s and gameOfLife.s in the same directory):
# ./run.sh
# Enable permission with 'chmod u+x run.sh'


rm -f test.s
cat common.s > test.s
cat gameOfLife.s >> test.s
spim -notrap -mapped_io -f test.s
