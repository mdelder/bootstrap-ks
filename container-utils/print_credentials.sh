#!/bin/sh

SECRET=${1}
NAMESPACE=${2:-bootstrap-ks}

oc get secrets -n $NAMESPACE $SECRET \
     -ogo-template='{{printf "\nConsole: %s\nUsername: %s\nPassword: %s\nJSON: %s\n\n" (.data.console_url|base64decode) (.data.username|base64decode) (.data.password|base64decode) (.data.json|base64decode) }}'