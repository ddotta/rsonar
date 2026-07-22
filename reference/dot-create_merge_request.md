# Create a Merge Request / Pull Request

Detects the CI environment (GitLab CI or GitHub Actions) and opens a
Merge Request or Pull Request with the formatted changes.

## Usage

``` r
.create_merge_request(path, branch_name, commit_message, mr_title)
```

## Arguments

- path:

  Project root.

- branch_name:

  Name of the branch to create.

- commit_message:

  Git commit message.

- mr_title:

  Title of the MR/PR.

## Value

A list with `url` (MR/PR URL) and `branch` (branch name).
