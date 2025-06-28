# Scope

The difference between using the `--local`, `--global`, and no flag in the `git config` command determines the scope at which the configuration is applied:

1. **`--local` flag**:

   - This sets the configuration for the current **repository** only.
   - The configuration is stored in the `.git/config` file inside the specific repository.
   - Example:
     ```bash
     git config --local user.email "myEmailAddress@example.com"
     ```
   - **Use case**: When you want the email address (or any other configuration) to be specific to a particular repository.

2. **`--global` flag**:

   - This sets the configuration for the **global** scope, meaning it applies to **all repositories** for the current user on that system.
   - The configuration is stored in the user's `~/.gitconfig` file (in the user's home directory).
   - Example:
     ```bash
     git config --global user.email "myEmailAddress@example.com"
     ```
   - **Use case**: When you want to set your email or other settings for all repositories globally, without needing to set it for each one individually.

3. **No flag (default)**:
   - When no flag is provided, Git tries to set the configuration at the **local level** if you're inside a repository. If you're not in a Git repository, it defaults to **global** scope.
   - Example:
     ```bash
     git config user.email "myEmailAddress@example.com"
     ```
   - **Use case**: It is generally safer to explicitly specify `--local` or `--global` to avoid confusion, but if no flag is specified and you're inside a repository, it will apply to the current repository.

### Summary:

- `--local`: Sets configuration specific to the current repository.
- `--global`: Sets configuration for all repositories for the current user.
- No flag: Defaults to the current repository (local scope) if inside one, or global otherwise.
