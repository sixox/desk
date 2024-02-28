class LetterHeadsController < ApplicationController
	before_action :authenticate_user!

	def new	
		@letter_head = LetterHead.new
	end

	def create
		@letter_head = LetterHead.new(letter_head_params)
		respond_to do |format|
			if @letter_head.save
				format.html { redirect_to projects_path, notice: "file was successfully created." }
			else
				format.html { redirect_to projects_path, alert: "file was not created." }

			end
		end
	end



	private

   

   

    def letter_head_params
      params.require(:letter_head).permit(:name, :file)
    end
end
