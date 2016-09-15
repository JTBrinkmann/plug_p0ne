#! /bin/bash
#(I didn't really test this script yet, pls don't murder me)
line="                  "

# use first argument as output file
output="$1"
filename=$(basename $output .ls)
echo == $filename.ls ==
echo "/*=====================*\\"       >   $output
echo "|* $filename ${line:${#filename}} *|" >> $output
echo "\*=====================*/"        >>   $output
echo>> $output

compiled="$2"
shift
shift

# loop through arguments
for file in "$@"
do
	# append file to the output
	file=$(basename $file)
	echo - $file
	echo "/*@source $file */" >> $output
	if [ "${filename##*.}" == "js" ]; then
		echo ``>>    $output
		echo>>       $output
		cat $file >> $output
		echo>>       $output
		echo ``>>    $output
	else
		cat $file >> $output
	fi
	echo>> $output
	echo>> $output
done

# compile merged LiveScript file
lsc -b -p -c $output > $compiled

# end
echo End