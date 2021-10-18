# Action Deploy on Managed Instance

Github action for deployment on managed instance.

[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)

## Usage

1. Create a `.github/workflows/deploy.yml` file in your GitHub repo, if one doesn't exist already.
2. Add the following code to the `deploy.yml` file.

```yml
on: push
name: Deploying WordPress Site
jobs:
  deploy:
    name: Deploy
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Deploy
      uses: docker://ghcr.io/rtcamp/action-deploy-on-managed-instance:latest
      env:
        SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY }}
        NPM_VERSION: 7.20.5
        NODE_VERSION: 14.17.6
        BUILD_DIRECTORY: buildDirectory/
        BUILD_COMMAND: echo "buildCommand"
        BUILD_SCRIPT: path/to/custom/script.sh
        DEPLOY_LOCATIONS: ./locations.csv
        VIP: false
```

3. Create `SSH_PRIVATE_KEY` secret using [GitHub Action's Secret](https://developer.github.com/actions/creating-workflows/storing-secrets) and store the private key that you use use to ssh to server(s) defined in `hosts.yml`.
4. Create `.github/hosts.yml` inventory file, based on [Deployer inventory file](https://deployer.org/docs/hosts.html#inventory-file) format. Make sure you explictly define GitHub branch mapping. Only the GitHub branches mapped in `hosts.yml` will be deployed, rest will be filtered out. Here is a sample [hosts.yml](https://github.com/rtCamp/wordpress-skeleton/blob/main/.github/hosts.yml).

## Environment Variables

This GitHub action's behavior can be customized using following environment variables:

Variable          | Default | Possible  Values            | Purpose
------------------|---------|-----------------------------|----------------------------------------------------
`NPM_VERSION`  | null    | 14.17.0       | NPM Version. If not specified, latest version will be used.
`NODE_VERSION`  | null    | 16.6.0       | Node Version. If not specified, latest version will be used.
`BUILD_DIRECTORY`  | null    | buildDirectory/       | Build directory. Generally root directory or directory like frontend
`BUILD_COMMAND`  | null    | npm run build       | Command used to compile the package and/or files etc.
`BUILD_SCRIPT`  | null    | `runTests.sh`       | Custom or predefined script to run after compilation.
`DEPLOY_LOCATIONS`  | null    | ./locations.csv       | csv file for locations needs to deployed on host.
`VIP`  | null    | True, False       | csv file for locations needs to deployed on host.

##### NOTE (For locations.csv): if trailing slash is not specified, then folder along with all files will be deployed. if trailing slash is appended to it content of the folder will be deployed.

## Maintainer

### rtCamp Maintainers:

| Name                    | Github Username   |
|-------------------------|-------------------|
| [Jay Shamnani](mailto:jay.shamnani@rtcamp.com) |  [@JayShamnani](https://github.com/JayShamnani) |

### Default Branch

`main`

### Branch naming convention

- For bug - `fix/issue-name` For example, `fix/shell-script-errors`
- For feature - `feature/issue-name` For example, `feature/add-plugin`

### Pull Request and issue notes

- Title should be same as Issue title. Also add issue number before title. For example, `AC-3 Added support for EC2`.
- Add proper description.
- Assign reviewer.
- PR should have one approval.

## Repo integrations

- Runs on Docker 😎
- Now configurable for github modules