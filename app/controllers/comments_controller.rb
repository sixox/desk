# app/controllers/comments_controller.rb
class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_commentable
  before_action :set_comment, only: %i[show edit update destroy]

  def index
    @comments = @commentable.comments
  end

  def new
    @comment = @commentable.comments.new
  end

  def create
    @comment = @commentable.comments.new(comment_params)
    @comment.user = current_user

    respond_to do |format|
      if @comment.save
        format.turbo_stream { render turbo_stream: turbo_stream.prepend('comment_items', partial: 'comments/comment', locals: { comment: @comment }) }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace('remote_modal', partial: 'shared/turbo_modal', locals: { form_partial: 'comments/form', modal_title: 'Create New Comment' })}
      end
    end

    
  end

  def show
  end

  def edit
  end


  private

  def set_commentable
    if params[:payment_order_id]
      @commentable = PaymentOrder.find(params[:payment_order_id])
    end
  end

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:body, files: [])
  end
end
