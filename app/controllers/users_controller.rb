class UsersController < ApplicationController
  before_action :require_logout, except: [:index, :show, :update_avatar, :update_cover, :notify]
  before_action :get_user, only: [:show, :update_avatar, :update_cover, :stats]
  skip_before_filter :get_current_url, except: :show
  skip_before_filter :require_login

  def index
    @users = User.all.where("LOWER(first_name) LIKE LOWER(?)", "%#{params[:search]}%") if params[:search]
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.validate_password!

    if !@user.errors.any? && @user.save
      auto_login(@user)
      redirect_to root_url
    else
      @user.save # throws validation errors
      @user.validate_password!
      render :new
    end
  end

  def create_with_particle
    @user = User.new(user_params)
    h = particle_params(user_params[:email], user_params[:password])

    unless @user.is_not_particle_authenticated(h)
      @user.access_token = HTTParty.post('https://api.particle.io/oauth/token', body: h)["access_token"]

      if @user.save
        auto_login(@user)
        redirect_to root_url
      else
        render :new
      end
    else
      @user.errors[:base] << "Email or password was incorrect"
      render :new
    end
  end

  def show
    get_friendships(@user)
    get_stats(@user)
    gon.userId = @user.id
  end

  def update_avatar
    respond_to do |format|
      if @user.update_attributes(avatar_params)
        format.html { redirect_to session[:current_url], alert: "Avatar updated" }
        format.js {}
      else
        format.html { render session[:current_url], alert: "Update failed" }
        format.js {}
      end
    end
  end

  def update_cover
    respond_to do |format|
      if @user.update_attributes(cover_params)
        format.html { redirect_to session[:current_url], alert: "Cover Photo updated" }
        format.js {}
      else
        format.html { render session[:current_url], alert: "Update failed" }
        format.js {}
      end
    end
  end

  def notify
    respond_to do |format|
      format.js {}
    end
  end

  private
  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation)
  end

  def avatar_params
    params.require(:user).permit(:avatar)
  end

  def cover_params
    params.require(:user).permit(:cover)
  end

  def get_user
    @user = User.find(params[:id])
  end
end
