#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [ -e blog ]; then echo "blog/ already exists; refusing to overwrite it."; exit 1; fi
command -v ruby >/dev/null || { echo "Install Ruby 3.2+ first"; exit 1; }
command -v bundle >/dev/null || gem install bundler
gem install rails -v 8.1.4 --no-document
rails _8.1.4_ new blog --database=sqlite3 --skip-git
cd blog
mkdir -p app/controllers app/models app/views/articles app/views/comments db/migrate test/models
cat > config/routes.rb <<'RUBY'
Rails.application.routes.draw do
  root "articles#index"
  resources :articles do
    resources :comments, only: [:create, :destroy]
  end
end
RUBY
cat > app/models/article.rb <<'RUBY'
class Article < ApplicationRecord
  CATEGORIES = %w[Campus Technology Sports Arts].freeze
  has_many :comments, dependent: :destroy
  validates :title, presence: true, length: { minimum: 5, maximum: 120 }
  validates :body, presence: true, length: { minimum: 20 }
  validates :category, inclusion: { in: CATEGORIES }
  scope :recent_first, -> { order(created_at: :desc) }
end
RUBY
cat > app/models/comment.rb <<'RUBY'
class Comment < ApplicationRecord
  belongs_to :article
  validates :author, presence: true, length: { maximum: 60 }
  validates :body, presence: true, length: { minimum: 2, maximum: 1000 }
end
RUBY
cat > app/controllers/articles_controller.rb <<'RUBY'
class ArticlesController < ApplicationController
  before_action :find_article, only: %i[show edit update destroy]
  before_action :editor_only, except: %i[index show]
  def index
    @category = Article::CATEGORIES.include?(params[:category]) ? params[:category] : nil
    @articles = Article.includes(:comments).recent_first
    @articles = @articles.where(category: @category) if @category
  end
  def show
    @comment = @article.comments.build
  end
  def new
    @article = Article.new
  end
  def create
    @article = Article.new(article_params)
    return redirect_to @article, notice: "Article published" if @article.save
    render :new, status: :unprocessable_entity
  end
  def edit; end
  def update
    return redirect_to @article, notice: "Article updated" if @article.update(article_params)
    render :edit, status: :unprocessable_entity
  end
  def destroy
    @article.destroy!
    redirect_to articles_path, notice: "Article deleted", status: :see_other
  end
  private
  def find_article
    @article = Article.find(params[:id])
  end
  def article_params
    params.require(:article).permit(:title, :body, :category, :featured)
  end
  def editor_only
    authenticate_or_request_with_http_basic("Editor") do |user, pass|
      expected_user = ENV["MIDTERM_EDITOR_USER"]
      expected_pass = ENV["MIDTERM_EDITOR_PASSWORD"]
      expected_user.present? && expected_pass.present? &&
        ActiveSupport::SecurityUtils.secure_compare(user, expected_user) &&
        ActiveSupport::SecurityUtils.secure_compare(pass, expected_pass)
    end
  end
end
RUBY
cat > app/controllers/comments_controller.rb <<'RUBY'
class CommentsController < ApplicationController
  before_action :find_article
  def create
    @comment = @article.comments.new(params.require(:comment).permit(:author, :body))
    if @comment.save
      redirect_to @article, notice: "Comment added", status: :see_other
    else
      redirect_to @article, alert: @comment.errors.full_messages.to_sentence, status: :see_other
    end
  end
  def destroy
    authenticate_or_request_with_http_basic("Editor") do |user, pass|
      ENV["MIDTERM_EDITOR_USER"].present? && ENV["MIDTERM_EDITOR_PASSWORD"].present? &&
        ActiveSupport::SecurityUtils.secure_compare(user, ENV["MIDTERM_EDITOR_USER"]) &&
        ActiveSupport::SecurityUtils.secure_compare(pass, ENV["MIDTERM_EDITOR_PASSWORD"])
    end
    @article.comments.find(params[:id]).destroy!
    redirect_to @article, status: :see_other
  end
  private
  def find_article
    @article = Article.find(params[:article_id])
  end
end
RUBY
cat > db/migrate/20261113000001_create_articles.rb <<'RUBY'
class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.string :title, null: false
      t.text :body, null: false
      t.string :category, null: false, default: "Campus"
      t.boolean :featured, default: false, null: false
      t.timestamps
    end
    add_index :articles, :category
  end
