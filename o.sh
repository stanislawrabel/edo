#!/bin/bash

# 🎨 Farby pre výstup
WHITE="\033[37m"
PURPLE="\033[35m" 
YELLOW="\033[33m"
BLUE="\033[34m"
RED="\033[31m"
BLACK="\033[30m"
WHITE="\033[37m"
GREEN="\033[32m"
YELLOW_BG="\033[43m"
GREEN_BG="\033[42m"
RED_BG="\033[41m"
RESET="\033[0m"

OUT="/storage/emulated/0/Download/DownloadeR/ota_common.txt"

mkdir -p "$(dirname "$OUT")"

# 📌 Regióny, verzie a servery
declare -A REGIONS=(
    [00]="EX Export 00000000"
    [A4]="APC Global 10100100"
    [A5]="OCA Oce_Cen_Australia 10100101"
    [A6]="MEA Middle_East_Africa 10100110"
    [A7]="ROW Global 10100111"  
    [1A]="TW Taiwan 00011010"
    [1B]="IN India 00011011"
    [2C]="SG Singapure 00101100" 
    [3C]="VN Vietnam 00111100" 
    [3E]="PH Philippines 00111110"
    [33]="ID Indonesia 00110011" 
    [37]="RU Russia 00110111" 
    [38]="MY Malaysia 00111000"
    [39]="TH Thailand 00111001" 
    [44]="EUEX Europe 01000100" 
    [51]="TR Turkey 01010001"
    [7B]="MX Mexico 01111011" 
    [75]="EG Egypt 01110101" 
    [8D]="EU-NO Europe_Non_GDPR 10001101"
    [83]="SA Saudi_Arabia 10000011" 
    [9A]="LATAM Latin_America 10011010" 
    [9E]="BR Brazil 10011110"
    [97]="CN China 10010111"
)

declare -A VERSIONS=(
  [A]="Launch version" 
  [C]="First update" 
  [F]="Second update" 
  [H]="Third update"
)
declare -A SERVERS=(
  [97]="-r 1" 
  [44]="-r 0" 
  [51]="-r 0"
)

declare -A MODEL_NAMES
while IFS='|' read -r code name; do
MODEL_NAMES["$code"]="$name"
done < models.txt
# Načítanie názvov modelov
declare -A MODEL_NAMES
[[ -f models.txt ]] && while IFS='|' read -r code name; do
  MODEL_NAMES["$code"]="$name"
done < models.txt



resolve_zip() {
  curl -s -I --http1.1 \
    -H "User-Agent: Dalvik/2.1.0 (Linux; Android 16)" \
    -H "userId: oplus-ota|16002018" \
    -H "Accept: */*" \
    -H "Accept-Encoding: identity" \
    "$1" \
  | grep -i '^location:' \
  | tail -1 \
  | awk '{print $2}' \
  | tr -d '\r'
}
fix_old_zip() {
  local url="$1"

  echo "$url" | sed \
    -e 's|gauss-componentotamanual.allawnofs.com|gauss-opexcostmanual-eu.allawnofs.com|'
}


