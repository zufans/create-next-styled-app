#!/bin/bash
clear="\x1Bc"
echo "$clear"

source ./Shell/Github/check/checkBrew.sh
source ./Shell/Github/check/checkDialog.sh
source ./Shell/Github/check/checkPackage.sh
# functions
source ./Shell/Github/functions/isGitInitialized.sh
source ./Shell/Github/functions/stageAndCommitFiles.sh
source ./Shell/Github/functions/pushTOGitHub.sh
source ./Shell/Github/functions/createNewRepo.sh
# source ./Shell/Github/functions/getPersonalTokenFile.sh
source ./Shell/Github/functions/getAllGithubRepositores.sh
source ./Shell/Github/functions/newRepository.sh
source ./Shell/Github/functions/selectAccount.sh
source ./Shell/Github/functions/sendToGitHub.sh
source ./Shell/Github/functions/getPersonalAccessToken.sh
source ./Shell/Github/functions/publicOrPrivate.sh

# authentication
source ./Shell/Github/authentication/repository.sh
source ./Shell/Github/authentication/githubAuth.sh



checkPackageLoop(){
    checkBrew
    checkDialog
    packageList=( "jq" "gh" "git")
    count=0
    for package in "${packageList[@]}"; do
        checkPackage "$package"
    done
}
checkPackageLoop
echo "$clear"

function increment_test_file() {
  for file in *.test; do
    if [ -f "$file" ]; then
      number=$(echo "$file" | sed 's/\([0-9]*\).test/\1/')
      new_number=$((number + 1))
      new_filename="${new_number}.test"
      mv "$file" "$new_filename"
      
      echo "Renamed '$file' to '$new_filename'"
      return 0
    fi
  done
  echo "Error: No .test file found in the current directory."
  return 1
}
increment_test_file
HOME_DIR="$HOME"
PERSONAL_ACCESS_TOKEN_PATH="$HOME_DIR/.ssh/personal_access_token"
isGitInitialized "$PERSONAL_ACCESS_TOKEN_PATH"