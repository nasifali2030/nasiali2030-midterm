# Nasif's Campus Chronicle — Rails 8.1 Midterm

An original article and comment web application for the ET-718 midterm, built with Ruby on Rails 8.1.

## Features
- Article listing, individual article pages, category filters, and featured labels
- Create, edit, and delete articles with editor authentication
- Reader comments and editor comment removal
- SQLite database, Rails validations, and database migrations

## Generate the full Rails app
This repository currently contains an application **generator script**, not a committed, fully generated Rails application. Run the following from a Ruby 3.2+ development environment:

```bash
git clone https://github.com/nasifali2030/nasiali2030-midterm.git
cd nasiali2030-midterm
git switch rails81-midterm-implementation
bash setup-midterm.sh
cd blog
MIDTERM_EDITOR_USER=editor MIDTERM_EDITOR_PASSWORD='replace-with-your-own-strong-password' bin/rails server -b 0.0.0.0 -p 8080
```

Open the development preview on port 8080. Editor actions prompt for HTTP Basic credentials. Never commit the editor password.

## Submit the generated application
After testing, commit the generated `blog/` folder, including `Gemfile.lock`, to your repository. Review `git status` first and ensure that no `.env`, credentials, database files, or passwords are staged.

```bash
cd ..
git add setup-midterm.sh README.md blog
git status
git commit -m "Add complete Rails 8.1 campus chronicle application"
git push -u origin rails81-midterm-implementation
```

## Verification
Run `cd blog && bin/rails -v`, `bin/rails db:prepare`, and `bin/rails test` in the development environment. The generated application has **not yet been boot-tested** by this repository change. The script refuses to overwrite an existing `blog/` directory.

## Attribution
The project structure and article/comment feature requirements were compared with a classmate's public midterm example. This implementation uses an original Campus Chronicle presentation and its own Rails application source.
