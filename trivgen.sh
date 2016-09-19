#!/bin/bash

HELP_STRING="Supported options:
	-h			show this help
	-c <number>		number of categories
	-C <number>		number of cards
	--data <file>		data file (specify several times, one per cat.)
	-o <file>		output HTML file
	-V			verbose execution

	Example call:
	 ./trivgen.sh -c6 -C100 --data cat1.txt --data cat2.txt --data cat3.txt --data cat4.txt --data cat5.txt --data cat6.txt -o trivial.html
"

verbose_msg() {
	if [ "$VERBOSE" != "y" ] ; then
		return
	fi
	echo "INFO: $1"
}

DATA_COUNT=0
DATA_LIST=""

while getopts "Vhc:C:o:-:" opt; do
	case $opt in
	V)
		VERBOSE=y
	;;
	h)
		echo "$HELP_STRING"
		exit 0
	;;
	c)
		if [ -z "${OPTARG}" ] ; then
			echo "E: missing argument for -c"
			exit 1
		fi
		CAT_COUNT=$OPTARG
	;;
	C)
		if [ -z "${OPTARG}" ] ; then
			echo "E: missing argument for -C"
			exit 1
		fi
		CARDS_COUNT=$OPTARG
	;;
	-)
		case "${OPTARG}" in
		data)
			((DATA_COUNT++))
			file=${!OPTIND}; OPTIND=$(( $OPTIND + 1 ))
			DATA_LIST="$DATA_LIST $file"
		;;
		esac
	;;
	o)
		if [ -z "${OPTARG}" ] ; then
			echo "E: missing argument for -o"
			exit 1
		fi
		OUTPUT_FILE=$OPTARG
	;;
	\?)
		echo "Invalid option: Try -h" >&2
		exit 1
	;;
	esac
done

#
# validations
#

if [ -z "$CAT_COUNT" ] ; then
	echo "E: Missing number of categories" >&2
	exit 1
fi

if [ -z "$CARDS_COUNT" ] ; then
	echo "E: Missing number of cards" >&2
	exit 1
fi

if [ "$DATA_COUNT" != "$CAT_COUNT" ] ; then
	echo "E: Different number of categories and data files" >&2
	exit 1
fi

if [ -z "$OUTPUT_FILE" ] ; then
	echo "E: Missing output file" >&2
	exit 1
fi

verbose_msg "First validations passed"

# data files existence
for data_file in $DATA_LIST ; do
	if [ ! -r "$data_file" ] ; then
		echo "E: Can't read data file $data_file" >&2
		exit 1
	fi
done

verbose_msg "All datafiles seems to exists"

# number of lines
for data_file in $DATA_LIST ; do
	verbose_msg "Checking datafile $data_file for number of lines"

	nl=$(wc -l $data_file | awk -F' ' '{print $1}')
	if [ ! -z "$next" ] ; then
		if [ "$nl" -ne "$next" ] ; then
			echo "E: Wrong number of lines in $data_file" >&2
			exit 1
		fi
	fi
	next=$nl
done

#number of cards
for data_file in $DATA_LIST ; do
	verbose_msg "Checking datafile $data_file for format"
	for (( i=1; i<=${CARDS_COUNT}; i++ )) ; do
		if ! grep ^${i}Q: $data_file >/dev/null ; then
			echo "E: Missing question in data file $data_file $i" >&2
			exit 1
		fi
		if ! grep ^${i}A: $data_file >/dev/null ; then
			echo "E: Missing answer in data file $data_file $i" >&2
			exit 1
		fi
	done
done

verbose_msg "All validations passed"

HTML_TEMPLATE_INIT="<!DOCTYPE html>
<html>
	<head>
		<meta charset=\"utf-8\">
		<title>trivgen.sh output</title>
		<link rel=\"stylesheet\" href=\"trivgen.css\" />
	</head>
	<body>
"

HTML_TEMPLATE_FINI="
	</body>
</html>"

QCARD_TMPL_INIT="
		<table class=\"card_q\" >
			<tbody>"

Q_TMPL_INIT="			<tr>
					<td class=\"card_td_cat"
Q_TMPL_INIT_CLOSE="\" >"

Q_TMPL_MID="				</td><td>"
Q_TMP_FINI="				</td>
				</tr>"

QCARD_TMPL_FINI="	</tbody>
		</table>"

SEPARATOR_TMPL="<br/>"
#<div class=\"card_separator\"></div>"

ACARD_TMPL_INIT="<div class=\"card_a\">
		<div class=\"logo\">
		<img src=\"logo_extraviaos.jpg\"/>
		</div>
		<div class=\"tajeta_respuestas\">
		<table class=\"card_a_table\" >
			<tbody>"

A_TMPL_INIT="			<tr>
					<td class=\"card_td_cat"
A_TMPL_INIT_CLOSE="\" >"

A_TMPL_MID="				</td><td>"
A_TMP_FINI="				</td>
				</tr>"

ACARD_TMPL_FINI="	</tbody>
		</table></div></div>"

PAGEBREAK="<p style=\"page-break-after:always;\"><!-- pagebreak --></p>"


#
# Main execution
#

verbose_msg "Main execution"

echo "$HTML_TEMPLATE_INIT" > $OUTPUT_FILE

pagebreak=0
for (( i=1; i<=$CARDS_COUNT; i++ )) ; do
	verbose_msg "Generating card $i"
	((pagebreak++))

	echo "<p>card $i</p><br/>" >> $OUTPUT_FILE

	#
	# question face
	#

	echo "$QCARD_TMPL_INIT" >> $OUTPUT_FILE

	c=0
	for data_file in $DATA_LIST ; do
		((c++))
		echo -n "$Q_TMPL_INIT" >> $OUTPUT_FILE
		# css category
		echo -n "$c" >> $OUTPUT_FILE
		echo "$Q_TMPL_INIT_CLOSE" >> $OUTPUT_FILE

		# category name
		head -n 1 $data_file >> $OUTPUT_FILE

		QUESTION=$(grep ^${i}Q: $data_file | awk -F':' '{print $2}')
		echo "$Q_TMPL_MID" >> $OUTPUT_FILE
		echo $QUESTION >> $OUTPUT_FILE
		echo "$Q_TMPL_FINI" >> $OUTPUT_FILE
	done
	echo "$QCARD_TMPL_FINI" >> $OUTPUT_FILE

	echo "$CARD_SEPARATOR" >> $OUTPUT_FILE

	#
	# answer face
	#

	echo "$ACARD_TMPL_INIT" >> $OUTPUT_FILE

	c=0
	for data_file in $DATA_LIST ; do
		((c++))
		echo -n "$A_TMPL_INIT" >> $OUTPUT_FILE
		# css category
		echo -n "$c" >> $OUTPUT_FILE
		echo "$A_TMPL_INIT_CLOSE" >> $OUTPUT_FILE

		# category name
		head -n 1 $data_file >> $OUTPUT_FILE

		QUESTION=$(grep ^${i}A: $data_file | awk -F':' '{print $2}')
		echo "$A_TMPL_MID" >> $OUTPUT_FILE
		echo $QUESTION >> $OUTPUT_FILE
		echo "$A_TMPL_FINI" >> $OUTPUT_FILE
	done

	echo "$ACARD_TMPL_FINI" >> $OUTPUT_FILE

	echo "<p/>" >> $OUTPUT_FILE

	if [ "$pagebreak" == "3" ] ; then
		echo "$PAGEBREAK" >> $OUTPUT_FILE
		pagebreak=0
	fi
done


echo "$HTML_TEMPLATE_FINI" >> $OUTPUT_FILE

verbose_msg "Done"
