# Git AI Assist

> Generate commit messages and daily reports with AI based on your Git changes.

**Git AI Assist** is a command-line tool that uses Artificial Intelligence to turn your project's changes into **professional commit messages** and **daily development reports**.

Instead of sending the entire source code to the AI, the tool primarily uses **Git diffs** to describe what has changed.

This allows it to generate contextualized text without Git AI Assist needing to maintain a copy of your project.

> **Important:** the tool requires access to an AI provider through an **API key** or equivalent credential. Git AI Assist does not provide or host the AI model itself.

---

# Requirements

Before using Git AI Assist, you need:

* Git installed.
* A Linux system compatible with the installation methods described below.
* An API key from one of the supported AI providers.

## API Key

Git AI Assist requires credentials to send requests to the AI provider's API.

During the initial setup, the tool will ask for:

1. Your AI provider.
2. Your API key.
3. Project-specific configuration.

The API key is used to authenticate requests made to the selected provider's API.

---

# 📦 Installation

There are several ways to install Git AI Assist.

## Method 1 — Download the script

Download `git-ai-assist.sh` from the repository:

**REPOSITORY URL**

Then make the file executable:

```bash
chmod +x git-ai-assist.sh
```

Optionally, move it to a directory available in your `PATH`:

```bash
sudo mv git-ai-assist.sh /usr/local/bin/git-ai-assist
```

You can then run the command directly:

```bash
git-ai-assist
```

---

## Method 2 — Clone the repository

Clone the project:

```bash
git clone https://github.com/leandroleonard/git-ai-assist.git
```

Enter the project directory:

```bash
cd git-ai-assist
```

Make the script executable:

```bash
chmod +x git-ai-assist.sh
```

Create a link so the command is available in your `PATH`:

```bash
sudo ln -s "$(pwd)/git-ai-assist.sh" /usr/local/bin/git-ai-assist
```

You can now run:

```bash
git-ai-assist
```

---

# ⚙️ Initial configuration

After installation, run:

```bash
git-ai-assist init
```

The setup assistant will ask for the information required to use the AI.

You will need to:

1. Choose an AI provider.
2. Enter your API key.
3. Configure the current project.

Once configured, Git AI Assist is ready to generate commits and reports.

---

# 🚀 Usage

## Generate a commit message

```bash
git-ai-assist gen-commit
```

The tool analyzes the current changes and asks the AI to generate a commit message based on them.

You can also provide additional context:

```bash
git-ai-assist gen-commit "Refactor authentication module"
```

---

## Generate a daily report

```bash
git-ai-assist gen-report
```

To provide additional context:

```bash
git-ai-assist gen-report "Fixed bug #123 in the payments API"
```

The result can be used in team communication tools such as Teams or Slack.

---

## View changes

Before sending the changes to the AI, you can inspect the current context:

```bash
git-ai-assist see-alt
```

This allows you to view the changes/diffs being considered.

---

## View command history

```bash
git-ai-assist history
```

Displays the history of commands executed by Git AI Assist.

---

# Commands

| Command                    | Description                              |
| -------------------------- | ---------------------------------------- |
| `git-ai-assist init`       | Configure the AI provider and project    |
| `git-ai-assist gen-commit` | Generate an AI-powered commit message    |
| `git-ai-assist gen-report` | Generate a daily report using AI         |
| `git-ai-assist see-alt`    | Display the current changes/diffs        |
| `git-ai-assist config`     | Reconfigure the provider and API key     |
| `git-ai-assist history`    | Display command history                  |

---

# AI Providers

Git AI Assist can use different AI providers.

| Provider   | Endpoint         | Models                |
| ---------- | ---------------- | --------------------- |
| **Groq**   | `api.groq.com`   | Llama, Mixtral, Gemma |
| **OpenAI** | `api.openai.com` | GPT models            |
| **xAI**    | `api.x.ai`       | Grok models           |

Model availability may change depending on the provider.

Git AI Assist does not host these models. Requests are made directly through the API of the configured provider.

---

# Security and privacy

Git AI Assist is designed to work with Git changes rather than requiring the entire project to be sent to the AI.

### API Keys

Credentials are stored with restricted permissions:

```text
600
```

This means the file can only be read and modified by its owner.

### Never commit your credentials

Do not upload files containing API keys to a public repository.

For example:

```text
config.env
```

should never be committed.

The project-specific directory is also automatically added to `.gitignore`.

### About code sent to the AI

Git AI Assist uses information from Git changes/diffs as context when generating results.

This **does not mean that no code can leave your machine**: a diff can naturally contain portions of source code.

Therefore, before using an AI provider, review that provider's privacy policies, data-retention policies, and API data usage terms.

---

# Configuration files

Git AI Assist maintains both global and project-specific configuration.

## Global configuration

```text
~/.config/git-ai-assist/

├── config.env
└── history.log
```

### `config.env`

Contains global settings such as:

* AI provider.
* API key.
* Other tool configuration.

### `history.log`

Stores the history of executed commands.

---

## Project configuration

Inside the Git project:

```text
.your-project/
└── .git-ai-assist/
    └── config.env
```

This file contains project-specific settings such as:

* Branch.
* Automatic commit settings.
* Other project-related preferences.

The `.git-ai-assist/` directory is automatically added to `.gitignore`.

---

# Examples

## Normal development workflow

After implementing a feature:

```bash
git status
```

Review the changes:

```bash
git-ai-assist see-alt
```

Generate a commit message:

```bash
git-ai-assist gen-commit
```

After reviewing the message:

```bash
git commit -m "generated message"
```

---

## With additional context

If the diff does not fully explain the purpose of the change:

```bash
git-ai-assist gen-commit "Fix authentication when the token expires"
```

The provided text is used as additional context during generation.

---

## Daily report

At the end of the day:

```bash
git-ai-assist gen-report
```

Or provide information that is not explicitly present in the diffs:

```bash
git-ai-assist gen-report "I also investigated the payment API timeout issue"
```

---

# Development

To contribute to the project:

```bash
git clone https://github.com/YOUR_USERNAME/git-ai-assist.git

cd git-ai-assist

git checkout -b feature/new-feature
```

Make your changes and create a commit:

```bash
git commit -m "feat: add new feature"
```

Push your branch:

```bash
git push origin feature/new-feature
```

Then open a Pull Request.

---

# Conventional Commits

The project follows the **Conventional Commits** specification.

| Type       | Usage                            |
| ---------- | -------------------------------- |
| `feat`     | New feature                      |
| `fix`      | Bug fix                          |
| `docs`     | Documentation changes            |
| `style`    | Formatting without logic changes |
| `refactor` | Code refactoring                 |
| `test`     | Adding or modifying tests        |
| `chore`    | Maintenance tasks                |

Example:

```bash
git commit -m "feat: add OpenAI provider support"
```

---

# License

This project is distributed under the **MIT License**.

See [`LICENSE`](LICENSE) for the complete license terms.

---

# ⭐ Contribute

If Git AI Assist is useful to you, consider leaving a ⭐ on the repository.

Contributions, suggestions, and fixes are welcome.

