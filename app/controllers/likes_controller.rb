class LikesController < ApplicationController

  def create
    # crea un like a partir del usuario logueado enlazando el id del post enviado en el link_to
    like = current_user.likes.build(post_id: params[:post_id])
    
    if like.save
      redirect_to :back
    else
      flash[:error] = "Something went wrong!"
    end
  end

  def destroy
    Like.find(params[:id]).destroy
    redirect_to :back
  end
end
