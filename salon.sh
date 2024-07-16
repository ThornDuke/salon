#!/bin/bash

# Salon manager

PSQL="psql --username=postgres --dbname=salon -X --tuples-only -c"

echo -e "\n~~~~~ MY SALON ~~~~~\n"

MAIN_MENU() {
  # Show a message if given as a parameter
  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  echo -e "Here are the services we offer:\n"
  # Show services
  SERVICES_RESULT=$($PSQL "SELECT service_id, name FROM services")
  echo "$SERVICES_RESULT" | while read SERVICE_ID BAR SERVICE_NAME
  do
    echo "$SERVICE_ID) $SERVICE_NAME"
  done

  echo -e "\nx) Exit"

  # choose a service
  echo -e "\nWhat service do you want to book?"
  read SERVICE_ID_SELECTED

  # if response = x (exit)
  if [[ $SERVICE_ID_SELECTED =~ ^[xX]$ ]]
  then
    exit 0
  fi

  # if service does not exists
  SERVICE_IN_DB=$($PSQL "SELECT service_id FROM services WHERE service_id = $SERVICE_ID_SELECTED;")
  if [[ -z $SERVICE_IN_DB ]]
  then
    # send to main menu
    MAIN_MENU "That service does not exists\n"
  else
    # show the choosen service
    CHOOSEN_SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;")
    echo -e "\nYou choosed the service: $(echo $CHOOSEN_SERVICE_NAME | sed -r 's/^ *| *$//g')"
  fi

  # if service exists, ask for a phone number
  echo -e "\nWhat is your phone number?\n"
  read CUSTOMER_PHONE
  # if CUSTOMER_PHONE is not into the db
  CUSTOMER_PHONE_IN_DB=$($PSQL "SELECT phone FROM customers WHERE phone = '$CUSTOMER_PHONE';")
  if [[ -z $CUSTOMER_PHONE_IN_DB ]]
  then
    # ask for the customer name
    echo -e "\nThere is no customer with that number."
    echo "What is your name?"
    read CUSTOMER_NAME
    # insert phone_number and customer name into the db
    INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers (phone, name) VALUES ('$CUSTOMER_PHONE', '$CUSTOMER_NAME');")
    # get the customer_id now inserted
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE';")
  else
    # retrieve the name and id of the customer, for future use
    CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE';")
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE';")
  fi
  # ask for the service time
  echo -e "\nWhat time would you like your $(echo $CHOOSEN_SERVICE_NAME | sed -r 's/^ *| *$//g'), $(echo $CUSTOMER_NAME | sed -r 's/^ *| *$//g')?"
  read SERVICE_TIME
  # insert service_id, customer_id and time into db
  INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments (service_id, customer_id, time) VALUES ($SERVICE_ID_SELECTED, $CUSTOMER_ID, '$SERVICE_TIME');")
  # notify the success of the operation
  echo -e "\nI have put you down for a $(echo $CHOOSEN_SERVICE_NAME | sed -r 's/^ *| *$//g') at $(echo $SERVICE_TIME | sed -r 's/^ *| *$//g'), $(echo $CUSTOMER_NAME | sed -r 's/^ *| *$//g')."
  exit
}

MAIN_MENU