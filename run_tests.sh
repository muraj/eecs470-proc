#!/usr/bin/env bash
usage() {
cat << EOF
USAGE: $0 [OPTIONS] [syn]

This script runs one or all the tests against both this processor's output and another processor's output

OPTIONS:
  -h, --help            Show this message
  -t, --test            Specific test program to run
  -d, --compare-dir     Directory with standard processor simulation
  syn                   Run tests in synthesis mode
EOF
}
TMP=`getopt --name=$0 -a --longoptions="help,compare-dir:,test:" -o="h,d:,t:" -- $@`
eval set -- $TMP;
until [ $1 == -- ]; do
    case $1 in
        -h|--help)
            usage; exit 1;;
        -d|--compare-dir)
            comp_dir=$2;;
        -t|--test)
            prog=$2;;
        *)  #Default unknown option
            usage; exit 1;;
     esac
     shift;
done
shift;
comp_dir=${comp_dir:-./vsimp4_w11}
if ! [ -f $comp_dir/Makefile ]; then
  echo "In order processor makefile not found in $comp_dir";
  exit 1;
fi
echo "Comparing results against directory in-order proc in $comp_dir";
printf "%-40s %-8s %-4s\n" "File" "CPI" "Test";
for f in ${prog:-test_progs/*.s}
do
	(./vs-asm $f > ./program.mem) || exit;
	cp -f ./program.mem $comp_dir/program.mem;
	(make $1 > /dev/null) || exit;
	(cd $comp_dir; make > /dev/null) || exit;
	diff -I '^#' writeback.out $comp_dir/writeback.out > results.txt; # Ignore extra comments
	printf "%-40s " "$(basename $f)";
	printf "%-8s" `grep CPI ${1:+${1}_}program.out | cut -d " " -f 9`;
	if [ -s results.txt ]; then
		echo -e "\033[31m FAIL\033[0m";
		read -n 1 -p "Continue [Y/n]? " yno 1>&2;
		echo '' 1>&2;
		case $yno in
			[nN] ) 
				exit 1
				;;
			*)
				;;
		esac
	else
		echo -e "\033[32m PASS\033[0m";
		rm results.txt;
	fi
done
