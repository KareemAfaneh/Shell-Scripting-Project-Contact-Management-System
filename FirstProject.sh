#!/bin/sh

# this while loop checks the vaildation of the file entered
while true
do
	# to read the file name from the user
	echo "Please enter the name of the contact file: or (%) to exit. "
	read filename
	if [ "$filename" = "%" ]	#if % entered then exit from the program
	then 	exit 1
	elif [ ! -e "$filename" ]
	then	echo "Sorry your file does not exist!"
	elif [ ! -f "$filename" ]
	then	echo "Sorry the file is not an ordinary file!"
	elif [ ! -r "$filename" -o ! -w "$filename" ]	# the file permision does not allowed you to read from the file or write on it
	then 	echo "Error: Permision denied!"
	else
		break
	fi
done
# this statement save the first line in the file which should contains the headers [first name,last name, phone numbers,email]
header=$(sed -n '1p' $filename)
#in this loop we will check if the header is as needed, otherwise we will exit from the program
for i in 1 2 3 4
do
	# cut the header line based on the comma (,) and get the filed accoeding to i as a counter
	var=$(echo $header | cut -d',' -f"$i")
	# xargs will trim all spaces in the first and end, and then convert all capital letters to small letters
	var=$(echo $var | xargs | tr '[A-Z]' '[a-z]')
	if [ "$var" = "first name" ]
		then fn=$i	# the field number that contains the first name
	elif [ "$var" = "last name" ]
		then la=$i	# the field number that contains the last name
	elif [ "$var" = "phone numbers" ]
		then ph=$i	# the field number that contains the phone numbers
	elif [ "$var" = "email" ]
		then em=$i	# the field number that contains the email
	else	# if the first line contains any thing else then it is not the needed file so exit
		echo "The file entered does not have the right header which means it doesn't contains the right data."
		exit 2
	fi
done
# calculate the lines number in the file with the header 
numlines=$(cat $filename | wc -l)
i=1
#creating temporarily file to store data in it $$ is used beacuse it gives a special number to file in a case that the file exist before
touch temp.$$_$$
# loop that takes each line alone and reorder it and then insert it in the temp file
while [ "$i" -le "$numlines" ]
do
	# get the line based on a counter using sed command
	line=$(sed -n ''$i'p' $filename)
	# get the field that contains the first name based on the variables from the up loop, xargs will trim spaces form the start and end
	fname=$(echo "$line" | cut -d',' -f"$fn")
        fname=$(echo $fname | xargs)
	lname=$(echo "$line" | cut -d',' -f"$la")
        lname=$(echo $lname | xargs)
	phone=$(echo "$line" | cut -d',' -f"$ph")
        phone=$(echo $phone | xargs)
	emai=$(echo "$line" | cut -d',' -f"$em")
        emai=$(echo $emai | xargs)
	#insert the data inside the temp file
	echo "$fname, $lname, $phone, $emai" >> temp.$$_$$
	i=$(($i + 1))
