## Un

## Unnecessary Functions

- Directory: ./Shell/Github/functions/isGitInitialized.sh
- Function: initializtionType
- isDeleted: no

<br/>

- Directory:
- Function:
- isDeleted: no

<br/>

- Directory:
- Function:
- isDeleted: no

## Scripts

```sh
    echo "\n----------start newRepository-----------"
    script_path="$(dirname "${BASH_SOURCE[0]}")/${BASH_SOURCE[0]##*/}"
    echo "newRepository: $script_path"
    echo "personal_access_token_dir: $personal_access_token_dir"
    ls -la $personal_access_token_dir
    echo "----------start newRepository-----------\n"
    exit 0
```

### To see configurations from a specific scope:

```sh
git config --local --list
```

After running git push -u origin main, you can just use git push in the future to push changes to origin/main without specifying origin or the branch.

The -f flag stands for --force.
