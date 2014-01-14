# coding: utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :user_email

  class Helper
    include ::Singleton
    include ::ActionView::Helpers::SanitizeHelper
    extend ActionView::Helpers::SanitizeHelper::ClassMethods
  end

  def helper
    return Helper.instance
  end

  def current_book
    if session[:book_id] != nil and session[:book_id] != 0
      current_user.books.find_by_id(session[:book_id])
    else
      nil
    end
  end

  def current_tasks
    current_book ? current_book.tasks : current_user.tasks
  end

  def user_email
    @user_email = current_user ? current_user.email : ""
  end

  def get_book_name
    current_book ? current_book.name : Book.default_name
  end

  def get_prefix
    current_book ? current_book.name : ""
  end

  def get_task_counts
    current_book ? current_book.tasks.all_counts : current_user.tasks.all_counts
  end

  def get_all_book_counts
    [all_count_info] + books_count_info_array
  end

  def all_count_info
    all_info = current_user.tasks.all_counts
    all_info['id'] = 0
    all_info['name'] = Book.default_name

    all_info
  end

  def books_count_info_array
    current_user.books.inject([]){|all_book_count_info, book|
      all_book_count_info << book.task_count_info
    }.sort{|a,b| b['active_task'] <=> a['active_task'] }
  end

  def get_tasks(filter_str = "", done_num = 10)
    target_tasks = current_tasks

    if filter_str.blank?
      get_unfiltered_tasks(target_tasks, done_num)
    else
      get_filtered_tasks(target_tasks, filter_str, done_num)
    end
  end

  def get_unfiltered_tasks(target_tasks, done_num = 10)
    tasks = {
      :temporarily_tasks => target_tasks.by_status(:temporarily),
      :happy_tasks => target_tasks.by_status(:happy),
      :todo_low_tasks  => target_tasks.by_status(:todo_l),
      :doing_tasks     => target_tasks.by_status(:doing),
      :waiting_tasks   => target_tasks.by_status(:waiting),
      :done_tasks      => target_tasks.by_status(:done).limit(done_num),
    }
  end

  def get_filtered_tasks(target_tasks, filter_word, done_num = 10 )
    tasks = {
      :temporarily_tasks=> target_tasks.by_status_and_filter(:temporarily,  filter_word),
      :happy_tasks  => target_tasks.by_status_and_filter(:happy,  filter_word),
      :todo_low_tasks  => target_tasks.by_status_and_filter(:todo_l,  filter_word),
      :doing_tasks     => target_tasks.by_status_and_filter(:doing,   filter_word),
      :waiting_tasks   => target_tasks.by_status_and_filter(:waiting, filter_word),
      :done_tasks      => target_tasks.by_status_and_filter(:done,    filter_word).limit(done_num),
    }
  end

  def get_task_list_html
    render_to_string :partial => 'tasks/tasklist_default'
  end

end