done
# copy the temp file to main file of Contacts
cat temp.$$_$$ > $filename
rm temp.$$_$$
# search method will be used in Edit and listing and deleting
# it will read from the user and then find the lines that contains what he/she entered
search(){
	read searchstr
	# if the user enter more than one field or part of field
	for str in $searchstr
	do
		grep "$str" searchfile.$$_$$ > /tmp/searchfile.$$_$$
		mv /tmp/searchfile.$$_$$ searchfile.$$_$$
	done
}
# the add contact method will let the user enter a new Contact and save it in the file
AddContact(){
	echo "\tPlease add the data of the new contact as follows: "
	echo "Enter the first name: "
	read firstname
	# check if the user entered a first name, if not it will ask him/her again
	while [ -z "$firstname" ]
	do
		echo "You didn't enter the first name."
		echo "if you want to back to menu enter (%), otherwise enter the name again"
		read firstname
		# if the user change his mind and don't want to insert new contact, he/she could enter a (%) symbol
		if [ "$firstname" = "%" ]
		then 	return
		fi
	done
	# enter the last name, it could be empty and put (-) in its place
	echo "Enter the last name: "
	read lastname
	if [ -z "$lastname" ]
	then lastname='-'
	fi
	# ask the user how many numbers he/she wants to add
	echo "Please enter how many phone number you want to add: (%) to exit."
	while true
	do
		read numberofphones
		# if he/she didin't enter any value this line will appear at screen
		if [ -z "$numberofphones" ]
		then echo "You didn't enter anything, please enter a value, or (%) to exit"
			continue
		# if he/she enterd % then it will back to the main menu
		elif [ "$numberofphones" = "%" ]
		then return
		fi
		# after entering the number needed i will check if there are another charecters except digits
		# so i count the number of digits before deleting any other character and after then a compare the result
		beforelength=$(echo "$numberofphones" | wc -c)
                numberofphones=$(echo "$numberofphones" | tr -dc '[0-9]')
                afterlength=$(echo "$numberofphones" | wc -c)
                if [ "$beforelength" != "$afterlength" ]
                then echo "It is not allowed to enter any character. only digits. Try again or enter (%) to exit"
                	continue 1
		elif [ "$numberofphones" -lt 1 ]
                then echo "you must add at least one number. Try again or enter (%) to back to menu"
		else
			break 1
		fi
	done
	# after get the number of phones we will read these numbers
	phones=''
	while [ "$numberofphones" -gt 0 ] 	#loop that will repeated based on the number of phones
	do
		echo "Enter the phone number :"
		read phonenumber
		# if the user didn't enter any thing
		if [ -z "$phonenumber" ]
		then echo "Please enter any value. or (%) to exit."
			continue
		elif [ "$phonenumber" = "%" ]
		then return
		fi
		# the same operaton as i illustrated above
		beforelength=$(echo "$phonenumber" | wc -c)
		phonenumber=$(echo "$phonenumber" | tr -dc '[0-9]')
		afterlength=$(echo "$phonenumber" | wc -c)
		# if the phone number contains characters that not digits
		if [ "$beforelength" != "$afterlength" ]
		then	echo "the phone number you entered is wrong! Try again"
			continue 1
		# if the phone number is not 9 or 10 digits, i put (10 and 11 because the $ character at the end)
		elif [ "$afterlength" != 10 -a "$afterlength" != 11 ]
		then	echo "the number of digits in the number is not allowed! Try again"
			continue 1
		fi
		# this if..else statement will handle the phone number string with (;) which will be saved in the file
		if [ "$numberofphones" = 1 ]
		then
			phones="$phones$phonenumber"
		else
			phones="$phones$phonenumber;"
		fi
		numberofphones=$(($numberofphones - 1))
	done
	# ask the user to enter the email address
	echo "Please enter the email address: "
	read email
	# if the user didn't enter any value it will be (-)
	if [ -z "$email" ]
	then email='-'
	else
		# if he/she entered an email it must check the number of (@) in it
		ATsign=$(echo "$email" | tr -dc '@' | wc -c) #delete all characters except the @ and count them after
		while [ "$ATsign" != 1 -a -n "$email" ]
		do	 echo "You have entered a wrong email address! Try agian: (or enter (%) to exit)"
			read email
			#if the user enter an % symbol it will back to main menu
			if [ "$email" = "%" ]
			then	return
			fi
			ATsign=$(echo "$email" | tr -dc '@' | wc -c)
		done
	fi
	#enter the informations to the file as one line
	echo "$firstname, $lastname, $phones, $email" >> $filename
}
# in this method we will list all the contacts based on two options sort, first name or last name
ListContacts(){
	echo "Choose how you want to sort the Contacts based on the first name OR the last name "
	echo "enter (f) if you want first name, enter (l) for the last name, otherwise it will back to the menu"
	read sortchoice
	# if the user enter some thing wrong then it will back to menu
	if [ "$sortchoice" != "f" -a "$sortchoice" != "l" ]
	then return
	fi
	flags=
	# ask the user what fields he wants to show , character y considered as yes, otherwise is no
	echo "choose the fileds that you want to appear in the list"
	echo "Enter y if you want to insert it in the list otherwise it won't be add"
	echo "Do you want to show the first name"
	read fname
	# if yes add the first name to variable flags
	if [ "$fname" = "y" ]
	then	flags="1"
	fi
	echo "Do you want to show the last name"
	read lname
	if [ "$lname" = "y" ]
        then
		# if the flags still null the first parameter will be last name, otherwise it will be the concatenated
		if [ -z "$flags" ]
		then 	flags="2"
		else
		flags="$flags,2"
		fi
	fi
	echo "Do you want to show the phone numbers"
	read pnumbers
	if [ "$pnumbers" = "y" ]
        then
		# if the flags still null the first parameter will be phone numbers, otherwise it will be the concatenated
        	if [ -z "$flags" ]
        		then    flags="3"
                else
                       flags="$flags,3"
                fi
        fi
	echo "Do you want to show the email address"
	read eaddress
	if [ "$eaddress" = "y" ]
        then
		# if the flags still null the first parameter will be email address, otherwise it will be the concatenated
        	if [ -z "$flags" ]
                then    flags="4"
                else
                  	flags="$flags,4"
                 fi
         fi
	# if all fields was chosen as null then there is nothing to print or show, so back to main menu
	if [ -z "$flags" ]
	then	return
	fi
	echo "\n"
	if [ "$sortchoice" = "f" ]
	then
		#this command will sort the data based on first name we do it by using sort -k1
		cat "$filename" | sed '1d' | sort -k1 | cut -d',' -f"$flags"
	else
		#this command will sort the data based on last name we do it by using sort -k2
		cat "$filename" | sed '1d' | sort -k2 | cut -d',' -f"$flags"
	fi
}
# search method that will find all contacts with the entered details
SearchContacts(){
	echo "Please enter the details of the contact of your search:"
	# calling search method that was implemented before
	search
	echo "Search results:"
	cat searchfile.$$_$$
	rm searchfile.$$_$$
}
# this method will edit a specific contact after finding him/her from the entered details
EditContact(){
	echo "Please enter the details of the contact to edit"
	header=$(sed -n '1p' $filename)
	search
	# find the number of lines in the searchfile.$$_$$ (number of Contacts found)
	numoflines=$(cat searchfile.$$_$$ | wc -l)
	# if the number was greater than 1 then the user should enter more details beacuse we need only one contact
	while [ "$numoflines" -gt 1 ]
	do
		echo "There are many Contacts with your entered details: "
		# to show the user the contacts found and help him/her be more specific
		cat searchfile.$$_$$
		echo "Please enter more details so that you could find one contact."
		echo "I recommend you to enter the phone number"
		search
		numoflines=$(cat searchfile.$$_$$ | wc -l)
	done
	# if the number of lines found is 0 so no contact found, so back to menu
	if [ "$numoflines" = 0 ]
	then	echo "Sorry! there are no contact with the details entered. Try again from menu."
		return
	fi
	echo "the contact you want to edit before editing:"
	cat searchfile.$$_$$
	# then use comm command to delete this contact, and insert it again after editing
	sed '1d' $filename -i
        sort $filename > temp.$$_$$
        echo $header > $filename
	# comm command needs the file to be sorted
        comm -23 temp.$$_$$ searchfile.$$_$$ >> $filename
	rm temp.$$_$$
	# now we will start with the fields he/she wants to edit
	echo "Now enter the fields you want to edit"
	# save the old value of first name in fname variable after divide the line based on ','
	fname=$(cut -d',' -f"1" searchfile.$$_$$)
	fname=`echo $fname | xargs`	# use xargs to trim the string
	echo "Do you want to edit the first name? (y) for yes otherwise will be considered as No"
	read editFirst
	# if the user choose y then the first name will be edit
	if [ "$editFirst" = "y" ]
	then echo "Please enter the new First name:"
		read editFirst
		# if no name was entered then repeat the loop, and ask the user about the new name or keep the old name
		while [ -z "$editFirst" ]
                do
                	echo "You didn't enter the first name."
			# if the user entered % then it will keep the same old name
                        echo "if you want to keep the same name enter (%), otherwise enter the name again"
                        read editFirst
                        if [ "$editFirst" = "%" ]
                        then    editFirst=$fname
				break
                	fi
        	done
		# saving the name of the new edit name (could be the same old name)
		fname=$editFirst
	fi
	# save the old value of the last name in lname variable after divide the line based on ','
	lname=$(cut -d',' -f"2" searchfile.$$_$$)
	lname=`echo $lname | xargs`
	echo "Do you want to edit the last name? (y) for yes otherwise will be considered as No"
	read editLast
	# if the user choose y then the last name will be edit
	if [ "$editLast" = "y" ]
	then	echo "Please enter the new Last neme:"
		read editLast
		# if no name entered save the new name as (-)
		if [ -z "$editLast" ]
		then 	editLast="-"
		fi
		lname=$editLast
	fi
	# save the old value of the phone numbers in ePhone variable after divide the line based on ','
	ePhone=$(cut -d',' -f"3" searchfile.$$_$$)
	ePhone=`echo $ePhone | xargs`
	echo "Do you want to edit the phone numbers? (y) for yes otherwise will be considered as No"
	read editphone
	# if the user choose y the phone number will be edit
	if [ "$editphone" = "y" ]
	then
		# ask the user how many new number he wants to insert
		echo "Please enter how many new phone numbers you want to add:"
       		while true
       		do
                      	read numberofphones
			# if the user didn't entered anything ask him/her again
                       	if [ -z "$numberofphones" ]
                       	then echo "You didn't enter anything, please enter a value"
				continue
                       	fi
			# if the user enterd a non numberic value ask him/her again
                       	beforelength=$(echo "$numberofphones" | wc -c)
                       	numberofphones=$(echo "$numberofphones" | tr -dc '[0-9]')
                       	afterlength=$(echo "$numberofphones" | wc -c)
                       	if [ "$beforelength" != "$afterlength" ]
                       	then echo "It is not allowed to enter any character. only digits. Try again"
                               	continue 1
			# if the user enter number less than 1 ask him/her again
                       	elif [ "$numberofphones" -lt 1 ]
                       	then echo "you must add at least one number. Try again"
                       	else
                              	break 1
                       	fi
       		done
		phones=''
	        while [ "$numberofphones" -gt 0 ]
	        do
			# now ask the user to enter the numbers
	       		echo "Enter the phone number :"
               		read phonenumber
			# if the user enter didn't enter anything ask him/her again, or if he wants to keep the old numbers
               		if [ -z "$phonenumber" ]
                       	then echo "Please enter any value. or (%) to keep the same old numbers."
                              	continue
			# saving the old phone numbers if the user enter %
              		elif [ "$phonenumber" = "%" ]
			then	phones=$ePhone
                      		break
              		fi
			# check if the user enter a number with non numeric characters
                        beforelength=$(echo "$phonenumber" | wc -c)
               		phonenumber=$(echo "$phonenumber" | tr -dc '[0-9]')
                        afterlength=$(echo "$phonenumber" | wc -c)
                        if [ "$beforelength" != "$afterlength" ]
                        then    echo "the phone number you entered is wrong! Try again"
                        	continue 1
			# check if the number of digits in the phone number is 10 or 9 ( i put 10 and 11 beacuse of $ character at the end)
                        elif [ "$afterlength" != 10 -a "$afterlength" != 11 ]
                        then    echo "the number of digits in the number is not allowed! Try again"
                           	continue 1
                        fi
			# this format is used to handle the phone numbers together with (;)
			if [ "$numberofphones" = 1 ]
	               	then
                               	phones="$phones$phonenumber"
                      	else
        	               	phones="$phones$phonenumber;"
                	fi
               		numberofphones=$(($numberofphones - 1))
       		done
		ePhone=$phones
	fi
	# save the old email in the newemail variable
	newemail=$(cut -d',' -f"4" searchfile.$$_$$)
	newemail=`echo $newemail | xargs`
        echo "Do you want to edit the email? (y) for yes otherwise will be considered as No"
        read editemail
	# if the user choose y, then the email will be edit
	if [ "$editemail" = "y" ]
	then
		echo "Please enter the new email address: "
               	read email
		# check if the number of @ equals 1 only
               	ATsign=$(echo "$email" | tr -dc '@' | wc -c)
              	while [ "$ATsign" != 1 -a -n "$email" ]
               	do       echo "You have entered a wrong email address! Try agian: (or enter (%) to keep the same old email)"
                       	read email
			# if the user enter % then it will keep the same old email address
                       	if [ "$email" = "%" ]
                       	then    email=$newemail
				break
                       	fi
                       	ATsign=$(echo "$email" | tr -dc '@' | wc -c)
               	done
		newemail=$email
	fi
        rm searchfile.$$_$$
	# save the new edited contact in the file (it could not changed)
       	echo "$fname, $lname, $ePhone, $newemail" >> $filename
}
# this method will delete all the cotacts matched with the entered details
DeleteContact(){
	echo "Please enter the details of the contact to delete:"
	#saving the first line of the contact file
	header=$(sed -n '1p' $filename)
	search	# calling the search file
	#deleting the first line (the header)
	sed '1d' $filename -i
	# sort the search file and the contact file to use comm command
	sort searchfile.$$_$$ > /tmp/searchfile.$$_$$	# /tmp/searchfile.$$_$$ is the garbage file
	mv /tmp/searchfile.$$_$$ searchfile.$$_$$
	sort $filename > temp.$$_$$
	echo $header > $filename
	# to use this command you shoud sort the files before
	comm -23 temp.$$_$$ searchfile.$$_$$ >> $filename
	#delete the search file and the temp file
	rm searchfile.$$_$$
	rm temp.$$_$$
}
# if the file exist then he will enter this loop which will not end until choosing (0) which mean exit
while true
do
	# copy the contacts file to searchfile that will be used on searching opertion and delete the header
	cp $filename searchfile.$$_$$
        sed '1d' searchfile.$$_$$ -i
	# the main menu of the program
	echo "\n**** Welcome to Contact Managemnet System ****\n"
	echo "\t\tMain MENU"
	echo "\t======================"
	echo "\t[1] Add a new Contact"
	echo "\t[2] List all Contacts"
	echo "\t[3] Search for contact"
	echo "\t[4] Edit a contact"
	echo "\t[5] Delete a contact"
	echo "\t[0] Exit"
	echo "\t================="
	echo "\tEnter the choice: "
	read choice
	# case statement that will handle the user choice
	case "$choice"
	in
		# if the user choose 0 the program will exit
		0) echo "\t Thanks for using the program. GoodBye!"
			rm searchfile.$$_$$
			 exit 2 ;;
		1) AddContact;;
		2) ListContacts;;
		3) SearchContacts;;
		4) EditContact;;
		5) DeleteContact;;
	esac
done
