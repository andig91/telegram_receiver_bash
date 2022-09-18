#!/bin/bash

cd "$(dirname -- "$0")"
mkdir -p history_messages

#next=$(sed -n 1p last_id.txt)
next=$(($(sed -n 1p last_id.txt)+1))
while true; do
	#checkAviable=$(curl "https://api.telegram.org/bot$(sed -n 1p cred.txt)/getUpdates?offset=566435895&limit=1" --compressed | grep -vc "result\":\[\]")
	checkAviable=$(curl "https://api.telegram.org/bot$(sed -n 1p cred.txt)/getUpdates?offset=$next&limit=1" --compressed | jq '.result | length')


	# Denke, dass es hier einen Fehler gibt da es auch andere Anworten als 0 und 1 geben koennte und daher es zu Falschantworten kommt
	# 1 sollte die einzig richtige Antwort sein
	#if [ ! "$checkAviable" = "0" ]
	if [ "$checkAviable" = "1" ]
	then
		echo "Nachricht da"
		curl "https://api.telegram.org/bot$(sed -n 1p cred.txt)/getUpdates?offset=$next&limit=1" > lastMessage.txt
		timeMessage=$(date +"%Y%m%d_%H%M%S")
		cp lastMessage.txt "history_messages/"$timeMessage"_message.txt"
		update_id=$(cat lastMessage.txt | jq '.result[] | .update_id ')

		# Welche Art der Nachricht
		if [ ! $(cat lastMessage.txt | jq -r '.result[].message | length') = "0" ]
		then
			#echo "Normale Nachricht"
			#sleep 1
			from=$(cat lastMessage.txt | jq '.result[] | .message.from.id ')
			text=$(cat lastMessage.txt | jq -r '.result[] | .message.text ' | awk '{print tolower($0)}' )
		fi

		if [ ! $(cat lastMessage.txt | jq -r '.result[].callback_query | length') = "0" ]
		then
			#echo "Inline Nachricht"
			#sleep 1
			from=$(cat lastMessage.txt | jq '.result[] | .callback_query.from.id ')
			text=$(cat lastMessage.txt | jq -r '.result[] | .callback_query.data ' | awk '{print tolower($0)}' )
		fi

		# Alles mit InlineKeyboard geloest, darum keine Umfragen mehr
		#if [ ! $(cat lastMessage.txt | jq -r '.result[].poll_answer | length') = "0" ]
		#then
		#	echo "Poll Antwort Nachricht"
		#	sleep 1
		#	from=$(cat lastMessage.txt | jq '.result[] | .poll_answer.user.id ')
		#	text=$(cat lastMessage.txt | jq -r '.result[] | .poll_answer.option_ids[0] ' | awk '{print tolower($0)}' )
		#fi

		echo "Nummer: $update_id von $from mit $text"
		echo "Nummer: $update_id von $from mit $text" >> "history_messages/"$timeMessage"_message.txt"
		echo "$update_id" > last_id.txt

		next=$(($update_id+1))

		echo "$next"


		# Mehrere moegliche Absender, Zeile 2, 3 und 4 in cred.txt
		#if [ "$from" = "$(sed -n 2p cred.txt)" ] || [ "$from" = "$(sed -n 3p cred.txt)" ] || [ "$from" = "$(sed -n 4p cred.txt)" ]
		# Ein Absender, zweile 2 in cred.txt
		if [ "$from" = "$(sed -n 2p cred.txt)" ]
		then
			echo "Richtiger Absender"

			if [ "$text" = "help" ]
			then
				verstanden=1
				#Alte Version Poll/Umfrage
				#curl -X POST -H "Content-Type: application/json" -d '{"is_anonymous":false,"options":["Schweden","Norwegen","Schweiz","IP"]}' "https://api.telegram.org/bot$(sed -n 1p cred.txt)/sendPoll?chat_id=$from&question=Was soll passieren"
				#Neue Version Inline Keyboard
				curl -X POST -H "Content-Type: application/json" -d '{"reply_markup":{"keyboard": [[{"text": "Schweden","callback_data": "schweden"},{"text": "Norwegen","callback_data": "norwegen"}],[{"text": "Schweiz","callback_data": "schweiz"},{"text": "IP","callback_data": "ip"}],[{"text": "Tastatur_ausblenden","callback_data": "ausblenden"}]]}}' "https://api.telegram.org/bot$(sed -n 1p cred.txt)/sendMessage?chat_id=$from&text=Was soll passieren%3F"
				echo "$(date +"%Y%m%d_%H%M%S");$update_id;$from;$text;Help-Anfrage" >> history.txt
			fi

			#if [ "$text" = "schweden" ] || [ "$pollanswer" = "0" ]
			if [ "$text" = "schweden" ]
			then
				verstanden=1
				vpnauswahl=schweden
				vpn=1
			fi

			if [ "$text" = "norwegen" ]
			then
				verstanden=1
				vpnauswahl=norwegen
				vpn=1
			fi

			if [ "$text" = "schweiz" ]
			then
				verstanden=1
				vpnauswahl=schweiz
				vpn=1
			fi

			if [ "$vpn" = "1" ]
			then
				sudo service openvpn stop
				sleep 5
				sudo service openvpn@$vpnauswahl start
				sleep 15
				ip=$(curl ifconfig.me)
				curl "https://api.telegram.org/bot$(sed -n 1p cred.txt)/sendMessage?chat_id=$from" -d text="text=VPN Verbindung mit $vpnauswahl erneut aufgebaut, die IP lautet $ip"
				echo "$(date +"%Y%m%d_%H%M%S");$update_id;$from;$text;VPN $vpnauswahl $ip" >> history.txt
				vpn=0
			fi

			if [ "$text" = "ip" ]
			then
				verstanden=1
				ip=$(curl ifconfig.me)
				curl "https://api.telegram.org/bot$(sed -n 1p cred.txt)/sendMessage?chat_id=$from" -d text="text=Die IP lautet $ip"
				echo "$(date +"%Y%m%d_%H%M%S");$update_id;$from;$text;IP Abfrage $ip" >> history.txt
			fi

			if [ "$text" = "tastatur_ausblenden" ]
			then
				verstanden=1
				curl -X POST -H "Content-Type: application/json" -d '{"reply_markup":{"remove_keyboard": true }}' "https://api.telegram.org/bot$(sed -n 1p cred.txt)/sendMessage?chat_id=$from&text=OK"
				echo "$(date +"%Y%m%d_%H%M%S");$update_id;$from;$text;Tastatur ausblenden" >> history.txt
			fi


			if [ ! "$verstanden" = "1" ]
			then
				curl "https://api.telegram.org/bot$(sed -n 1p cred.txt)/sendMessage?chat_id=$from&text=Kommando nicht bekannt"
				echo "$(date +"%Y%m%d_%H%M%S");$update_id;$from;$text;Befehl nicht verstanden" >> history.txt
			fi

		else
			echo "Falscher Absender"
			echo "$(date +"%Y%m%d_%H%M%S");$update_id;$from;$text;User nicht authorisiert" >> history.txt
		fi
		verstanden=0
	fi
	sleep 2
done