# 📌 Funkcia na spracovanie OTA
run_ota() {
    region_data=(${REGIONS[$region]})
    region_code=${region_data[0]}
    region_name=${region_data[1]}
    nv_id=${region_data[2]}
    server="${SERVERS[$region]:--r 3}"
    ota_model="$device_model"
    for rm in TR RU EEA T2 CN IN ID MY TH ; do 
    ota_model="${ota_model//$rm/}"; 
done

       
    ota_command="realme-ota $server $device_model ${ota_model}_11.${version}.01_0001_100001010001 6 $nv_id"
    
    output=$(eval "$ota_command")

    real_ota_version=$(echo "$output" | grep -o '"realOtaVersion": *"[^"]*"' | cut -d '"' -f4)
    real_version_name=$(echo "$output" | grep -o '"realVersionName": *"[^"]*"' | cut -d '"' -f4)
    os_version=$(echo "$output" | grep -o '"realOsVersion": *"[^"]*"' | cut -d '"' -f4)
    android_version=$(echo "$output" | grep -o '"realAndroidVersion": *"[^"]*"' | cut -d '"' -f4)
    security_os=$(echo "$output" | grep -o '"securityPatchVendor": *"[^"]*"' | cut -d '"' -f4)
    ota_f_version=$(echo "$real_ota_version" | grep -oE '_11\.[A-Z]\.[0-9]+' | sed 's/_11\.//')
    ota_date=$(echo "$real_ota_version" | grep -oE '_[0-9]{12}$' | tr -d '_')
    ota_version_full="${ota_model}_11.${ota_f_version}_${region_code}_${ota_date}"
# Získať URL k About this update
    about_update_url=$(echo "$output" | grep -oP '"panelUrl"\s*:\s*"\K[^"]+')
# Získať VersionTypeId
    version_type_id=$(echo "$output" | grep -oP '"versionTypeId"\s*:\s*"\K[^"]+')

# 🟡 Extrahuj celý obsah poľa "header" z JSON výstupu
header_block=$(echo "$output" | sed -n '/"header"\s*:/,/]/p' | tr -d '\n' | sed -E 's/.*"header"[[:space:]]*:[[:space:]]*([^]+).*/\1/')
# 🔍 Skontroluj obsah poľa na výskyt hodnoty
if echo "$header_block" | grep -q 'forbid_ota_local_update=true'; then
    forbid_status="${RED}❌ Forbidden${RESET}"
elif echo "$header_block" | grep -q 'forbid_ota_local_update=false'; then
    forbid_status="${GREEN}✔️ Allowed${RESET}"
else
    forbid_status="${YELLOW}❓ Unknown${RESET}"
fi


clean_model=$(echo "$device_model" | sed 's/IN\|RU\|TR\|EEA\|T2//g')
model_name="${MODEL_NAMES[$clean_model]:-Unknown}"

# 📋 Výpis ako tabuľka 
echo -e
echo -e "${BLUE}${model_name:-Unknown}${RESET} 
 (${device_model})${GREEN}$region_name${RESET} (code: ${YELLOW}$region_code${RESET})"
echo -e
echo -e "${YELLOW}$ota_version_full${RESET}"
echo -e "${YELLOW}$real_version_name${RESET}"
echo -e "${YELLOW}$android_version${RESET}"
echo -e "${YELLOW}$os_version${RESET}"
echo -e "${YELLOW}$security_os${RESET}"
echo -e "${YELLOW}$version_type_id${RESET}"
echo -e "Local install:" "$forbid_status"
echo -e


    download_link=$(echo "$output" | grep -o 'http[s]*://[^"]*' | head -n 1 | sed 's/["\r\n]*$//')
   modified_link=$(echo "$download_link" | sed 's/componentotamanual/componentotamanual/g')       
fixed_zip=$(fix_old_zip "$download_link")
FINAL_ZIP_URL="$download_link"

if [[ "$download_link" == *"downloadCheck"* ]]; then
    FINAL_ZIP_URL=$(resolve_zip "$download_link")
fi


OUT="/storage/emulated/0/Download/DownloadeR/ota_common.txt"

mkdir -p "$(dirname "$OUT")"

cat > "$OUT" <<EOF
MODEL=$device_model
REGION=$region_data
OTA=$ota_version_full
ANDROID="Android $android_version"
OS="$os_version"
PATCH=$security_os
VERSION=$version_type_id
LOCAL_INSTALL=$local_install_raw
ABOUT="$about_update_url"
DOWNLOAD="$FINAL_ZIP_URL"
EOF


    echo -e "📥    About this update: 
${GREEN}$about_update_url${RESET}"
    if [[ -n "$modified_link" ]]; then
    echo -e "📥    Download link: 
${GREEN}$modified_link${RESET}"
    else
        echo -e "❌ Download link not found."
        
   fi

if [[ -n "$FINAL_ZIP_URL" ]]; then
  echo -e "    📥 Resolved link:\n${GREEN}$FINAL_ZIP_URL${RESET}"
else
  echo "❌ No download link found."
fi
    echo "$ota_version_full" >> "ota_${device_model}.txt"
    echo "$modified_link" >> "ota_${device_model}.txt"
    echo "" >> "ota_${device_model}.txt"

    [[ ! -f ota_links.csv ]] && echo "OTA verzia,Odkaz" > ota_links.csv
    grep -qF "$modified_link" ota_links.csv || echo "$ota_version_full,$modified_link" >> ota_links.csv
}

# 📌 Výber prefixu a modelu
clear

echo -e "${GREEN}+=====================================+${RESET}"
echo -e "${GREEN}|==${RESET} ${GREEN}   OTA FindeR${RESET} ${RED}  by${RESET} ${BLUE}Stano 36${RESET}  ${GREEN}   ==|${RESET}"
echo -e "${GREEN}|${RESET} ${YELLOW_BG}${BLACK}  realme   ${RESET} ${GREEN_BG}${WHITE}   oppo   ${RESET} ${RED_BG}${WHITE}  OnePlus   ${RESET} ${GREEN}|${RESET}"
echo -e "${GREEN}+=====================================+${RESET}"
printf "| %-5s | %-6s | %-18s |\n" "Mani." "R code" "Region"
echo -e "+-------------------------------------+"

# Výpis tabuľky
for key in "${!REGIONS[@]}"; do
    region_data=(${REGIONS[$key]})
    region_code=${region_data[0]}
    region_name=${region_data[1]}

printf "|  ${YELLOW}%-4s${RESET} | %-6s | %-18s |\n" "$key" "$region_code" "$region_name"
done


echo -e "+-------------------------------------+"
echo -e "${GREEN}+=====================================+${RESET}"
echo -e "${GREEN}|==${RESET}" "OTA version :  ${BLUE}A${RESET} ,  ${BLUE}C${RESET} ,  ${BLUE}F${RESET} ,  ${BLUE}H${RESET}"      "${GREEN}==|${RESET}"
echo -e "${GREEN}+=====================================+${RESET}"

# Zoznam prefixov
echo -e " 📦 Choose model:  ${YELLOW}1) RMX${RESET}, ${GREEN}2) CPH${RESET},
           ${BLUE}3) Custom${RESET}, ${PURPLE}4) Selected${RESET}"