end
RUBY
cat > db/migrate/20261113000002_create_comments.rb <<'RUBY'
class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.references :article, null: false, foreign_key: true
      t.string :author, null: false
      t.text :body, null: false
      t.timestamps
    end
  end
end
RUBY
cat > app/views/articles/index.html.erb <<'ERB'
<main style="max-width:850px;margin:3rem auto;font-family:system-ui;padding:1rem">
  <h1>Nasif's Campus Chronicle</h1>
  <p>Stories from campus, technology, sports and the arts.</p>
  <nav><%= link_to "All", root_path %>
    <% Article::CATEGORIES.each do |category| %> |
      <%= link_to category, root_path(category: category) %>
    <% end %>
  </nav>
  <p><%= link_to "Write a story (editor)", new_article_path %></p>
  <% @articles.each do |article| %>
    <article style="padding:1.5rem 0;border-bottom:1px solid #ddd">
      <small><%= article.category %> · <%= article.created_at.strftime("%b %d, %Y") %>
        <%= "· Featured" if article.featured? %></small>
      <h2><%= link_to article.title, article %></h2>
      <p><%= truncate(article.body, length: 180) %></p>
      <small><%= pluralize(article.comments.size, "comment") %></small>
    </article>
  <% end %>
  <p><%= "No stories in this category yet." if @articles.empty? %></p>
</main>
ERB
cat > app/views/articles/_form.html.erb <<'ERB'
<%= form_with model: article do |f| %>
  <% if article.errors.any? %>
    <ul><% article.errors.full_messages.each do |error| %><li><%= error %></li><% end %></ul>
  <% end %>
  <p><%= f.label :title %><br><%= f.text_field :title, required: true, size: 60 %></p>
  <p><%= f.label :category %><br><%= f.select :category, Article::CATEGORIES %></p>
  <p><%= f.label :body %><br><%= f.text_area :body, rows: 12, cols: 70, required: true %></p>
  <p><%= f.check_box :featured %> <%= f.label :featured %></p>
  <%= f.submit %>
<% end %>
ERB
cat > app/views/articles/new.html.erb <<'ERB'
<h1>New article</h1>
<%= render "form", article: @article %>
<%= link_to "Back", articles_path %>
ERB
cat > app/views/articles/edit.html.erb <<'ERB'
<h1>Edit article</h1>
<%= render "form", article: @article %>
<%= link_to "Back", @article %>
ERB
cat > app/views/articles/show.html.erb <<'ERB'
<main style="max-width:850px;margin:3rem auto;font-family:system-ui;padding:1rem">
  <%= link_to "← All stories", articles_path %>
  <h1><%= @article.title %></h1>
  <small><%= @article.category %> · <%= @article.created_at.strftime("%b %d, %Y") %></small>
  <div style="white-space:pre-wrap;line-height:1.7"><%= @article.body %></div>
  <p><%= link_to "Edit (editor)", edit_article_path(@article) %>
  <%= button_to "Delete (editor)", @article, method: :delete, data: { turbo_confirm: "Delete this story?" } %></p>
  <h2>Comments</h2>
  <% @article.comments.where.not(id: nil).each do |comment| %>
    <p><strong><%= comment.author %></strong>: <%= comment.body %></p>
    <%= button_to "Remove (editor)", article_comment_path(@article, comment), method: :delete %>
  <% end %>
  <h3>Join the conversation</h3>
  <%= form_with model: [@article, @comment] do |f| %>
    <p><%= f.label :author %><br><%= f.text_field :author, required: true %></p>
    <p><%= f.label :body %><br><%= f.text_area :body, required: true %></p>
    <%= f.submit "Post comment" %>
  <% end %>
</main>
ERB
cat > db/seeds.rb <<'RUBY'
Article.find_or_create_by!(title: "Welcome to the Campus Chronicle") do |article|
  article.category = "Campus"
  article.featured = true
  article.body = "This is the first story in my Rails 8.1 midterm application. More campus updates, technology ideas, sports stories and creative projects are coming soon."
end
RUBY
bundle install
bin/rails db:prepare
bin/rails db:seed
echo "Setup complete. Run: cd blog && MIDTERM_EDITOR_USER=editor MIDTERM_EDITOR_PASSWORD='choose-a-strong-password' bin/rails server -b 0.0.0.0 -p 8080"
