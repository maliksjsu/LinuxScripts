#!/usr/bin/sh

arr=(~/Documents/Droid/*)
length=${#arr[@]}
#echo $length
function pause(){
        local message="$@"
        [ -z $message ] && message="Press [Enter] key to continue..."
        read -p "$message" readEnterKey
}

for ((i=1; i<${#arr[@]}; i++)) ;do
	#temp="${arr[i]}"
	temp=$(echo "${arr[i]}"| awk -F '[/=]' '{print $7}'|xargs)
	
	echo $temp
	
	echo "\n[Checking all the brances]"
	git branch -a 
	
	echo -e  "\n[Making a new branch]: $temp"
	git checkout -b $temp
	pause
	
	echo "\n[Copying the files from ~/Documents/Droid/$temp] "
	cp -r ~/Documents/Droid/$temp .
	ls 
	pause 

	echo "\n[Check Status]"
	git status 
	pause 

	echo "\n[Adding GIT .]"
	git add . 
	pause 

	echo "\n[Check Status]"
	git status 
	pause 

	echo "\n[Commiting all the files]"
	git commit -m "Added to Repo by Malik - Command Line"
	pause 

	echo "\n[PUSHING TO ORIGING]"
	git push origin $temp
	pause 

	echo "\n[Check Branches]"
	git branch -a 
	pause 

	echo "\n[Going to master branch now]"
	git checkout master 
	pause 

	echo -e "\n[Deleting local branch]: $temp "
	git branch -D $temp 
	pause 

	echo "DONE"

	
	#jump=$($temp | awk -F '[/=]' '{print $5}')
	#echo $temp
	#name= ($temp| awk -F '[/=]' '{print $7}')
	#echo $name
done

#echo $temp
#echo "${arr[2]}" | awk -F '[/=]' '{print $6}'
