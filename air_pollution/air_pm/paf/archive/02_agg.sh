#source: bash /home/j/WORK/2013/05_risk/01_database/02_data/air_pm/04_paf/04_models/code/02_agg.sh

# declare variables
ISOS=("AFG" "AGO" "ALB" "AND" "ARE" "ARG" "ARM" "ATG" "AUS" "AUT" "AZE" "BDI" "BEL" "BEN" "BFA" "BGD" "BGR" "BHR" "BHS" "BIH" "BLR" "BLZ" "BOL" "BRA" "BRB" "BRN" "BTN" "BWA" "CAF" "CAN" "CHE" "CHL" "CHN" "CHN_354" "CHN_361" "CHN_491" "CHN_492" "CHN_493" "CHN_494" "CHN_495" "CHN_496" "CHN_497" "CHN_498" "CHN_499" "CHN_500" "CHN_501" "CHN_502" "CHN_503" "CHN_504" "CHN_505" "CHN_506" "CHN_507" "CHN_508" "CHN_509" "CHN_510" "CHN_511" "CHN_512" "CHN_513" "CHN_514" "CHN_515" "CHN_516" "CHN_517" "CHN_518" "CHN_519" "CHN_520" "CHN_521" "CIV" "CMR" "COD" "COG" "COL" "COM" "CPV" "CRI" "CUB" "CYP" "CZE" "DEU" "DJI" "DMA" "DNK" "DOM" "DZA" "ECU" "EGY" "ERI" "ESP" "EST" "ETH" "FIN" "FJI" "FRA" "FSM" "GAB" "GBR" "GBR_433" "GBR_434" "GBR_4618" "GBR_4619" "GBR_4620" "GBR_4621" "GBR_4622" "GBR_4623" "GBR_4624" "GBR_4625" "GBR_4626" "GBR_4636" "GEO" "GHA" "GIN" "GMB" "GNB" "GNQ" "GRC" "GRD" "GTM" "GUY" "HND" "HRV" "HTI" "HUN" "IDN" "IND" "IRL" "IRN" "IRQ" "ISL" "ISR" "ITA" "JAM" "JOR" "JPN" "KAZ" "KEN" "KGZ" "KHM" "KIR" "KOR" "KWT" "LAO" "LBN" "LBR" "LBY" "LCA" "LKA" "LSO" "LTU" "LUX" "LVA" "MAR" "MDA" "MDG" "MDV" "MEX" "MEX_4643" "MEX_4644" "MEX_4645" "MEX_4646" "MEX_4647" "MEX_4648" "MEX_4649" "MEX_4650" "MEX_4651" "MEX_4652" "MEX_4653" "MEX_4654" "MEX_4655" "MEX_4656" "MEX_4657" "MEX_4658" "MEX_4659" "MEX_4660" "MEX_4661" "MEX_4662" "MEX_4663" "MEX_4664" "MEX_4665" "MEX_4666" "MEX_4667" "MEX_4668" "MEX_4669" "MEX_4670" "MEX_4671" "MEX_4672" "MEX_4673" "MEX_4674" "MHL" "MKD" "MLI" "MLT" "MMR" "MNE" "MNG" "MOZ" "MRT" "MUS" "MWI" "MYS" "NAM" "NER" "NGA" "NIC" "NLD" "NOR" "NPL" "NZL" "OMN" "PAK" "PAN" "PER" "PHL" "PNG" "POL" "PRK" "PRT" "PRY" "PSE" "QAT" "ROU" "RUS" "RWA" "SAU" "SDN" "SEN" "SGP" "SLB" "SLE" "SLV" "SOM" "SRB" "SSD" "STP" "SUR" "SVK" "SVN" "SWE" "SWZ" "SYC" "SYR" "TCD" "TGO" "THA" "TJK" "TKM" "TLS" "TON" "TTO" "TUN" "TUR" "TWN" "TZA" "UGA" "UKR" "URY" "USA" "UZB" "VCT" "VEN" "VNM" "VUT" "WSM" "YEM" "ZAF" "ZMB" "ZWE")
YEARS=(1990 1995 2000 2005 2010 2013)
VERSION=26

