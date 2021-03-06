class RegistrationsController < Devise::RegistrationsController
  prepend_before_filter :authenticate_scope!, :only => [:index, :billing, :edit, :update, :destroy]
  before_filter :verify_admin, :only => [:index, :destroy, :billing]
  before_filter :set_cache_buster, except: [:new, :create, :update, :billing]

  layout "application"

  def index
    @users = current_account.users.active.order("name") if current_user

    respond_to { |format|
      format.json { render :json => @users.to_json(:only => User::JSON_FIELDS), :status => :ok}
    }
  end

  def new
    flash.now[:plan] = params[:plan]
    flash.now[:plan] = "trial" if !["basic", "professional", "premier"].include? flash.now[:plan]
    super
  end

  # DELETE /users/(:id)
  def destroy
    if params[:id]    # deactivating a user
      u = current_account.users.find(params[:id])
      u.update_attribute :active, false
      respond_to { |format|
        format.json { render :json => {}, :status => :ok }
      }
    else              # deactivating the account
      current_account.deactivate
      flash.now[:alert] = "We are sorry to see you go. If you have any feedback about OnlineChecklists, please write us "
      #redirect_to destroy_user_session_path
      sign_out # this will sign out everyone (I think)
    end
  end

  def create
    success = false

    begin
      Account.transaction {
        plan = params[resource_name][:plan]
        acc = Account.new
        build_resource
        resource.role = "admin"
        acc.users << resource
        acc.save!
        acc.create_subscriber(plan)
        success = true
      }
    rescue ActiveRecord::RecordInvalid
      flash.now[:alert] = "The email address is already in use, please log into your existing account or use another email address to create a new account."
    rescue
      flash.now[:alert] = "Account couldn't be created, sorry about that. Please contact us at #{SUPPORT_EMAIL} and we'll sort it out for you."
      raise
    end
    if success
      set_flash_message :notice, :signed_up
      DelayedMailer.push(:signup_confirmation, resource.id)
      sign_in_and_redirect(resource_name, resource)
    else
      flash.now[:alert] ||= "Sign up failed, please try again"
      clean_up_passwords(resource)
      flash.now[:plan] = params[resource_name][:plan]
      render_with_scope :new
    end
  end

  # PUT /resource
  def update
    if resource.update_with_password(params[resource_name])
      sign_in(resource, :bypass => true)  # this is to prevent Devise from signing out after password change
      current_account.update_attribute :time_zone, params[:account][:time_zone] if current_user.role == "admin"
      set_flash_message :notice, :updated
      redirect_to after_update_path_for(resource)
    else
      clean_up_passwords(resource)
      render_with_scope :edit
    end
  end


  def billing
    check_account_status

    @plan = get_plan
    @plans = current_account.get_plans
    @edit_subscription_url = Spreedly::edit_subscriber_url(current_account.get_subscriber.token, billing_url)
  end

  protected

#  def after_update_path_for(resource)
#    edit_user_registration_path
#  end

  def after_sign_in_path_for(resource)
    root_path
  end

  def verify_admin
    if current_user.role != "admin"
      redirect_to edit_user_registration_path
    end
  end
end
