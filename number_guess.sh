#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"


GAME_ON(){
	USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
	NUMBER=$(( 1 + $RANDOM % 1000 ))
	echo -e "Guess the secret number between 1 and 1000:"
	LOSE=true
	TRIES=0
	while $LOSE
	do
		read GUESS
		if [[ ! $GUESS =~ ^[0-9]+$ ]]
		then
			echo "That is not an integer, guess again:"
		else
			if [[ $GUESS -lt $NUMBER ]]
			then
				(( TRIES++ ))
				echo -e "It's higher than that, guess again:"
			elif [[ $GUESS -gt $NUMBER ]]
			then
				(( TRIES++ ))
				echo -e "It's lower than that, guess again:"
			elif [[ $GUESS -eq $NUMBER ]]
			then
				(( TRIES++ ))
				INSERT_GAME=$($PSQL "INSERT INTO games(number_guesses,user_id) VALUES($TRIES,$USER_ID)")
				echo -e "You guessed it in $TRIES tries. The secret number was $NUMBER. Nice job!"
				LOSE=false
			fi
		fi
	done
}


echo -e "\n~~Welcome to the Number guessing Game~~\n"

echo -e "\nEnter your username:"
read USERNAME

USERNAME_FOUND=$($PSQL "SELECT * FROM users WHERE username = '$USERNAME'")

if [[ -z $USERNAME_FOUND ]]
then
	echo -e "Welcome, $USERNAME! It looks like this is your first time here."
	USERNAME_ENTERED=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
	GAME_ON
else
	FULL_USER_INFORMATION=$($PSQL "SELECT username,COUNT(number_guesses),MIN(number_guesses) FROM users INNER JOIN games USING (user_id) WHERE username = '$USERNAME' GROUP BY username")
	if [[ -z $FULL_USER_INFORMATION ]]
	then
		echo -e "Welcome, $USERNAME! It looks like this is your first time here."
		GAME_ON
	else
		echo "$FULL_USER_INFORMATION" | while IFS=" | " read FULL_USERNAME GAMES_COUNT GAMES_MAX
		do
			echo -e "Welcome back, $FULL_USERNAME! You have played $GAMES_COUNT games, and your best game took $GAMES_MAX guesses."
		done
		GAME_ON
	fi
fi
