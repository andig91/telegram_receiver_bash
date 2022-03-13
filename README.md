### Telegram Receiver  

Telegram receiver als Bash-Skript umgesetzt  

#### Curl und JQ installieren  
`sudo apt install openvpn curl jq -y`  

#### cred.txt anpassen  
1. Zeile Bot-Token
Jede weitere Zeile, erlaubte User-IDs (muss in Code aktiviert werden)

#### Ausfuehrbar machen  
`chmod +x receive_commands.sh`  

#### Ausfuehren  

##### Einmalig  
`./receive_commands.sh`  

##### Als Cronjob  
`crontab -e`  
`@reboot /<base>/<directory>/telegram/receive_commands.sh > /dev/null 2>&1`  

#### Code Aufbau  
Aktuell sind Abfragen ob Nachricht verfügbar, Berechtigungskontrolle und alle Verzweigungen alle in einem Skript.  
**Zukunftsvision:**  
Statt der Befehle kann der Text/Befehl oder das komplette JSON-File an ein anderes Programm/Skript weitergegeben werden.  
