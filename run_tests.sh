#!/usr/bin/env bash
usage() {
cat << EOF
USAGE: ${PROGNAME} [OPTIONS] [syn]

This script runs one or all the tests against both this processor's output and another processor's output

OPTIONS:
  -h, --help             Show this message
  -t, --test FILE        Specific test program to run (can be specified multiple times for more tests)
  -d, --compare-dir DIR  Directory with standard processor simulation to test against
  -q, --quiet            Run in non-interactive mode
  syn                    Run tests in synthesis mode
EOF
}
TMP=`getopt --name=$0 -a --longoptions="help,quiet,compare-dir:,test:" -o="h,q,d:,t:" -- $@`
PROGNAME=$0;
QUIET_MODE=false;
eval set -- $TMP;
until [ $1 == -- ]; do
    case $1 in
        -h|--help)
            usage; exit 1;;
        -d|--compare-dir)
            comp_dir=$2;
            shift;;
        -t|--test)
            prog="${prog} $2";
            shift;;
        -q|--quiet)
            QUIET_MODE=true;;
        *)  #Default unknown option
            usage; exit 1;;
     esac
     shift;
done
shift;
comp_dir=${comp_dir:-./llvsimp4}
if ! [ -f $comp_dir/Makefile ]; then
  echo "In order processor makefile not found in $comp_dir";
  exit 1;
fi
echo "Comparing results against directory in-order proc in $comp_dir";
printf "%-40s %7s %9s %9s %4s\n" "File" "BR ACCR" "Our CPI" "Their CPI" "Test";
for f in ${prog:-test_progs/*.s}
do
	(./vs-asm $f > ./program.mem 2> /dev/null) || exit;
	cp -f ./program.mem $comp_dir/program.mem;
	(make $1 > /dev/null) || exit;
	(cd $comp_dir; make > /dev/null) || exit;
	diff -u -I '^#' $comp_dir/writeback.out writeback.out > results.txt; # Ignore extra comments
  if [ -f $comp_dir/memory.out -a -f memory.out ]; then   # Compare the memories if possible, append the result
  	diff -u -I '^#' $comp_dir/memory.out memory.out >> results.txt; # Ignore extra comments
  fi
	printf "%-40s " "$(basename $f)";
  printf "%7s " `grep "^@.\+Branch Accuracy$" ${1:+${1}_}program.out | cut -d " " -f 8`
	printf "%9.6f " `grep "^@.\+CPI$" ${1:+${1}_}program.out | cut -d " " -f 9`;
	printf "%9.6f" `grep "^@.\+CPI$" ${comp_dir}/program.out | cut -d " " -f 9`;
	if [ -s results.txt ]; then
    grep "@@@ System halted on HALT instruction" program.out &> /dev/null
    if [ $? -ne 0 ]; then
      echo -e " \033[1;37;41mERROR\033[0m";
    else
  		echo -e " \033[1;31mFAIL\033[0m";
    fi
    if ! $QUIET_MODE ; then
  		read -n 1 -p "Continue [Y/n]? " yno 1>&2;
  		echo '' 1>&2;
  		case $yno in
  			[nN] ) 
  				exit 1
  				;;
  			*)
  				;;
  		esac
    fi
	else
		echo -e "\033[1;32m PASS\033[0m";
		rm results.txt;
	fi
done
