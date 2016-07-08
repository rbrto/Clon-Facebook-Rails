class UsersController < ApplicationController
  require 'will_paginate/array'
  
  def index
    @users = User.paginate(page: params[:page])
  end
  
  def show
    @user = User.find(params[:id])
    @post = current_user.posts.build
    @posts = @user.posts.paginate(page: params[:page])
  end
  
  def friends
    #devuelve el usuario puede ser el logueado o no logueado 
    @user = User.find(params[:id])
    @friends = @user.friends.paginate(page: params[:page])
  end
end
