# author: JF
# date: 02/08/2016
# purpose: append all the country gridded files into one global gridded file, then append subnationals into national gridded files
# bash /homes/jfrostad/_code/risks/air_pm/paf/agg.sh

##GLOBAL FILE##
# declare variables
#VERSION=$1
VERSION=13 #annualized draw version
LOC=4769
DIR="/share/gbd/WORK/05_risk/02_models/02_results/air_pm/paf/${VERSION}/annual_draws"
OUTPUT="${DIR}/all.csv"

cd ${DIR}

# make sure that you haven't already created a global file (do this before you create the ISOS var)
if [ -f $OUTPUT ] ; then
    rm $OUTPUT
fi

# pull in all the country files as an array
ISOS=(`ls -d paf_yll_${LOC}_****_2.csv`)
 
# copy the first line of the first file into a new file, adding new columns for iso3
head -n1 "${DIR}/${ISOS[0]}" | sed "s/$/,iso3/" > "${OUTPUT}"
 
# loop through files
for f in "${ISOS[@]}"
do

    i="${f[@]%.csv}" #remove the file extension (only want iso3)
    echo "${i}" # print current loop status

    # append remaining lines from each file, adding on new columns
    # "1,1d" removes the first line
    # "s/$/,${i}" adds new columns to each line for iso
    sed  -e "1,1d" -e "s/$/,${i}/" "${DIR}/${f}" >> "${OUTPUT}"

done
