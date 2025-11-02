#!/bin/bash

# PSQL helper
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# generate random number 1-1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# ask for username
echo "Enter your username:"
read USERNAME

# get user row
USER_RESULT=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username='$USERNAME';")

if [[ -z $USER_RESULT ]]
then
  # new user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  # insert new user
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 0, NULL);")
  # pull user info again
  USER_RESULT=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username='$USERNAME';")
else
  # existing user
  IFS="|" read USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_RESULT"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# parse values after possibly inserting
IFS="|" read USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_RESULT"

# ask to guess
echo "Guess the secret number between 1 and 1000:"
NUMBER_OF_GUESSES=0

while true
do
  read GUESS

  # check integer using regex: optional minus? not allowed actually, but we'll just require digits
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    continue
  fi

  # valid integer
  NUMBER_OF_GUESSES=$(( NUMBER_OF_GUESSES + 1 ))

  if (( GUESS == SECRET_NUMBER ))
  then
    # player wins, update DB

    # games_played +1
    NEW_GAMES_PLAYED=$(( GAMES_PLAYED + 1 ))

    # best_game: if NULL or current < best
    if [[ -z $BEST_GAME ]] || (( NUMBER_OF_GUESSES < BEST_GAME ))
    then
      NEW_BEST_GAME=$NUMBER_OF_GUESSES
    else
      NEW_BEST_GAME=$BEST_GAME
    fi

    # update row
    UPDATE_RESULT=$($PSQL "UPDATE users SET games_played=$NEW_GAMES_PLAYED, best_game=$NEW_BEST_GAME WHERE user_id=$USER_ID;")

    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
    break
  elif (( GUESS > SECRET_NUMBER ))
  then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
done