# EXPOSURE
DIR="/home/j/WORK/2013/05_risk/01_database/02_data/air_pm/01_exp/05_products/iso3_draws/${VERSION}/summary"
SAVE_DIR="/home/j/WORK/2013/05_risk/01_database/02_data/air_pm/01_exp/05_products/iso3_draws/${VERSION}/summary"
# copy the first line of the first file into a new file, adding new columns for iso3/year
head -n1 "${DIR}/${ISOS[0]}_${YEARS[0]}.csv" | sed "s/$/,iso3,year/" > "${SAVE_DIR}/all_exposure_v${VERSION}.csv"
 
# loop through files
for i in "${ISOS[@]}"
do
    for y in "${YEARS[@]}"
	do
		# append remaining lines from each file, adding on new columns
		# "1,1d" removes the first line
		# "s/$/,${i},${s},${y}"" adds new columns to each line for iso and year
		sed  -e "1,1d" -e "s/$/,${i},${y}/" "${DIR}/${i}_${y}.csv" >> "${SAVE_DIR}/all_exposure_v${VERSION}.csv"
    done
done

# SUMMARY FILES YLD:
DIR="/clustertmp/WORK/05_risk/03_outputs/02_results/air_pm/${VERSION}/summary"
SAVE_DIR="/home/j/WORK/05_risk/01_database/02_data/air_pm/04_paf/04_models/output/summary"
# copy the first line of the first file into a new file, adding new columns for iso3/year
head -n1 "${DIR}/paf_yld_${ISOS[0]}_${YEARS[0]}.csv" | sed "s/$/,iso3,year/" > "${SAVE_DIR}/all_pafs_yld_compiled_v${VERSION}.csv"
 
# loop through files
for i in "${ISOS[@]}"
do
    for y in "${YEARS[@]}"
	do
		# append remaining lines from each file, adding on new columns
		# "1,1d" removes the first line
		# "s/$/,${i},${s},${y}"" adds new columns to each line for iso and year
		sed  -e "1,1d" -e "s/$/,${i},${y}/" "${DIR}/paf_yld_${i}_${y}.csv" >> "${SAVE_DIR}/all_pafs_yld_compiled_v${VERSION}.csv"
    done
done

# SUMMARY FILES YLL:
DIR="/clustertmp/WORK/05_risk/03_outputs/02_results/air_pm/${VERSION}/summary"
SAVE_DIR="/home/j/WORK/05_risk/01_database/02_data/air_pm/04_paf/04_models/output/summary"
# copy the first line of the first file into a new file, adding new columns for iso3/year
head -n1 "${DIR}/paf_yll_${ISOS[0]}_${YEARS[0]}.csv" | sed "s/$/,iso3,year/" > "${SAVE_DIR}/all_pafs_yll_compiled_v${VERSION}.csv"
 
# loop through files
for i in "${ISOS[@]}"
do
    for y in "${YEARS[@]}"
	do
		# append remaining lines from each file, adding on new columns
		# "1,1d" removes the first line
		# "s/$/,${i},${s},${y}"" adds new columns to each line for iso and year
		sed  -e "1,1d" -e "s/$/,${i},${y}/" "${DIR}/paf_yll_${i}_${y}.csv" >> "${SAVE_DIR}/all_pafs_yll_compiled_v${VERSION}.csv"
    done
done
# DRAWS:
DIR="/clustertmp/WORK/05_risk/03_outputs/02_results/air_pm/${VERSION}/draws"
SAVE_DIR="/home/j/WORK/05_risk/01_database/02_data/air_pm/04_paf/04_models/output/draws"
# copy the first line of the first file into a new file, adding new columns for iso3/year
head -n1 "${DIR}/${ISOS[0]}_${YEARS[0]}.csv" | sed "s/$/,iso3,year/" > "${SAVE_DIR}/all_pafs_compiled_v${VERSION}.csv"

# loop through files
for i in "${ISOS[@]}"
do
    for y in "${YEARS[@]}"
	do
		# append remaining lines from each file, adding on new columns
		# "1,1d" removes the first line
		# "s/$/,${i},${s},${y}"" adds new columns to each line for iso and year
		sed  -e "1,1d" -e "s/$/,${i},${y}/" "${DIR}/${i}_${y}.csv" >> "${SAVE_DIR}/all_pafs_compiled_v${VERSION}.csv"
    done
done

