class ProfilesController < AuthenticatedController
  def show
    @user = Current.user
  end

  def update
    @user = Current.user

    if @user.update(profile_params)
      redirect_to profile_path, status: :see_other, notice: "Profile updated."
    else
      flash.now[:alert] = "Please fix the highlighted fields."
      render :show, status: :unprocessable_content
    end
  end

  def destroy_avatar
    # Sync purge so the avatar is gone the moment we redirect — purge_later
    # only deferred the blob deletion, but here we want both gone now.
    Current.user.avatar.purge
    redirect_to profile_path, status: :see_other, notice: "Avatar removed."
  end

  private

  def profile_params
    params.expect(user: [ :name, :avatar ])
  end
end
