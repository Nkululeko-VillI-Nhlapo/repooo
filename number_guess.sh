
#!/bin/bash

# Function to generate a random number between 1 and 1000
generate_random_number() {
  echo $((1 + RANDOM % 1000))
}

# Function to check if a username exists in the database
check_username_exists() {
  local username=$1
  local count=$(psql --username=freecodecamp --dbname=postgres -t --no-align -c "SELECT COUNT(*) FROM number_guess WHERE username='$username';")
  echo "$count"
}

# Function to fetch user's game statistics
fetch_user_stats() {
  local username=$1
  local stats=$(psql --username=freecodecamp --dbname=postgres -t --no-align -c "SELECT games_played, best_game FROM number_guess WHERE username='$username';")
  echo "$stats"
}

# Function to update user's game statistics
update_user_stats() {
  local username=$1
  local games_played=$2
  local best_game=$3
  psql --username=freecodecamp --dbname=postgres -c "INSERT INTO number_guess (username, games_played, best_game) VALUES ('$username', $games_played, $best_game) ON CONFLICT (username) DO UPDATE SET games_played = EXCLUDED.games_played, best_game = EXCLUDED.best_game;"
}

# Main function
main() {
  clear

  # Prompt the user for a username
  read -p "Enter your username: " username

  # Check if the username exists in the database
  username_exists=$(check_username_exists "$username")

  if [ "$username_exists" -eq 1 ]; then
    # Fetch user's game statistics if the username exists
    stats=$(fetch_user_stats "$username")
    IFS='|' read -r games_played best_game <<< "$stats"
    echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
  else
    echo "Welcome, $username! It looks like this is your first time here."
  fi

  # Generate the secret number
  secret_number=$(generate_random_number)

  # Initialize variables
  guess=""
  num_guesses=0

  # Start the game
  while true; do
    read -p "Guess the secret number between 1 and 1000: " guess

    # Check if the input is an integer
    if ! [[ "$guess" =~ ^[0-9]+$ ]]; then
      echo "That is not an integer, guess again:"
      continue
    fi

    # Increment the number of guesses
    ((num_guesses++))

    # Check if the guess is correct
    if [ "$guess" -eq "$secret_number" ]; then
      echo "You guessed it in $num_guesses tries. The secret number was $secret_number. Nice job!"
      break
    elif [ "$guess" -lt "$secret_number" ]; then
      echo "It's higher than that, guess again:"
    else
      echo "It's lower than that, guess again:"
    fi
  done

  # Update user's game statistics
  if [ "$username_exists" -eq 1 ]; then
    if [ "$num_guesses" -lt "$best_game" ]; then
      update_user_stats "$username" "$(($games_played + 1))" "$num_guesses"
    else
      update_user_stats "$username" "$(($games_played + 1))" "$best_game"
    fi
  else
    update_user_stats "$username" 1 "$num_guesses"
  fi
}

# Call the main function
main
