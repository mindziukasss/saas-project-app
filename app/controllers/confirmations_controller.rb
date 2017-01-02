class ConfirmationsControlle < Milia::ConfirmationsControlle

	def update
		if @confirmable.attempt_set_password(user_params)

			self.resource = resource_class.confirm_class.confirm_by_token(params[:confirmation_token])
			yield resource if block_given?

			if resource.errors.empty?
				log_action( "invitee confirmed")
				set_flash_message(:notice, :confirmed) if is_flashing_format?

				sign_in_tenanted_and_redirect(resource)
			else
				log_action ("invitee confirmation failed")
				respond_with_navigational(resource.errors, status: :unprocessable){ render :new}
			end

		else
			log_action ("invitee password set faild")
			prep_do_show()
			respond_with_navigational(resource.errors, status: :unprocessable_entity) { render :show}
		end

	end

	def show
		if @confirmable.new_record? ||
			!::Milia.use_invite_member ||
			@confirmable.skip_confirm_change_password

			log_action( "devise pass-thru")
			self.resource = resource_class.confirmed_by_token(params[:confirmation_token])
			yield resource if block_given?

			if resource.errors.empty?
				set_flash_message(:notice, :confirmed) if is_flashing_format?
			end

			if @confirmable.skip_confirm_change_password
				sign_in_tenanted_and_redirect(resource)
			end
		else
			log_action("password set form")
			flash[:notice] = "Pleass choose a password and confirm it"
			prep_do_show()
		end

		
	end
	def after_confirmation_path_for(resource_name, resource)
		if user_signed_in?
			root_path
		else
			new_user_session_path
		end
		
	end

	private

	def set_confirmable()
		@confirmable = User.find_or_initialize_with_errors_by(:confirmation_token,params[:confirmation_token])
	end

end