read -p " 💡 Select an option (1/2/3/4): " choice
if [[ "$choice" == "4" ]]; then
    if [[ ! -f devices.txt ]]; then
        echo -e "${RED}❌ Súbor devices.txt neexistuje.${RESET}"
        exit 1
    fi

    echo -e "\n📱 ${PURPLE}Selected device list :${RESET}"
  echo -e "${GREEN}+======================================+${RESET}"
  printf "| %-3s | %-30s |\n" "No." "Model" 
    echo -e "+-----+--------------------------------+"

    mapfile -t lines < devices.txt
        total=${#lines[@]}  # aby podmienka pre rozsah fungovala správne
    for i in "${!lines[@]}"; do
        index=$((i + 1))
        IFS='|' read -r model region version <<< "${lines[$i]}"
# Pôvodný model z devices.txt
clean_model=$(echo "$model" | grep -oE '(RMX|CPH|PK[A-Z]|PJ[A-Z]|PG[A-Z]|PH[A-Z])[0-9]{3,4}')

if [[ -n "$clean_model" && -n "${MODEL_NAMES[$clean_model]}" ]]; then
    device_name="${BLUE}MODEL_NAMES${RESET}[$clean_model]}"
else
    device_name="Unknown"
fi
device_name="${MODEL_NAMES[$clean_model]:-Unknown}"

printf "| ${RED}%-3s${RESET} | ${GREEN}%-30s${RESET} |\n" "$index" "$device_name" 
    done

    echo -e "+-----+--------------------------------+"
  echo -e "${GREEN}+======================================+${RESET}"

  read -p "🔢 Select device number: " selected

if [[ "$selected" == "A" || "$selected" == "a" ]]; then
    echo -e "${PURPLE}▶ Running OTA check for all devices...${RESET}"
    for line in "${lines[@]}"; do
        IFS='|' read -r selected_model selected_region selected_version <<< "$line"
        device_model="$(echo "$selected_model" | xargs)"
        region="$(echo "$selected_region" | xargs)"
        version="$(echo "$selected_version" | xargs)"
        
        run_ota
    done
fi

if ! [[ "$selected" =~ ^[0-9]+$ ]] || (( selected < 1 || selected > total )); then
    echo "❌ Invalid selection."; exit 1
fi

IFS='|' read -r selected_model selected_region selected_version <<< "${lines[$((selected-1))]}"
device_model="$(echo "$selected_model" | xargs)"
region="$(echo "$selected_region" | xargs)"
version="$(echo "$selected_version" | xargs)"

echo -e "✅ Selected device: ${BLUE}$device_model${RESET}, ${YELLOW}$region${RESET}, ${BLUE}$version${RESET}"
else
    if [[ "$choice" == "1" ]]; then
        COLOR=$YELLOW
    elif [[ "$choice" == "2" ]]; then
        COLOR=$GREEN
    elif [[ "$choice" == "3" ]]; then
        COLOR=$BLUE
    else
        COLOR=$RESET
    fi

    echo -e "${COLOR}➡️  You selected option $choice${RESET}"

    case $choice in
        1) prefix="RMX" ;;
        2) prefix="CPH" ;;
        3)
            read -p "🧩 Enter your custom prefix (e.g. XYZ): " prefix
            if [[ -z "$prefix" ]]; then
                echo "❌ Prefix cannot be empty."
                exit 1
            fi
            ;;
        *) echo "❌ Invalid choice."; exit 1 ;;
    esac

    read -p "🔢 Enter model number : " model_number
    device_model="${prefix}${model_number}"
    echo -e "✅ Selected model: ${COLOR}$device_model${RESET}"

    read -p "📌 Manifest + OTA version : " input
    region="${input:0:${#input}-1}"
    version="${input: -1}"

    if [[ -z "${REGIONS[$region]}" || -z "${VERSIONS[$version]}" ]]; then
        echo -e "❌ Invalid input! Exiting."
        exit 1
    fi
fi

run_ota

# 🔁 Cyklus pre ďalšie voľby
while true; do
    echo -e "\n🔄 1 - Change only region/version"
    echo -e "🔄 2 - Change device model"
    echo -e "❌ 3 - End script"
    echo -e "⬇️  4 -${GREEN}$Show URLs${RESET} (long press to open the menu)"
    echo -e "     → More > Select URL"
    echo -e "     → ${PURPLE}Tap to copy the link${RESET}, ${BLUE}long press to open in browser${RESET}"
    read -p "💡 Select an option (1/2/3): " option
    case "$option" in
        1)
            read -p "📌 Manifest + OTA version (e.g. 33F): " input
            region="${input:0:${#input}-1}"
            version="${input: -1}"
            if [[ -z "${REGIONS[$region]}" || -z "${VERSIONS[$version]}" ]]; then
                echo "❌ Invalid input."
                continue
            fi
            run_ota
            ;;
        2)
            bash "$0"  # reštart skriptu
            ;;
        3)
            echo -e "👋 Goodbye."
            exit 0
            ;;
        *)
            echo "❌ Invalid option."
            ;;
    esac
done
