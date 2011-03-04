#!/usr/bin/env bash
printf "%-40s %-8s %-4s\n" "File" "CPI" "Test";
for f in test_progs/*.s
do
	(./vs-asm $f > ./program.mem) || exit;
	cp -f ./program.mem ../vsimp4_w11/program.mem;
	(make $1 > /dev/null) || exit;
	(cd ../vsimp4_w11; make > /dev/null) || exit;
	diff writeback.out ../vsimp4_w11/writeback.out > results.txt;
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
